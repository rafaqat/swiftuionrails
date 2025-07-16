# frozen_string_literal: true

require "application_system_test_case"

class MonacoDirectTest < ApplicationSystemTestCase
  test "Direct Monaco editor investigation" do
    puts "\n🔍 Direct Monaco editor investigation..."
    
    visit "/playground"
    sleep 3
    
    # Check if loading indicator is visible
    loading_visible = page.execute_script("
      const loading = document.getElementById('editor-loading');
      return loading && window.getComputedStyle(loading).display !== 'none';
    ")
    
    puts "Loading indicator visible: #{loading_visible}"
    
    # Check if Monaco container is visible
    monaco_visible = page.execute_script("
      const monaco = document.getElementById('monaco-editor');
      return monaco && window.getComputedStyle(monaco).display !== 'none';
    ")
    
    puts "Monaco container visible: #{monaco_visible}"
    
    # Check for Monaco editor instance
    monaco_instance = page.execute_script("return typeof window.monacoEditorInstance")
    puts "Monaco instance type: #{monaco_instance}"
    
    # Check Monaco container dimensions
    monaco_dimensions = page.execute_script("
      const monaco = document.getElementById('monaco-editor');
      if (monaco) {
        const rect = monaco.getBoundingClientRect();
        const computed = window.getComputedStyle(monaco);
        return {
          width: rect.width,
          height: rect.height,
          display: computed.display,
          visibility: computed.visibility,
          opacity: computed.opacity
        };
      }
      return null;
    ")
    
    puts "Monaco dimensions: #{monaco_dimensions}"
    
    # Check parent container
    parent_info = page.execute_script("
      const parent = document.querySelector('.flex-1.flex.relative');
      if (parent) {
        const rect = parent.getBoundingClientRect();
        return {
          width: rect.width,
          height: rect.height,
          children: parent.children.length
        };
      }
      return null;
    ")
    
    puts "Parent container info: #{parent_info}"
    
    # Try to force Monaco to show
    puts "Attempting to force Monaco visibility..."
    force_result = page.execute_script("
      const loading = document.getElementById('editor-loading');
      const monaco = document.getElementById('monaco-editor');
      
      if (loading) {
        loading.style.display = 'none';
      }
      
      if (monaco) {
        monaco.style.display = 'block';
        monaco.style.width = '100%';
        monaco.style.height = '100%';
        monaco.style.minHeight = '400px';
        
        // Force layout recalculation
        if (window.monacoEditorInstance) {
          window.monacoEditorInstance.layout();
        }
      }
      
      return {
        loadingHidden: loading ? loading.style.display === 'none' : false,
        monacoVisible: monaco ? monaco.style.display === 'block' : false
      };
    ")
    
    puts "Force result: #{force_result}"
    
    # Wait and check again
    sleep 2
    
    # Check if Monaco is now visible
    final_check = page.execute_script("
      const monaco = document.getElementById('monaco-editor');
      return monaco && window.getComputedStyle(monaco).display !== 'none';
    ")
    
    puts "Monaco visible after force: #{final_check}"
    
    save_screenshot("monaco_direct_test.png")
    puts "✅ Direct Monaco test completed"
  end
end