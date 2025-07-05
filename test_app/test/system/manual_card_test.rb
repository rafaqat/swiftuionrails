# frozen_string_literal: true

require "application_system_test_case"

class ManualCardTest < ApplicationSystemTestCase
  test "manually test card background color changing step by step" do
    puts "🔍 Manual testing of card background color..."
    
    visit "/storybook/show?story=card_component"
    sleep 2
    
    puts "✅ Page loaded"
    
    # Take a screenshot to see current state
    page.save_screenshot("card_initial.png")
    puts "📸 Screenshot saved: card_initial.png"
    
    # Check what HTML is actually rendered
    component_html = page.find("#component-preview")['innerHTML']
    puts "📄 Current component HTML:"
    puts component_html[0..500] + "..." if component_html.length > 500
    
    # Check current background control value
    bg_select = find("select[name='background_color']")
    puts "📝 Current background color control: #{bg_select.value}"
    
    # List all available options
    options = bg_select.all("option").map(&:text)
    puts "📋 Available options: #{options.join(', ')}"
    
    # Try changing to each color and see what happens
    ["Gray-50", "Blue-50", "Green-50"].each do |color|
      puts "\n🔄 Testing #{color}..."
      
      # Change to this color
      bg_select.select(color)
      sleep 1
      
      # Check if anything changed
      new_html = page.find("#component-preview")['innerHTML']
      if new_html != component_html
        puts "✅ HTML changed when selecting #{color}"
        puts "🔍 New HTML snippet: #{new_html[0..200]}..."
      else
        puts "❌ HTML did not change when selecting #{color}"
      end
      
      # Check console for any errors
      logs = console_logs.select { |log| log.level == "SEVERE" }
      if logs.any?
        puts "❌ JavaScript errors:"
        logs.each { |log| puts "  - #{log.message}" }
      end
      
      component_html = new_html
    end
    
    # Try clicking a color swatch
    puts "\n🎨 Testing color swatch buttons..."
    blue_swatch = find("button[data-value='blue-50']")
    puts "📝 Found blue swatch: #{blue_swatch[:class]}"
    blue_swatch.click
    sleep 1
    
    final_html = page.find("#component-preview")['innerHTML']
    if final_html != component_html
      puts "✅ HTML changed when clicking blue swatch"
      puts "🔍 Final HTML snippet: #{final_html[0..200]}..."
    else
      puts "❌ HTML did not change when clicking blue swatch"
    end
    
    # Take final screenshot
    page.save_screenshot("card_final.png")
    puts "📸 Final screenshot saved: card_final.png"
  end
end
# Copyright 2025
