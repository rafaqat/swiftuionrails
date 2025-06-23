# frozen_string_literal: true

require "view_component"

module SwiftUIRails
  module Component
    class Base < ::ViewComponent::Base
      include SwiftUIRails::DSL

      class_attribute :swift_states, default: {}
      class_attribute :swift_props, default: {}
      class_attribute :swift_computed, default: {}
      class_attribute :swift_effects, default: {}
      class_attribute :swift_slots, default: {}

      class << self
        # Define the swift_ui DSL block
        def swift_ui(&block)
          # Store the block to be executed in the component context
          @swift_ui_block = block
          
          define_method :call do
            # ViewComponent expects the call method to return the rendered content
            # Execute the block in the component instance context
            result = instance_eval(&self.class.instance_variable_get(:@swift_ui_block))
            
            # If the result is an Element, convert it to string
            if defined?(SwiftUIRails::DSL::Element) && result.is_a?(SwiftUIRails::DSL::Element)
              result.to_s.html_safe
            elsif defined?(SwiftUIRails::DSL::SafeElement) && result.is_a?(SwiftUIRails::DSL::SafeElement)
              result.to_s.html_safe
            elsif result.respond_to?(:html_safe?)
              result.html_safe
            else
              result
            end
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
          end
        end

        def prop(name, type: nil, required: false, default: nil)
          self.swift_props = swift_props.merge(
            name => { type: type, required: required, default: default }
          )
          attr_reader name
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
        validate_and_set_props(our_props)
        super(**view_component_props)
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

      # Helper methods that components can use
      def div(**attrs, &block)
        content_tag(:div, **attrs, &block)
      end

      def span(**attrs, &block)
        content_tag(:span, **attrs, &block)
      end
      
      # Make DSL methods available in components
      include SwiftUIRails::DSL
      
      # Ensure Element class is accessible
      Element = SwiftUIRails::DSL::Element
    end
  end
end