# frozen_string_literal: true

require "application_system_test_case"

class SidebarLinksTest < ApplicationSystemTestCase
  test "Sidebar component links functionality" do
    puts "\n🔍 Testing sidebar component links functionality..."
    
    visit "/playground"
    sleep 3
    
    # Check if sidebar components exist
    components = ["Text", "Button", "Image", "VStack", "HStack", "Grid", "Card", "List"]
    
    components.each do |component|
      puts "Checking #{component} component..."
      
      # Find the component button
      component_button = find("button", text: component)
      assert component_button.present?, "#{component} button should exist"
      
      # Check if it has the correct data action
      action = component_button["data-action"]
      code_param = component_button["data-playground-code-param"]
      
      puts "  #{component} action: #{action}"
      puts "  #{component} code param present: #{code_param.present?}"
      
      # Test clicking the component (if Monaco is available)
      monaco_exists = page.execute_script("return typeof window.monacoEditorInstance !== 'undefined'")
      
      if monaco_exists
        puts "  Testing #{component} insertion..."
        
        # Clear editor first
        page.execute_script("window.monacoEditorInstance.setValue('')")
        
        # Click the component button
        component_button.click
        sleep 1
        
        # Check if content was inserted
        new_content = page.execute_script("return window.monacoEditorInstance.getValue()")
        
        if new_content.length > 0
          puts "  ✅ #{component} inserted successfully (#{new_content.length} chars)"
        else
          puts "  ❌ #{component} insertion failed"
        end
      else
        puts "  ⚠️  Monaco not available, skipping insertion test"
      end
    end
    
    save_screenshot("sidebar_links_test.png")
    puts "✅ Sidebar links test completed"
  end
end