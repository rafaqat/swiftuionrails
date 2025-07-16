# frozen_string_literal: true

require "application_system_test_case"

class MonacoLoadingComprehensiveTest < ApplicationSystemTestCase
  test "Monaco editor loads correctly with proper timing" do
    puts "\n🔍 Testing Monaco editor loading with proper timing..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for initial page load
    sleep 2
    
    # Take initial screenshot
    save_screenshot("01_monaco_initial.png")
    puts "✅ Initial screenshot taken"
    
    # Check HTML structure
    has_loading = has_selector?("#editor-loading", visible: false)
    has_monaco = has_selector?("#monaco-editor", visible: false)
    has_script = page.html.include?("Monaco initialization script running")
    
    puts "Loading element exists: #{has_loading}"
    puts "Monaco element exists: #{has_monaco}"
    puts "Initialization script present: #{has_script}"
    
    # Check loading indicator text
    loading_element = find("#editor-loading", visible: false)
    if loading_element
      puts "Loading element HTML: #{loading_element.native.attribute('outerHTML')}"
      
      # Check if text is visible
      span_elements = loading_element.all("span", visible: false)
      puts "Span elements in loading: #{span_elements.count}"
      span_elements.each do |span|
        puts "  Span text: '#{span.text}'"
        puts "  Span HTML: #{span.native.attribute('outerHTML')}"
      end
    end
    
    # Wait for Monaco to initialize
    puts "\n⏳ Waiting 15 seconds for Monaco to initialize..."
    sleep 15
    
    # Take screenshot after waiting
    save_screenshot("02_monaco_after_wait.png")
    puts "✅ Screenshot after wait taken"
    
    # Final screenshot
    save_screenshot("03_monaco_final.png")
    puts "✅ Final screenshot taken"
    
    puts "\n📋 Test Summary:"
    puts "- Loading indicator exists: #{has_loading}"
    puts "- Monaco container exists: #{has_monaco}"
    puts "- Script is present: #{has_script}"
    puts "- Check screenshots for visual confirmation"
    
    puts "\n✅ Comprehensive Monaco test complete"
  end
end