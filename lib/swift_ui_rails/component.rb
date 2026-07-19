# frozen_string_literal: true

require "view_component"
require "ostruct"
require "digest"
require_relative "component/collection_support"
require_relative "component/slots"
require_relative "component/caching"
require_relative "reactive"
require_relative "security/component_validator"

module SwiftUIRails
  module Component
    class Base < ::ViewComponent::Base
      include SwiftUIRails::DSL
      include SwiftUIRails::Component::CollectionSupport
      include SwiftUIRails::Component::Slots
      include SwiftUIRails::Component::Caching
      include SwiftUIRails::Reactive if defined?(SwiftUIRails::Reactive)
      include SwiftUIRails::Security::ComponentValidator

      class_attribute :swift_states, default: {}
      class_attribute :swift_props, default: {}
      class_attribute :swift_computed, default: {}
      class_attribute :swift_effects, default: {}
      class_attribute :swift_slots, default: {}
      class_attribute :swift_ui_block, instance_accessor: false, default: nil

      class << self
        # ViewComponent 2.0 Collection Support
        def with_collection(collection, *args, **kwargs, &block)
          # Leverage ViewComponent 2.0's optimized collection rendering
          # This provides ~10x performance improvement over manual iteration
          super(collection, *args, **kwargs) do |item, item_counter|
            # Pass collection item and counter to block if provided
            if block_given?
              if block.arity == 2
                block.call(item, item_counter)
              else
                block.call(item)
              end
            else
              # Default rendering behavior
              new(collection_item: item, collection_counter: item_counter)
            end
          end
        end

        # Define the swift_ui DSL block
        def swift_ui(&block)
          # Store the block to be executed in the component context
          self.swift_ui_block = block

          define_method :call do
            # Create a DSL context for proper element management
            dsl_context = SwiftUIRails::DSLContext.new(self)

            # Store component reference in the context
            dsl_context.instance_variable_set(:@component, self)

            # Execute the block in the DSL context
            # The block execution will automatically register elements via create_element
            dsl_context.instance_eval(&self.class.swift_ui_block)

            # Lower the complete component, including its reactive root, into
            # one resolved RenderIR document before rendering any HTML. Action
            # handlers are registered while child nodes lower, so this decision
            # happens inside flush_elements after that work has completed.
            dsl_context.flush_elements do |children|
              if respond_to?(:reactive_rendering_enabled) && reactive_rendering_enabled
                [build_reactive_container_node(children, component_id)]
              else
                children
              end
            end
          end
        end

        # Component state uses Reactive::State as its single source of truth.
        # `swift_states` remains a compatibility view for callers that used the
        # original component API before the reactive modules were introduced.
        def state(name, default_value = nil, type: nil, &block)
          initial = block || default_value
          super(name, default_value, type: type, &block)
          self.swift_states = swift_states.merge(name.to_sym => initial)
        end

        def prop(name, type: nil, required: false, default: nil, **validation_options)
          self.swift_props = swift_props.merge(
            name => { type: type, required: required, default: default }
          )
          attr_reader name

          register_prop_validation(name, **validation_options) if validation_options.any?
          
          # For ViewComponent 2.0 collection support, automatically add collection parameter
          # Only do this for properly named components
          if name.to_s == "title" && self.name && self.name.include?("Component")
            collection_param = self.name.demodulize.underscore.gsub('_component', '').gsub('/', '_')
            
            # Only add if it's a valid Ruby identifier
            if collection_param =~ /\A[a-z_][a-z0-9_]*\z/
              # Define collection parameter dynamically
              self.swift_props = swift_props.merge(
                collection_param.to_sym => { type: Object, required: false, default: nil },
                "#{collection_param}_counter".to_sym => { type: Integer, required: false, default: nil }
              )
              
              attr_reader collection_param.to_sym
              attr_reader "#{collection_param}_counter".to_sym
            end
          end
        end

        def computed(name, &block)
          self.swift_computed = swift_computed.merge(name => block)
          define_method(name, &block)
        end

        def effect(trigger, &block)
          trigger = trigger.to_sym
          self.swift_effects = swift_effects.merge(trigger => block)
          observe(trigger, &block)
        end

        # Restore encrypted reactive values before state defaults are
        # evaluated. This prevents callable/side-effecting initializers from
        # running again on every HTTP round trip only to be overwritten.
        def restore_reactive_snapshot(props:, state:, bindings:, component_id:)
          component = new(
            **normalize_reactive_snapshot_props(props),
            __swift_ui_restored_state: normalize_reactive_snapshot_state(state),
            __swift_ui_restored_bindings: normalize_declared_snapshot_values(bindings, binding_definitions)
          )
          component.component_id = component_id
          component
        end

        # A configured JSON-compatible MessageEncryptor serializer cannot
        # represent Ruby Symbols. Only
        # restore a String to a Symbol when the prop's declared type requires
        # one and an inclusion validation provides a finite allowlist. The
        # matching Symbol is returned from that allowlist, so snapshot data is
        # never interned with String#to_sym.
        def normalize_reactive_snapshot_props(props)
          normalize_declared_snapshot_values(props, swift_props) do |name, value, definition|
            normalize_snapshot_symbol_prop(name, value, definition)
          end
        end

        def normalize_reactive_snapshot_state(state)
          normalized = normalize_declared_snapshot_values(state, state_definitions)
          return normalized unless respond_to?(:swift_focus_state_definitions)

          swift_focus_state_definitions.each do |name, definition|
            next unless normalized.key?(name)

            normalized[name] = normalize_snapshot_focus_value(name, normalized[name], definition)
          end
          normalized
        end

        private

        def normalize_declared_snapshot_values(values, definitions)
          raise TypeError, "reactive snapshot values must be a Hash" unless values.is_a?(Hash)

          definitions.each_with_object({}) do |(declared_name, definition), normalized|
            name = declared_name.to_sym
            value_present, value = declared_snapshot_value(values, name)
            next unless value_present

            normalized[name] = block_given? ? yield(name, value, definition) : value
          end
        end

        def declared_snapshot_value(values, name)
          return [true, values[name]] if values.key?(name)

          string_name = name.to_s
          return [true, values[string_name]] if values.key?(string_name)

          [false, nil]
        end

        def normalize_snapshot_symbol_prop(name, value, definition)
          return value unless value.is_a?(String)

          allowed_types = Array(definition[:type])
          return value unless allowed_types.include?(Symbol)
          return value if allowed_types.any? { |type| type != Symbol && value.is_a?(type) }

          allowed_values = prop_validations.dig(name, :inclusion, :in)
          return value unless allowed_values.is_a?(Array) && allowed_values.length <= 256

          allowed_values.find do |candidate|
            candidate.is_a?(Symbol) && candidate.to_s == value
          end || value
        end

        def normalize_snapshot_focus_value(name, value, definition)
          SwiftUIRails::FocusState.serialize_value(value)
          allowed_values = definition[:values]
          return value if allowed_values.nil? || value.nil? || allowed_values.include?(value)

          restored_value = if value.is_a?(String)
            allowed_values.find do |candidate|
              candidate.is_a?(Symbol) && candidate.to_s == value
            end
          end
          return restored_value if restored_value

          raise ArgumentError, "Focus state '#{name}' must be one of #{allowed_values.inspect}"
        end

        public

        def slot(name, required: false)
          self.swift_slots = swift_slots.merge(name => { required: required })
          
          # Define with_#{name} method for setting slot content
          define_method("with_#{name}") do |&block|
            @slots ||= {}
            @slots[name] = block
            self
          end
          
          # Define #{name} method for getting slot content
          define_method(name) do
            @slots ||= {}
            if @slots[name]
              if @slots[name].arity > 0
                # Block expects arguments, call it with yield arguments
                @slots[name]
              else
                # Block expects no arguments, call it directly
                capture(&@slots[name])
              end
            else
              nil
            end
          end
        end
      end

      def initialize(__swift_ui_restored_state: nil, __swift_ui_restored_bindings: nil, **props)
        # Extract ViewComponent-specific props from our custom props
        swift_props_names = self.class.swift_props.keys
        our_props = props.slice(*swift_props_names)
        view_component_props = props.except(*swift_props_names)
        
        @state_values = {}
        @binding_values = {}
        
        # Handle ViewComponent 2.0 collection parameters
        # Convert collection item to our props if present
        collection_param_name = self.class.name.underscore.gsub('_component', '')
        if props[collection_param_name.to_sym]
          collection_item = props[collection_param_name.to_sym]
          collection_counter = props["#{collection_param_name}_counter".to_sym]
          
          # Extract props from collection item
          if collection_item.is_a?(Hash)
            our_props = our_props.merge(collection_item.slice(*swift_props_names))
            our_props[collection_param_name.to_sym] = collection_item
            our_props["#{collection_param_name}_counter".to_sym] = collection_counter if collection_counter
          else
            our_props[collection_param_name.to_sym] = collection_item
            our_props["#{collection_param_name}_counter".to_sym] = collection_counter if collection_counter
          end
        end
        
        validate_and_set_props(our_props)
        self.state_values = __swift_ui_restored_state if __swift_ui_restored_state
        self.binding_values = __swift_ui_restored_bindings if __swift_ui_restored_bindings
        initialize_state_tracking
        super(**view_component_props)
      end

      # Register component actions for event handling
      def register_component_action(action_id, block)
        @component_actions ||= {}
        @component_action_descriptors ||= {}
        @component_actions[action_id] = block
        source = block&.source_location&.join(":") || "anonymous"
        @component_action_descriptors[action_id] = Digest::SHA256.hexdigest(
          [action_id, source].join("\0")
        )
      end
      
      # Execute a component action
      def execute_action(action_id, event_data = {})
        return unless @component_actions && @component_actions[action_id]

        normalized_event = event_data.respond_to?(:to_h) ? event_data.to_h : {}
        normalized_event = normalized_event.symbolize_keys
        normalized_event[:detail] = normalized_event[:event_detail] if normalized_event.key?(:event_detail)
        normalized_event[:value] = normalized_event[:target_value] if normalized_event.key?(:target_value)
        normalized_event[:checked] = normalized_event[:target_checked] if normalized_event.key?(:target_checked)
        normalized_event[:dataset] = normalized_event[:target_dataset] if normalized_event.key?(:target_dataset)
        event = OpenStruct.new(normalized_event)
        
        # Execute the action block in the component context
        instance_exec(event, &@component_actions[action_id])
      end
      
      # Get all registered actions (for debugging)
      def registered_actions
        @component_actions&.keys || []
      end

      def registered_action_descriptors
        (@component_action_descriptors || {}).dup.freeze
      end
      
      # Get current state values for persistence
      def state_values
        values = @state_values || {}
        values.respond_to?(:deep_dup) ? values.deep_dup : values.dup
      end

      # Restore only state declared by this component. Session contents must not
      # be able to create arbitrary instance state.
      def state_values=(values)
        raise TypeError, "state values must be a Hash" unless values.is_a?(Hash)

        restored_values = values.to_h.symbolize_keys.slice(*self.class.state_definitions.keys)
        restored_values.each { |name, value| validate_state_value!(name, value) }
        @state_values = (@state_values || {}).merge(restored_values)
      end
      
      # Get current prop values for persistence
      def get_component_props
        props = {}
        self.class.swift_props.each_key do |prop_name|
          props[prop_name] = instance_variable_get("@#{prop_name}")
        end
        props
      end
      
      # Enable reactive rendering for this component
      def reactive_rendering_enabled
        self.class.reactive_rendering_enabled && (
          self.class.state_definitions.any? ||
          self.class.binding_definitions.any? ||
          self.class.observed_object_definitions.any? ||
          self.class.swift_effects.any? ||
          registered_actions.any?
        )
      end
      
      # Get the component's unique identifier
      def component_id
        @component_id ||= begin
          component_name = self.class.name.to_s.underscore.tr("/", "-").dasherize
          id = "swift-ui-#{component_name}-#{object_id}"
          Rails.logger.debug "Generating component_id: #{id} for #{self.class.name}"
          id
        end
      end

      # Controllers restore the original DOM identity before a component is
      # rendered again. The narrow identifier grammar keeps the value safe for
      # Turbo targets, DOM ids, cache keys, and audit logs.
      def component_id=(value)
        unless value.is_a?(String) && value.match?(/\A[A-Za-z][A-Za-z0-9_-]{0,127}\z/)
          raise ArgumentError, "invalid component id"
        end

        @component_id = value
      end
      
      # SECURITY: Safe method to update reactive state
      def update_reactive_state(changes)
        return unless changes.is_a?(Hash)

        accepted_changes = {}
        changes.each do |prop_name, new_value|
          prop_def = self.class.swift_props[prop_name.to_sym]
          
          # Only allow updates to defined props
          unless prop_def
            Rails.logger.warn "[SECURITY] Attempted to update undefined prop: #{prop_name}"
            next
          end
          
          # Type validation
          if prop_def[:type] && new_value && !valid_type?(new_value, prop_def[:type])
            Rails.logger.warn "[SECURITY] Type mismatch for prop #{prop_name}: expected #{prop_def[:type]}, got #{new_value.class}"
            next
          end

          accepted_changes[prop_name.to_sym] = new_value
        end

        return if accepted_changes.empty?

        previous_values = accepted_changes.each_key.to_h do |prop_name|
          [prop_name, instance_variable_get("@#{prop_name}")]
        end
        accepted_changes.each do |prop_name, new_value|
          instance_variable_set("@#{prop_name}", new_value)
        end

        begin
          validate_props! if respond_to?(:validate_props!, true)
        rescue ArgumentError, TypeError => error
          previous_values.each do |prop_name, previous_value|
            instance_variable_set("@#{prop_name}", previous_value)
          end
          Rails.logger.warn "[SECURITY] Validation rejected reactive prop update: #{error.message}"
          return
        end

        # Trigger re-render if needed
        if respond_to?(:trigger_update)
          trigger_update
        end
      end

      private

      def validate_and_set_props(props)
        self.class.swift_props.each do |name, config|
          # Use has_key? to properly handle false values
          value = if props.has_key?(name)
            props[name]
          else
            # Handle lambda/proc defaults
            default = config[:default]
            value = default.respond_to?(:call) ? instance_exec(&default) : default
            value.respond_to?(:deep_dup) ? value.deep_dup : value
          end
          
          if config[:required] && value.nil?
            raise ArgumentError, "Required prop '#{name}' is missing"
          end
          
          if config[:type] && value && !valid_type?(value, config[:type])
            raise TypeError, "Prop '#{name}' must be a #{config[:type]}"
          end
          
          instance_variable_set("@#{name}", value)
        end
        
        # SECURITY: Run component-specific validations
        validate_props! if respond_to?(:validate_props!, true)
      end

      def valid_type?(value, type)
        if type.is_a?(Array)
          type.any? { |t| value.is_a?(t) }
        else
          value.is_a?(type)
        end
      end

      # Wrap content with a reactive container for Turbo Stream updates
      def wrap_with_reactive_container(content)
        build_reactive_container(content, component_id)
      end
      
      # Make DSL methods available in components
      include SwiftUIRails::DSL
      
      # Ensure Element class is accessible
      Element = SwiftUIRails::DSL::Element
    end
  end
end
