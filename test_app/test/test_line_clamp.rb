# Copyright 2025
require "test_helper"

class TestLineClamp < ActiveSupport::TestCase
  test "line_clamp method exists and works" do
    # Test that the method exists
    element = SwiftUIRails::DSL::Element.new(:span, "test")
    assert element.respond_to?(:line_clamp), "line_clamp method should exist"

    # Test that it returns the element for chaining
    result = element.line_clamp("2")
    assert_equal element, result, "line_clamp should return self for chaining"

    # Test that it adds the correct CSS class
    element.line_clamp("3")
    html = element.to_s
    assert_includes html, "line-clamp-3", "Should include line-clamp-3 CSS class"
  end
end
# Copyright 2025
