# frozen_string_literal: true

require "application_system_test_case"

class TestReactiveFix < ApplicationSystemTestCase
  test "reactive property changes work after stimulus fix" do
    puts "🔧 Testing if reactive property changes work after Stimulus fix..."
    
    visit "/storybook/show?story=simple_button_component"
    
    # Wait for element with correct controller
    assert_selector "[data-controller='live-story']", wait: 10
    puts "✅ Page loaded with live-story controller"
    
    # Check if button is rendered
    assert_selector "#component-preview button", wait: 5
    initial_button = find("#component-preview button", match: :first)
    initial_text = initial_button.text
    puts "📝 Initial button text: '#{initial_text}'"
    
    # Find title input and change it
    title_input = find("input[name='title']", wait: 5)
    puts "📝 Found title input with value: '#{title_input.value}'"
    
    # Change the title
    new_title = "REACTIVE TEST WORKS"
    title_input.fill_in with: new_title
    title_input.send_keys(:tab)
    
    puts "⏳ Waiting for reactive update..."
    sleep 3
    
    # Check if button text changed
    updated_button = find("#component-preview button", match: :first, wait: 5)
    updated_text = updated_button.text
    
    puts "📝 Updated button text: '#{updated_text}'"
    
    if updated_text.include?(new_title)
      puts "🎉 SUCCESS! Reactive property changes are working!"
      assert true
    else
      puts "❌ FAILED: Button text did not update"
      puts "  Expected text to include: '#{new_title}'"
      puts "  Actual text: '#{updated_text}'"
      
      # Debug console logs
      logs = console_logs
      error_logs = logs.select { |log| log.level == "SEVERE" }
      if error_logs.any?
        puts "❌ JavaScript errors found:"
        error_logs.each { |log| puts "  - #{log.message}" }
      end
      
      flunk "Reactive updates not working"
    end
  end
end