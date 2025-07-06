# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class StorybookProductPreviewTest < ApplicationSystemTestCase
  test "storybook index shows DSL product list preview with image and details" do
    visit "/storybook/index"
    
    # Check that the page loads
    assert_selector "h1", text: "Interactive Storybook"
    
    # Find the DSL Product List card
    product_card = find("h2", text: "DSL Product List").ancestor(".bg-white")
    
    within product_card do
      # Check for the mini product preview with scaled container
      assert_selector ".scale-75.-m-8", visible: true
      
      # Check for the product image
      assert_selector "img[src='https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg']"
      assert_selector "img[alt='Basic Tee']"
      
      # Check for product details
      assert_selector "h3", text: "Basic Tee"
      assert_selector "p", text: "Black"
      assert_selector "p", text: "$35"
      
      # Check that the launch button exists
      assert_selector "a", text: "Launch Interactive"
    end
    
    # Take a screenshot for visual verification
    take_screenshot
  end
  
  test "product layout renders with DSL content" do
    visit "/storybook/show?story=product_layout"
    
    # Wait for the page to load
    assert_selector "h1", text: "Product Layout"
    
    # Check that the live preview shows the product
    within "#component-preview" do
      # Check for product image
      assert_selector "img[src='https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg']"
      
      # Check for product text content
      assert_text "Basic Tee"
      assert_text "Black"
      assert_text "$35"
    end
    
    # Check interactive controls exist
    assert_selector "input#product_name[value='Basic Tee']"
    assert_selector "input#variant[value='Black']"
    assert_selector "input#price[value='35']"
    
    # Take a screenshot
    take_screenshot
  end
  
  test "product layout interactive controls work" do
    visit "/storybook/show?story=product_layout"
    
    # Change product name
    fill_in "Product name", with: "Premium Shirt"
    
    # Wait for preview to update
    within "#component-preview" do
      assert_text "Premium Shirt"
    end
    
    # Change variant
    fill_in "Variant", with: "Navy Blue"
    
    within "#component-preview" do
      assert_text "Navy Blue"
    end
    
    # Change price
    fill_in "Price", with: "99"
    
    within "#component-preview" do
      assert_text "$99"
    end
    
    # Verify the image is still present after updates
    assert_selector "img[src='https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg']"
    
    take_screenshot
  end
end
# Copyright 2025
