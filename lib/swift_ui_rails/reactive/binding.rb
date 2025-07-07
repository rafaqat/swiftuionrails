# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Reactive
    # @Binding equivalent for two-way data flow
    module Binding
      extend ActiveSupport::Concern

      included do
        class_attribute :binding_definitions, default: {}
      end

      class_methods do
        # Define a binding property
        # @binding :is_selected
        ##
        # Declares a reactive binding property with two-way data flow.
        # Dynamically defines getter, setter, and raw value accessor methods for the specified binding.
        # @param [Symbol] name - The name of the binding property.
        # @param [Class, nil] type - The expected type of the binding value (optional).
        # @param [Object, nil] default - The default value for the binding (optional).
        def binding(name, type: nil, default: nil)
          binding_definitions[name] = {
            type: type,
            default: default
          }

          # Define getter that returns a Binding object
          define_method(name) do
            @bindings ||= {}
            @bindings[name] ||= BindingValue.new(
              getter: -> { get_binding_value(name) },
              setter: ->(value) { set_binding_value(name, value) },
              source: self,
              name: name
            )
          end

          # Define setter for direct assignment
          define_method("#{name}=") do |value|
            set_binding_value(name, value)
          end

          # Define raw value getter
          define_method("#{name}_value") do
            get_binding_value(name)
          end
        end
      end

      private

      ##
      # Retrieves the current value of a binding by checking for an instance variable, internal storage, or falling back to the default value.
      # @param [Symbol, String] name - The name of the binding property.
      # @return [Object] The current value of the specified binding.
      def get_binding_value(name)
        # Check if value was passed as prop
        if instance_variable_defined?("@#{name}")
          instance_variable_get("@#{name}")
        elsif @binding_values && @binding_values[name]
          @binding_values[name]
        else
          binding_definitions[name][:default]
        end
      end

      ##
      # Sets the value of a binding, notifies any parent callback, and tracks the change for reactivity.
      # @param [Symbol, String] name - The name of the binding to update.
      # @param value - The new value to assign to the binding.
      def set_binding_value(name, value)
        @binding_values ||= {}
        old_value = @binding_values[name]
        @binding_values[name] = value

        # Notify parent component if this is a child binding
        @parent_binding_callback&.call(name, value, old_value)

        # Track change for reactivity
        track_binding_change(name, old_value, value)
      end

      ##
      # Records a change to a binding property if the value has changed, including the old value, new value, and a timestamp.
      # @param [Symbol, String] name - The name of the binding property.
      # @param old_value - The previous value of the binding.
      # @param new_value - The new value assigned to the binding.
      def track_binding_change(name, old_value, new_value)
        return if old_value == new_value

        @binding_changes ||= []
        @binding_changes << {
          name: name,
          old_value: old_value,
          new_value: new_value,
          timestamp: Time.current.to_f
        }
      end

      ##
      # Passes a binding to a child component, establishing two-way data synchronization.
      # Sets the child's instance variable to the current binding value and configures a callback to propagate updates back to the parent.
      # @param [Object] component The child component receiving the binding.
      # @param [Symbol, String] binding_name The name of the binding to pass.
      # @param [Symbol, String, nil] as Optional alternative name for the binding in the child component.
      def pass_binding(component, binding_name, as: nil)
        target_name = as || binding_name

        # Set up two-way connection
        component.instance_variable_set("@#{target_name}", send(binding_name).value)
        component.instance_variable_set(:@parent_binding_callback,
                                        lambda do |name, value, _old_value|
                                          send(binding_name).value = value if name == target_name
                                        end)
      end
    end

    # Binding value wrapper
    class BindingValue
      attr_reader :source, :name

      ##
      # Initializes a new BindingValue with the provided getter and setter lambdas, source object, and binding name.
      # @param getter [Proc] Lambda to retrieve the binding's value.
      # @param setter [Proc] Lambda to set the binding's value.
      # @param source [Object] The object that owns the binding.
      # @param name [Symbol] The name of the binding property.
      def initialize(getter:, setter:, source:, name:)
        @getter = getter
        @setter = setter
        @source = source
        @name = name
      end

      ##
      # Returns the current value of the binding by invoking the getter lambda.
      # @return [Object] The current value of the binding.
      def value
        @getter.call
      end

      ##
      # Sets the binding's value to the specified value using the underlying setter logic.
      # @param new_value The new value to assign to the binding.
      def value=(new_value)
        @setter.call(new_value)
      end

      # Allow binding to be used in DSL
      delegate :to_s, to: :value

      ##
      # Registers a handler to be called when the binding value changes.
      # @yield [new_value] The block to execute on value change.
      # @return [self] Returns self for method chaining.
      def on_change(&block)
        @change_handler = block
        self
      end

      ##
      # Creates a derived binding by applying a transformation to the current value.
      # The returned binding reflects the transformed value on get, and attempts to reverse the transformation on set if the transform block responds to `inverse`.
      # @return [BindingValue] A new binding representing the transformed value.
      def map(&transform)
        BindingValue.new(
          getter: -> { yield(value) },
          setter: lambda { |new_value|
            # Reverse transform if possible
            self.value = transform.inverse.call(new_value) if transform.respond_to?(:inverse)
          },
          source: source,
          name: "#{name}_mapped"
        )
      end

      ##
      # Creates a derived binding for a nested property specified by a dot-separated key path.
      # The returned binding allows reactive access and assignment to the nested value, updating the parent object when changes occur.
      # @param [String, Symbol] key_path - Dot-separated path to the nested property (e.g., "address.street").
      # @return [BindingValue] A new binding for the nested property.
      def project(key_path)
        keys = key_path.to_s.split('.')

        BindingValue.new(
          getter: lambda {
            keys.reduce(value) { |obj, key| obj&.send(key) || obj&.[](key) }
          },
          setter: lambda { |new_value|
            obj = value.dup
            last_key = keys.pop
            parent = keys.reduce(obj) { |o, key| o.send(key) || o[key] }

            if parent.respond_to?("#{last_key}=")
              parent.send("#{last_key}=", new_value)
            else
              parent[last_key] = new_value
            end

            self.value = obj
          },
          source: source,
          name: "#{name}.#{key_path}"
        )
      end
    end
  end
end
# Copyright 2025
