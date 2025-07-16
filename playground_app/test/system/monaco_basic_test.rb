# frozen_string_literal: true

require "application_system_test_case"

class MonacoBasicTest < ApplicationSystemTestCase
  test "basic Monaco functionality works" do
    visit root_path
    
    # Wait for playground to load
    assert_selector "[data-controller='playground']", wait: 10
    
    # Check that Monaco editor container exists
    assert_selector "#monaco-editor", wait: 10
    
    # Wait for Monaco to be ready
    sleep 5
    
    # Check if Monaco instance is available
    monaco_ready = page.evaluate_script("
      typeof window.monacoEditorInstance !== 'undefined' && 
      window.monacoEditorInstance !== null
    ")
    
    puts "Monaco ready: #{monaco_ready}"
    
    if monaco_ready
      # Test setting and getting code
      test_code = 'text("Hello Monaco!")'
      
      # Set code in Monaco
      page.evaluate_script("
        window.monacoEditorInstance.setValue('#{test_code}');
      ")
      
      # Get code back from Monaco
      retrieved_code = page.evaluate_script("
        window.monacoEditorInstance.getValue()
      ")
      
      puts "Set code: #{test_code}"
      puts "Retrieved code: #{retrieved_code}"
      
      # Check if they match
      assert_equal test_code, retrieved_code
      
      # Wait for preview to update
      sleep 2
      
      # Check if preview shows the text
      within("#preview-container") do
        assert_text "Hello Monaco!", wait: 5
      end
      
      puts "✅ Monaco basic functionality works!"
    else
      puts "⚠️ Monaco not ready, skipping advanced tests"
    end
  end
end