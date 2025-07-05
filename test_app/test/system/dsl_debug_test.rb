# frozen_string_literal: true

require "application_system_test_case"

class DslDebugTest < ApplicationSystemTestCase
  test "debug why product data isn't rendering in DSL" do
    puts "🔍 Debugging DSL product data rendering..."
    
    visit "/storybook/show?story=product_list_component"
    assert_selector "[data-controller='live_story']", wait: 10
    
    puts "✅ Page loaded, checking what's actually rendered..."
    
    # Check what's in the component preview
    preview_content = find("#component-preview", wait: 5).text
    puts "\n📄 Component Preview Content:"
    puts preview_content
    
    # Check the raw HTML to see what DSL generated
    preview_html = find("#component-preview", wait: 5)[:innerHTML]
    puts "\n🔍 Component Preview HTML:"
    puts preview_html
    
    # Look for specific DSL elements
    puts "\n🔍 Checking for specific DSL elements..."
    
    # Check for title (this should work)
    if page.has_text?("Customers also purchased")
      puts "✅ Title found - text() DSL working"
    else
      puts "❌ Title not found - text() DSL issue"
    end
    
    # Check for grid structure
    grid_elements = all("[class*='grid']")
    puts "✅ Found #{grid_elements.count} grid elements - grid() DSL working"
    
    # Check for any card elements
    card_elements = all("[class*='card'], [class*='bg-white'], [class*='shadow']")
    puts "✅ Found #{card_elements.count} potential card elements"
    
    # Check for any image elements
    image_elements = all("img")
    puts "✅ Found #{image_elements.count} image elements - image() DSL"
    
    # Check for product names specifically
    product_names = ["Basic Tee", "Premium Hoodie", "Classic Jeans", "Summer Dress"]
    found_products = []
    
    product_names.each do |name|
      if page.has_text?(name)
        found_products << name
        puts "✅ Found product: #{name}"
      else
        puts "❌ Missing product: #{name}"
      end
    end
    
    puts "\n📊 Summary:"
    puts "  - Products found: #{found_products.count}/#{product_names.count}"
    puts "  - Grid elements: #{grid_elements.count}"
    puts "  - Card elements: #{card_elements.count}"
    puts "  - Image elements: #{image_elements.count}"
    
    if found_products.empty?
      puts "\n🚨 ISSUE: No product data is rendering in the DSL"
      puts "The grid and title work, but the product iteration isn't working"
      
      # Check for any error indicators
      if page.has_text?("Error")
        puts "❌ Found error text in page"
      end
      
      if page.has_css?(".text-red-600")
        puts "❌ Found error styling in page"
      end
    else
      puts "\n✅ DSL product rendering is working!"
    end
  end
end
# Copyright 2025
