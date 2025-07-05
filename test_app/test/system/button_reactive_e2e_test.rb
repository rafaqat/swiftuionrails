# frozen_string_literal: true

require "application_system_test_case"

class ButtonReactiveE2eTest < ApplicationSystemTestCase
  test "button component reactive storybook property changes work end-to-end" do
    puts "🧪 Testing Button Component Reactive Storybook - End-to-End Fix"
    
    visit "/storybook/show?story=simple_button_component"
    
    # Wait for page to load with Stimulus controller
    assert_selector "[data-controller='live_story']", wait: 10
    puts "✅ Storybook page loaded with live_story controller"
    
    # Check for any rendering errors first
    assert_no_page_errors
    puts "✅ No page errors detected"
    
    # Verify button component is rendered
    assert_selector "#component-preview", wait: 5
    puts "✅ Component preview container found"
    
    # Look for button element
    button_element = find("#component-preview button", wait: 5)
    puts "✅ Button element found"
    
    initial_button_text = button_element.text
    puts "📝 Initial button text: '#{initial_button_text}'"
    
    # Test 1: Button text property change
    puts "\n🧪 Test 1: Testing button text property change..."
    
    # Find the button text input control
    text_input = find("input[name='title']", wait: 5)
    original_text = text_input.value
    puts "📝 Found text input with value: '#{original_text}'"
    
    # Change the button text
    new_text = "Reactive Test Button"
    text_input.fill_in with: new_text
    text_input.send_keys(:tab)
    
    puts "⏳ Waiting for reactive update..."
    sleep 2
    
    # Check if button text updated
    updated_button = find("#component-preview button", wait: 5)
    updated_text = updated_button.text
    
    if updated_text.include?(new_text)
      puts "✅ Button text property change working - reactive update successful"
    else
      puts "❌ Button text property change FAILED"
      puts "  Expected: #{new_text}"
      puts "  Got: #{updated_text}"
      flunk "Button text reactive update not working"
    end
    
    # Test 2: Button variant property change
    puts "\n🧪 Test 2: Testing button variant property change..."
    
    variant_select = find("select[name='variant']", wait: 5)
    original_variant = variant_select.value
    puts "📝 Original variant: #{original_variant}"
    
    # Change to secondary variant
    variant_select.select("Secondary")
    sleep 2
    
    # Check for variant change in button classes
    updated_button = find("#component-preview button", wait: 5)
    button_classes = updated_button[:class]
    
    if button_classes.include?("secondary") || button_classes.include?("gray")
      puts "✅ Button variant property change working"
    else
      puts "❌ Button variant property change may not be working"
      puts "  Button classes: #{button_classes}"
    end
    
    # Test 3: Button size property change  
    puts "\n🧪 Test 3: Testing button size property change..."
    
    size_select = find("select[name='size']", wait: 5)
    original_size = size_select.value
    puts "📝 Original size: #{original_size}"
    
    # Change to large size
    size_select.select("Large")
    sleep 2
    
    # Check for size change in button classes
    updated_button = find("#component-preview button", wait: 5)
    button_classes = updated_button[:class]
    
    if button_classes.include?("lg") || button_classes.include?("large")
      puts "✅ Button size property change working"
    else
      puts "❌ Button size property change may not be working"
      puts "  Button classes: #{button_classes}"
    end
    
    # Test 4: Boolean property change (disabled)
    puts "\n🧪 Test 4: Testing boolean property change..."
    
    if page.has_selector?("input[name='disabled']")
      disabled_checkbox = find("input[name='disabled']", wait: 5)
      
      # Toggle disabled state
      disabled_checkbox.click
      sleep 2
      
      # Check if button is disabled
      updated_button = find("#component-preview button", wait: 5)
      is_disabled = updated_button[:disabled] == "true" || updated_button[:class].include?("disabled")
      
      if is_disabled
        puts "✅ Boolean property change working - button disabled"
      else
        puts "❌ Boolean property change may not be working"
      end
    else
      puts "⚠️ Disabled property not available for this button component"
    end
    
    # Test 5: Check JavaScript errors
    puts "\n🧪 Test 5: Checking for JavaScript errors..."
    debug_console_output
    
    # Verify no console errors
    logs = console_logs
    error_logs = logs.select { |log| log.level == "SEVERE" }
    
    if error_logs.any?
      puts "❌ JavaScript errors found:"
      error_logs.each { |log| puts "  - #{log.message}" }
      flunk "JavaScript errors detected during reactive testing"
    else
      puts "✅ No JavaScript errors - reactive system clean"
    end
    
    # Test 6: Rapid property changes
    puts "\n🧪 Test 6: Testing rapid property changes..."
    
    text_input = find("input[name='title']", wait: 5)
    
    # Rapid changes
    text_input.fill_in with: "Change 1"
    text_input.send_keys(:tab)
    sleep 0.5
    
    text_input.fill_in with: "Change 2"  
    text_input.send_keys(:tab)
    sleep 0.5
    
    text_input.fill_in with: "Final Button Text"
    text_input.send_keys(:tab)
    sleep 1
    
    # Verify final state
    final_button = find("#component-preview button", wait: 5)
    final_text = final_button.text
    
    if final_text.include?("Final Button Text")
      puts "✅ Rapid property changes working - reactive system stable"
    else
      puts "❌ Rapid property changes failed"
      puts "  Expected: Final Button Text"
      puts "  Got: #{final_text}"
    end
    
    puts "\n🎉 BUTTON REACTIVE STORYBOOK E2E TEST COMPLETED!"
    puts "✅ Testing button component reactive property changes"
    puts "✅ Identifying what's broken in the reactive system"
  end
  
  test "debug stimulus controller connection for button component" do
    puts "🔍 Debugging Stimulus controller for button component..."
    
    visit "/storybook/show?story=simple_button_component"
    assert_selector "[data-controller='live_story']", wait: 10
    
    # Check stimulus controller state
    stimulus_debug = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"live_story\"]');
      return {
        element_found: element !== null,
        controller_connected: element && element.hasAttribute('data-live-story-connected'),
        controller_instance: element && element.controller !== undefined,
        form_target: element && element.controller && element.controller.hasFormTarget,
        mode_value: element && element.controller && element.controller.modeValue
      };
    ")
    
    puts "📊 Stimulus Debug Info:"
    puts "  Element found: #{stimulus_debug['element_found']}"
    puts "  Controller connected: #{stimulus_debug['controller_connected']}"
    puts "  Controller instance: #{stimulus_debug['controller_instance']}"
    puts "  Form target: #{stimulus_debug['form_target']}"
    puts "  Mode value: #{stimulus_debug['mode_value']}"
    
    # Check if controlChanged method exists
    has_control_changed = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"live_story\"]');
      return element && element.controller && typeof element.controller.controlChanged === 'function';
    ")
    
    puts "  controlChanged method: #{has_control_changed}"
    
    if !has_control_changed
      puts "🚨 ISSUE: controlChanged method not available - this breaks reactivity"
    end
  end
end