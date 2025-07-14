# frozen_string_literal: true

require "application_system_test_case"

class PlaygroundButtonTest < ApplicationSystemTestCase
  test "renders button with teal background and yellow text" do
    visit playground_path
    
    # Clear the default code
    find('[data-action="click->playground#clearCode"]').click
    
    # Enter the button code
    button_code = <<~RUBY
      button("Hello World")
        .bg("teal")
        .text_color("yellow")
        .px(16).py(8)
        .rounded("lg")
    RUBY
    
    # Wait for Monaco editor to be ready
    assert_selector '#monaco-editor', visible: true
    
    # Input the code (Monaco requires special handling)
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue(`#{button_code.gsub("\n", "\\n").gsub('"', '\"')}`)
      }
    JS
    
    # Click run button
    find('[data-action="click->playground#runCode"]').click
    
    # Wait for preview to update
    within '#preview-container' do
      # Should render a button element
      assert_selector 'button', text: 'Hello World', wait: 5
      
      # Check if button has correct classes
      button = find('button', text: 'Hello World')
      assert button[:class].include?('bg-teal'), "Button should have teal background class"
      assert button[:class].include?('text-yellow'), "Button should have yellow text class"
      assert button[:class].include?('px-4'), "Button should have horizontal padding"
      assert button[:class].include?('py-2'), "Button should have vertical padding"
      assert button[:class].include?('rounded-lg'), "Button should have rounded corners"
    end
  end
  
  test "renders simple button without chained methods" do
    visit playground_path
    
    # Clear and enter simple button code
    find('[data-action="click->playground#clearCode"]').click
    
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue('button("Test")')
      }
    JS
    
    find('[data-action="click->playground#runCode"]').click
    
    within '#preview-container' do
      assert_selector 'button', text: 'Test', wait: 5
    end
  end
  
  test "button renders inside swift_ui block" do
    visit playground_path
    
    find('[data-action="click->playground#clearCode"]').click
    
    button_code = <<~RUBY
      swift_ui do
        button("Hello World")
          .bg("teal")
          .text_color("yellow")
      end
    RUBY
    
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue(`#{button_code.gsub("\n", "\\n").gsub('"', '\"')}`)
      }
    JS
    
    find('[data-action="click->playground#runCode"]').click
    
    within '#preview-container' do
      assert_selector 'button', text: 'Hello World', wait: 5
    end
  end
end