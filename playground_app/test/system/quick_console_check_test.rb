# frozen_string_literal: true

require "application_system_test_case"

class QuickConsoleCheckTest < ApplicationSystemTestCase
  test "check console errors on playground page" do
    puts "\n🔍 Checking console errors on playground page..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 3
    
    # Capture console logs
    logs = page.driver.browser.logs.get(:browser)
    
    puts "\n📋 CONSOLE LOGS:"
    puts "="*50
    logs.each do |log|
      level_emoji = case log.level
      when "SEVERE", "ERROR" then "🚨"
      when "WARNING" then "⚠️"
      when "INFO" then "ℹ️"
      else "📝"
      end
      puts "#{level_emoji} [#{log.level}] #{log.message}"
    end
    puts "="*50
    
    # Check Monaco container dimensions
    monaco_dims = page.evaluate_script("
      const container = document.getElementById('monaco-editor');
      if (container) {
        return {
          width: container.offsetWidth,
          height: container.offsetHeight,
          computed: window.getComputedStyle(container)
        };
      }
      return null;
    ")
    
    puts "\n📊 Monaco container: #{monaco_dims ? "#{monaco_dims['width']}x#{monaco_dims['height']}" : "NOT FOUND"}"
    
    # Check if Monaco is defined
    monaco_check = page.evaluate_script("typeof monaco")
    puts "Monaco type: #{monaco_check}"
    
    # Check if require is defined
    require_check = page.evaluate_script("typeof require")
    puts "Require type: #{require_check}"
    
    # Check if require.js scripts are loaded
    require_scripts = page.evaluate_script("
      const scripts = Array.from(document.querySelectorAll('script[src*=\"loader\"]'));
      return scripts.map(s => s.src);
    ")
    
    puts "\n📊 RequireJS scripts: #{require_scripts}"
    
    # Check for Monaco editor scripts
    monaco_scripts = page.evaluate_script("
      const scripts = Array.from(document.querySelectorAll('script[src*=\"monaco\"]'));
      return scripts.map(s => s.src);
    ")
    
    puts "Monaco scripts: #{monaco_scripts}"
    
    # Check if Stimulus playground controller is connected
    stimulus_check = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"playground\"]');
      return element ? 'FOUND' : 'NOT FOUND';
    ")
    
    puts "Stimulus playground controller: #{stimulus_check}"
    
    # Take screenshot
    save_screenshot("quick_console_check.png")
    
    puts "\n✅ Console check complete"
  end
end