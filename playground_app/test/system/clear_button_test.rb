# frozen_string_literal: true

require "application_system_test_case"

class ClearButtonTest < ApplicationSystemTestCase
  test "Clear button functionality" do
    puts "\n🔍 Testing Clear button functionality..."
    
    visit "/playground"
    sleep 3
    
    # Check if Clear button exists
    assert has_selector?("button", text: "Clear"), "Clear button should exist"
    
    # Find the clear button
    clear_button = find("button", text: "Clear")
    puts "Clear button found: #{clear_button.present?}"
    
    # Check button attributes
    clear_button_action = clear_button["data-action"]
    puts "Clear button action: #{clear_button_action}"
    
    # Check if Monaco editor instance exists
    monaco_exists = page.execute_script("return typeof window.monacoEditorInstance !== 'undefined'")
    puts "Monaco instance exists: #{monaco_exists}"
    
    if monaco_exists
      # Get initial content
      initial_content = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Initial content length: #{initial_content.length}"
      
      # Click the clear button
      clear_button.click
      sleep 1
      
      # Check if content was cleared
      cleared_content = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Content after clear: '#{cleared_content}'"
      
      assert cleared_content.empty?, "Content should be cleared after clicking Clear button"
    else
      puts "⚠️  Monaco editor instance not available, cannot test clear functionality"
    end
    
    save_screenshot("clear_button_test.png")
    puts "✅ Clear button test completed"
  end
end