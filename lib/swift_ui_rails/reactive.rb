# frozen_string_literal: true
# Copyright 2025

require_relative "reactive/state"
require_relative "reactive/binding"
require_relative "reactive/observed_object"
require_relative "reactive/rendering"
require_relative "reactive/debugging"

module SwiftUIRails
  # SwiftUI-style reactive state management
  module Reactive
    extend ActiveSupport::Concern
    
    included do
      # Include all reactive modules
      include State
      include Binding
      include ObservedObject
      include Rendering
      include Debugging if Rails.env.development?
    end
    
    class_methods do
      # Configure reactive features
      def reactive_config
        @reactive_config ||= {
          auto_render: true,
          debug: Rails.env.development?,
          cable_enabled: true,
          debounce_ms: 100
        }
      end
      
      def configure_reactive
        yield reactive_config
      end
    end
    
    # Helper methods for reactive components
    def reactive?
      true
    end
    
    def state_dependencies
      dependencies = []
      
      # Collect state dependencies
      if respond_to?(:state_definitions)
        dependencies.concat(self.class.state_definitions.keys.map { |k| "state.#{k}" })
      end
      
      # Collect binding dependencies
      if respond_to?(:binding_definitions)
        dependencies.concat(self.class.binding_definitions.keys.map { |k| "binding.#{k}" })
      end
      
      # Collect observed object dependencies
      if respond_to?(:observed_object_definitions)
        self.class.observed_object_definitions.each do |name, _|
          store = send(name)
          dependencies.concat(store.data.keys.map { |k| "observed.#{name}.#{k}" })
        end
      end
      
      dependencies
    end
    
    # Trigger manual update
    def trigger_update
      return unless reactive?
      
      if defined?(Reactive::ReactiveUpdateJob)
        Reactive::ReactiveUpdateJob.perform_later(
          self.class.name,
          "swift-ui-#{self.class.name.underscore.dasherize}-#{object_id}",
          serialize_props
        )
      end
    end
    
    # Check if component should update
    def should_update?(new_props = {})
      # Always update if props changed
      return true if props_changed?(new_props)
      
      # Check if any reactive state changed
      state_dependencies.any? { |dep| dependency_changed?(dep) }
    end
    
    private
    
    def props_changed?(new_props)
      return false if new_props.empty?
      
      self.class.prop_definitions.keys.any? do |prop_name|
        new_value = new_props[prop_name] || new_props[prop_name.to_s]
        current_value = instance_variable_get("@#{prop_name}")
        new_value != current_value
      end
    end
    
    def dependency_changed?(dependency)
      # This would be implemented to check if a specific dependency changed
      # In practice, this would integrate with the change tracking system
      false
    end
  end
end
# Copyright 2025
