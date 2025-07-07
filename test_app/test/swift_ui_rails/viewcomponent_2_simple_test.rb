# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class ViewComponent2SimpleTest < ViewComponent::TestCase
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context

  # Test basic DSL functionality
  def test_basic_dsl_elements
    result = swift_ui do
      text("Hello World")
        .font_size("xl")
        .text_color("blue-600")
        .font_weight("bold")
    end

    html = result.to_s
    assert_includes html, "Hello World"
    assert_includes html, "text-xl"
    assert_includes html, "text-blue-600"
    assert_includes html, "font-bold"
  end

  # Test layout elements
  def test_layout_elements
    result = swift_ui do
      vstack(spacing: 16) do
        text("Item 1")
        text("Item 2")
        text("Item 3")
      end
    end

    html = result.to_s
    assert_includes html, "flex flex-col"
    assert_includes html, "space-y-16"
    assert_includes html, "Item 1"
    assert_includes html, "Item 2"
    assert_includes html, "Item 3"
  end

  # Test button elements
  def test_button_elements
    result = swift_ui do
      button("Click Me")
        .button_style(:primary)
        .button_size(:lg)
    end

    html = result.to_s
    assert_includes html, "Click Me"
    assert_includes html, "<button"
  end

  # Test card elements with collection counter simulation
  def test_card_with_collection_counter
    result = swift_ui do
      card(elevation: 2) do
        vstack(spacing: 8) do
          text("Card Title")
            .font_size("lg")
            .font_weight("semibold")

          text("Card content here")
            .text_color("gray-600")

          # Simulate collection counter
          span("Badge 1")
            .background("blue-100")
            .text_color("blue-800")
            .padding_x(2)
            .padding_y(1)
            .corner_radius("full")
            .font_size("xs")
        end
      end
      .background("white")
      .corner_radius("lg")
    end

    html = result.to_s
    assert_includes html, "Card Title"
    assert_includes html, "Card content here"
    assert_includes html, "Badge 1"
    assert_includes html, "bg-white"
    assert_includes html, "rounded-lg"
    assert_includes html, "shadow-md"  # elevation: 2
  end

  # Test collection simulation with manual iteration
  def test_collection_simulation
    items = [ "Item A", "Item B", "Item C" ]

    result = swift_ui do
      vstack(spacing: 12) do
        items.each_with_index do |item, index|
          div do
            text("#{item} (#{index + 1})")
              .font_weight("medium")
              .padding(4)
              .background(index.even? ? "blue-50" : "gray-50")
              .corner_radius("md")
          end
        end
      end
    end

    html = result.to_s
    assert_includes html, "Item A (1)"
    assert_includes html, "Item B (2)"
    assert_includes html, "Item C (3)"
    assert_includes html, "bg-blue-50"
    assert_includes html, "bg-gray-50"
  end

  # Test error handling
  def test_dsl_error_handling
    # Should handle nil values gracefully
    result = swift_ui do
      text(nil)
        .font_size("md")
    end

    # Should not crash
    assert_not_nil result.to_s
  end
end
# Copyright 2025
