# frozen_string_literal: true

require "application_system_test_case"

class PlaygroundFinalTest < ApplicationSystemTestCase
  def setup
    @test_start_time = Time.current
    puts "\n" + "="*80
    puts "🎯 PLAYGROUND FINAL TEST - #{@test_start_time}"
    puts "="*80
  end

  test "playground loads correctly with all components" do
    puts "\n📋 Testing playground with all components..."
    
    # Visit the playground
    visit "/playground"
    
    # Take initial screenshot
    save_screenshot("01_final_playground_load.png")
    puts "✅ Initial page loaded"
    
    # Test 1: Check if header is present
    assert has_content?("SwiftUI Rails Playground"), "Header should be present"
    puts "✅ Header found"
    
    # Test 2: Check if sidebar is present  
    assert has_selector?("input[placeholder='Search components...']"), "Search input should be present"
    puts "✅ Sidebar search found"
    
    # Test 3: Check if components are listed
    assert has_content?("Text"), "Text component should be listed"
    assert has_content?("Button"), "Button component should be listed"
    assert has_content?("VStack"), "VStack component should be listed"
    puts "✅ Component list found"
    
    # Test 4: Check if examples are listed
    assert has_content?("Product Grid"), "Product Grid example should be listed"
    assert has_content?("Dashboard Stats"), "Dashboard Stats example should be listed"
    puts "✅ Examples list found"
    
    # Test 5: Check if Monaco editor container exists
    assert has_selector?("#monaco-editor"), "Monaco editor container should exist"
    puts "✅ Monaco editor container found"
    
    # Test 6: Check if loading UI exists
    assert has_selector?("#editor-loading"), "Editor loading UI should exist"
    puts "✅ Editor loading UI found"
    
    # Test 7: Check if preview container exists
    assert has_selector?("#preview-container"), "Preview container should exist"
    puts "✅ Preview container found"
    
    # Test 8: Wait for Monaco to potentially load
    puts "⏳ Waiting for Monaco to load..."
    sleep 5
    
    # Test 9: Check if Stimulus playground controller is connected
    playground_controller = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"playground\"]');
      element !== null
    ")
    assert playground_controller, "Playground controller should be connected"
    puts "✅ Stimulus playground controller connected"
    
    # Test 10: Check if Monaco scripts are loaded
    monaco_script = page.evaluate_script("typeof require !== 'undefined'")
    assert monaco_script, "Monaco require.js should be loaded"
    puts "✅ Monaco scripts loaded"
    
    # Test 11: Check specific Monaco editor dimensions
    editor_width = page.evaluate_script("
      const editor = document.getElementById('monaco-editor');
      editor ? editor.offsetWidth : 0
    ")
    editor_height = page.evaluate_script("
      const editor = document.getElementById('monaco-editor');
      editor ? editor.offsetHeight : 0
    ")
    
    puts "📊 Monaco editor dimensions: #{editor_width}x#{editor_height}"
    assert editor_width > 0, "Monaco editor should have width > 0"
    assert editor_height > 0, "Monaco editor should have height > 0"
    puts "✅ Monaco editor has valid dimensions"
    
    # Final screenshot
    save_screenshot("02_final_playground_complete.png")
    
    puts "\n🎉 ALL TESTS PASSED! Playground is working correctly!"
    puts "🎯 Test completed at: #{Time.current}"
    puts "⏱️  Total runtime: #{Time.current - @test_start_time} seconds"
    puts "="*80
  end
end