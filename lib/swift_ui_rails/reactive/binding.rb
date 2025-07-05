# frozen_string_literal: true

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
        # @binding :text_value, type: String
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
      
      def set_binding_value(name, value)
        @binding_values ||= {}
        old_value = @binding_values[name]
        @binding_values[name] = value
        
        # Notify parent component if this is a child binding
        if @parent_binding_callback
          @parent_binding_callback.call(name, value, old_value)
        end
        
        # Track change for reactivity
        track_binding_change(name, old_value, value)
      end
      
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
      
      # Pass binding to child component
      def pass_binding(component, binding_name, as: nil)
        target_name = as || binding_name
        
        # Set up two-way connection
        component.instance_variable_set("@#{target_name}", send(binding_name).value)
        component.instance_variable_set("@parent_binding_callback", 
          ->(name, value, old_value) do
            if name == target_name
              send(binding_name).value = value
            end
          end
        )
      end
    end
    
    # Binding value wrapper
    class BindingValue
      attr_reader :source, :name
      
      def initialize(getter:, setter:, source:, name:)
        @getter = getter
        @setter = setter
        @source = source
        @name = name
      end
      
      def value
        @getter.call
      end
      
      def value=(new_value)
        @setter.call(new_value)
      end
      
      # Allow binding to be used in DSL
      def to_s
        value.to_s
      end
      
      # For reactive updates
      def on_change(&block)
        @change_handler = block
        self
      end
      
      # Create derived binding
      def map(&transform)
        BindingValue.new(
          getter: -> { transform.call(value) },
          setter: ->(new_value) { 
            # Reverse transform if possible
            if transform.respond_to?(:inverse)
              self.value = transform.inverse.call(new_value)
            end
          },
          source: source,
          name: "#{name}_mapped"
        )
      end
      
      # Create binding projection (for nested values)
      def project(key_path)
        keys = key_path.to_s.split('.')
        
        BindingValue.new(
          getter: -> { 
            keys.reduce(value) { |obj, key| obj&.send(key) || obj&.[](key) }
          },
          setter: ->(new_value) {
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
