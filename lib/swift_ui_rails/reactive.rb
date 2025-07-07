# frozen_string_literal: true

# Copyright 2025

require_relative 'reactive/state'
require_relative 'reactive/binding'
require_relative 'reactive/observed_object'
require_relative 'reactive/rendering'
require_relative 'reactive/debugging'

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
      ##
      # Returns the current configuration settings for reactive features, including auto-rendering, debug mode, cable support, and debounce interval.
      # @return [Hash] The configuration hash for reactive behavior.
      def reactive_config
        @reactive_config ||= {
          auto_render: true,
          debug: Rails.env.development?,
          cable_enabled: true,
          debounce_ms: 100
        }
      end

      ##
      # Yields the current reactive configuration hash to a block for modification.
      # The block can update settings such as auto rendering, debug mode, cable support, and debounce interval.
      # @yield [config] Gives the current configuration hash to the block for in-place modification.
      def configure_reactive
        yield reactive_config
      end
    end

    ##
    # Indicates that the component is reactive.
    # @return [Boolean] Always returns true.
    def reactive?
      true
    end

    ##
    # Returns an array of strings representing all reactive state, binding, and observed object dependencies for the component.
    # Each dependency is prefixed to indicate its type (e.g., "state.", "binding.", "observed.").
    # @return [Array<String>] List of reactive dependency identifiers.
    def state_dependencies
      dependencies = []

      # Collect state dependencies
      dependencies.concat(self.class.state_definitions.keys.map { |k| "state.#{k}" }) if respond_to?(:state_definitions)

      # Collect binding dependencies
      if respond_to?(:binding_definitions)
        dependencies.concat(self.class.binding_definitions.keys.map { |k| "binding.#{k}" })
      end

      # Collect observed object dependencies
      if respond_to?(:observed_object_definitions)
        self.class.observed_object_definitions.each_key do |name|
          store = send(name)
          dependencies.concat(store.data.keys.map { |k| "observed.#{name}.#{k}" })
        end
      end

      dependencies
    end

    ##
    # Enqueues a background job to trigger a manual update for the reactive component if supported.
    # The job is only enqueued if the component is reactive and the ReactiveUpdateJob is defined.
    def trigger_update
      return unless reactive?

      return unless defined?(Reactive::ReactiveUpdateJob)

      Reactive::ReactiveUpdateJob.perform_later(
        self.class.name,
        "swift-ui-#{self.class.name.underscore.dasherize}-#{object_id}",
        serialize_props
      )
    end

    ##
    # Determines whether the component should update based on changes to props or reactive state dependencies.
    # @param [Hash] new_props Optional new props to compare against current props.
    # @return [Boolean] True if an update is needed due to changed props or dependencies.
    def should_update?(new_props = {})
      # Always update if props changed
      return true if props_changed?(new_props)

      # Check if any reactive state changed
      state_dependencies.any? { |dep| dependency_changed?(dep) }
    end

    private

    ##
    # Determines if any defined prop has changed compared to the current instance variables.
    # @param [Hash] new_props - The new props to compare against current values.
    # @return [Boolean] True if any prop value differs; false otherwise.
    def props_changed?(new_props)
      return false if new_props.empty?

      self.class.prop_definitions.keys.any? do |prop_name|
        new_value = new_props[prop_name] || new_props[prop_name.to_s]
        current_value = instance_variable_get("@#{prop_name}")
        new_value != current_value
      end
    end

    ##
    # Checks if a specific reactive dependency has changed.
    # Currently returns false as a placeholder; intended for integration with a change tracking system.
    # @return [Boolean] Always returns false in the current implementation.
    def dependency_changed?(_dependency)
      # This would be implemented to check if a specific dependency changed
      # In practice, this would integrate with the change tracking system
      false
    end
  end
end
# Copyright 2025
