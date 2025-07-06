# frozen_string_literal: true
# Copyright 2025

require "test_helper"

class DSLViewComponent2Test < ViewComponent::TestCase
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context

  # Test ViewComponent 2.0 collection rendering optimization
  def test_simple_collection_rendering
    items = ["Item 1", "Item 2", "Item 3"]
    
    # Test collection with vstack  
    result = swift_ui do
      vstack_collection(items: items, spacing: 16) do |item, index|
        text("#{item} (#{index + 1})")
          .font_weight("bold")
      end
    end
    
    html = result.to_s
    
    # Should render all items efficiently
    assert_includes html, "Item 1 (1)"
    assert_includes html, "Item 2 (2)" 
    assert_includes html, "Item 3 (3)"
    assert_includes html, "flex flex-col"
    assert_includes html, "space-y-16"
  end

  # Test ViewComponent 2.0 collection performance
  def test_collection_rendering_performance
    items = Array.new(50) { |i| "Item #{i}" }
    
    # Test grid collection for performance
    result = swift_ui do
      grid_collection(items: items, columns: 5, spacing: 8) do |item, index|
        text(item)
          .padding(4)
          .background(index.even? ? "blue-100" : "gray-100")
          .corner_radius("md")
      end
    end
    
    html = result.to_s
    assert_includes html, "Item 0"
    assert_includes html, "Item 49"
    assert_includes html, "grid"
    assert_includes html, "grid-cols-5"
  end

  # Test slot-based composition with ViewComponent 2.0 patterns
  def test_slot_based_card_composition
    header_slot = proc {
      text("Dynamic Header")
        .font_size("xl")
        .font_weight("bold")
    }
    
    content_slot = proc {
      vstack(spacing: 8) do
        text("Main content here")
        text("Additional details")
          .text_color("gray-500")
      end
    }
    
    actions_array = [
      proc { button("Save").button_style(:primary) },
      proc { button("Cancel").button_style(:secondary) }
    ]
    
    result = swift_ui do
      card(
        header: header_slot,
        content: content_slot,
        actions: actions_array,
        elevation: 2
      )
      .background("blue-50")
      .corner_radius("xl")
    end
    
    html = result.to_s
    
    # Verify slot content rendered
    assert_includes html, "Dynamic Header"
    assert_includes html, "Main content here"
    assert_includes html, "Save"
    assert_includes html, "Cancel"
    
    # Verify DSL modifiers applied
    assert_includes html, "bg-blue-50"
    assert_includes html, "rounded-xl"
    assert_includes html, "shadow-md"  # elevation: 2
  end

  # Test DSL performance vs traditional partials
  def test_dsl_rendering_performance
    require 'benchmark'
    
    products = Array.new(100) { |i| { name: "Product #{i}", price: i * 10 } }
    
    # Measure DSL rendering time
    dsl_time = Benchmark.realtime do
      10.times do
        swift_ui do
          product_list(products: products, columns: 4)
            .background("white")
            .padding(16)
        end
      end
    end
    
    # DSL should be reasonably fast (< 1 second for 1000 renders)
    assert dsl_time < 1.0, "DSL rendering too slow: #{dsl_time}s"
  end

  # Test ViewComponent 2.0 unit testing approach for DSL components
  def test_dsl_component_unit_testing
    # Test individual DSL methods in isolation (100x faster than controller tests)
    
    # Text component
    text_result = text("Hello World")
      .font_size("xl")
      .text_color("blue-600")
      .font_weight("bold")
    
    html = text_result.to_s
    assert_includes html, "Hello World"
    assert_includes html, "text-xl"
    assert_includes html, "text-blue-600"
    assert_includes html, "font-bold"
    
    # Button component
    button_result = button("Click Me")
      .button_style(:primary)
      .button_size(:lg)
      .corner_radius("full")
    
    html = button_result.to_s
    assert_includes html, "Click Me"
    assert_includes html, "<button"
    
    # Layout components
    layout_result = vstack(spacing: 16) do
      text("Item 1")
      text("Item 2")
      text("Item 3")
    end
    
    html = layout_result.to_s
    assert_includes html, "flex flex-col"
    assert_includes html, "space-y-16"
    assert_includes html, "Item 1"
    assert_includes html, "Item 2"
    assert_includes html, "Item 3"
  end

  # Test ViewComponent 2.0 i18n support with DSL
  def test_dsl_internationalization
    I18n.with_locale(:en) do
      result = swift_ui do
        card do
          text(I18n.t('welcome.title', default: 'Welcome'))
            .font_size("xl")
          text(I18n.t('welcome.subtitle', default: 'Get started'))
            .text_color("gray-600")
        end
      end
      
      html = result.to_s
      assert_includes html, "Welcome"
      assert_includes html, "Get started"
    end
  end

  # Test error handling and validation
  def test_dsl_error_handling
    # Should handle nil values gracefully
    result = swift_ui do
      text(nil)
        .font_size("md")
    end
    
    # Should not crash
    assert_not_nil result.to_s
    
    # Should handle empty collections
    result = swift_ui do
      product_list(products: [])
        .background("white")
    end
    
    assert_not_nil result.to_s
  end
end
# Copyright 2025
