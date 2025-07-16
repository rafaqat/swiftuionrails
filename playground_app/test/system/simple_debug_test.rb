# frozen_string_literal: true

require "application_system_test_case"

class SimpleDebugTest < ApplicationSystemTestCase
  test "simple debug with basic JavaScript" do
    puts "\n🔍 Simple debug test..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 2
    
    # Use basic JavaScript (no ES6)
    loading_display = page.evaluate_script("
      var loading = document.getElementById('editor-loading');
      if (loading) {
        var styles = window.getComputedStyle(loading);
        return styles.display;
      }
      return null;
    ")
    
    puts "Loading display: #{loading_display}"
    
    # Check if loading element exists
    loading_exists = page.evaluate_script("document.getElementById('editor-loading') !== null")
    puts "Loading exists: #{loading_exists}"
    
    # Check if Monaco exists
    monaco_exists = page.evaluate_script("document.getElementById('monaco-editor') !== null")
    puts "Monaco exists: #{monaco_exists}"
    
    # Check if require is available
    require_available = page.evaluate_script("typeof require !== 'undefined'")
    puts "Require available: #{require_available}"
    
    # Check basic console logs
    logs = page.driver.browser.logs.get(:browser)
    puts "\n📋 Console logs:"
    logs.each do |log|
      puts "#{log.level}: #{log.message}"
    end
    
    # Take screenshot
    save_screenshot("simple_debug.png")
    
    puts "\n✅ Simple debug complete"
  end
end