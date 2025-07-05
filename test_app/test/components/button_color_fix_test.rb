# Copyright 2025
require "test_helper"

class ButtonColorFixTest < ViewComponent::TestCase
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  def test_purple_600_background_color_works
    render_inline(SimpleButtonComponent.new(title: "Purple Button", background_color: "purple-600"))
    
    assert_selector "button.bg-purple-600", text: "Purple Button"
    # Should have smart text color (white for dark purple background)
    assert_selector "button.text-white", text: "Purple Button" 
  end

  def test_light_background_gets_dark_text
    # Light colors should get dark text
    render_inline(SimpleButtonComponent.new(title: "Light Button", background_color: "blue-200"))
    
    assert_selector "button.bg-blue-200", text: "Light Button"
    assert_selector "button.text-gray-900", text: "Light Button"
  end

  def test_dark_background_gets_light_text
    # Dark colors should get light text
    render_inline(SimpleButtonComponent.new(title: "Dark Button", background_color: "blue-800"))
    
    assert_selector "button.bg-blue-800", text: "Dark Button"
    assert_selector "button.text-white", text: "Dark Button"
  end

  def test_custom_text_color_overrides_smart_defaults
    # Custom text color should override smart defaults
    render_inline(SimpleButtonComponent.new(
      title: "Custom Text", 
      background_color: "purple-600", 
      text_color: "yellow-300"
    ))
    
    assert_selector "button.bg-purple-600", text: "Custom Text"
    assert_selector "button.text-yellow-300", text: "Custom Text"
  end

  def test_is_light_background_helper_logic
    component = SimpleButtonComponent.new(title: "Test")
    
    # Light colors (50-400)
    assert component.send(:is_light_background?, "blue-50")
    assert component.send(:is_light_background?, "purple-200")
    assert component.send(:is_light_background?, "green-400")
    
    # Dark colors (500-900)
    refute component.send(:is_light_background?, "blue-500")
    refute component.send(:is_light_background?, "purple-600")
    refute component.send(:is_light_background?, "green-800")
  end
end
# Copyright 2025
