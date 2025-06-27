# frozen_string_literal: true

module SwiftUIRails
  # DSL Context that properly delegates to the view while including DSL methods
  class DSLContext
    include SwiftUIRails::DSL
    
    def initialize(view_context)
      @view_context = view_context
      @pending_elements = []
      @element_stack = []
    end
    
    # Delegate all view helper methods to the view context
    def method_missing(method, *args, &block)
      if @view_context.respond_to?(method)
        @view_context.send(method, *args, &block)
      else
        super
      end
    end
    
    def respond_to_missing?(method, include_private = false)
      @view_context.respond_to?(method, include_private) || super
    end
    
    # Make sure view context methods are available
    def content_tag(*args, &block)
      @view_context.content_tag(*args, &block)
    end
    
    def tag(*args)
      @view_context.tag(*args)
    end
    
    def raw(content)
      @view_context.raw(content)
    end
    
    def capture(&block)
      @view_context.capture(&block)
    end
    
    def concat(content)
      @view_context.concat(content)
    end
    
    def class_names(*args)
      @view_context.class_names(*args)
    end
    
    # Override the render method to use the view context
    def render(*args, &block)
      @view_context.render(*args, &block)
    end
    
    # Register an element for deferred rendering
    def register_element(element)
      @pending_elements << element
    end
    
    # Flush pending elements to buffer and return their HTML
    def flush_elements
      html_parts = @pending_elements.map { |element| (element.to_s || "").html_safe }
      @pending_elements.clear
      @view_context.safe_join(html_parts)
    end
    
    # Get current buffer for block capture
    def current_buffer
      @_element_buffer ||= ActionView::OutputBuffer.new
    end
    
    # Set the element buffer
    def set_buffer(buffer)
      @_element_buffer = buffer
    end
  end
  
  module Helpers
    # Helper for inline Swift DSL usage in views
    def swift_ui(&block)
      # Create a DSL context that delegates view helpers to the current view
      dsl_context = DSLContext.new(self)
      
      # Execute the block in the DSL context
      content = dsl_context.instance_eval(&block)
      
      # Convert Element instances to HTML
      if content.is_a?(SwiftUIRails::DSL::Element)
        # Set the view context on the element
        content.view_context = self
        raw(content.to_s)
      else
        raw(content)
      end
    end

    def swift_component(name, **props, &block)
      component_class = "#{name.to_s.camelize}Component".constantize
      render component_class.new(**props), &block
    end
  end
end