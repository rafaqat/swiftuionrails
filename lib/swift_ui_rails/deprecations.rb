# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  # Handles deprecation warnings for removed or renamed components
  module Deprecations
    REMOVED_COMPONENTS = {
      'ProductListComponent' => {
        removed_in: '1.0.0',
        alternative: 'Use DSL-based product cards with swift_ui blocks instead',
        message: 'ProductListComponent has been removed in favor of DSL-first approach'
      },
      'EnhancedProductListComponent' => {
        removed_in: '1.0.0', 
        alternative: 'Use DSL-based product cards with swift_ui blocks instead',
        message: 'EnhancedProductListComponent has been removed in favor of DSL-first approach'
      },
      'SwiftUIComponent' => {
        removed_in: '1.0.0',
        alternative: 'Use SwiftUIRails::Component::Base as the base class',
        message: 'SwiftUIComponent has been renamed to SwiftUIRails::Component::Base'
      }
    }.freeze

    class << self
      def warn_if_removed(component_name)
        if (deprecation = REMOVED_COMPONENTS[component_name])
          message = "[DEPRECATION] #{deprecation[:message]}. "
          message += "Removed in version #{deprecation[:removed_in]}. "
          message += deprecation[:alternative]
          
          warn message
          
          # Log to Rails logger if available
          if defined?(Rails) && Rails.logger
            Rails.logger.warn message
          end
        end
      end

      def check_component_usage(klass)
        # Check if trying to use a removed component
        component_name = klass.name.demodulize
        warn_if_removed(component_name)
      end
    end
  end
end
# Copyright 2025