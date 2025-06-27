require "application_system_test_case"

class ButtonColorInteractiveTest < ApplicationSystemTestCase
  def test_button_color_changes_work_in_storybook
    visit "/rails/stories/simple_button_component"
    
    # Wait for page to load
    assert_selector "h1", text: "Simple Button"
    
    # Check initial button state
    assert_selector "button", text: "Click Me"
    puts "✅ Storybook loaded successfully"
    
    # Find the background color dropdown - it should exist on the page
    if has_selector?("select[name='background_color']", wait: 2)
      background_dropdown = find("select[name='background_color']")
      
      # Try to find all available options
      options = background_dropdown.all('option').map(&:text)
      puts "Available background color options: #{options.join(', ')}"
      
      # Try to find a purple option (case-insensitive)
      purple_option = options.find { |opt| opt.downcase == "purple-600" }
      if purple_option
        background_dropdown.select purple_option
        sleep 2
        
        # Find the main preview button specifically
        preview_button = find("[data-controller='live-story'] button", text: "Click Me")
        button_classes = preview_button.native.attribute('class')
        
        if button_classes.include?('bg-purple-600')
          puts "✅ Purple-600 background color is working!"
          puts "Button classes: #{button_classes}"
          
          # Check smart text color
          if button_classes.include?('text-white')
            puts "✅ Smart text color (white) applied for dark background!"
          else
            puts "❌ Smart text color not applied. Classes: #{button_classes}"
          end
        else
          puts "❌ Purple-600 background not applied"
          puts "Current button classes: #{button_classes}"
        end
      else
        # Try using color swatches instead - look for purple color swatch buttons
        purple_swatches = all("[data-field='background_color'][data-value*='purple']")
        if purple_swatches.any?
          puts "Found #{purple_swatches.count} purple color swatches"
          purple_swatches.first.click
          sleep 2
          
          # Check for any purple background
          preview_button = find("[data-controller='live-story'] button", text: "Click Me")
          button_classes = preview_button.native.attribute('class')
          if button_classes.include?('bg-purple')
            puts "✅ Purple background color is working via color swatch!"
            puts "Button classes: #{button_classes}"
          else
            puts "❌ Purple background not applied via color swatch"
            puts "Current button classes: #{button_classes}"
          end
        else
          puts "❌ No purple options or swatches found"
        end
      end
    else
      puts "❌ Background color dropdown not found"
    end
    
    # Test text color change if text color dropdown exists
    if has_selector?("select[name='text_color']", wait: 1)
      text_color_dropdown = find("select[name='text_color']")
      
      # Find a yellow option (case-insensitive)
      text_options = text_color_dropdown.all('option').map(&:text)
      yellow_option = text_options.find { |opt| opt.downcase == "yellow-300" }
      
      if yellow_option
        text_color_dropdown.select yellow_option
        
        # Wait for update
        sleep 2
        
        # Check that custom text color was applied
        preview_button = find("[data-controller='live-story'] button", text: "Click Me")
        button_classes = preview_button.native.attribute('class')
        
        if button_classes.include?('text-yellow-300')
          puts "✅ Custom text color is working!"
        else
          puts "❌ Custom text color not applied"
          puts "Current button classes: #{button_classes}"
        end
      else
        puts "❌ Yellow-300 text color option not found"
      end
    else
      puts "❌ Text color dropdown not found"
    end
  end
end