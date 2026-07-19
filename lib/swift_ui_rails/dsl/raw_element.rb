# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Wraps pre-rendered HTML — typically a child ViewComponent rendered
    # inside a swift_ui block — so it participates in the DSL element tree
    # like any other child. Strings that are not explicitly html_safe are
    # escaped at render time.
    class RawElement < Element
      def initialize(html, dsl_context = nil)
        super(:raw, nil, {}, dsl_context)
        @raw_html = html
      end

      def to_s
        return @raw_html if @raw_html.respond_to?(:html_safe?) && @raw_html.html_safe?

        ERB::Util.html_escape(@raw_html.to_s)
      end
      alias to_str to_s
    end
  end
end
