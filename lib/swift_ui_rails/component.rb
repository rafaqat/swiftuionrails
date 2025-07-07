# frozen_string_literal: true

# Copyright 2025

require 'view_component'
require 'digest'
require_relative 'component/collection_support'
require_relative 'component/slots'
require_relative 'component/caching'
require_relative 'reactive'
require_relative 'security/component_validator'
require_relative 'dev_tools/component_tree_debugger' if Rails.env.local?
require_relative 'dev_tools/debug_helpers' if Rails.env.local?

module SwiftUIRails
  module Component
    class Base < ::ViewComponent::Base
      include SwiftUIRails::DSL
      include SwiftUIRails::Component::CollectionSupport
      include SwiftUIRails::Component::Slots
      include SwiftUIRails::Component::Caching
      include SwiftUIRails::Reactive if defined?(SwiftUIRails::Reactive)
      include SwiftUIRails::Security::ComponentValidator
      include SwiftUIRails::DevTools::DebugHelpers if Rails.env.local?

      class_attribute :swift_states, default: {}
      class_attribute :swift_props, default: {}
      class_attribute :swift_computed, default: {}
      class_attribute :swift_effects, default: {}
      class_attribute :swift_slots, default: {}

      # Memoization support for swift_ui content
      class_attribute :swift_ui_memoization_enabled, default: true

      class << self
        ##
        # Enables or disables memoization for the component's rendered output.
        # @param [Boolean] enabled - Whether to enable memoization (default: true).
        def enable_memoization(enabled = true)
          self.swift_ui_memoization_enabled = enabled
        end

        ##
        # Renders a collection of items using ViewComponent's optimized collection rendering.
        # Yields each item and its counter to the provided block, or uses default rendering if no block is given.
        # @param collection [Enumerable] The collection of items to render.
        def with_collection(collection, *args, **kwargs, &block)
          # Leverage ViewComponent 2.0's optimized collection rendering
          # This provides ~10x performance improvement over manual iteration
          super do |item, item_counter|
            # Pass collection item and counter to block if provided
            if block
              if block.arity == 2
                yield(item, item_counter)
              else
                yield(item)
              end
            else
              # Default rendering behavior
              new(collection_item: item, collection_counter: item_counter)
            end
          end
        end

        ##
        # Defines the main SwiftUI-inspired DSL block for the component, enabling declarative UI construction.
        # When invoked, executes the provided block in a dedicated DSL context, collects and renders elements, optionally wraps the output for reactive updates, and memoizes the result if enabled.
        # @yield The DSL block for building the component's UI.
        def swift_ui(&block)
          # Store the block to be executed in the component context
          @swift_ui_block = block

          define_method :call do
            # Check if memoization is enabled and we have a cached result
            return @memoized_swift_ui_content if self.class.swift_ui_memoization_enabled && memoized_content_valid?

            # Create a DSL context for proper element management
            dsl_context = SwiftUIRails::DSLContext.new(self)

            # Store component reference in the context
            dsl_context.instance_variable_set(:@component, self)

            # Execute the block in the DSL context
            # The block execution will automatically register elements via create_element
            dsl_context.instance_eval(&self.class.instance_variable_get(:@swift_ui_block))

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

        ##
        # Defines a reactive state variable with getter and setter methods.
        # The setter triggers state change effects and requests automatic re-rendering if applicable.
        # @param [Symbol] name - The name of the state variable.
        # @param [Object] default_value - The initial value for the state variable.
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
            return unless defined?(@component_id) && @component_id && respond_to?(:request_automatic_rerender)

            request_automatic_rerender
          end
        end

        ##
        # Defines a prop for the component with optional type, requirement, and default value.
        # For components named with "Component" and a prop named "title", also adds collection parameters for ViewComponent collection rendering support.
        # @param [Symbol] name - The name of the prop.
        # @param [Class, nil] type - The expected type of the prop, or nil for any type.
        # @param [Boolean] required - Whether the prop is required.
        # @param [Object, nil] default - The default value for the prop.
        def prop(name, type: nil, required: false, default: nil)
          self.swift_props = swift_props.merge(
            name => { type: type, required: required, default: default }
          )
          attr_reader name

          # For ViewComponent 2.0 collection support, automatically add collection parameter
          # Only do this for properly named components
          return unless name.to_s == 'title' && self.name&.include?('Component')

          collection_param = self.name&.demodulize&.underscore&.gsub('_component', '')&.tr('/', '_')

          # Only add if it's a valid Ruby identifier
          return unless /\A[a-z_][a-z0-9_]*\z/.match?(collection_param)

          # Define collection parameter dynamically
          self.swift_props = swift_props.merge(
            collection_param.to_sym => { type: Object, required: false, default: nil },
            :"#{collection_param}_counter" => { type: Integer, required: false, default: nil }
          )

          attr_reader collection_param.to_sym
          attr_reader :"#{collection_param}_counter"
        end

        ##
        # Defines a computed property for the component.
        # The property is evaluated by the provided block and made accessible as an instance method.
        # @param [Symbol] name - The name of the computed property.
        def computed(name, &block)
          self.swift_computed = swift_computed.merge(name => block)
          define_method(name, &block)
        end

        def effect(trigger, &block)
          self.swift_effects = swift_effects.merge(trigger => block)
        end

        ##
        # Defines a named slot for the component, enabling content injection via a setter and retrieval via a getter.
        # The setter method (`with_<name>`) assigns a block to the slot, while the getter method (`<name>`) retrieves and evaluates the slot content.
        # @param [Symbol] name - The name of the slot to define.
        # @param [Boolean] required - Whether the slot is required for the component.
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
            return unless @slots[name]

            if @slots[name].arity.positive?
              # Block expects arguments, call it with yield arguments
              @slots[name]
            else
              # Block expects no arguments, call it directly
              capture(&@slots[name])
            end
          end
        end
      end

      ##
      # Initializes the component with provided props, separating custom SwiftUIRails props from ViewComponent props, handling collection parameters, and validating and setting prop values.
      # Calls the superclass initializer with remaining ViewComponent props.
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
            collection_counter = props[:"#{collection_param_name}_counter"]

            # Extract props from collection item
            our_props = our_props.merge(collection_item.slice(*swift_props_names)) if collection_item.is_a?(Hash)
            our_props[collection_param_name.to_sym] = collection_item
            our_props[:"#{collection_param_name}_counter"] = collection_counter if collection_counter
          end
        end

        validate_and_set_props(our_props)
        super(**view_component_props)
      end

      ##
      # Registers an action block for a given action ID to handle component events.
      # @param [Symbol, String] action_id - The identifier for the action.
      # @param [Proc] block - The block to execute when the action is triggered.
      def register_component_action(action_id, block)
        @component_actions ||= {}
        @component_actions[action_id] = block
      end

      ##
      # Executes a registered component action with the provided event data.
      # @param [Symbol, String] action_id - The identifier of the action to execute.
      # @param [Hash] event_data - Optional data to be passed to the action as an event object.
      # @return [Object, nil] The result of the action block, or nil if the action is not registered.
      def execute_action(action_id, event_data = {})
        return unless @component_actions && @component_actions[action_id]

        # Create an event object with the data
        event = OpenStruct.new(event_data)

        # Execute the action block in the component context
        instance_exec(event, &@component_actions[action_id])
      end

      ##
      # Returns a list of all registered action identifiers for the component.
      # @return [Array<Symbol>] The keys of registered actions, or an empty array if none are registered.
      def registered_actions
        @component_actions&.keys || []
      end

      ##
      # Returns a hash of the current reactive state values for the component.
      # @return [Hash] The current state values, or an empty hash if none are set.
      def state_values
        @state_values || {}
      end

      ##
      # Returns a hash of the current prop values for the component, keyed by prop name.
      # @return [Hash] The current prop values.
      def get_component_props
        props = {}
        self.class.swift_props.each_key do |prop_name|
          props[prop_name] = instance_variable_get("@#{prop_name}")
        end
        props
      end

      ##
      # Returns true if the component has any reactive state variables or effects defined.
      # @return [Boolean] Whether reactive rendering is enabled for this component.
      def reactive_rendering_enabled
        # Check if component has state or effects defined
        self.class.swift_states.any? || self.class.swift_effects.any?
      end

      ##
      # Flags the component to be re-rendered automatically, typically in response to state changes or Turbo updates.
      def request_automatic_rerender
        # This would typically be handled by the controller/view layer
        # For now, we'll store a flag that can be checked
        @needs_rerender = true
      end

      ##
      # Returns whether the component is flagged for automatic re-rendering.
      # @return [Boolean] True if a re-render is needed, false otherwise.
      def needs_rerender?
        @needs_rerender || false
      end

      ##
      # Returns a unique identifier for the component instance, generating and memoizing it if necessary.
      # @return [String] The unique component identifier.
      def component_id
        @component_id ||= begin
          id = "swift_ui_component_#{object_id}"
          Rails.logger.debug { "Generating component_id: #{id} for #{self.class.name}" }
          id
        end
      end

      ##
      # Safely updates reactive state properties from a hash of changes, validating property existence and type.
      # Logs warnings for invalid or unauthorized updates and triggers a re-render if supported.
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
        trigger_update if respond_to?(:trigger_update)
      end

      private

      ##
      # Validates and assigns component props, applying defaults and type checks.
      # Raises an error if required props are missing or if a prop value does not match its specified type.
      # Executes component-specific prop validations if defined.
      def validate_and_set_props(props)
        self.class.swift_props.each do |name, config|
          # Use has_key? to properly handle false values
          value = if props.key?(name)
                    props[name]
                  else
                    # Handle lambda/proc defaults
                    default = config[:default]
                    default.respond_to?(:call) ? instance_exec(&default) : default
                  end

          raise ArgumentError, "Required prop '#{name}' is missing" if config[:required] && value.nil?

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

      ##
      # Invokes the effect block associated with a state variable when its value changes.
      # @param [Symbol] name - The name of the state variable.
      # @param old_value - The previous value of the state.
      # @param new_value - The new value of the state.
      def trigger_state_change(name, old_value, new_value)
        return if old_value == new_value

        if (effect = self.class.swift_effects[name])
          instance_exec(new_value, old_value, &effect)
        end
      end

      ##
      # Wraps the given content in a div with data attributes for Turbo Stream and client-side reactive updates.
      # The container includes a unique component ID and class information for client-side reconstruction.
      # @param [String] content - The HTML content to be wrapped.
      # @return [String] The HTML-safe string wrapped in a reactive container div.
      def wrap_with_reactive_container(content)
        # Generate a unique component ID if not already set
        @component_id ||= "swift_ui_component_#{object_id}"

        # Store component class for client-side reconstruction
        component_class = self.class.name

        # NOTE: Components don't have direct access to session
        # Props and state management should be handled by the controller

        # Build the container div with necessary attributes
        container_attrs = {
          id: @component_id,
          data: {
            controller: 'swift-ui-component',
            'swift-ui-component-component-id-value': @component_id,
            'swift-ui-component-component-class-value': component_class,
            'turbo-permanent': true
          }
        }

        # Wrap the content in the reactive container
        content_tag(:div, content.html_safe, container_attrs)
      end

      ##
      # Returns true if the component has any reactive state variables or effects defined.
      # @return [Boolean] Whether reactive rendering is enabled for this component.
      def reactive_rendering_enabled
        # Check if component has state or effects defined
        self.class.swift_states.any? || self.class.swift_effects.any?
      end

      ##
      # Flags the component to be re-rendered automatically, typically in response to state changes or Turbo updates.
      def request_automatic_rerender
        # This would typically be handled by the controller/view layer
        # For now, we'll store a flag that can be checked
        @needs_rerender = true
      end

      ##
      # Returns whether the component is flagged for automatic re-rendering.
      # @return [Boolean] True if a re-render is needed, false otherwise.
      def needs_rerender?
        @needs_rerender || false
      end

      # Make DSL methods available in components
      include SwiftUIRails::DSL

      # Ensure Element class is accessible
      Element = SwiftUIRails::DSL::Element

      ##
      # Generates a SHA256 hash key representing the current component's props, state, class, and version for memoization purposes.
      # @return [String] The computed memoization key.
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
        Digest::SHA256.hexdigest(key_parts.join('-'))
      end

      ##
      # Generates a unique string key representing the given value for memoization purposes.
      # Handles various data types, including arrays and hashes, by producing a consistent hash digest.
      # @param value The value to be converted into a memoization key.
      # @return [String] A string suitable for use as a memoization key.
      def memoization_value_key(value)
        case value
        when NilClass
          'nil'
        when TrueClass, FalseClass
          value.to_s
        when Numeric, String, Symbol
          value.to_s
        when Array
          # Create a hash of array contents
          Digest::SHA256.hexdigest(value.map { |v| memoization_value_key(v) }.join(','))[0..16]
        when Hash
          # Create a hash of hash contents
          Digest::SHA256.hexdigest(value.map { |k, v| "#{k}:#{memoization_value_key(v)}" }.sort.join(','))[0..16]
        when Time, DateTime, Date
          value.to_i.to_s
        else
          # For complex objects, use object_id and class
          "#{value.class.name}##{value.object_id}"
        end
      end

      ##
      # Checks if the memoized SwiftUI content is still valid based on the current memoization key.
      # @return [Boolean] true if the memoized content matches the current state and props, false otherwise.
      def memoized_content_valid?
        return false unless @memoized_swift_ui_content && @memoization_key

        # Check if the current state matches the memoized state
        current_key = calculate_memoization_key
        current_key == @memoization_key
      end

      ##
      # Clears the memoization cache for the component, removing any cached content and memoization key.
      # Useful for testing or forcing a refresh of the rendered output.
      def clear_memoization!
        @memoized_swift_ui_content = nil
        @memoization_key = nil
      end
    end
  end
end
# Copyright 2025
