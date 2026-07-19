# frozen_string_literal: true

require "test_helper"

class LineClampTest < ActionView::TestCase
  include SwiftUIRails::Helpers

  test "line clamp renders the requested utility and remains chainable" do
    result = swift_ui do
      text("Clamped content").line_clamp(3).text_color("gray-600")
    end

    fragment = Nokogiri::HTML.fragment(result)
    element = fragment.at_css("span.line-clamp-3.text-gray-600")

    assert element
    assert_equal "Clamped content", element.text
  end
end
