# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class ProductLayoutVisualTest < ApplicationSystemTestCase
  test "product layout with top filters renders correctly" do
    visit "/storybook/show?story=product_layout"

    # Wait for page to load
    assert_selector "h1", text: "Product Layout"

    within "#component-preview" do
      # Check header
      assert_text "Products"
      assert_text "8 items"

      # Check filter bar exists and shows results count
      assert_selector ".bg-white.p-6.rounded-lg.shadow-sm"
      assert_text "24 Results"

      # Check filters are visible
      assert_text "Filters"
      assert_text "Price"
      assert_text "Color"
      assert_text "Category"

      # Check products are displayed
      assert_text "Basic Tee"
      assert_text "Leather Jacket"
      assert_text "$35"
      assert_text "$250"

      # Check CTA buttons
      assert_text "Add to cart", minimum: 8
    end

    # Take screenshot for visual reference
    take_screenshot
  end
end
# Copyright 2025
