require "application_system_test_case"

class ColorFixTest < ApplicationSystemTestCase
  def setup
    visit "/"
    sleep 2 # Allow initial page load
  end

  test "bg('blue') now works correctly with list of buttons" do
    # Click the List button in the sidebar
    within "[data-playground-target='componentsContainer']" do
      click_button "List"
    end
    sleep 2 # Allow Monaco editor to update and preview to render
    
    # Check that the code was inserted correctly into Monaco editor
    code = page.evaluate_script("window.monacoEditorInstance ? window.monacoEditorInstance.getValue() : 'editor not ready'")
    puts "📝 Code in Monaco editor:"
    puts code
    
    # Verify the new button list code is present
    assert code.include?('.bg("blue")'), "Should contain .bg('blue') syntax"
    assert code.include?('vstack(spacing: 8)'), "Should use vstack with spacing"
    assert code.include?('button("Click Me Item'), "Should contain button elements"
    
    # Check the preview container for rendered output
    within "#preview-container" do
      # Check for error messages
      if page.has_css?(".playground-error")
        error_msg = find(".playground-error").text
        puts "❌ Error found: #{error_msg}"
        
        # If there's a backtrace, show it
        if page.has_css?("details pre")
          backtrace = find("details pre").text
          puts "🔍 Backtrace: #{backtrace}"
        end
        
        flunk "Button list failed with error: #{error_msg}"
      else
        puts "✅ No errors found in preview"
        
        # Check for expected button structure
        if page.has_css?("button")
          buttons = all("button")
          puts "✅ Found #{buttons.count} buttons"
          
          # Check each button for correct styling
          buttons.each_with_index do |button, index|
            button_classes = button[:class]
            puts "Button #{index + 1} classes: #{button_classes}"
            
            # Verify the button has blue background (bg-blue-500 from security validator)
            if button_classes.include?("bg-blue-500")
              puts "✅ Button #{index + 1}: Correct blue background (bg-blue-500)"
            else
              puts "❌ Button #{index + 1}: Missing blue background. Classes: #{button_classes}"
            end
            
            # Verify the button has white text
            if button_classes.include?("text-white")
              puts "✅ Button #{index + 1}: Correct white text"
            else
              puts "❌ Button #{index + 1}: Missing white text. Classes: #{button_classes}"
            end
          end
          
          # Verify we have exactly 5 buttons as expected
          assert_equal 5, buttons.count, "Expected 5 buttons"
          
          # Verify all buttons have the correct blue background
          buttons.each_with_index do |button, index|
            assert button[:class].include?("bg-blue-500"), "Button #{index + 1} should have bg-blue-500 class"
            assert button[:class].include?("text-white"), "Button #{index + 1} should have text-white class"
          end
          
        else
          puts "❌ No buttons found"
          page_html = find("#preview-container").native.inner_html
          puts "Preview container HTML:"
          puts page_html
          flunk "Button list did not render any buttons"
        end
      end
    end
  end
end