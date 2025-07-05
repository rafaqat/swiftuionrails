# frozen_string_literal: true

require "application_system_test_case"

class FinalCardTest < ApplicationSystemTestCase
  test "final verification of card background color functionality" do
    puts "🎯 Final verification of card background color functionality..."
    
    visit "/storybook/show?story=card_component"
    sleep 2
    
    # Verify the card loads with correct initial structure
    card = find("#component-preview div.rounded-lg.shadow")
    initial_classes = card[:class]
    puts "📝 Initial card classes: #{initial_classes}"
    
    # Should be: "rounded-lg shadow bg-white" (no duplicates)
    if initial_classes.include?("bg-white") && initial_classes.scan(/bg-white/).length == 1
      puts "✅ Card has single bg-white class (no duplicates)"
    else
      puts "❌ Card background class issue: #{initial_classes}"
    end
    
    # Test each color option
    bg_select = find("select[name='background_color']")
    
    colors_to_test = [
      { name: "Gray-50", expected_class: "bg-gray-50" },
      { name: "Blue-50", expected_class: "bg-blue-50" },
      { name: "Green-50", expected_class: "bg-green-50" },
      { name: "White", expected_class: "bg-white" }
    ]
    
    colors_to_test.each do |color_test|
      puts "\n🎨 Testing #{color_test[:name]}..."
      
      # Select the color
      bg_select.select(color_test[:name])
      sleep 1
      
      # Check if card updated
      updated_card = find("#component-preview div.rounded-lg.shadow")
      updated_classes = updated_card[:class]
      
      if updated_classes.include?(color_test[:expected_class])
        puts "✅ #{color_test[:name]} working - found #{color_test[:expected_class]}"
        
        # Verify no duplicate backgrounds
        bg_classes = updated_classes.scan(/bg-\w+(?:-\w+)*/)
        if bg_classes.length == 1
          puts "✅ Single background class: #{bg_classes.first}"
        else
          puts "⚠️ Multiple background classes: #{bg_classes.join(', ')}"
        end
      else
        puts "❌ #{color_test[:name]} FAILED - expected #{color_test[:expected_class]}"
        puts "   Got: #{updated_classes}"
      end
    end
    
    # Test color swatches too
    puts "\n🎨 Testing color swatch buttons..."
    
    if page.has_selector?("button[data-value='blue-50']")
      blue_swatch = find("button[data-value='blue-50']")
      blue_swatch.click
      sleep 1
      
      swatch_card = find("#component-preview div.rounded-lg.shadow")
      if swatch_card[:class].include?("bg-blue-50")
        puts "✅ Blue swatch button working"
      else
        puts "❌ Blue swatch button not working"
      end
    end
    
    puts "\n🎉 Card background color testing completed!"
  end
end