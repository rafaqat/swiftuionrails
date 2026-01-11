# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Basic HTML elements for SwiftUI Rails DSL
    module HTMLElements
      def div(**attrs, &block)
        Rails.logger.debug { "DSL.div called with block: #{block}" }
        create_element(:div, nil, **attrs, &block)
      end

      def span(content = nil, **attrs, &block)
        create_element(:span, content, **attrs, &block)
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

      def aside(**attrs, &block)
        create_element(:aside, nil, **attrs, &block)
      end

      def nav(**attrs, &block)
        Rails.logger.debug { "DSL.nav called with block: #{block}, attrs: #{attrs.inspect}" }
        create_element(:nav, nil, **attrs, &block)
      end

      def a(content = nil, **attrs, &block)
        Rails.logger.debug { "DSL.a called with content: #{content}, block: #{block}, attrs: #{attrs.inspect}" }
        create_element(:a, content, **attrs, &block)
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

      # HTML paragraph element - clean separation from Tailwind p() modifier
      def paragraph(**attrs, &block)
        Rails.logger.debug { "DSL.paragraph called with attrs: #{attrs.inspect}, block: #{block}" }
        create_element(:p, nil, **attrs, &block)
      end

      # Text element - special handling for inline text
      def text(content, **attrs)
        create_element(:span, content, **attrs)
      end
      alias_method :Text, :text

      # Link helper with destination
      def link(title = nil, destination: '#', **attrs, &block)
        attrs[:href] = destination
        if block_given?
          create_element(:a, nil, **attrs, &block)
        else
          create_element(:a, title, **attrs)
        end
      end

      # Script element for inline JavaScript
      def script(**attrs, &block)
        create_element(:script, nil, **attrs, &block)
      end

      # Main element for semantic HTML
      def main(**attrs, &block)
        create_element(:main, nil, **attrs, &block)
      end

      # Line break element - self-closing
      def br(**attrs)
        create_element(:br, nil, **attrs)
      end

      def svg(**attrs, &block)
        create_element(:svg, nil, **attrs, &block)
      end

      def path(**attrs)
        create_element(:path, nil, **attrs)
      end
    end
  end
end