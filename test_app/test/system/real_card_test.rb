# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class RealCardTest < ApplicationSystemTestCase
  test "real world test of card background color" do
    puts "🔍 Real world test of card background color..."
    
    visit "/storybook/show?story=card_component"
    sleep 3
    
    # Take a screenshot first
    page.save_screenshot("before_change.png")
    puts "📸 Before screenshot: before_change.png"
    
    # Find the card element and check its current style
    puts "\n🎯 FINDING THE ACTUAL CARD ELEMENT:"
    card_selector = "#component-preview div.rounded-lg.shadow"
    
    if page.has_selector?(card_selector)
      card = find(card_selector)
      puts "✅ Found card with selector: #{card_selector}"
      puts "📝 Current classes: #{card[:class]}"
      puts "📝 Current computed style: #{page.evaluate_script("getComputedStyle(document.querySelector('#{card_selector}')).backgroundColor")}"
    else
      puts "❌ Card not found with selector: #{card_selector}"
      puts "Available elements in preview:"
      elements = page.all("#component-preview *")
      elements.each_with_index do |elem, i|
        puts "  #{i+1}. #{elem.tag_name}: #{elem[:class]}"
      end
      return
    end
    
    # Check the background color dropdown
    puts "\n🎛️ TESTING DROPDOWN:"
    bg_select = find("select[name='background_color']")
    puts "Current dropdown value: #{bg_select.value}"
    puts "Available options: #{bg_select.all('option').map(&:text).join(', ')}"
    
    # Check if the form has proper Stimulus attributes
    form = find("form[data-live-story-target='form']")
    puts "Form has Stimulus target: #{form.present?}"
    
    # Test changing the background
    puts "\n🔄 CHANGING BACKGROUND TO BLUE-50:"
    bg_select.select("Blue-50")
    puts "Selected Blue-50"
    
    # Wait and check what happened
    sleep 3
    
    # Check if card element still exists and what changed
    if page.has_selector?(card_selector)
      updated_card = find(card_selector)
      puts "✅ Card still found after change"
      puts "📝 New classes: #{updated_card[:class]}"
      puts "📝 New computed style: #{page.evaluate_script("getComputedStyle(document.querySelector('#{card_selector}')).backgroundColor")}"
      
      # Check if dropdown value changed
      puts "📝 Dropdown value after change: #{bg_select.value}"
      
      # Visual comparison
      if updated_card[:class] != card[:class]
        puts "🎉 Classes changed! Background should be working"
      else
        puts "❌ Classes did not change"
      end
    else
      puts "❌ Card disappeared after change"
    end
    
    # Take after screenshot
    page.save_screenshot("after_change.png")
    puts "📸 After screenshot: after_change.png"
    
    # Test color swatch click as well
    puts "\n🎨 TESTING COLOR SWATCH CLICK:"
    
    if page.has_selector?("button[data-value='green-50']")
      green_swatch = find("button[data-value='green-50']")
      puts "Found green swatch button"
      green_swatch.click
      sleep 2
      
      final_card = find(card_selector)
      puts "📝 Classes after swatch click: #{final_card[:class]}"
      puts "📝 Computed style after swatch: #{page.evaluate_script("getComputedStyle(document.querySelector('#{card_selector}')).backgroundColor")}"
      
      page.save_screenshot("after_swatch.png")
      puts "📸 After swatch screenshot: after_swatch.png"
    else
      puts "❌ Green swatch button not found"
    end
    
    # Check for JavaScript errors
    puts "\n🐛 JAVASCRIPT ERRORS:"
    logs = console_logs.select { |log| log.level == "SEVERE" }
    if logs.any?
      logs.each { |log| puts "  ERROR: #{log.message}" }
    else
      puts "  No JavaScript errors found"
    end
  end
end
# Copyright 2025
