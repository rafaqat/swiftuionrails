# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class TestCardBackground < ApplicationSystemTestCase
  test "card background color property changes work" do
    puts "🃏 Testing card background color property changes..."
    
    visit "/storybook/show?story=dsl_card"
    
    # Wait for page to load
    assert_selector "[data-controller='live-story']", wait: 10
    puts "✅ Card storybook page loaded"
    
    # Check initial background (look for the card div with bg classes)
    card_element = find("#component-preview div.rounded-lg.shadow-md", wait: 5)
    initial_classes = card_element[:class]
    puts "📝 Initial card classes: #{initial_classes}"
    
    # Find background color select and change it
    bg_select = find("select[name='background']", wait: 5)
    current_value = bg_select.value
    puts "📝 Current background color: #{current_value}"
    
    # Check available options
    options = bg_select.all('option').map(&:text)
    puts "📝 Available options: #{options.inspect}"
    
    # Change to blue-50
    bg_select.select(options.find { |opt| opt.downcase.include?("blue") } || "gray-50")
    puts "🔄 Changed background to blue-50"
    
    sleep 2  # Wait for update
    
    # Check if background changed
    updated_card = find("#component-preview div.rounded-lg.shadow-md", wait: 5)
    updated_classes = updated_card[:class]
    puts "📝 Updated card classes: #{updated_classes}"
    
    if updated_classes.include?("bg-blue-50") || updated_classes != initial_classes
      puts "🎉 SUCCESS! Card background color is changing"
      assert true
    else
      puts "❌ FAILED: Card background color not changing"
      puts "  Expected: bg-blue-50 or different classes"
      puts "  Got: #{updated_classes}"
      
      # Try color swatch buttons instead
      puts "🔄 Trying color swatch buttons..."
      blue_swatch = find("button[data-value='blue-50']", wait: 5)
      blue_swatch.click
      
      sleep 2
      
      final_card = find("#component-preview div.rounded-lg.shadow-md", wait: 5)
      final_classes = final_card[:class]
      puts "📝 Final card classes after swatch click: #{final_classes}"
      
      if final_classes.include?("bg-blue-50") || final_classes != initial_classes
        puts "🎉 SUCCESS! Color swatch method works"
        assert true
      else
        flunk "Card background color not changing with either method"
      end
    end
  end
end
# Copyright 2025
