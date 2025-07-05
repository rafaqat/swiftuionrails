# frozen_string_literal: true

require "application_system_test_case"

class StimulusFixTest < ApplicationSystemTestCase
  test "debug and fix stimulus controller registration" do
    puts "🔧 Debugging and fixing Stimulus controller registration..."
    
    visit "/storybook/show?story=simple_button_component"
    
    # Wait for page to load
    sleep 3
    
    # Check if Stimulus is loaded at all
    stimulus_loaded = page.evaluate_script("typeof window.Stimulus !== 'undefined'")
    puts "Stimulus loaded: #{stimulus_loaded}"
    
    if stimulus_loaded
      # Check registered controllers
      registered_controllers = page.evaluate_script("Object.keys(window.Stimulus.router.controllersByIdentifier)")
      puts "Registered controllers: #{registered_controllers}"
      
      # Check if live_story is registered
      has_live_story = page.evaluate_script("'live_story' in window.Stimulus.router.controllersByIdentifier")
      puts "live_story registered: #{has_live_story}"
      
      # Check if element exists with controller
      element_exists = page.evaluate_script("document.querySelector('[data-controller=\"live_story\"]') !== null")
      puts "Element with live_story controller exists: #{element_exists}"
      
      if element_exists && !has_live_story
        puts "🚨 ISSUE: Element exists but controller not registered"
        puts "This suggests the live_story_controller.js file isn't being loaded"
      elsif !element_exists
        puts "🚨 ISSUE: No element with data-controller='live_story' found"
      end
    else
      puts "🚨 CRITICAL: Stimulus not loaded at all"
    end
    
    # Check JavaScript errors
    logs = console_logs
    error_logs = logs.select { |log| log.level == "SEVERE" }
    
    if error_logs.any?
      puts "\n❌ JavaScript errors found:"
      error_logs.each { |log| puts "  - #{log.message}" }
    end
    
    # Manual controller registration test
    if stimulus_loaded
      begin
        manual_registration = page.evaluate_script("
          // Try to manually register the controller
          try {
            window.Stimulus.register('test_controller', class extends window.Stimulus.Controller {
              connect() {
                console.log('Test controller connected successfully');
              }
            });
            return 'success';
          } catch(e) {
            return 'error: ' + e.message;
          }
        ")
        puts "Manual controller registration: #{manual_registration}"
      rescue => e
        puts "Manual registration failed: #{e.message}"
      end
    end
  end
  
  test "check controller file exists and loads" do
    puts "📁 Checking if controller file exists and loads..."
    
    # Check if the controller file exists
    controller_path = Rails.root.join("app/javascript/controllers/live_story_controller.js")
    puts "Controller file exists: #{File.exist?(controller_path)}"
    
    if File.exist?(controller_path)
      # Read the file content
      content = File.read(controller_path)
      puts "Controller file size: #{content.length} characters"
      
      # Check for syntax issues
      if content.include?("export default class extends Controller")
        puts "✅ Controller export syntax looks correct"
      else
        puts "❌ Controller export syntax issue"
      end
      
      if content.include?("static targets")
        puts "✅ Static targets defined"
      end
      
      if content.include?("controlChanged")
        puts "✅ controlChanged method exists"
      else
        puts "❌ controlChanged method missing"
      end
    end
  end
end
# Copyright 2025
