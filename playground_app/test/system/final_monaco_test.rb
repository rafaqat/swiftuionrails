# frozen_string_literal: true

require "application_system_test_case"

class FinalMonacoTest < ApplicationSystemTestCase
  test "final Monaco test - check if elements exist and take screenshots" do
    puts "\n🔍 Final Monaco test - checking elements and taking screenshots..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 3
    
    # Take initial screenshot
    save_screenshot("01_monaco_initial.png")
    puts "✅ Initial screenshot taken"
    
    # Check if editor loading element exists
    has_loading = has_selector?("#editor-loading", visible: false)
    puts "Loading element exists: #{has_loading}"
    
    # Check if Monaco editor element exists
    has_monaco = has_selector?("#monaco-editor", visible: false)
    puts "Monaco element exists: #{has_monaco}"
    
    # Check if playground controller element exists
    has_playground = has_selector?("[data-controller='playground']", visible: false)
    puts "Playground controller exists: #{has_playground}"
    
    # Check if components are listed
    has_text_component = has_content?("Text")
    puts "Text component listed: #{has_text_component}"
    
    # Check if examples are listed
    has_layout_demo = has_content?("Layout Demo")
    puts "Layout Demo example listed: #{has_layout_demo}"
    
    # Wait longer for Monaco to potentially load
    puts "⏳ Waiting 10 seconds for Monaco to load..."
    sleep 10
    
    # Take screenshot after waiting
    save_screenshot("02_monaco_after_wait.png")
    puts "✅ Screenshot after wait taken"
    
    # Check if Monaco editor is visible by checking display style
    monaco_element = find("#monaco-editor", visible: false)
    if monaco_element
      puts "Monaco element found, checking style..."
      # Get computed style without using JavaScript evaluation
      style_attribute = monaco_element.native.attribute('style')
      puts "Monaco style attribute: #{style_attribute}"
    end
    
    # Check if loading is visible
    loading_element = find("#editor-loading", visible: false)
    if loading_element
      puts "Loading element found"
      # Check if it has content
      loading_text = loading_element.text
      puts "Loading text: '#{loading_text}'"
    end
    
    # Final screenshot
    save_screenshot("03_monaco_final.png")
    puts "✅ Final screenshot taken"
    
    # Log some basic info
    puts "\n📋 Basic page info:"
    puts "Page title: #{page.title}"
    puts "Current URL: #{current_url}"
    puts "Has Monaco editor: #{has_monaco}"
    puts "Has loading indicator: #{has_loading}"
    
    puts "\n✅ Test complete - check screenshots for visual verification"
  end
end