# frozen_string_literal: true

require "application_system_test_case"

class DebugTitleJsTest < ApplicationSystemTestCase
  test "debug javascript execution step by step" do
    puts "🔍 Debugging JavaScript execution..."
    
    visit "/storybook/show?story=card_component"
    
    # Wait for page to load
    assert_selector "[data-controller='live_story']", wait: 5
    
    # Check if controller is actually connected in JavaScript
    controller_connected = page.evaluate_script("
      var element = document.querySelector('[data-controller=\"live_story\"]');
      return element && element.classList.contains('stimulus-connected');
    ")
    
    puts "Controller connected in DOM: #{controller_connected}"
    
    # Get controller instance
    controller_exists = page.evaluate_script("""
      const element = document.querySelector('[data-controller=\"live_story\"]');
      return element && element.controller !== undefined;
    """)
    
    puts "Controller instance exists: #{controller_exists}"
    
    # Check if modeValue is set correctly  
    mode_value = page.evaluate_script("""
      const element = document.querySelector('[data-controller=\"live_story\"]');
      return element && element.controller ? element.controller.modeValue : null;
    """)
    
    puts "Mode value: #{mode_value}"
    
    # Check if formTarget exists
    form_target_exists = page.evaluate_script("""
      const element = document.querySelector('[data-controller=\"live_story\"]');
      return element && element.controller ? element.controller.hasFormTarget : null;
    """)
    
    puts "Form target exists: #{form_target_exists}"
    
    # Find title input and check if it has event listeners
    title_input_setup = page.evaluate_script("""
      const input = document.querySelector('input[name=\"title\"]');
      if (!input) return 'Input not found';
      
      // Manually trigger controlChanged to see if method exists
      const element = document.querySelector('[data-controller=\"live_story\"]');
      if (element && element.controller && element.controller.controlChanged) {
        console.log('✅ controlChanged method exists');
        return 'controlChanged method exists';
      } else {
        return 'controlChanged method missing';
      }
    """)
    
    puts "Title input setup: #{title_input_setup}"
    
    # Try to trigger the controlChanged method manually
    manual_trigger_result = page.evaluate_script("""
      const input = document.querySelector('input[name=\"title\"]');
      const element = document.querySelector('[data-controller=\"live_story\"]');
      
      if (input && element && element.controller) {
        // Change the input value
        input.value = 'Manual Test Title';
        
        // Create and dispatch input event
        const event = new Event('input', { bubbles: true });
        input.dispatchEvent(event);
        
        return 'Event dispatched successfully';
      }
      return 'Failed to dispatch event';
    """)
    
    puts "Manual trigger result: #{manual_trigger_result}"
    
    # Wait a moment and check if anything changed
    sleep 1
    
    # Check the actual card title
    card_title = find("#component-preview .text-lg", wait: 2).text rescue "Not found"
    puts "Card title after manual trigger: '#{card_title}'"
    
    assert true # This test is for debugging, not assertions
  end
end