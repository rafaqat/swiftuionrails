# frozen_string_literal: true

require "application_system_test_case"

class MonacoDimensionsTest < ApplicationSystemTestCase
  test "check Monaco editor dimensions and styling" do
    puts "\n🔍 Checking Monaco editor dimensions and styling..."
    
    visit "/playground"
    sleep 3
    
    # Check if Monaco container exists
    monaco_container = find("#monaco-editor", visible: false)
    loading_indicator = find("#editor-loading", visible: false)
    
    puts "Monaco container found: #{monaco_container.present?}"
    puts "Loading indicator found: #{loading_indicator.present?}"
    
    # Check computed styles
    if monaco_container
      container_styles = page.execute_script("
        const container = document.getElementById('monaco-editor');
        const computed = window.getComputedStyle(container);
        return {
          display: computed.display,
          width: computed.width,
          height: computed.height,
          position: computed.position,
          visibility: computed.visibility,
          opacity: computed.opacity,
          zIndex: computed.zIndex
        };
      ")
      
      puts "Monaco container styles:"
      puts "  Display: #{container_styles['display']}"
      puts "  Width: #{container_styles['width']}"
      puts "  Height: #{container_styles['height']}"
      puts "  Position: #{container_styles['position']}"
      puts "  Visibility: #{container_styles['visibility']}"
      puts "  Opacity: #{container_styles['opacity']}"
      puts "  Z-index: #{container_styles['zIndex']}"
    end
    
    # Check loading indicator styles
    if loading_indicator
      loading_styles = page.execute_script("
        const loading = document.getElementById('editor-loading');
        const computed = window.getComputedStyle(loading);
        return {
          display: computed.display,
          width: computed.width,
          height: computed.height,
          position: computed.position,
          visibility: computed.visibility,
          opacity: computed.opacity,
          zIndex: computed.zIndex
        };
      ")
      
      puts "Loading indicator styles:"
      puts "  Display: #{loading_styles['display']}"
      puts "  Width: #{loading_styles['width']}"
      puts "  Height: #{loading_styles['height']}"
      puts "  Position: #{loading_styles['position']}"
      puts "  Visibility: #{loading_styles['visibility']}"
      puts "  Opacity: #{loading_styles['opacity']}"
      puts "  Z-index: #{loading_styles['zIndex']}"
    end
    
    # Check parent container dimensions
    parent_dimensions = page.execute_script("
      const parent = document.querySelector('.flex-1.flex.relative.min-h-\\\\[400px\\\\]');
      if (parent) {
        const computed = window.getComputedStyle(parent);
        return {
          width: computed.width,
          height: computed.height,
          minHeight: computed.minHeight,
          display: computed.display
        };
      }
      return null;
    ")
    
    if parent_dimensions
      puts "Parent container dimensions:"
      puts "  Width: #{parent_dimensions['width']}"
      puts "  Height: #{parent_dimensions['height']}"
      puts "  Min-height: #{parent_dimensions['minHeight']}"
      puts "  Display: #{parent_dimensions['display']}"
    end
    
    # Check if Monaco editor instance exists
    monaco_instance = page.execute_script("return typeof window.monacoEditorInstance !== 'undefined'")
    puts "Monaco instance exists: #{monaco_instance}"
    
    if monaco_instance
      monaco_info = page.execute_script("
        const editor = window.monacoEditorInstance;
        return {
          hasEditor: !!editor,
          domNode: !!editor.getDomNode(),
          model: !!editor.getModel(),
          value: editor.getValue ? editor.getValue().substring(0, 50) : 'No getValue method'
        };
      ")
      
      puts "Monaco instance info:"
      puts "  Has editor: #{monaco_info['hasEditor']}"
      puts "  Has DOM node: #{monaco_info['domNode']}"
      puts "  Has model: #{monaco_info['model']}"
      puts "  Value preview: #{monaco_info['value']}"
    end
    
    save_screenshot("monaco_dimensions_debug.png")
    puts "✅ Screenshot saved for visual inspection"
  end
end