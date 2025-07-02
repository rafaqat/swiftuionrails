# frozen_string_literal: true

require_relative "dsl/context"

module SwiftUIRails
  module Helpers
    # Helper for inline Swift DSL usage in views
    def swift_ui(&block)
      # Create a DSL context that delegates view helpers to the current view
      dsl_context = DSLContext.new(self)
      
      # Execute the block in the DSL context
      # Elements created during execution are automatically registered
      result = dsl_context.instance_eval(&block)
      
      # Always flush to get all registered elements
      # This includes both explicitly registered elements and any returned by the block
      flushed_content = dsl_context.flush_elements
      
      # Return the flushed content
      raw(flushed_content)
    end

    def swift_component(name, **props, &block)
      component_class = "#{name.to_s.camelize}Component".constantize
      render component_class.new(**props), &block
    end
  end
end