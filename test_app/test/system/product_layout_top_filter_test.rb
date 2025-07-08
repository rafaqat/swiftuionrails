# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class ProductLayoutTopFilterTest < ApplicationSystemTestCase
  test "product layout shows filters at top by default" do
    visit "/storybook/show?story=product_layout"

    # Check page loads
    assert_selector "h1", text: "Product Layout"

    # Check that filters are at the top (not in sidebar)
    within "#component-preview" do
      # Should see the horizontal filter bar
      assert_selector ".bg-white.p-4.rounded-lg.shadow-sm", visible: true

      # Should see dropdown filters
      assert_selector "select option[value='all_colors']", text: "All Colors", visible: false
      assert_selector "select option[value='all_categories']", text: "All Categories", visible: false
      assert_selector "select option[value='any_price']", text: "Any Price", visible: false

      # Should NOT see sidebar filter text
      assert_no_text "Clear all"
      assert_no_text "Under $50"
      assert_no_selector "div", text: "Filters" # The "Filters" header only appears in sidebar

      # Products should be below filters
      assert_text "Products"
      assert_text "8 items"

      # Product grid should be full width (no sidebar)
      assert_selector ".grid", visible: true
      assert_text "Basic Tee"
      assert_text "$35"
    end

    take_screenshot
  end

  test "can switch between top and sidebar filters" do
    visit "/storybook/show?story=product_layout"

    # Start with top filters (default)
    within "#component-preview" do
      assert_text "All Colors"
      assert_no_text "Clear all"
    end

    # Switch to sidebar
    select "sidebar", from: "Filter position"
    sleep 0.5

    within "#component-preview" do
      # Sidebar filters should appear
      assert_text "Filters"
      assert_text "Clear all"
      assert_text "Under $50"

      # Top filter bar should be gone
      assert_no_text "All Colors"
    end

    # Switch back to top
    select "top", from: "Filter position"
    sleep 0.5

    within "#component-preview" do
      assert_text "All Colors"
      assert_no_text "Clear all"
    end

    take_screenshot
  end
end
# Copyright 2025
