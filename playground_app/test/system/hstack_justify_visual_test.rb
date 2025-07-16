require "application_system_test_case"

class HStackJustifyVisualTest < ApplicationSystemTestCase
  test "justify between works visually with proper spacing" do
    visit root_path
    
    # Wait for Monaco editor to initialize
    wait_for_monaco_editor
    
    # Clear editor and insert test code
    clear_monaco_editor
    
    # Test code with no padding to see true edge alignment
    test_code = <<~RUBY
      swift_ui do
        div.bg("gray-100").min_h("screen").p(0) do
          vstack(spacing: 8) do
            text("Visual Test: justify: :between")
              .font_size("xl")
              .font_weight("bold")
              .text_align("center")
              .mb(8)
            
            # Test justify: :between with red border to see boundaries
            div.border_2.border_color("red-500").bg("yellow-100").p(0) do
              hstack(justify: :between) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md") do
                  text("LEFT")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md") do
                  text("RIGHT")
                end
              end
            end
            
            # Test justify: :start for comparison
            div.border_2.border_color("blue-500").bg("blue-100").p(0) do
              hstack(justify: :start) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md") do
                  text("LEFT")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md") do
                  text("RIGHT")
                end
              end
            end
            
            # Test justify: :center for comparison  
            div.border_2.border_color("green-500").bg("green-100").p(0) do
              hstack(justify: :center) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md") do
                  text("LEFT")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md") do
                  text("RIGHT")
                end
              end
            end
            
            # Test justify: :end for comparison
            div.border_2.border_color("purple-500").bg("purple-100").p(0) do
              hstack(justify: :end) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md") do
                  text("LEFT")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md") do
                  text("RIGHT")
                end
              end
            end
          end
        end
      end
    RUBY
    
    insert_code_into_monaco_editor(test_code)
    
    # Wait for preview to update
    sleep 2
    
    # Check that the HTML structure is correct
    within("#preview-container") do
      # Verify the justify-between container exists
      justify_between_container = find("div.justify-between")
      assert justify_between_container
      
      # Verify the classes are correct
      classes = justify_between_container[:class]
      assert_includes classes, "flex"
      assert_includes classes, "flex-row"
      assert_includes classes, "items-center"
      assert_includes classes, "justify-between"
      assert_includes classes, "w-full"
      
      # Verify the children exist
      left_element = justify_between_container.find("div", text: "LEFT")
      right_element = justify_between_container.find("div", text: "RIGHT")
      
      assert left_element
      assert right_element
      
      # Get the computed positions of the elements
      left_rect = page.evaluate_script("document.querySelector('div.justify-between div:nth-child(1)').getBoundingClientRect()")
      right_rect = page.evaluate_script("document.querySelector('div.justify-between div:nth-child(2)').getBoundingClientRect()")
      container_rect = page.evaluate_script("document.querySelector('div.justify-between').getBoundingClientRect()")
      
      puts "=== VISUAL TEST RESULTS ==="
      puts "Container width: #{container_rect['width']}"
      puts "Container left: #{container_rect['left']}"
      puts "Container right: #{container_rect['right']}"
      puts "Left element left: #{left_rect['left']}"
      puts "Left element right: #{left_rect['right']}"
      puts "Right element left: #{right_rect['left']}"
      puts "Right element right: #{right_rect['right']}"
      puts "Gap between elements: #{right_rect['left'] - left_rect['right']}"
      puts "=== END VISUAL TEST ==="
      
      # Check if elements are properly spaced
      # For justify-between, the left element should be at the start and right element at the end
      gap_between_elements = right_rect['left'] - left_rect['right']
      
      # Elements should be separated by a significant gap for justify-between
      assert gap_between_elements > 50, "Elements are not properly spaced for justify-between (gap: #{gap_between_elements}px)"
      
      # Left element should be near the container start
      left_distance_from_start = left_rect['left'] - container_rect['left']
      assert left_distance_from_start < 10, "Left element is not at container start (distance: #{left_distance_from_start}px)"
      
      # Right element should be near the container end
      right_distance_from_end = container_rect['right'] - right_rect['right']
      assert right_distance_from_end < 10, "Right element is not at container end (distance: #{right_distance_from_end}px)"
    end
    
    # Take a screenshot for visual inspection
    save_screenshot("hstack_justify_visual_test.png")
    
    # Test that other justify options work differently
    within("#preview-container") do
      # Check justify-start - elements should be close together at start
      start_container = find("div.justify-start")
      start_left = page.evaluate_script("document.querySelector('div.justify-start div:nth-child(1)').getBoundingClientRect()")
      start_right = page.evaluate_script("document.querySelector('div.justify-start div:nth-child(2)').getBoundingClientRect()")
      start_gap = start_right['left'] - start_left['right']
      
      # For justify-start, elements should be close together (just the space-x-8 gap)
      assert start_gap < 50, "justify-start elements should be close together (gap: #{start_gap}px)"
      
      # Check justify-center - elements should be centered
      center_container = find("div.justify-center")
      center_left = page.evaluate_script("document.querySelector('div.justify-center div:nth-child(1)').getBoundingClientRect()")
      center_right = page.evaluate_script("document.querySelector('div.justify-center div:nth-child(2)').getBoundingClientRect()")
      center_container_rect = page.evaluate_script("document.querySelector('div.justify-center').getBoundingClientRect()")
      
      # For justify-center, elements should be roughly centered
      center_point = (center_left['left'] + center_right['right']) / 2
      container_center = (center_container_rect['left'] + center_container_rect['right']) / 2
      center_offset = (center_point - container_center).abs
      
      assert center_offset < 20, "justify-center elements should be centered (offset: #{center_offset}px)"
    end
  end
  
  test "tailwind css classes are properly compiled and applied" do
    visit root_path
    
    # Check that Tailwind CSS is loaded
    css_loaded = page.evaluate_script("
      var styles = Array.from(document.styleSheets);
      var tailwindSheet = styles.find(function(sheet) {
        try {
          return sheet.href && sheet.href.includes('tailwind');
        } catch (e) {
          return false;
        }
      });
      
      if (tailwindSheet) {
        try {
          var rules = Array.from(tailwindSheet.cssRules || tailwindSheet.rules || []);
          var justifyBetweenRule = rules.find(function(rule) {
            return rule.selectorText && rule.selectorText.includes('justify-between');
          });
          
          return {
            tailwindLoaded: true,
            justifyBetweenExists: !!justifyBetweenRule,
            justifyBetweenRule: justifyBetweenRule ? justifyBetweenRule.cssText : null
          };
        } catch (e) {
          return {
            tailwindLoaded: true,
            justifyBetweenExists: false,
            error: e.message
          };
        }
      }
      
      return { tailwindLoaded: false };
    ")
    
    puts "=== CSS COMPILATION CHECK ==="
    puts "Tailwind loaded: #{css_loaded['tailwindLoaded']}"
    puts "justify-between exists: #{css_loaded['justifyBetweenExists']}"
    puts "justify-between rule: #{css_loaded['justifyBetweenRule']}"
    puts "Error: #{css_loaded['error']}" if css_loaded['error']
    puts "=== END CSS CHECK ==="
    
    assert css_loaded['tailwindLoaded'], "Tailwind CSS is not loaded"
    assert css_loaded['justifyBetweenExists'], "justify-between class is not defined in CSS"
  end
  
  test "playground rendering matches component rendering" do
    visit root_path
    wait_for_monaco_editor
    clear_monaco_editor
    
    # Test the same code that works in regular Rails
    test_code = <<~RUBY
      swift_ui do
        div.border.border_color("red-500").p(0) do
          hstack(justify: :between) do
            text("LEFT")
            text("RIGHT")
          end
        end
      end
    RUBY
    
    insert_code_into_monaco_editor(test_code)
    sleep 2
    
    # Get the rendered HTML from playground
    playground_html = find("#preview-container").native.inner_html
    
    # Compare with what we expect from the debug script
    expected_classes = ["flex", "flex-row", "items-center", "justify-between", "space-x-8", "w-full"]
    
    expected_classes.each do |css_class|
      assert_includes playground_html, css_class, "Missing expected class: #{css_class}"
    end
    
    # Verify the structure matches
    within("#preview-container") do
      container = find("div.justify-between")
      left_span = container.find("span", text: "LEFT")
      right_span = container.find("span", text: "RIGHT")
      
      assert left_span
      assert right_span
    end
  end
  
  private
  
  def wait_for_monaco_editor
    # Wait for Monaco editor container to be visible
    assert_selector "#monaco-editor", wait: 10
    
    # Wait for Monaco editor instance to be ready
    timeout = 30
    start_time = Time.now
    
    loop do
      editor_ready = page.evaluate_script "
        window.monacoEditorInstance && 
        window.monacoEditorInstance.getValue && 
        typeof window.monacoEditorInstance.getValue === 'function'
      "
      
      break if editor_ready
      
      if Time.now - start_time > timeout
        flunk "Monaco editor failed to initialize within #{timeout} seconds"
      end
      
      sleep 0.1
    end
  end
  
  def clear_monaco_editor
    page.evaluate_script "if (window.monacoEditorInstance) { window.monacoEditorInstance.setValue(''); }"
  end
  
  def insert_code_into_monaco_editor(code)
    page.evaluate_script "
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue(#{code.to_json});
        
        if (window.playgroundController) {
          window.playgroundController.onEditorChange();
        }
      }
    "
  end
end