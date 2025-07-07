# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Reactive
    # @State equivalent for component-local state
    module State
      extend ActiveSupport::Concern

      included do
        class_attribute :state_definitions, default: {}
        class_attribute :state_observers, default: {}

        ##
        # Initializes the component and sets up state tracking if the method is defined.
        # Calls the superclass initializer and then invokes `initialize_state_tracking` for reactive state setup.
        def initialize(...)
          super
          initialize_state_tracking if respond_to?(:initialize_state_tracking, true)
        end
      end

      class_methods do
        # Define a state variable
        # @state :count, 0
        ##
        # Defines a reactive state variable with automatic getter and setter methods.
        # Also generates mutation helper methods for arrays and hashes, enabling reactivity and observer notifications on state changes.
        # @param [Symbol] name - The name of the state variable.
        # @param [Object, Proc] initial_value - The initial value or a proc returning the initial value for the state variable.
        def state(name, initial_value = nil, &block)
          initial = block || initial_value

          state_definitions[name] = {
            initial: initial,
            type: infer_state_type(initial)
          }

          # Define getter
          define_method(name) do
            @state_values ||= {}
            @state_values[name]
          end

          # Define setter that triggers reactivity
          define_method("#{name}=") do |value|
            old_value = @state_values[name]
            @state_values ||= {}
            @state_values[name] = value

            # Track state change for re-rendering
            track_state_change(name, old_value, value)
          end

          # Define mutation methods for arrays/hashes
          if initial.is_a?(Array) || (initial.is_a?(Proc) && initial.call.is_a?(Array))
            define_array_mutation_methods(name)
          elsif initial.is_a?(Hash) || (initial.is_a?(Proc) && initial.call.is_a?(Hash))
            define_hash_mutation_methods(name)
          end
        end

        ##
        # Registers an observer block to be called whenever the specified state variable changes.
        # @param [Symbol, String] state_name - The name of the state variable to observe.
        def observe(state_name, &block)
          state_observers[state_name] ||= []
          state_observers[state_name] << block
        end

        private

        ##
        # Infers the type of a state variable based on its initial value.
        # Returns the class, :boolean for booleans, or nil if the type cannot be determined (e.g., for Procs).
        # @param initial The initial value of the state variable.
        # @return [Class, Symbol, nil] The inferred type, :boolean, or nil if undeterminable.
        def infer_state_type(initial)
          case initial
          when Proc
            # Can't infer type from Proc
            nil
          when Integer
            Integer
          when String
            String
          when TrueClass, FalseClass
            :boolean
          when Array
            Array
          when Hash
            Hash
          else
            initial.class
          end
        end

        ##
        # Defines array mutation helper methods for a state variable.
        # Adds push, remove, and clear methods for the specified array state variable name.
        # These methods allow adding items, removing an item, or clearing the array while ensuring state reactivity.
        def define_array_mutation_methods(name)
          # Push method
          define_method("#{name}_push") do |*items|
            array = send(name).dup
            array.push(*items)
            send("#{name}=", array)
          end

          # Remove method
          define_method("#{name}_remove") do |item|
            array = send(name).dup
            array.delete(item)
            send("#{name}=", array)
          end

          # Clear method
          define_method("#{name}_clear") do
            send("#{name}=", [])
          end
        end

        ##
        # Defines mutation helper methods for a hash state variable, enabling set, delete, and clear operations.
        # @param [Symbol, String] name - The name of the hash state variable.
        def define_hash_mutation_methods(name)
          # Set key method
          define_method("#{name}_set") do |key, value|
            hash = send(name).dup
            hash[key] = value
            send("#{name}=", hash)
          end

          # Delete key method
          define_method("#{name}_delete") do |key|
            hash = send(name).dup
            hash.delete(key)
            send("#{name}=", hash)
          end

          # Clear method
          define_method("#{name}_clear") do
            send("#{name}=", {})
          end
        end
      end

      private

      ##
      # Initializes internal tracking for reactive state variables, including their values, change history, and generation identifier.
      # Sets each state variable to its initial value, evaluating procs if provided.
      def initialize_state_tracking
        @state_values ||= {}
        @state_changes = []
        @state_generation = SecureRandom.hex(8)

        # Initialize all state variables
        self.class.state_definitions.each do |name, definition|
          if @state_values[name].nil?
            initial = definition[:initial]
            @state_values[name] = initial.is_a?(Proc) ? instance_exec(&initial) : initial
          end
        end
      end

      ##
      # Records a change to a state variable and notifies any registered observers.
      # Appends the change details to the internal state changes array and invokes observer callbacks with the new and old values.
      # @param [Symbol] name - The name of the state variable.
      # @param old_value - The previous value of the state variable.
      # @param new_value - The updated value of the state variable.
      def track_state_change(name, old_value, new_value)
        return if old_value == new_value

        @state_changes << {
          name: name,
          old_value: old_value,
          new_value: new_value,
          timestamp: Time.current.to_f
        }

        # Call observers
        if (observers = self.class.state_observers[name])
          observers.each do |observer|
            instance_exec(new_value, old_value, &observer)
          end
        end
      end

      ##
      # Injects state change metadata as data attributes into the component's HTML content for client-side reactivity.
      # Adds `data-state-generation` and `data-state-changes` attributes to the root HTML element if there are recorded state changes.
      def generate_state_updates
        return if @state_changes.empty?

        # Add state data attributes for Stimulus
        @_content = @_content.to_s.gsub(
          /(<[^>]+)(>)/,
          "\\1 data-state-generation=\"#{@state_generation}\" data-state-changes='#{@state_changes.to_json}'\\2"
        ).html_safe
      end

      ##
      # Wraps a block in a reactive context for state-dependent evaluation.
      # @return [ReactiveContext] The reactive context wrapping the provided block.
      def reactive(&block)
        ReactiveContext.new(self, &block)
      end

      class ReactiveContext
        ##
        # Initializes a new ReactiveContext with the given component and block.
        # @param component The component instance associated with this reactive context.
        def initialize(component, &block)
          @component = component
          @block = block
        end

        ##
        # Executes the reactive block and returns its result.
        # @return The result of evaluating the reactive block.
        def value
          @block.call
        end

        ##
        # Registers a handler to be called when the reactive context's value changes.
        # Returns self to allow method chaining.
        # @return [ReactiveContext] The current instance for chaining.
        def on_change(&handler)
          # This would integrate with Stimulus for client-side reactivity
          @change_handler = handler
          self
        end
      end
    end
  end
end
# Copyright 2025
