# frozen_string_literal: true

# Copyright 2025

require_relative 'dsl/context'
require_relative 'dev_tools/debug_helpers' if Rails.env.local?

module SwiftUIRails
  module Helpers
    include SwiftUIRails::DevTools::DebugHelpers if Rails.env.local?
    ##
    # Renders SwiftUI-style UI elements in a Rails view using a Ruby DSL block.
    # Executes the provided block within a DSL context, collects all created UI elements, and returns them as HTML-safe content.
    def swift_ui(&block)
      # Create a DSL context that delegates view helpers to the current view
      dsl_context = DSLContext.new(self)

      # Execute the block in the DSL context
      # Elements created during execution are automatically registered
      dsl_context.instance_eval(&block)

      # Always flush to get all registered elements
      # This includes both explicitly registered elements and any returned by the block
      flushed_content = dsl_context.flush_elements

      # Return the flushed content
      raw(flushed_content)
    end

    ##
    # Renders a SwiftUI-style component by name with the given properties and optional block content.
    #
    # Validates the component name against an allowed list and ensures the resolved class inherits from an approved base component class.
    # Raises a security error if the component is unauthorized or invalid, and an argument error if the component class cannot be found.
    # @param [String, Symbol] name The base name of the component to render (without "Component" suffix).
    # @param [Hash] props Properties to pass to the component initializer.
    # @yield Optional block providing content for the component.
    # @return [String] The rendered component HTML.
    def swift_component(name, **props, &block)
      # SECURITY: Validate component name against whitelist to prevent RCE
      component_name = name.to_s.camelize

      unless SwiftUIRails.configuration.component_allowed?(component_name)
        Rails.logger.error "[SECURITY] Attempted to instantiate unauthorized component via swift_component: #{component_name}"
        raise SwiftUIRails::SecurityError,
              "Unauthorized component: #{component_name}. Component must be added to the allowed_components list."
      end

      # Build the full component class name
      component_class_name = "#{component_name}Component"

      begin
        # Safe constantize with additional validation
        component_class = component_class_name.constantize

        # Verify it's actually a SwiftUI Rails component
        unless component_class < SwiftUIRails::Component::Base ||
               (defined?(ApplicationComponent) && component_class < ApplicationComponent) ||
               (defined?(ViewComponent::Base) && component_class < ViewComponent::Base)
          Rails.logger.error "[SECURITY] Class #{component_class_name} is not a valid component"
          raise SecurityError, "#{component_class_name} is not a valid SwiftUI Rails component"
        end

        # Log successful component instantiation for audit trail
        Rails.logger.info "[AUDIT] swift_component rendered: #{component_class_name}"

        # Render the component safely
        render component_class.new(**props), &block
      rescue NameError => e
        Rails.logger.error "[ERROR] Component class not found: #{component_class_name} - #{e.message}"
        raise ArgumentError,
              "Component #{component_class_name} not found. Ensure the component is defined and properly named."
      end
    end
  end
end
# Copyright 2025
