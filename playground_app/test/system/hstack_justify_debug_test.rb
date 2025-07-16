# frozen_string_literal: true

require "application_system_test_case"

class HstackJustifyDebugTest < ApplicationSystemTestCase
  def setup
    # Visit the unified playground 
    visit root_path
    
    # Wait for page to load
    assert_selector '[data-controller="playground"]', wait: 10
    
    # Wait for Monaco editor to initialize properly
    wait_for_monaco_editor
  end

  test "debug justify: :between rendering with minimal example" do
    # Clear editor and set a minimal justify: :between example
    clear_editor
    
    minimal_code = <<~RUBY
      swift_ui do
        div.border.border_color("red-500").p(0).bg("yellow-100") do
          hstack(justify: :between) do
            text("LEFT")
            text("RIGHT")
          end
        end
      end
    RUBY
    
    set_editor_code(minimal_code)
    
    # Wait for preview to update
    sleep 3
    
    # Debug what's actually in the preview
    puts "\n=== DEBUG JUSTIFY: :BETWEEN RENDERING ==="
    
    # Check if the preview container has any content
    preview_html = page.find("#preview-container").native.inner_html
    puts "Preview HTML: #{preview_html}"
    
    # Check for the specific elements
    within_preview_container do
      # Look for the container with red border
      if page.has_selector?("div[style*='border-color: rgb(239, 68, 68)']", wait: 5)
        puts "✓ Found container with red border"
      else
        puts "✗ Container with red border not found"
      end
      
      # Look for justify-between class
      if page.has_selector?("div.justify-between", wait: 5)
        puts "✓ Found justify-between class"
        
        # Check if the hstack actually has content
        justify_element = page.find("div.justify-between")
        puts "Justify element HTML: #{justify_element.native.inner_html}"
        
        # Check for text elements
        if page.has_selector?("span", text: "LEFT", wait: 5)
          puts "✓ Found LEFT text"
        else
          puts "✗ LEFT text not found"
        end
        
        if page.has_selector?("span", text: "RIGHT", wait: 5)
          puts "✓ Found RIGHT text"
        else
          puts "✗ RIGHT text not found"
        end
      else
        puts "✗ justify-between class not found"
        
        # Check what classes are actually present
        all_divs = page.all("div")
        puts "All div elements and their classes:"
        all_divs.each_with_index do |div, index|
          classes = div[:class] || "no-class"
          puts "  Div #{index}: #{classes}"
        end
      end
    end
    
    # Take screenshot for visual verification
    save_screenshot("debug_justify_between.png")
    
    puts "=== END DEBUG ==="
  end

  test "debug Layout Demo justify: :between section specifically" do
    # Load the Layout Demo
    within_examples_section do
      click_on "Layout Demo"
    end
    
    # Wait for code to load
    sleep 3
    
    puts "\n=== DEBUG LAYOUT DEMO JUSTIFY: :BETWEEN ==="
    
    within_preview_container do
      # Find all elements with justify-between class
      justify_between_elements = page.all("div.justify-between")
      puts "Found #{justify_between_elements.size} justify-between elements"
      
      justify_between_elements.each_with_index do |element, index|
        puts "Element #{index + 1}:"
        puts "  HTML: #{element.native.inner_html}"
        puts "  Classes: #{element[:class]}"
        
        # Check if this element has the expected A, B, C content
        if element.has_text?("A") && element.has_text?("B") && element.has_text?("C")
          puts "  ✓ Has A, B, C content"
        else
          puts "  ✗ Missing A, B, C content"
          puts "  Text content: '#{element.text}'"
        end
      end
      
      # Also check for the justify: :between label
      if page.has_selector?("span", text: "justify: :between", wait: 5)
        puts "✓ Found justify: :between label"
      else
        puts "✗ justify: :between label not found"
      end
    end
    
    # Take screenshot
    save_screenshot("debug_layout_demo_justify_between.png")
    
    puts "=== END LAYOUT DEMO DEBUG ==="
  end

  test "test raw hstack DSL generation" do
    # Test the DSL directly by examining what it generates
    puts "\n=== TEST RAW DSL GENERATION ==="
    
    # Create a simple hstack component for testing
    test_component = Class.new(SwiftUIRails::Component::Base) do
      swift_ui do
        div.border.border_color("blue-500").p(0) do
          hstack(justify: :between) do
            text("A")
            text("B")
            text("C")
          end
        end
      end
    end
    
    # Render it and check the output
    component_html = render_inline(test_component.new).to_html
    puts "Generated HTML: #{component_html}"
    
    # Check if it contains the expected classes
    if component_html.include?("justify-between")
      puts "✓ Contains justify-between class"
    else
      puts "✗ Missing justify-between class"
    end
    
    if component_html.include?("w-full")
      puts "✓ Contains w-full class"
    else
      puts "✗ Missing w-full class"
    end
    
    # Check for text content
    if component_html.include?("A") && component_html.include?("B") && component_html.include?("C")
      puts "✓ Contains A, B, C text"
    else
      puts "✗ Missing A, B, C text"
    end
    
    puts "=== END DSL GENERATION TEST ==="
  end

  private

  def clear_editor
    # Clear Monaco editor content
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue('');
      }
    JS
  end
  
  def wait_for_monaco_editor
    # Wait for Monaco editor container to be visible
    assert_selector "#monaco-editor", wait: 10
    
    # Wait for Monaco editor instance to be ready with timeout
    timeout = 30 # seconds
    start_time = Time.now
    
    loop do
      editor_ready = page.evaluate_script <<~JS
        window.monacoEditorInstance && 
        window.monacoEditorInstance.getValue && 
        typeof window.monacoEditorInstance.getValue === 'function'
      JS
      
      if editor_ready
        break
      end
      
      if Time.now - start_time > timeout
        puts "Monaco editor failed to initialize within #{timeout} seconds"
        break
      end
      
      sleep 0.1
    end
  end

  def set_editor_code(code)
    # Set code in Monaco editor
    escaped_code = code.gsub('"', '\\"').gsub("\n", "\\n")
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue("#{escaped_code}");
        // Trigger manual update
        setTimeout(() => {
          const event = new Event('input', { bubbles: true });
          window.monacoEditorInstance.trigger('keyboard', 'type', { text: ' ' });
        }, 100);
      }
    JS
  end

  def within_preview_container(&block)
    within "#preview-container", &block
  end

  def within_examples_section(&block)
    within "[data-playground-target='examplesContainer']", &block
  end
end