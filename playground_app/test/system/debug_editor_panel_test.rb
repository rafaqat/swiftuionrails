# frozen_string_literal: true

require "application_system_test_case"

class DebugEditorPanelTest < ApplicationSystemTestCase
  test "debug editor panel HTML structure" do
    puts "\n🔍 Debugging editor panel HTML structure..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 2
    
    # Check if editor panel div exists
    editor_panel = find("[data-playground-target='monacoContainer']", visible: false)
    if editor_panel
      puts "✅ Editor panel found"
      puts "Editor panel HTML: #{editor_panel.native.attribute('outerHTML')[0..500]}"
    else
      puts "❌ Editor panel not found"
    end
    
    # Check if loading indicator exists
    loading_indicator = find("#editor-loading", visible: false)
    if loading_indicator
      puts "✅ Loading indicator found"
      puts "Loading indicator HTML: #{loading_indicator.native.attribute('outerHTML')[0..200]}"
    else
      puts "❌ Loading indicator not found"
    end
    
    # Check if monaco editor container exists
    monaco_container = find("#monaco-editor", visible: false)
    if monaco_container
      puts "✅ Monaco container found"
      puts "Monaco container HTML: #{monaco_container.native.attribute('outerHTML')[0..200]}"
    else
      puts "❌ Monaco container not found"
    end
    
    # Check the overall structure
    puts "\n📋 Overall editor area structure:"
    editor_area = find(".flex-1.flex.relative", visible: false)
    if editor_area
      puts "Editor area HTML: #{editor_area.native.attribute('outerHTML')[0..1000]}"
    else
      puts "❌ Editor area not found"
    end
    
    # Take screenshot
    save_screenshot("debug_editor_panel.png")
    
    puts "\n✅ Debug complete"
  end
end