# frozen_string_literal: true

require "application_system_test_case"

class StimulusDebugTest < ApplicationSystemTestCase
  test "stimulus controller loading and availability" do
    puts "🔍 Testing Stimulus controller loading..."
    
    visit "/storybook/show?story=card_component"
    
    # Wait for page to load
    assert_selector "[data-controller='live_story']", wait: 5
    
    # Check Stimulus debug information
    stimulus_debug = page.evaluate_script("
      console.log('🔍 Stimulus debug check');
      const debug_info = {
        stimulus_available: typeof window.Stimulus !== 'undefined',
        stimulus_version: window.Stimulus ? window.Stimulus.version : null,
        registered_controllers: window.Stimulus ? Object.keys(window.Stimulus.router.controllersByIdentifier) : [],
        live_story_element: document.querySelector('[data-controller=\"live_story\"]') !== null,
        live_story_controller_connected: false
      };
      
      const element = document.querySelector('[data-controller=\"live_story\"]');
      if (element) {
        debug_info.live_story_controller_connected = element.hasAttribute('data-live-story-connected');
        debug_info.controller_instance = element.controller !== undefined;
        
        if (element.controller) {
          debug_info.controller_methods = Object.getOwnPropertyNames(Object.getPrototypeOf(element.controller));
        }
      }
      
      return debug_info;
    ")
    
    puts "📊 Stimulus Debug Info:"
    puts "  Stimulus available: #{stimulus_debug['stimulus_available']}"
    puts "  Stimulus version: #{stimulus_debug['stimulus_version']}"
    puts "  Registered controllers: #{stimulus_debug['registered_controllers']}"
    puts "  Live story element found: #{stimulus_debug['live_story_element']}"
    puts "  Controller connected: #{stimulus_debug['live_story_controller_connected']}"
    puts "  Controller instance exists: #{stimulus_debug['controller_instance']}"
    puts "  Controller methods: #{stimulus_debug['controller_methods']&.join(', ')}"
    
    # Try to get the controller instance directly
    controller_available = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"live_story\"]');
      return element && element.controller && typeof element.controller.controlChanged === 'function';
    ")
    
    puts "  controlChanged method available: #{controller_available}"
    
    # Check console for any Stimulus errors
    if respond_to?(:page) && page.driver.respond_to?(:browser)
      begin
        logs = page.driver.browser.logs.get(:browser)
        stimulus_logs = logs.select { |log| log.message.include?('Stimulus') || log.message.include?('stimulus') || log.message.include?('🎭') }
        
        if stimulus_logs.any?
          puts "\n📋 Stimulus-related console logs:"
          stimulus_logs.each do |log|
            puts "  #{log.level}: #{log.message}"
          end
        else
          puts "\n📋 No Stimulus-related console logs found"
        end
      rescue => e
        puts "⚠️ Could not retrieve console logs: #{e.message}"
      end
    end
    
    assert stimulus_debug['stimulus_available'], "Stimulus should be available"
    assert stimulus_debug['live_story_element'], "Live story element should be found"
  end
end