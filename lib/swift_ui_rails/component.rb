# frozen_string_literal: true
# Copyright 2025

require "view_component"
require "digest"
require_relative "component/collection_support"
require_relative "component/slots"
require_relative "component/caching"
require_relative "reactive"
require_relative "security/component_validator"
require_relative "dev_tools/component_tree_debugger" if Rails.env.development? || Rails.env.test?
require_relative "dev_tools/debug_helpers" if Rails.env.development? || Rails.env.test?

module SwiftUIRails
  module Component
    class Base < ::ViewComponent::Base
      include SwiftUIRails::DSL
      include SwiftUIRails::Component::CollectionSupport
      include SwiftUIRails::Component::Slots
      include SwiftUIRails::Component::Caching
      include SwiftUIRails::Reactive if defined?(SwiftUIRails::Reactive)
      include SwiftUIRails::Security::ComponentValidator
      include SwiftUIRails::DevTools::DebugHelpers if Rails.env.development? || Rails.env.test?

      class_attribute :swift_states, default: {}
      class_attribute :swift_props, default: {}
      class_attribute :swift_computed, default: {}
      class_attribute :swift_effects, default: {}
      class_attribute :swift_slots, default: {}

      # Memoization support for swift_ui content
      class_attribute :swift_ui_memoization_enabled, default: true
      
      class << self
        # Enable or disable memoization for this component
        def enable_memoization(enabled = true)
          self.swift_ui_memoization_enabled = enabled
        end
        
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
          @swift_ui_block = block
          
          define_method :call do
            # Check if memoization is enabled and we have a cached result
            if self.class.swift_ui_memoization_enabled && memoized_content_valid?
              return @memoized_swift_ui_content
            end
            
            # Create a DSL context for proper element management
            dsl_context = SwiftUIRails::DSLContext.new(self)
            
            # Store component reference in the context
            dsl_context.instance_variable_set(:@component, self)
            
            # Execute the block in the DSL context
            # The block execution will automatically register elements via create_element
            result = dsl_context.instance_eval(&self.class.instance_variable_get(:@swift_ui_block))
            
            # Don't double-register the result - it was already registered during creation
            # Just flush all collected elements
            rendered_content = dsl_context.flush_elements
            
            # Wrap with reactive container if enabled
            if respond_to?(:reactive_rendering_enabled) && reactive_rendering_enabled
              rendered_content = wrap_with_reactive_container(rendered_content)
            end
            
            # Memoize the content if enabled
            if self.class.swift_ui_memoization_enabled
              @memoized_swift_ui_content = rendered_content
              @memoization_key = calculate_memoization_key
            end
            
            rendered_content
          end
        end

        def state(name, default_value = nil)
          self.swift_states = swift_states.merge(name => default_value)
          
          define_method(name) do
            @state_values[name]
          end
          
          define_method("#{name}=") do |value|
            old_value = @state_values[name]
            @state_values[name] = value
            trigger_state_change(name, old_value, value)
            
            # Trigger automatic re-rendering if in a request context
            if defined?(@component_id) && @component_id && respond_to?(:request_automatic_rerender)
              request_automatic_rerender
            end
          end
        end

        def prop(name, type: nil, required: false, default: nil)
          self.swift_props = swift_props.merge(
            name => { type: type, required: required, default: default }
          )
          attr_reader name
          
          # For ViewComponent 2.0 collection support, automatically add collection parameter
          # Only do this for properly named components
          if name.to_s == "title" && self.name && self.name.include?("Component")
            collection_param = self.name&.demodulize&.underscore&.gsub('_component', '')&.gsub('/', '_')
            
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
          self.swift_effects = swift_effects.merge(trigger => block)
        end

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

      def initialize(**props)
        # Extract ViewComponent-specific props from our custom props
        swift_props_names = self.class.swift_props.keys
        our_props = props.slice(*swift_props_names)
        view_component_props = props.except(*swift_props_names)
        
        @state_values = self.class.swift_states.dup
        
        # Initialize memoization cache
        @memoized_swift_ui_content = nil
        @memoization_key = nil
        
        # Handle ViewComponent 2.0 collection parameters
        # Convert collection item to our props if present
        if self.class.name
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
        end
        
        validate_and_set_props(our_props)
        super(**view_component_props)
      end

      # Register component actions for event handling
      def register_component_action(action_id, block)
        @component_actions ||= {}
        @component_actions[action_id] = block
      end
      
      # Execute a component action
      def execute_action(action_id, event_data = {})
        return unless @component_actions && @component_actions[action_id]
        
        # Create an event object with the data
        event = OpenStruct.new(event_data)
        
        # Execute the action block in the component context
        instance_exec(event, &@component_actions[action_id])
      end
      
      # Get all registered actions (for debugging)
      def registered_actions
        @component_actions&.keys || []
      end
      
      # Get current state values for persistence
      def state_values
        @state_values || {}
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
        # Check if component has state or effects defined
        self.class.swift_states.any? || self.class.swift_effects.any?
      end
      
      # Request automatic re-rendering (for use with Turbo)
      def request_automatic_rerender
        # This would typically be handled by the controller/view layer
        # For now, we'll store a flag that can be checked
        @needs_rerender = true
      end
      
      # Check if component needs re-rendering
      def needs_rerender?
        @needs_rerender || false
      end
      
      # Get the component's unique identifier
      def component_id
        @component_id ||= begin
          id = "swift_ui_component_#{object_id}"
          Rails.logger.debug "Generating component_id: #{id} for #{self.class.name}"
          id
        end
      end
      
      # SECURITY: Safe method to update reactive state
      def update_reactive_state(changes)
        return unless changes.is_a?(Hash)
        
        # Validate each change against prop definitions
        changes.each do |prop_name, new_value|
          prop_def = self.class.swift_props[prop_name.to_sym]
          
          # Only allow updates to defined props
          unless prop_def
            Rails.logger.warn "[SECURITY] Attempted to update undefined prop: #{prop_name}"
            next
          end
          
          # Type validation
          if prop_def[:type] && new_value && !new_value.is_a?(prop_def[:type])
            Rails.logger.warn "[SECURITY] Type mismatch for prop #{prop_name}: expected #{prop_def[:type]}, got #{new_value.class}"
            next
          end
          
          # Update the prop value
          instance_variable_set("@#{prop_name}", new_value)
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
            default.respond_to?(:call) ? instance_exec(&default) : default
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
        validate_props! if respond_to?(:validate_props!)
      end

      def valid_type?(value, type)
        if type.is_a?(Array)
          type.any? { |t| value.is_a?(t) }
        else
          value.is_a?(type)
        end
      end

      def trigger_state_change(name, old_value, new_value)
        return if old_value == new_value
        
        if effect = self.class.swift_effects[name]
          instance_exec(new_value, old_value, &effect)
        end
      end
      
      # Wrap content with a reactive container for Turbo Stream updates
      def wrap_with_reactive_container(content)
        # Generate a unique component ID if not already set
        @component_id ||= "swift_ui_component_#{object_id}"
        
        # Store component class for client-side reconstruction
        component_class = self.class.name
        
        # Note: Components don't have direct access to session
        # Props and state management should be handled by the controller
        
        # Build the container div with necessary attributes
        container_attrs = {
          id: @component_id,
          data: {
            controller: "swift-ui-component",
            "swift-ui-component-component-id-value": @component_id,
            "swift-ui-component-component-class-value": component_class,
            "turbo-permanent": true
          }
        }
        
        # Wrap the content in the reactive container
        content_tag(:div, content.html_safe, container_attrs)
      end
      
      # Enable reactive rendering for this component
      def reactive_rendering_enabled
        # Check if component has state or effects defined
        self.class.swift_states.any? || self.class.swift_effects.any?
      end
      
      # Request automatic re-rendering (for use with Turbo)
      def request_automatic_rerender
        # This would typically be handled by the controller/view layer
        # For now, we'll store a flag that can be checked
        @needs_rerender = true
      end
      
      # Check if component needs re-rendering
      def needs_rerender?
        @needs_rerender || false
      end

      # Make DSL methods available in components
      include SwiftUIRails::DSL
      
      # Ensure Element class is accessible
      Element = SwiftUIRails::DSL::Element
      
      # Memoization helpers (public for testing)
      def calculate_memoization_key
        # Create a cache key based on props and state
        key_parts = []
        
        # Include all prop values in the key
        self.class.swift_props.each_key do |prop_name|
          value = instance_variable_get("@#{prop_name}")
          key_parts << "#{prop_name}:#{memoization_value_key(value)}"
        end
        
        # Include all state values in the key
        @state_values.each do |state_name, state_value|
          key_parts << "state_#{state_name}:#{memoization_value_key(state_value)}"
        end
        
        # Include component class and version
        key_parts.unshift("#{self.class.name}:#{self.class.object_id}")
        
        # Generate a hash of the key parts for efficiency
        Digest::SHA256.hexdigest(key_parts.join("-"))
      end
      
      def memoization_value_key(value)
        case value
        when NilClass
          "nil"
        when TrueClass, FalseClass
          value.to_s
        when Numeric, String, Symbol
          value.to_s
        when Array
          # Create a hash of array contents
          Digest::SHA256.hexdigest(value.map { |v| memoization_value_key(v) }.join(","))[0..16]
        when Hash
          # Create a hash of hash contents  
          Digest::SHA256.hexdigest(value.map { |k, v| "#{k}:#{memoization_value_key(v)}" }.sort.join(","))[0..16]
        when Time, DateTime, Date
          value.to_i.to_s
        else
          # For complex objects, use object_id and class
          "#{value.class.name}##{value.object_id}"
        end
      end
      
      def memoized_content_valid?
        return false unless @memoized_swift_ui_content && @memoization_key
        
        # Check if the current state matches the memoized state
        current_key = calculate_memoization_key
        current_key == @memoization_key
      end
      
      # Clear memoization cache (useful for testing or forced refresh)
      def clear_memoization!
        @memoized_swift_ui_content = nil
        @memoization_key = nil
      end
    end
  end
end
# Copyright 2025
