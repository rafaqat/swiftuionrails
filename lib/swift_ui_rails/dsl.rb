# frozen_string_literal: true

# Copyright 2025

require_relative 'dsl/element'
require_relative 'dsl/safe_element'
require_relative 'dsl/context'
require_relative 'security/css_validator'
require_relative 'security/form_helpers'
require_relative 'security/url_validator'
require_relative 'orientation'

# Load DSL modules
require_relative 'dsl/layout'
require_relative 'dsl/html_elements'
require_relative 'dsl/form_elements'
require_relative 'dsl/table_components'
require_relative 'dsl/media'
require_relative 'dsl/containers'
require_relative 'dsl/collections'
require_relative 'dsl/commerce'
require_relative 'dsl/utilities'

module SwiftUIRails
  module DSL
    extend ActiveSupport::Concern
    include Security::FormHelpers
    include Orientation::Helpers
    include Orientation::SizeClasses
    
    # Include all DSL modules
    include Layout
    include HTMLElements
    include FormElements
    include TableComponents
    include Media
    include Containers
    include Collections
    include Commerce
    include Utilities
    
    # Thread-local storage for current DSL context
    # This enables helper methods to work within the DSL
    thread_mattr_accessor :current_context

    # Create a chainable element
    def create_element(tag_name, content = nil, options = {}, &block)
      # Determine the context - either a DSLContext or a Component
      dsl_context = case self
                    when SwiftUIRails::DSLContext
                      self
                    when SwiftUIRails::Component::Base
                      # Component is the DSL context now
                      self
                    else
                      nil
                    end
      
      element = Element.new(tag_name, content, options, dsl_context, &block)

      # Set the view context for Rails helper access
      element.view_context = if is_a?(SwiftUIRails::DSLContext)
                               @view_context
                             else
                               self
                             end

      # Store component reference for event handling
      if respond_to?(:component_id)
        Rails.logger.debug { "Storing component on element: #{self.class.name}, component_id=#{component_id}" }
        element.instance_variable_set(:@component, self)
      elsif is_a?(DSLContext) && @component
        Rails.logger.debug do
          "Storing component from context: #{@component.class.name}, component_id=#{@component&.component_id}"
        end
        element.instance_variable_set(:@component, @component)
      end

      # Register the element if we're in a DSL context or component
      # This prevents double registration when blocks return elements
      if is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base)
        Rails.logger.debug { "[DSL] Registering element #{tag_name} to #{self.class.name} #{object_id}" }
        register_element(element)
      else
        Rails.logger.debug { "[DSL] Created element #{tag_name} outside DSL context/component - not registering" }
      end

      element
    end
  end
end
# Copyright 2025