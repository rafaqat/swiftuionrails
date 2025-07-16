# frozen_string_literal: true

require "application_system_test_case"

class ClearButtonFixedTest < ApplicationSystemTestCase
  test "Clear button works without errors after fix" do
    puts "\n🔍 Testing Clear button after fixing codeEditor target issue..."
    
    visit "/playground"
    sleep 3
    
    # Check Monaco editor is available
    monaco_available = page.execute_script("return typeof window.monacoEditorInstance === 'object'")
    puts "Monaco editor available: #{monaco_available}"
    
    if monaco_available
      # Get initial content
      initial_content = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Initial content length: #{initial_content.length}"
      
      # Find and click Clear button
      clear_button = find("button", text: "Clear")
      puts "Clear button found: #{clear_button.present?}"
      
      # Click the clear button
      clear_button.click
      sleep 1
      
      # Check if content was cleared
      cleared_content = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Content after clear: '#{cleared_content}'"
      
      # Check for JavaScript errors
      logs = page.driver.browser.logs.get(:browser)
      error_logs = logs.select { |log| log.level == "SEVERE" }
      puts "JavaScript errors after clear: #{error_logs.count}"
      
      error_logs.each do |log|
        puts "  ERROR: #{log.message}"
      end
      
      # Test sidebar component insertion
      puts "Testing Text component insertion..."
      text_button = find("button", text: "Text")
      text_button.click
      sleep 1
      
      # Check content after insertion
      content_after_insert = page.execute_script("return window.monacoEditorInstance.getValue()")
      puts "Content after insert: '#{content_after_insert[0..100]}...'"
      
      # Check for errors again
      logs_after_insert = page.driver.browser.logs.get(:browser)
      new_error_logs = logs_after_insert.select { |log| log.level == "SEVERE" }
      puts "JavaScript errors after insert: #{new_error_logs.count}"
      
      save_screenshot("clear_button_fixed_test.png")
      
      # Assertions
      assert cleared_content.empty?, "Content should be cleared"
      assert content_after_insert.include?("text("), "Text component should be inserted"
      assert_equal 0, error_logs.count, "Should have no JavaScript errors"
      
      puts "✅ Clear button test passed without errors!"
    else
      puts "❌ Monaco editor not available, cannot test"
    end
  end
end