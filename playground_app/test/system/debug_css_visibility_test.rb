# frozen_string_literal: true

require "application_system_test_case"

class DebugCssVisibilityTest < ApplicationSystemTestCase
  test "debug CSS visibility and console logs" do
    puts "\n🔍 Debugging CSS visibility and console logs..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 2
    
    # Check computed styles of loading indicator
    loading_styles = page.evaluate_script("
      const loading = document.getElementById('editor-loading');
      if (loading) {
        const styles = window.getComputedStyle(loading);
        return {
          display: styles.display,
          visibility: styles.visibility,
          opacity: styles.opacity,
          position: styles.position,
          zIndex: styles.zIndex,
          width: styles.width,
          height: styles.height,
          backgroundColor: styles.backgroundColor
        };
      }
      return null;
    ")
    
    puts "Loading indicator styles: #{loading_styles}"
    
    # Check computed styles of Monaco container
    monaco_styles = page.evaluate_script("
      const monaco = document.getElementById('monaco-editor');
      if (monaco) {
        const styles = window.getComputedStyle(monaco);
        return {
          display: styles.display,
          visibility: styles.visibility,
          opacity: styles.opacity,
          position: styles.position,
          zIndex: styles.zIndex,
          width: styles.width,
          height: styles.height
        };
      }
      return null;
    ")
    
    puts "Monaco container styles: #{monaco_styles}"
    
    # Check if scripts are running
    puts "\n📋 Checking if scripts are present..."
    
    # Look for our script in the page
    script_present = page.evaluate_script("
      const scripts = document.querySelectorAll('script');
      let found = false;
      scripts.forEach(script => {
        if (script.textContent && script.textContent.includes('Monaco initialization script running')) {
          found = true;
        }
      });
      return found;
    ")
    
    puts "Monaco initialization script present: #{script_present}"
    
    # Wait a bit and check console again
    sleep 3
    
    # Check console logs
    logs = page.driver.browser.logs.get(:browser)
    
    puts "\n📋 Console logs:"
    logs.each do |log|
      puts "#{log.level}: #{log.message}"
    end
    
    # Check if require is available
    require_available = page.evaluate_script("typeof require !== 'undefined'")
    puts "\nRequire available: #{require_available}"
    
    # Check if Monaco is loaded
    monaco_loaded = page.evaluate_script("typeof monaco !== 'undefined'")
    puts "Monaco loaded: #{monaco_loaded}"
    
    # Take screenshot
    save_screenshot("debug_css_visibility.png")
    
    puts "\n✅ Debug complete"
  end
end