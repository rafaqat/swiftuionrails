# frozen_string_literal: true

module SwiftUIRails
  # Context for executing DSL blocks and capturing elements
  class DSLContext
    include DSL
    
    attr_reader :view_context
    
    def initialize(view_context)
      @view_context = view_context
      @pending_elements = []
      # Store the original component if view_context is already a DSLContext
      @component = if view_context.is_a?(DSLContext) && view_context.instance_variable_get(:@component)
        view_context.instance_variable_get(:@component)
      elsif view_context.respond_to?(:component_id)
        view_context
      else
        nil
      end
    end
    
    # Register an element for rendering
    def register_element(element)
      @pending_elements << element
    end
    
    # Flush all pending elements as HTML
    def flush_elements
      html_parts = @pending_elements.map do |element|
        element.view_context = @view_context
        element.to_s
      end
      
      html_parts.join.html_safe
    end
    
    # Delegate component_id to the component if available
    def component_id
      if @component
        @component.component_id
      elsif @view_context.respond_to?(:component_id)
        @view_context.component_id
      else
        nil
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
    def method_missing(method, *args, &block)
      if @view_context.respond_to?(method)
        @view_context.send(method, *args, &block)
      else
        super
      end
    end
    
    def respond_to_missing?(method, include_private = false)
      @view_context.respond_to?(method) || super
    end
    
    # Make sure respond_to? works for component_id
    def respond_to?(method, include_private = false)
      if method.to_sym == :component_id
        true  # Always return true for component_id since we handle it in the method
      else
        super
      end
    end
  end
end