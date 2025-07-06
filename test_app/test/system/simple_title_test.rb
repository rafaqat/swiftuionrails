# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class SimpleTitleTest < ApplicationSystemTestCase
  test "simple title change with console logging" do
    puts "🧪 Testing simple title change..."
    
    visit "/storybook/show?story=card_component"
    
    # Wait for page to load
    assert_selector "[data-controller='live_story']", wait: 5
    
    # Add JavaScript to log everything
    page.execute_script("
      console.log('🔍 Starting debug mode');
      window.debugMode = true;
      
      // Override the controlChanged method to add logging
      const element = document.querySelector('[data-controller=\"live_story\"]');
      if (element && element.controller) {
        const originalMethod = element.controller.controlChanged;
        element.controller.controlChanged = function(event) {
          console.log('🎯 controlChanged called!', event.target.name, event.target.value);
          return originalMethod.call(this, event);
        };
        
        const originalUpdate = element.controller.updatePreview;
        element.controller.updatePreview = function() {
          console.log('📡 updatePreview called!');
          return originalUpdate.call(this);
        };
        
        console.log('✅ Debug overrides installed');
      } else {
        console.log('❌ Controller not found');
      }
    ")
    
    # Find and change the title input
    title_input = find("input[name='title']")
    title_input.fill_in with: "Debug Test Title"
    
    # Manually trigger events to see what happens
    page.execute_script("
      const input = document.querySelector('input[name=\"title\"]');
      if (input) {
        console.log('📝 Triggering input event on:', input);
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));
      }
    ")
    
    # Wait and check logs
    sleep 2
    
    # Get console logs
    if respond_to?(:page) && page.driver.respond_to?(:browser)
      begin
        logs = page.driver.browser.logs.get(:browser)
        console_logs = logs.select { |log| log.message.include?('🔍') || log.message.include?('🎯') || log.message.include?('📡') || log.message.include?('✅') || log.message.include?('❌') }
        
        puts "\n📋 Console logs:"
        console_logs.each do |log|
          puts "  #{log.message}"
        end
      rescue => e
        puts "⚠️ Could not retrieve console logs: #{e.message}"
      end
    end
    
    # Check if title actually changed
    card_title = find("#component-preview .text-lg", wait: 2).text rescue "Not found"
    puts "\n🎯 Final card title: '#{card_title}'"
    
    if card_title == "Debug Test Title"
      puts "✅ Title update worked!"
    else
      puts "❌ Title update failed - still showing: '#{card_title}'"
    end
  end
end
# Copyright 2025
