# frozen_string_literal: true

module SwiftUIRails
  module DevTools
    module DebugHelpers
      ##
      # Returns a string representation of a component's tree in the specified format, but only in the local Rails environment.
      # If no component is provided, uses self if it is a component; otherwise, raises an ArgumentError.
      # @param [Object, nil] component - The component whose tree to debug. Defaults to self if self is a component.
      # @param [Symbol] format - The output format (:ascii by default).
      # @return [String] The formatted component tree, or an empty string if not in the local environment.
      # @raise [ArgumentError] If no component is provided and self is not a component.
      def debug_component_tree(component = nil, format: :ascii, **options)
        return '' unless Rails.env.local?

        component ||= self if is_a?(SwiftUIRails::Component::Base)

        raise ArgumentError, 'No component provided and self is not a component' unless component

        ComponentTreeDebugger.debug_tree(component, format: format, **options)
      end

      ##
      # Prints the component tree to the console in the local Rails environment.
      # If no component is provided, uses self if it is a component.
      # Does nothing outside the local environment.
      def print_component_tree(component = nil, **options)
        return unless Rails.env.local?

        component ||= self if is_a?(SwiftUIRails::Component::Base)
        ComponentTreeDebugger.print_tree(component, **options)
      end

      ##
      # Logs the component tree to the Rails logger in the local environment.
      # If no component is provided, uses self if it is a component.
      # Returns nil if not in the local environment.
      def log_component_tree(component = nil, **options)
        return unless Rails.env.local?

        component ||= self if is_a?(SwiftUIRails::Component::Base)
        ComponentTreeDebugger.log_tree(component, **options)
      end

      ##
      # Returns a string representation of the given DSL element tree in the specified format, but only in the local Rails environment.
      # Raises an ArgumentError if the provided element is not a SwiftUIRails::DSL::Element.
      # @param element The DSL element whose tree will be rendered.
      # @param format [Symbol] The output format, either :ascii or :html (default: :ascii).
      # @return [String] The formatted element tree, or an empty string if not in the local environment.
      def debug_element_tree(element, format: :ascii, **options)
        return '' unless Rails.env.local?

        unless element.is_a?(SwiftUIRails::DSL::Element)
          raise ArgumentError, "Expected DSL::Element, got #{element.class}"
        end

        ComponentTreeDebugger.debug_tree(element, format: format, **options)
      end

      ##
      # Wraps the output of a block with a div containing debug metadata attributes, but only in the local environment and if debugging is enabled.
      # Returns the block's content unmodified if not in a local environment or if debugging is disabled.
      # @param [Boolean] enabled Whether to include debug info; defaults to true.
      def with_debug_info(enabled: true, &block)
        return capture(&block) unless Rails.env.local? && enabled

        content = capture(&block)
        debug_id = "debug_#{SecureRandom.hex(4)}"

        content_tag(:div,
                    data: {
                      debug_id: debug_id,
                      component: self.class.name,
                      timestamp: Time.current.to_i
                    },
                    class: 'swift-ui-debug-wrapper') do
          content
        end
      end

      ##
      # Returns an HTML details element displaying the component tree in an inline, expandable format for local debugging.
      # If no component is provided, uses self if it is a component.
      # Only renders output in the local Rails environment.
      # @return [String, nil] HTML markup for the inline debug tree, or nil if not in a local environment.
      def debug_tree_inline(component = nil, **options)
        return unless Rails.env.local?

        component ||= self if is_a?(SwiftUIRails::Component::Base)
        tree = ComponentTreeDebugger.debug_tree(component, format: :html, **options)

        content_tag(:details, class: 'swift-ui-debug-tree-inline') do
          content_tag(:summary, '🔍 Component Tree') + tree
        end
      end
    end
  end
end
