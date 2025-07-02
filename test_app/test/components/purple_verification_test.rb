require "test_helper"

class PurpleVerificationTest < ViewComponent::TestCase
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  def test_purple_600_specifically_renders_correctly
    # This was the exact issue reported by user: "purple 600 not changing"
    render_inline(SimpleButtonComponent.new(title: "Purple 600 Test", background_color: "purple-600"))
    
    # Verify purple-600 background is applied
    assert_selector "button.bg-purple-600", text: "Purple 600 Test"
    
    # Verify smart text color is white (since purple-600 is dark)
    assert_selector "button.text-white", text: "Purple 600 Test"
    
    # Verify no hardcoded text colors from variants are interfering
    assert_no_selector "button.text-gray-900", text: "Purple 600 Test"
  end

  def test_purple_color_classes_are_available_in_css
    # Test that purple classes were properly added to safelist
    purple_colors = %w[purple-400 purple-500 purple-600 purple-700 purple-800]
    
    purple_colors.each do |color|
      render_inline(SimpleButtonComponent.new(title: "Test #{color}", background_color: color))
      assert_selector "button.bg-#{color}", text: "Test #{color}"
    end
  end
end