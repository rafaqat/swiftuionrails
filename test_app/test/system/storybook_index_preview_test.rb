# frozen_string_literal: true

require "application_system_test_case"

class StorybookIndexPreviewTest < ApplicationSystemTestCase
  test "storybook index shows DSL product card preview" do
    visit "/storybook/index"
    
    # Check that the page loads
    assert_selector "h1", text: "Interactive Storybook"
    
    # Find the DSL Product List card
    product_card = find("h2", text: "DSL Product List").ancestor(".bg-white")
    
    within product_card do
      # Check for the mini product preview
      assert_selector "img[alt='Basic Tee']"
      assert_text "Basic Tee"
      assert_text "Black"
      assert_text "$35"
      
      # Check that the launch button exists
      assert_selector "a", text: "Launch Interactive"
    end
    
    # Take a screenshot for visual verification
    take_screenshot
  end
  
  test "all story cards have appropriate previews" do
    visit "/storybook/index"
    
    # Check DSL Button preview
    within find("h2", text: "DSL Button").ancestor(".bg-white") do
      assert_selector "button", text: "Click Me"
    end
    
    # Check DSL Card preview  
    within find("h2", text: "DSL Card").ancestor(".bg-white") do
      assert_text "Card Title"
      assert_text "Card content goes here"
    end
    
    # Check DSL Product List preview
    within find("h2", text: "DSL Product List").ancestor(".bg-white") do
      assert_selector "img[src*='tailwindcss.com']"
      assert_text "$35"
    end
  end
end