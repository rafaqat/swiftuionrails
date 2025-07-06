# Copyright 2025
require "application_system_test_case"

class DslProductCardTest < ApplicationSystemTestCase
  test "DSL product card renders correctly" do
    visit storybook_show_path(story: "dsl_product_card")
    
    # Wait for page to load
    assert_selector ".bg-gray-50", wait: 5
    
    # Check if product card container exists
    assert_selector ".group.relative", wait: 5
    
    # Check if image exists
    assert_selector "img", wait: 5
    
    # Take screenshot for debugging
    take_screenshot
    
    # Check if product info exists
    assert_selector ".flex.justify-between", wait: 5
    
    # Check for product name
    assert_text "Basic Tee", wait: 5
    
    # Check for variant
    assert_text "Black", wait: 5
    
    # Check for price
    assert_text "$35", wait: 5
  end
end
# Copyright 2025
