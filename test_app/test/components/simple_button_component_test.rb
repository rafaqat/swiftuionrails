require "test_helper"

class SimpleButtonComponentTest < ViewComponent::TestCase
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
    assert_selector "button.px-4.py-2.text-base", text: "Large"
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
end