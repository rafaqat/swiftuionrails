# frozen_string_literal: true

module SwiftUIRails
  module DevTools
    module DebugHelpers
      # Debug component tree in development
      def debug_component_tree(component = nil, format: :ascii, **options)
        return "" unless Rails.env.development? || Rails.env.test?
        
        component ||= self if self.is_a?(SwiftUIRails::Component::Base)
        
        unless component
          raise ArgumentError, "No component provided and self is not a component"
        end
        
        ComponentTreeDebugger.debug_tree(component, format: format, **options)
      end
      
      # Print component tree to console
      def print_component_tree(component = nil, **options)
        return unless Rails.env.development? || Rails.env.test?
        
        component ||= self if self.is_a?(SwiftUIRails::Component::Base)
        ComponentTreeDebugger.print_tree(component, **options)
      end
      
      # Log component tree to Rails logger
      def log_component_tree(component = nil, **options)
        return unless Rails.env.development? || Rails.env.test?
        
        component ||= self if self.is_a?(SwiftUIRails::Component::Base)
        ComponentTreeDebugger.log_tree(component, **options)
      end
      
      # Debug DSL element tree
      def debug_element_tree(element, format: :ascii, **options)
        return "" unless Rails.env.development? || Rails.env.test?
        
        unless element.is_a?(SwiftUIRails::DSL::Element)
          raise ArgumentError, "Expected DSL::Element, got #{element.class}"
        end
        
        ComponentTreeDebugger.debug_tree(element, format: format, **options)
      end
      
      # Helper to wrap content with debug info in development
      def with_debug_info(enabled: true, &block)
        return capture(&block) unless (Rails.env.development? || Rails.env.test?) && enabled
        
        content = capture(&block)
        debug_id = "debug_#{SecureRandom.hex(4)}"
        
        content_tag(:div, 
          data: { 
            debug_id: debug_id,
            component: self.class.name,
            timestamp: Time.current.to_i
          },
          class: "swift-ui-debug-wrapper"
        ) do
          content
        end
      end
      
      # Inline debug tree display
      def debug_tree_inline(component = nil, **options)
        return unless Rails.env.development? || Rails.env.test?
        
        component ||= self if self.is_a?(SwiftUIRails::Component::Base)
        tree = ComponentTreeDebugger.debug_tree(component, format: :html, **options)
        
        content_tag(:details, class: "swift-ui-debug-tree-inline") do
          content_tag(:summary, "🔍 Component Tree") + tree
        end
      end
    end
  end
end