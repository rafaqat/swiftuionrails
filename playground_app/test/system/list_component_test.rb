require "application_system_test_case"

class ListComponentTest < ApplicationSystemTestCase
  def setup
    visit "/"
    sleep 2 # Allow initial page load
  end

  test "List component renders correctly when clicked in sidebar" do
    # Click the List button in the sidebar (be specific to avoid ambiguity)
    within "[data-playground-target='componentsContainer']" do
      click_button "List"
    end
    sleep 2 # Allow Monaco editor to update and preview to render
    
    # Check that the code was inserted correctly into Monaco editor
    code = page.evaluate_script("window.monacoEditorInstance ? window.monacoEditorInstance.getValue() : 'editor not ready'")
    puts "📝 Code in Monaco editor:"
    puts code
    
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
        
        flunk "List component failed with error: #{error_msg}"
      else
        puts "✅ No errors found in preview"
        
        # Check for expected HTML structure
        if page.has_css?("ul")
          puts "✅ Found <ul> element"
          
          list_items = all("li")
          puts "✅ Found #{list_items.count} list items"
          
          # Check if interpolation worked correctly
          list_items.each_with_index do |li, index|
            expected_text = "Item #{index + 1}"
            if li.has_text?(expected_text)
              puts "✅ List item #{index + 1}: #{expected_text}"
            else
              actual_text = li.text
              puts "❌ List item #{index + 1}: expected '#{expected_text}', got '#{actual_text}'"
            end
          end
          
          # Verify we have exactly 5 items as expected
          assert_equal 5, list_items.count, "Expected 5 list items"
          
          # Verify interpolation worked for at least the first item
          assert_text "Item 1", wait: 5
          
        else
          puts "❌ No <ul> element found"
          page_html = find("#preview-container").native.inner_html
          puts "Preview container HTML:"
          puts page_html
          flunk "List component did not render <ul> element"
        end
      end
    end
  end
  
  test "List component structure and styling" do
    within "[data-playground-target='componentsContainer']" do
      click_button "List"
    end
    sleep 2
    
    within "#preview-container" do
      # Check that we get the expected list structure
      assert_selector "ul", count: 1
      assert_selector "li", count: 5
      
      # Check that each list item contains a span with text
      assert_selector "li span", count: 5
      
      # Check that the text interpolation worked
      (1..5).each do |i|
        assert_text "Item #{i}"
      end
    end
  end
end