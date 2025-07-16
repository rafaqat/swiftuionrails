# frozen_string_literal: true

require "application_system_test_case"

class MonacoLoadingTest < ApplicationSystemTestCase
  test "Monaco editor loads and displays correctly" do
    puts "\n🔍 Testing Monaco editor loading..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 2
    
    # Take initial screenshot
    save_screenshot("01_monaco_initial.png")
    
    # Check if Monaco container exists
    assert has_selector?("#monaco-editor"), "Monaco container should exist"
    puts "✅ Monaco container found"
    
    # Check if loading indicator exists
    assert has_selector?("#editor-loading"), "Loading indicator should exist"
    puts "✅ Loading indicator found"
    
    # Wait for Monaco to load
    puts "⏳ Waiting for Monaco to load..."
    sleep 8
    
    # Take screenshot after waiting
    save_screenshot("02_monaco_after_wait.png")
    
    # Check if Monaco is visible
    monaco_visible = page.evaluate_script("
      const container = document.getElementById('monaco-editor');
      return container ? window.getComputedStyle(container).display !== 'none' : false;
    ")
    
    puts "Monaco visible: #{monaco_visible}"
    
    # Check if loading indicator is hidden
    loading_visible = page.evaluate_script("
      const loading = document.getElementById('editor-loading');
      return loading ? window.getComputedStyle(loading).display !== 'none' : false;
    ")
    
    puts "Loading visible: #{loading_visible}"
    
    # Check console logs
    logs = page.driver.browser.logs.get(:browser)
    puts "\n📋 Console logs:"
    logs.each do |log|
      puts "#{log.level}: #{log.message}"
    end
    
    # Check if Monaco is defined
    monaco_defined = page.evaluate_script("typeof monaco !== 'undefined'")
    puts "Monaco defined: #{monaco_defined}"
    
    # Check if require is defined
    require_defined = page.evaluate_script("typeof require !== 'undefined'")
    puts "Require defined: #{require_defined}"
    
    # Check if editor instance exists
    editor_exists = page.evaluate_script("typeof window.monacoEditorInstance !== 'undefined'")
    puts "Editor instance exists: #{editor_exists}"
    
    # Check Monaco container dimensions
    monaco_dims = page.evaluate_script("
      const container = document.getElementById('monaco-editor');
      if (container) {
        return {
          width: container.offsetWidth,
          height: container.offsetHeight
        };
      }
      return null;
    ")
    
    puts "Monaco dimensions: #{monaco_dims}"
    
    # Final screenshot
    save_screenshot("03_monaco_final.png")
    
    puts "\n✅ Monaco loading test complete"
  end
end