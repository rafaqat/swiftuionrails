# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class StimulusQuickTest < ApplicationSystemTestCase
  test "stimulus controller loads and connects properly" do
    puts "🔧 Quick test - checking if Stimulus controller loads..."
    
    visit "/storybook/show?story=simple_button_component"
    
    # Wait for page to load
    assert_selector "[data-controller='live-story']", wait: 10
    puts "✅ Page loaded with live-story controller"
    
    # Check if controller connected
    connected = page.evaluate_script("
      var element = document.querySelector('[data-controller=\"live-story\"]');
      return element && element.hasAttribute('data-live-story-connected');
    ")
    
    puts "Controller connected: #{connected}"
    
    # Check console for errors
    logs = console_logs
    error_logs = logs.select { |log| log.level == "SEVERE" }
    
    if error_logs.any?
      puts "❌ JavaScript errors found:"
      error_logs.each { |log| puts "  - #{log.message}" }
    else
      puts "✅ No JavaScript errors"
    end
    
    # Check if controlChanged method exists
    has_method = page.evaluate_script("
      var element = document.querySelector('[data-controller=\"live-story\"]');
      return element && element.controller && typeof element.controller.controlChanged === 'function';
    ")
    
    puts "controlChanged method available: #{has_method}"
    
    assert connected, "Controller should be connected"
    assert has_method, "controlChanged method should be available"
  end
end
# Copyright 2025
