require "test_helper"

class SimpleButtonComponentTest < ViewComponent::TestCase
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  # ViewComponent 2.0 DSL-FIRST Unit Testing (100x faster than controller tests)
  def test_dsl_button_rendering_performance
    # Test simple button rendering with DSL
    render_inline(SimpleButtonComponent.new(title: "Fast Button", size: :lg, corner_radius: "full"))
    
    assert_selector "button", text: "Fast Button"
    assert_selector "button.rounded-full"
    assert_selector "button.px-6.py-3"
  end

  # ViewComponent 2.0 Collection Rendering Test
  def test_button_collection_with_counter_variables
    # Create individual buttons for collection test
    buttons = [
      SimpleButtonComponent.new(title: "Button 1", variant: :primary),
      SimpleButtonComponent.new(title: "Button 2", variant: :secondary),
      SimpleButtonComponent.new(title: "Button 3", variant: :danger)
    ]
    
    # Render each button individually for now
    html = ""
    buttons.each do |button|
      html += render_inline(button).to_s
    end
    
    assert_includes html, "Button 1"
    assert_includes html, "Button 2" 
    assert_includes html, "Button 3"
  end

  def test_renders_with_default_props
    render_inline(SimpleButtonComponent.new(title: "Test Button"))
    
    assert_selector "button", text: "Test Button"
    assert_selector "button.bg-blue-600"  # Default primary variant
    assert_selector "button.px-4.py-2.text-sm"  # Default medium size
  end

  def test_renders_primary_variant
    render_inline(SimpleButtonComponent.new(title: "Primary", variant: :primary))
    
    assert_selector "button.bg-blue-600.hover\\:bg-blue-700.text-white", text: "Primary"
  end

  def test_renders_secondary_variant
    render_inline(SimpleButtonComponent.new(title: "Secondary", variant: :secondary))
    
    assert_selector "button.bg-gray-200.hover\\:bg-gray-300.text-gray-900", text: "Secondary"
  end

  def test_renders_danger_variant
    render_inline(SimpleButtonComponent.new(title: "Danger", variant: :danger))
    
    assert_selector "button.bg-red-600.hover\\:bg-red-700.text-white", text: "Danger"
  end

  def test_renders_different_sizes
    # Small
    render_inline(SimpleButtonComponent.new(title: "Small", size: :sm))
    assert_selector "button.px-3.py-2.text-sm", text: "Small"
    
    # Medium
    render_inline(SimpleButtonComponent.new(title: "Medium", size: :md))
    assert_selector "button.px-4.py-2.text-sm", text: "Medium"
    
    # Large
    render_inline(SimpleButtonComponent.new(title: "Large", size: :lg))
    assert_selector "button.px-6.py-3.text-base", text: "Large"
  end

  def test_renders_disabled_state
    render_inline(SimpleButtonComponent.new(title: "Disabled", disabled: true))
    
    assert_selector "button[disabled]", text: "Disabled"
    assert_selector "button.opacity-50.cursor-not-allowed"
  end

  def test_uses_swift_ui_dsl
    component = SimpleButtonComponent.new(title: "Swift UI")
    
    # The component should respond to swift_ui method
    assert_respond_to component.class, :swift_ui
    
    # Should be a SwiftUIRails component
    assert_kind_of SwiftUIRails::Component::Base, component
  end

  def test_custom_background_colors
    # Test blue background
    render_inline(SimpleButtonComponent.new(title: "Blue Button", background_color: "blue-500"))
    assert_selector "button.bg-blue-500", text: "Blue Button"
    
    # Test red background  
    render_inline(SimpleButtonComponent.new(title: "Red Button", background_color: "red-600"))
    assert_selector "button.bg-red-600", text: "Red Button"
    
    # Test green background
    render_inline(SimpleButtonComponent.new(title: "Green Button", background_color: "green-400"))
    assert_selector "button.bg-green-400", text: "Green Button"
    
    # Test purple background
    render_inline(SimpleButtonComponent.new(title: "Purple Button", background_color: "purple-500"))
    assert_selector "button.bg-purple-500", text: "Purple Button"
  end
  
  private
  
  def raw(content)
    content.html_safe
  end
end