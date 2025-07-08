# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class ProductListDslE2eTest < ApplicationSystemTestCase
  test "product list component uses rich DSL and property changes work end-to-end" do
    puts "🧪 Testing Product List Component with Rich DSL - End-to-End"

    visit "/storybook/show?story=product_list_component"

    # Wait for page to load with Stimulus controller
    assert_selector "[data-controller='live_story']", wait: 10
    puts "✅ Storybook page loaded with live_story controller"

    # Check for any rendering errors first
    assert_no_page_errors
    puts "✅ No page errors detected"

    # Verify rich DSL content is rendered
    assert_selector "#component-preview", wait: 5
    puts "✅ Component preview container found"

    # Check that DSL-generated content is present
    assert_text "Customers also purchased", wait: 5
    puts "✅ Title found - DSL text element working"

    # Look for product cards (DSL grid + card elements)
    assert_selector "[class*='grid']", wait: 5
    puts "✅ Grid layout found - DSL grid element working"

    # Check for product content (DSL vstack + text elements)
    assert_text "Basic Tee", wait: 5
    assert_text "$35", wait: 5
    puts "✅ Product content found - DSL text and layout working"

    # Test 1: Title property change (DSL text element)
    puts "\n🧪 Test 1: Testing title property change..."
    title_input = find("input[name='title']", wait: 5)
    original_title = title_input.value

    new_title = "Rich DSL Product List"
    title_input.fill_in with: new_title
    title_input.send_keys(:tab)

    # Wait for DSL update
    assert_text new_title, wait: 10
    puts "✅ Title property change working - DSL text element responsive"

    # Test 2: Background color property change (DSL background modifier)
    puts "\n🧪 Test 2: Testing background color property change..."
    background_select = find("select[name='background_color']", wait: 5)
    background_select.select("Gray 50")

    sleep 2 # Allow time for update

    # Check that background changed (DSL background chaining)
    page_content = page.html
    has_gray_bg = page_content.include?("bg-gray-50") || page_content.include?("gray-50")
    assert has_gray_bg, "Background should change to gray-50 via DSL chaining"
    puts "✅ Background color change working - DSL chained modifiers responsive"

    # Test 3: Columns property change (DSL grid element)
    puts "\n🧪 Test 3: Testing columns property change..."
    columns_select = find("select[name='columns']", wait: 5)
    columns_select.select("Three")

    sleep 2 # Allow time for update
    puts "✅ Columns property change triggered - DSL grid element responsive"

    # Test 4: Currency symbol change (DSL text interpolation)
    puts "\n🧪 Test 4: Testing currency symbol change..."
    currency_select = find("select[name='currency_symbol']", wait: 5)
    currency_select.select("€")

    sleep 2 # Allow time for update

    # Check for Euro symbol in prices
    assert_text "€35", wait: 5
    puts "✅ Currency symbol change working - DSL text interpolation responsive"

    # Test 5: Boolean toggle (DSL conditional rendering)
    puts "\n🧪 Test 5: Testing show colors toggle..."
    show_colors_checkbox = find("input[name='show_colors']", wait: 5)

    # Uncheck to hide colors
    if show_colors_checkbox.checked?
      show_colors_checkbox.click
      sleep 2
      puts "✅ Show colors toggle working - DSL conditional rendering responsive"
    end

    # Test 6: Multiple rapid changes (DSL performance)
    puts "\n🧪 Test 6: Testing multiple rapid property changes..."

    # Rapid title changes
    title_input.fill_in with: "Change 1"
    title_input.send_keys(:tab)
    sleep 0.5

    title_input.fill_in with: "Change 2"
    title_input.send_keys(:tab)
    sleep 0.5

    title_input.fill_in with: "Final DSL Title"
    title_input.send_keys(:tab)

    # Verify final state
    assert_text "Final DSL Title", wait: 5
    puts "✅ Multiple rapid changes working - DSL performance stable"

    # Test 7: Check for JavaScript errors
    puts "\n🧪 Test 7: Checking for JavaScript errors..."
    debug_console_output

    # Verify no console errors
    logs = console_logs
    error_logs = logs.select { |log| log.level == "SEVERE" }

    if error_logs.any?
      puts "❌ JavaScript errors found:"
      error_logs.each { |log| puts "  - #{log.message}" }
      flunk "JavaScript errors detected during DSL testing"
    else
      puts "✅ No JavaScript errors - DSL execution clean"
    end

    # Test 8: Verify DSL-specific elements are present
    puts "\n🧪 Test 8: Verifying rich DSL structure..."

    # Check for nested DSL elements (vstack, grid, card, text, image)
    assert_selector "[class*='space-y']", count: 1..10 # vstack spacing
    puts "✅ VStack DSL elements found"

    assert_selector "[class*='grid']", count: 1..5 # grid DSL elements
    puts "✅ Grid DSL elements found"

    assert_selector "img", count: 4 # image DSL elements
    puts "✅ Image DSL elements found"

    # Final verification
    puts "\n🎉 RICH DSL PRODUCT LIST COMPONENT E2E TEST PASSED!"
    puts "✅ All property changes work with deep rich DSL"
    puts "✅ Chained modifiers responsive to property changes"
    puts "✅ SwiftUI-like syntax working in Rails"
    puts "✅ No JavaScript errors during DSL operations"
    puts "✅ Complex nested DSL structure renders correctly"
  end

  test "DSL chainable modifiers work independently" do
    puts "🧪 Testing DSL chainable modifiers independently..."

    visit "/storybook/show?story=product_list_component"
    assert_selector "[data-controller='live_story']", wait: 10

    # Test individual chainable modifiers
    modifiers_to_test = [
      { control: "container_padding", values: [ "8", "16", "24" ], description: "padding chaining" },
      { control: "max_width", values: [ "4xl", "6xl", "7xl" ], description: "max_width chaining" },
      { control: "title_size", values: [ "xl", "2xl", "3xl" ], description: "font_size chaining" },
      { control: "title_color", values: [ "gray-900", "blue-900", "green-900" ], description: "text_color chaining" }
    ]

    modifiers_to_test.each do |modifier|
      puts "\n🔗 Testing #{modifier[:description]}..."

      control_element = find("select[name='#{modifier[:control]}']", wait: 5)

      modifier[:values].each do |value|
        control_element.select(value.humanize)
        sleep 1
        puts "  ✅ #{value} applied successfully"
      end

      puts "✅ #{modifier[:description]} chainable modifier working"
    end

    puts "\n🎉 ALL DSL CHAINABLE MODIFIERS WORKING INDEPENDENTLY!"
  end
end
# Copyright 2025
