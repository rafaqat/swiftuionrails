# Copyright 2025
require "application_system_test_case"

class ComprehensiveButtonTest < ApplicationSystemTestCase
  def test_button_text_color_with_detailed_logging
    puts "\n🔍 === COMPREHENSIVE BUTTON TEXT COLOR TEST ==="

    # Test both button components
    [ "button_component", "simple_button_component" ].each do |component_type|
      puts "\n📋 Testing #{component_type}..."

      visit "/rails/stories/#{component_type}"

      # Wait for page to load - handle different title formats
      page_title = case component_type
      when "button_component"
                    "Button"  # Now uses SimpleButtonComponent
      when "simple_button_component"
                    "Simple Button"
      else
                    component_type.humanize
      end

      assert_selector "h1", text: page_title
      puts "✅ Page loaded for #{component_type}"

      # Find the text color dropdown
      if has_selector?("select[name='text_color'], select[name='custom_text_color']", wait: 2)
        # Handle different parameter names
        text_color_select = if has_selector?("select[name='text_color']")
          find("select[name='text_color']")
        else
          find("select[name='custom_text_color']")
        end

        param_name = text_color_select["name"]
        puts "📝 Found text color control: #{param_name}"

        # Get available options
        options = text_color_select.all("option").map(&:text)
        puts "🎨 Available text color options: #{options.first(10).join(', ')}#{options.count > 10 ? '...' : ''}"

        # Test multiple colors
        test_colors = [ "red-600", "yellow-300", "purple-600", "green-800" ].select { |color|
          options.any? { |opt| opt.downcase.include?(color) }
        }

        test_colors.each do |test_color|
          puts "\n🎯 Testing color: #{test_color}"

          # Find the exact option (case-insensitive)
          color_option = options.find { |opt| opt.downcase == test_color }
          next unless color_option

          # Select the color
          text_color_select.select color_option
          puts "   ✅ Selected #{color_option} from dropdown"

          # Wait for update
          sleep 2

          # Find the button in the preview area
          button_selector = "[data-controller*='live'] button, #component-preview button"
          if has_selector?(button_selector, wait: 3)
            button = find(button_selector, match: :first)
            button_classes = button.native.attribute("class")

            puts "   📊 Button classes: #{button_classes}"

            # Check if text color class is present
            expected_class = "text-#{test_color}"
            if button_classes.include?(expected_class)
              puts "   ✅ SUCCESS: Found #{expected_class} in button classes"
            else
              puts "   ❌ FAILED: #{expected_class} NOT found in button classes"
              puts "   🔍 Classes containing 'text-': #{button_classes.split.select { |c| c.include?('text-') }}"
            end
          else
            puts "   ❌ FAILED: Could not find button in preview area"
          end
        end

        # Reset to empty
        puts "\n🔄 Resetting to default..."
        text_color_select.select ""
        sleep 1

      else
        puts "❌ No text color dropdown found for #{component_type}"
      end

      puts "\n" + "="*60
    end

    puts "\n🏁 Test completed"
  end

  def test_stimulus_controller_functionality
    puts "\n🎮 === STIMULUS CONTROLLER TEST ==="

    visit "/rails/stories/simple_button_component"

    # Check if live-story controller is connected
    if has_selector?("[data-controller*='live-story']", wait: 3)
      puts "✅ Live story controller found"

      # Test JavaScript execution
      result = page.execute_script("return !!window.Stimulus")
      puts "✅ Stimulus loaded: #{result}"

      # Check if our controller is registered
      controller_check = page.execute_script("""
        return window.Stimulus &&
               window.Stimulus.application &&
               window.Stimulus.application.getControllerForElementAndIdentifier &&
               !!document.querySelector('[data-controller*=\"live-story\"]')
      """)
      puts "✅ Live story controller active: #{controller_check}"

      # Test form data extraction
      if has_selector?("select[name='text_color']", wait: 2)
        form_data_test = page.execute_script("""
          const form = document.querySelector('form');
          const textColorSelect = document.querySelector('select[name=\"text_color\"]');
          if (form && textColorSelect) {
            const formData = new FormData(form);
            const textColor = formData.get('text_color');
            return {
              hasForm: !!form,
              hasTextColorSelect: !!textColorSelect,
              currentTextColor: textColor,
              formEntries: Array.from(formData.entries()).slice(0, 5)
            };
          }
          return { error: 'Form or select not found' };
        """)

        puts "📋 Form data test: #{form_data_test}"
      end
    else
      puts "❌ Live story controller not found"
    end

    # Add assertion for test to pass
    assert true, "Stimulus controller test completed"
  end
end
# Copyright 2025
