# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  # Context for executing DSL blocks and capturing elements
  class DSLContext
    include DSL

    attr_reader :view_context, :component, :depth

    def initialize(view_context, parent_depth = 0)
      @view_context = view_context
      @pending_elements = []
      @depth = parent_depth + 1

      # SECURITY: Check maximum component depth to prevent stack overflow
      max_depth = SwiftUIRails.configuration.maximum_component_depth
      if @depth > max_depth
        Rails.logger.error "[SECURITY] Maximum component depth (#{max_depth}) exceeded at depth #{@depth}"
        raise SwiftUIRails::SecurityError,
              'Maximum component nesting depth exceeded. This may indicate an infinite loop or attack.'
      end

      # SECURITY: Use public API instead of private access
      # Store the original component if view_context is already a DSLContext
      @component = if view_context.is_a?(DSLContext) && view_context.respond_to?(:component)
                     view_context.component
                   elsif view_context.respond_to?(:component_id)
                     view_context
                   end
    end

    # Register an element for rendering
    def register_element(element)
      # Prevent duplicate registration
      if @pending_elements.include?(element)
        Rails.logger.debug do
          "DSLContext: Skipping duplicate registration of #{element.tag_name} (#{element.object_id})"
        end
      else
        Rails.logger.debug do
          "DSLContext: Registering element #{element.tag_name} (#{element.object_id}), class: #{element.class.name}"
        end
        @pending_elements << element
      end
    end

    # Flush all pending elements as HTML
    def flush_elements
      Rails.logger.debug { "DSLContext: Flushing #{@pending_elements.length} elements" }

      html_parts = @pending_elements.map do |element|
        # Ensure view context is set
        element.view_context ||= @view_context
        Rails.logger.debug { "DSLContext: Rendering element #{element.tag_name}" }
        (element.to_s || '').html_safe
      end

      # Clear the pending elements after rendering
      @pending_elements.clear

      result = safe_join(html_parts)
      Rails.logger.debug { "DSLContext: Flushed #{html_parts.length} elements, total length: #{result.to_s.length}" }
      result
    end

    # Delegate component_id to the component if available
    def component_id
      if @component
        @component.component_id
      elsif @view_context.respond_to?(:component_id)
        @view_context.component_id
      end
    end

    # Delegate class to the component for metadata
    def class
      # If we have a component, return its class
      # Otherwise if view_context is a component, return its class
      # Otherwise return our own class
      if @component
        @component.class
      elsif @view_context.respond_to?(:component_id)
        @view_context.class
      else
        super
      end
    end

    # Delegate view helpers to the view context
    def method_missing(method, *args, **kwargs, &block)
      # Check for both public and private methods since component methods are often private
      Rails.logger.debug { "DSLContext.method_missing: #{method}, view_context: #{@view_context.class.name}" }
      if @view_context.respond_to?(method, true)
        Rails.logger.debug { "DSLContext.method_missing: Delegating #{method} to view_context" }
        # Handle both positional and keyword arguments
        if kwargs.empty?
          @view_context.send(method, *args, &block)
        elsif args.empty?
          @view_context.send(method, **kwargs, &block)
        else
          @view_context.send(method, *args, **kwargs, &block)
        end
      else
        Rails.logger.debug { "DSLContext.method_missing: #{method} not found on view_context" }
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @view_context.respond_to?(method, include_private) || super
    end

    # Make sure view context methods are available
    def content_tag(...)
      @view_context.content_tag(...)
    end

    def tag(*args)
      @view_context.tag(*args)
    end

    delegate :raw, to: :@view_context

    def capture(&block)
      @view_context.capture(&block)
    end

    delegate :concat, to: :@view_context

    def class_names(*args)
      @view_context.class_names(*args)
    end

    # Override the render method to use the view context
    def render(...)
      @view_context.render(...)
    end

    # Use safe_join for combining HTML parts
    delegate :safe_join, to: :@view_context

    # Make sure respond_to? works for component_id
    def respond_to?(method, include_private = false)
      if method.to_sym == :component_id
        true # Always return true for component_id since we handle it in the method
      else
        super
      end
    end
  end
end
# Copyright 2025
