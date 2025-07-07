# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  # Context for executing DSL blocks and capturing elements
  class DSLContext
    include DSL

    attr_reader :view_context, :component, :depth

    ##
    # Initializes a new DSLContext for executing DSL blocks and tracking UI elements.
    # Enforces a maximum component nesting depth for security and determines the current component context.
    # @param view_context The Rails view context or another DSLContext instance.
    # @param parent_depth [Integer] The current nesting depth (default: 0).
    # @raise [SwiftUIRails::SecurityError] If the maximum component nesting depth is exceeded.
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

    ##
    # Registers a UI element for later rendering, ensuring each element is only registered once.
    # Skips duplicate registrations based on object identity.
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

    ##
    # Renders all registered UI elements to HTML and returns the combined output.
    # Clears the list of pending elements after rendering.
    # @return [ActiveSupport::SafeBuffer] The HTML-safe string containing all rendered elements.
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

    ##
    # Returns the component ID from the current component if present, or from the view context if available.
    # @return [Object, nil] The component ID, or nil if not available.
    def component_id
      if @component
        @component.component_id
      elsif @view_context.respond_to?(:component_id)
        @view_context.component_id
      end
    end

    ##
    # Returns the class of the current component if available, otherwise the class of the view context if it represents a component, or falls back to the superclass implementation.
    # @return [Class] The class object representing the current component or view context.
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

    ##
    # Forwards missing method calls to the underlying view context if it responds to the method.
    # Supports delegation of both positional and keyword arguments, as well as blocks.
    # Calls `super` if the method is not found on the view context.
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

    ##
    # Determines if the view context or superclass responds to a given method, including private methods if specified.
    # @param [Symbol] method - The method name to check.
    # @param [Boolean] include_private - Whether to include private methods in the check.
    # @return [Boolean] True if the method is handled by the view context or superclass.
    def respond_to_missing?(method, include_private = false)
      @view_context.respond_to?(method, include_private) || super
    end

    ##
    # Delegates the `content_tag` method to the underlying view context, allowing HTML tag generation within the DSL context.
    def content_tag(...)
      @view_context.content_tag(...)
    end

    ##
    # Delegates the `tag` helper method to the underlying view context for generating HTML tags.
    def tag(*args)
      @view_context.tag(*args)
    end

    delegate :raw, to: :@view_context

    ##
    # Captures the output of a block for use in templates, delegating to the underlying view context.
    # @yield The block whose output will be captured.
    # @return [String] The captured output as a string.
    def capture(&block)
      @view_context.capture(&block)
    end

    delegate :concat, to: :@view_context

    ##
    # Combines CSS class names using the underlying view context's helper.
    # @return [String] The resulting space-separated class names.
    def class_names(*args)
      @view_context.class_names(*args)
    end

    ##
    # Renders content using the underlying view context's render method.
    # Forwards all arguments and blocks to the view context.
    def render(...)
      @view_context.render(...)
    end

    # Use safe_join for combining HTML parts
    delegate :safe_join, to: :@view_context

    ##
    # Returns true for :component_id to ensure proper delegation, otherwise defers to the superclass.
    # @param [Symbol, String] method - The method name being checked.
    # @param [Boolean] include_private - Whether to include private methods in the check.
    # @return [Boolean] True if the method is :component_id or as determined by the superclass.
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
