# frozen_string_literal: true

require "application_system_test_case"

class ProductLayoutFlexTest < ApplicationSystemTestCase
  test "product layout renders with flexible grid and filters" do
    visit "/storybook/show?story=product_layout"
    
    # Check page loads
    assert_selector "h1", text: "Product Layout"
    
    # Check component renders
    within "#component-preview" do
      # Header section
      assert_text "Products"
      assert_text "8 items"
      
      # Filters visible
      assert_text "Filters"
      assert_text "Clear all"
      
      # Product cards exist
      assert_text "Basic Tee"
      assert_text "Nomad Tumbler"
      assert_text "Leather Jacket"
      assert_text "$35"
      assert_text "$250"
    end
    
    take_screenshot
  end
end