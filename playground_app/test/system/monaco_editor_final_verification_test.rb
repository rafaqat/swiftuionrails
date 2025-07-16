# frozen_string_literal: true

require "application_system_test_case"

class MonacoEditorFinalVerificationTest < ApplicationSystemTestCase
  test "Monaco editor loads and displays correctly - final verification" do
    puts "\n🔍 Final Monaco Editor Verification Test"
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 3
    
    # Take screenshot
    save_screenshot("monaco_final_verification.png")
    
    # Verify Monaco container exists and is visible
    assert has_selector?("#monaco-editor", visible: true), "Monaco container should be visible"
    
    # Verify loading indicator exists (may not be visible if Monaco loaded)
    assert has_selector?("#editor-loading", visible: false), "Loading indicator should exist"
    
    # Verify Monaco has the correct styling attributes
    monaco_element = find("#monaco-editor")
    style_attr = monaco_element.native.attribute("style")
    
    puts "Monaco style attribute: #{style_attr}"
    
    # Check if Monaco has editor-specific styles (indicates successful initialization)
    assert style_attr.include?("display: block"), "Monaco should have display: block"
    assert style_attr.include?("vscode"), "Monaco should have VS Code editor styles"
    
    # Verify the editor container has proper dimensions
    container_height = page.execute_script("return document.getElementById('monaco-editor').offsetHeight")
    container_width = page.execute_script("return document.getElementById('monaco-editor').offsetWidth")
    
    puts "Monaco container dimensions: #{container_width}x#{container_height}"
    
    assert container_height > 0, "Monaco container should have positive height"
    assert container_width > 0, "Monaco container should have positive width"
    
    # Verify Monaco editor instance exists globally
    monaco_exists = page.execute_script("return typeof window.monacoEditorInstance !== 'undefined'")
    assert monaco_exists, "Monaco editor instance should exist globally"
    
    puts "✅ Monaco Editor is working correctly!"
    puts "   - Container is visible"
    puts "   - Proper styling applied"
    puts "   - Correct dimensions: #{container_width}x#{container_height}"
    puts "   - Global instance available"
  end
end