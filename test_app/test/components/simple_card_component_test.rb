# Copyright 2025
require "test_helper"

class SimpleCardComponentTest < ViewComponent::TestCase
  def test_renders_with_default_props
    render_inline(SimpleCardComponent.new) do
      "Card content"
    end

    assert_selector "div.bg-white.rounded-lg"
    assert_selector "div.shadow-md"  # Default elevated variant
    assert_selector "div.p-6"  # Default medium padding
    assert_text "Card content"
  end

  def test_renders_elevated_variant
    render_inline(SimpleCardComponent.new(variant: :elevated)) do
      "Elevated card"
    end

    assert_selector "div.shadow-md"
    assert_text "Elevated card"
  end

  def test_renders_outlined_variant
    render_inline(SimpleCardComponent.new(variant: :outlined)) do
      "Outlined card"
    end

    assert_selector "div.border.border-gray-200"
    assert_text "Outlined card"
  end

  def test_renders_filled_variant
    render_inline(SimpleCardComponent.new(variant: :filled)) do
      "Filled card"
    end

    assert_selector "div.bg-gray-50"
    assert_text "Filled card"
  end

  def test_renders_with_header_slot
    component = SimpleCardComponent.new
    component.with_header do
      "Card Header"
    end

    render_inline(component) do
      "Card body"
    end

    assert_selector "div.pb-4.mb-4.border-b.border-gray-200", text: "Card Header"
    assert_text "Card body"
  end

  def test_renders_with_footer_slot
    component = SimpleCardComponent.new
    component.with_footer do
      "Card Footer"
    end

    render_inline(component) do
      "Card body"
    end

    assert_selector "div.pt-4.mt-4.border-t.border-gray-200", text: "Card Footer"
    assert_text "Card body"
  end

  def test_renders_with_all_slots
    component = SimpleCardComponent.new
    component.with_header { "Header" }
    component.with_footer { "Footer" }

    render_inline(component) do
      "Body"
    end

    assert_text "Header"
    assert_text "Body"
    assert_text "Footer"

    # Check order
    assert_match /Header.*Body.*Footer/m, page.native.to_s
  end

  def test_different_padding_sizes
    # Small padding
    render_inline(SimpleCardComponent.new(padding: :sm)) { "Small" }
    assert_selector "div.p-4"

    # Medium padding
    render_inline(SimpleCardComponent.new(padding: :md)) { "Medium" }
    assert_selector "div.p-6"

    # Large padding
    render_inline(SimpleCardComponent.new(padding: :lg)) { "Large" }
    assert_selector "div.p-8"
  end

  def test_variant_with_slots_and_padding
    # Test combining variant, padding, and slots
    component = SimpleCardComponent.new(variant: :outlined, padding: :lg)
    component.with_header { "Large Outlined Card" }
    component.with_footer { "Footer Content" }

    render_inline(component) do
      "Main content with large padding"
    end

    assert_selector "div.border.border-gray-200"
    assert_selector "div.p-8"
    assert_text "Large Outlined Card"
    assert_text "Main content with large padding"
    assert_text "Footer Content"
  end

  def test_invalid_variant_falls_back_to_default
    render_inline(SimpleCardComponent.new(variant: :invalid)) do
      "Content"
    end

    # Should fall back to elevated (default)
    assert_selector "div.shadow-md"
  end

  def test_invalid_padding_falls_back_to_default
    render_inline(SimpleCardComponent.new(padding: :invalid)) do
      "Content"
    end

    # Should fall back to md (default)
    assert_selector "div.p-6"
  end

  def test_component_without_slots
    # Test that a component without any slots defined only shows body content
    component = SimpleCardComponent.new

    render_inline(component) do
      "Only body content"
    end

    # Should not render header/footer divs when slots are not used
    assert_no_selector "div.pb-4.mb-4.border-b.border-gray-200"
    assert_no_selector "div.pt-4.mt-4.border-t.border-gray-200"
    assert_text "Only body content"
  end

  def test_html_content_in_slots
    component = SimpleCardComponent.new
    component.with_header do
      "<h2 class='text-xl font-bold'>Complex Header</h2>".html_safe
    end
    component.with_footer do
      "<div class='flex justify-between'><span>Left</span><span>Right</span></div>".html_safe
    end

    render_inline(component) do
      "<p class='text-gray-600'>Body with HTML</p>".html_safe
    end

    assert_selector "h2.text-xl.font-bold", text: "Complex Header"
    assert_selector "p.text-gray-600", text: "Body with HTML"
    assert_selector "div.flex.justify-between span", count: 2
  end

  def test_css_classes_are_properly_combined
    render_inline(SimpleCardComponent.new(variant: :filled, padding: :lg)) do
      "Content"
    end

    # Check that all classes are present
    card = page.find("div.bg-white.rounded-lg")
    assert card[:class].include?("bg-white")
    assert card[:class].include?("rounded-lg")
    assert card[:class].include?("bg-gray-50")
    assert card[:class].include?("p-8")
  end
end
# Copyright 2025
