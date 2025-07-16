# frozen_string_literal: true

require "application_system_test_case"

class MonacoVisibilityTest < ApplicationSystemTestCase
  test "Monaco editor visibility after fix" do
    puts "\n🔍 Testing Monaco editor visibility after fix..."
    
    visit "/playground"
    
    # Wait for initialization
    sleep 5
    
    # Check if Monaco editor is visible
    monaco_visible = has_selector?("#monaco-editor", visible: true)
    puts "Monaco editor visible: #{monaco_visible}"
    
    # Check if loading indicator is hidden
    loading_hidden = has_selector?("#editor-loading", visible: false)
    puts "Loading indicator hidden: #{loading_hidden}"
    
    # Check Monaco instance
    monaco_instance = page.execute_script("return typeof window.monacoEditorInstance")
    puts "Monaco instance type: #{monaco_instance}"
    
    if monaco_instance == "object"
      # Test clear button
      puts "Testing clear button..."
      clear_button = find("button", text: "Clear")
      clear_button.click
      sleep 1
      
      # Check if content was cleared
      content_after_clear = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Content after clear: '#{content_after_clear}'"
      
      # Test sidebar component insertion
      puts "Testing sidebar component insertion..."
      text_button = find("button", text: "Text")
      text_button.click
      sleep 1
      
      # Check if text component was inserted
      content_after_insert = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Content after text insert: '#{content_after_insert[0..50]}...'"
    end
    
    save_screenshot("monaco_visibility_test.png")
    
    # Basic assertions
    assert monaco_visible, "Monaco editor should be visible"
    assert loading_hidden, "Loading indicator should be hidden"
    assert_equal "object", monaco_instance, "Monaco instance should exist"
    
    puts "✅ Monaco visibility test completed successfully!"
  end
end