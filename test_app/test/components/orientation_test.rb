# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class OrientationTest < ViewComponent::TestCase
  # Test component with orientation support - use a clean base to avoid validation contamination
  class TestOrientationComponent < TestComponentBase
    prop :title, type: String, default: "Test"

    swift_ui do
      vstack do
        text(title)
        
        # Conditional rendering based on orientation
        if_portrait do
          text("Portrait Mode").text_color("blue-500")
        end
        
        if_landscape do
          text("Landscape Mode").text_color("green-500")
        end
        
        # Adaptive layout
        orientation_stack(spacing: 16) do
          button("Button 1")
          button("Button 2")
        end
        
        # Size class information
        div do
          text("H: #{horizontal_size_class}, V: #{vertical_size_class}")
            .text_sm
            .text_color("gray-500")
        end
      end
    end
  end

  test "default orientation is portrait" do
    component = TestOrientationComponent.new
    assert_equal :portrait, component.orientation
  end

  test "can initialize with landscape orientation" do
    component = TestOrientationComponent.new(orientation: :landscape)
    assert_equal :landscape, component.orientation
  end

  test "portrait mode shows portrait content" do
    render_inline(TestOrientationComponent.new(orientation: :portrait))
    assert_text "Portrait Mode"
    assert_no_text "Landscape Mode"
  end

  test "landscape mode shows landscape content" do
    render_inline(TestOrientationComponent.new(orientation: :landscape))
    assert_text "Landscape Mode"
    assert_no_text "Portrait Mode"
  end

  test "size classes work correctly" do
    # Portrait mode
    component = TestOrientationComponent.new(orientation: :portrait)
    assert_equal :compact, component.horizontal_size_class
    assert_equal :regular, component.vertical_size_class
    assert component.compact_width?
    assert component.regular_height?

    # Landscape mode
    component = TestOrientationComponent.new(orientation: :landscape)
    assert_equal :regular, component.horizontal_size_class
    assert_equal :compact, component.vertical_size_class
    assert component.regular_width?
    assert component.compact_height?
  end

  test "orientation_stack uses vstack in portrait" do
    render_inline(TestOrientationComponent.new(orientation: :portrait))
    # In portrait, orientation_stack should create a vstack (flex-col)
    assert_selector "div.flex.flex-col"
  end

  test "orientation_stack uses hstack in landscape" do
    render_inline(TestOrientationComponent.new(orientation: :landscape))
    # In landscape, orientation_stack should create an hstack (flex-row)
    assert_selector "div.flex.flex-row"
  end
end
# Copyright 2025