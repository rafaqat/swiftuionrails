# frozen_string_literal: true

module SwiftUIRails
  module Reactive
    # @State equivalent for component-local state
    module State
      extend ActiveSupport::Concern
      
      included do
        class_attribute :state_definitions, default: {}
        class_attribute :state_observers, default: {}
        
        # Override initialization instead of using hooks
        def initialize(...)
          super
          initialize_state_tracking if respond_to?(:initialize_state_tracking, true)
        end
      end
      
      class_methods do
        # Define a state variable
        # @state :count, 0
        # @state :user, -> { current_user }
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
        
        # Define a state observer
        def observe(state_name, &block)
          state_observers[state_name] ||= []
          state_observers[state_name] << block
        end
        
        private
        
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
      
      def track_state_change(name, old_value, new_value)
        return if old_value == new_value
        
        @state_changes << {
          name: name,
          old_value: old_value,
          new_value: new_value,
          timestamp: Time.current.to_f
        }
        
        # Call observers
        if observers = self.class.state_observers[name]
          observers.each do |observer|
            instance_exec(new_value, old_value, &observer)
          end
        end
      end
      
      def generate_state_updates
        return if @state_changes.empty?
        
        # Add state data attributes for Stimulus
        @_content = @_content.to_s.gsub(
          /(<[^>]+)(>)/,
          "\\1 data-state-generation=\"#{@state_generation}\" data-state-changes='#{@state_changes.to_json}'\\2"
        ).html_safe
      end
      
      # Helper to create reactive wrappers
      def reactive(&block)
        ReactiveContext.new(self, &block)
      end
      
      class ReactiveContext
        def initialize(component, &block)
          @component = component
          @block = block
        end
        
        def value
          @block.call
        end
        
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
