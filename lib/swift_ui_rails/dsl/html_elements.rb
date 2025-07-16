# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Basic HTML elements for SwiftUI Rails DSL
    module HTMLElements
      def div(**attrs, &block)
        Rails.logger.debug { "DSL.div called with block: #{block}" }
        create_element(:div, nil, **attrs, &block)
      end

      def span(**attrs, &block)
        create_element(:span, nil, **attrs, &block)
      end

      def section(**attrs, &block)
        Rails.logger.debug { "DSL.section called with block: #{block}, attrs: #{attrs.inspect}" }
        create_element(:section, nil, **attrs, &block)
      end

      def article(**attrs, &block)
        create_element(:article, nil, **attrs, &block)
      end

      def header(**attrs, &block)
        create_element(:header, nil, **attrs, &block)
      end

      def footer(**attrs, &block)
        create_element(:footer, nil, **attrs, &block)
      end

      def nav(**attrs, &block)
        create_element(:nav, nil, **attrs, &block)
      end

      def a(**attrs, &block)
        create_element(:a, nil, **attrs, &block)
      end

      def h1(**attrs, &block)
        create_element(:h1, nil, **attrs, &block)
      end

      def h2(**attrs, &block)
        create_element(:h2, nil, **attrs, &block)
      end

      def h3(**attrs, &block)
        create_element(:h3, nil, **attrs, &block)
      end

      def h4(**attrs, &block)
        create_element(:h4, nil, **attrs, &block)
      end

      def h5(**attrs, &block)
        create_element(:h5, nil, **attrs, &block)
      end

      def h6(**attrs, &block)
        create_element(:h6, nil, **attrs, &block)
      end

      def p(**attrs, &block)
        create_element(:p, nil, **attrs, &block)
      end

      # Text element - special handling for inline text
      def text(content, **attrs)
        create_element(:span, content, **attrs)
      end

      # Link helper with destination
      def link(title = nil, destination: '#', **attrs, &block)
        attrs[:href] = destination
        if block_given?
          create_element(:a, nil, **attrs, &block)
        else
          create_element(:a, title, **attrs)
        end
      end
    end
  end
end