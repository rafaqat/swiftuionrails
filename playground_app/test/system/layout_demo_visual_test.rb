require "application_system_test_case"

class LayoutDemoVisualTest < ApplicationSystemTestCase
  test "Layout Demo justify between works visually" do
    visit root_path
    
    # Wait for page to load
    sleep 2
    
    # Click on Layout Demo example
    find("button", text: "Layout Demo").click
    
    # Wait for the preview to update
    sleep 3
    
    # Take a screenshot to see what's happening
    save_screenshot("layout_demo_loaded.png")
    
    # Find the justify-between section specifically
    within("#preview-container") do
      # Look for the justify-between section in the Layout Demo
      justify_between_section = find("div", text: "justify: :between")
      parent_section = justify_between_section.ancestor("div")
      
      # Find the actual hstack with justify-between
      hstack_element = parent_section.find("div.justify-between")
      
      puts "=== LAYOUT DEMO VISUAL TEST ==="
      puts "Found justify-between element: #{hstack_element.present?}"
      
      if hstack_element.present?
        puts "Classes: #{hstack_element[:class]}"
        
        # Get the positions of the elements
        left_rect = page.evaluate_script("arguments[0].children[0].getBoundingClientRect()", hstack_element)
        right_rect = page.evaluate_script("arguments[0].children[1].getBoundingClientRect()", hstack_element)
        container_rect = page.evaluate_script("arguments[0].getBoundingClientRect()", hstack_element)
        
        puts "Container width: #{container_rect['width']}"
        puts "Left element position: #{left_rect['left']}"
        puts "Right element position: #{right_rect['left']}"
        puts "Gap between elements: #{right_rect['left'] - left_rect['right']}"
        
        # Visual verification
        gap = right_rect['left'] - left_rect['right']
        assert gap > 50, "Elements should be spaced apart for justify-between (gap: #{gap}px)"
        
        # Take screenshot showing the layout
        save_screenshot("layout_demo_justify_between.png")
      else
        puts "ERROR: Could not find justify-between element"
        save_screenshot("layout_demo_error.png")
        flunk "Could not find justify-between element in Layout Demo"
      end
    end
  end
  
  test "Layout Demo loads all justify variations" do
    visit root_path
    sleep 2
    
    # Click on Layout Demo example
    find("button", text: "Layout Demo").click
    sleep 3
    
    within("#preview-container") do
      # Check that all justify variations are present
      justify_variations = [
        "justify: :start (default)",
        "justify: :center", 
        "justify: :end",
        "justify: :between",
        "justify: :around",
        "justify: :evenly"
      ]
      
      justify_variations.each do |variation|
        assert_text variation, "Layout Demo should contain #{variation}"
      end
      
      # Check that corresponding CSS classes exist
      css_classes = [
        "justify-start",
        "justify-center", 
        "justify-end",
        "justify-between",
        "justify-around",
        "justify-evenly"
      ]
      
      css_classes.each do |css_class|
        assert_selector "div.#{css_class}", "Should find element with class #{css_class}"
      end
    end
  end
  
  test "check raw HTML structure of justify-between" do
    visit root_path
    sleep 2
    
    find("button", text: "Layout Demo").click
    sleep 3
    
    # Get the raw HTML to inspect
    html = find("#preview-container").native.attribute("innerHTML")
    puts "=== RAW HTML INSPECTION ==="
    puts html
    puts "=== END RAW HTML ==="
    
    # Check for expected structure
    assert_includes html, "justify-between"
    assert_includes html, "flex flex-row"
    assert_includes html, "w-full"
    
    # Look for the specific elements
    within("#preview-container") do
      justify_between_elements = all("div.justify-between")
      puts "Found #{justify_between_elements.length} justify-between elements"
      
      justify_between_elements.each_with_index do |element, index|
        puts "Element #{index + 1}:"
        puts "  Classes: #{element[:class]}"
        puts "  Text: #{element.text}"
        puts "  HTML: #{element.native.attribute('outerHTML')}"
        
        # Check if it has the expected structure
        children = element.all("div")
        puts "  Children count: #{children.length}"
        children.each_with_index do |child, child_index|
          puts "    Child #{child_index + 1}: #{child.text}"
        end
      end
    end
  end
  
  test "verify CSS is actually applied" do
    visit root_path
    sleep 2
    
    find("button", text: "Layout Demo").click
    sleep 3
    
    within("#preview-container") do
      justify_between_element = find("div.justify-between")
      
      # Get computed styles
      computed_styles = page.evaluate_script("window.getComputedStyle(arguments[0])", justify_between_element)
      
      puts "=== COMPUTED STYLES ==="
      puts "Display: #{computed_styles['display']}"
      puts "Flex-direction: #{computed_styles['flexDirection']}"
      puts "Justify-content: #{computed_styles['justifyContent']}"
      puts "Width: #{computed_styles['width']}"
      puts "=== END COMPUTED STYLES ==="
      
      # Verify the styles are actually applied
      assert_equal "flex", computed_styles['display']
      assert_equal "row", computed_styles['flexDirection']
      assert_equal "space-between", computed_styles['justifyContent']
      
      # If we get here, the CSS is being applied correctly
      puts "✅ CSS is being applied correctly!"
    end
  end
end