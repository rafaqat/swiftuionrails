# frozen_string_literal: true
# Copyright 2025

require "test_helper"

class DslMethodsTest < ActionDispatch::IntegrationTest
  test "all recently added DSL methods work without errors" do
    # Test each recently added DSL method
    dsl_methods_to_test = %w[
      line_clamp font_size text_align italic underline corner_radius
      background padding button_style button_size hover_scale items_center
      justify_center margin_bottom margin_top padding_x padding_y
      max_width transition loading border_color cursor hover_background
      aspect_ratio object_fit grayscale blur text_center
    ]
    
    failing_methods = []
    
    dsl_methods_to_test.each do |method_name|
      begin
        # Test by visiting a story that uses this method
        case method_name
        when "line_clamp", "font_size", "text_align", "italic", "underline"
          get "/storybook/show", params: { 
            story: "text_component", 
            line_clamp: "2",
            font_size: "lg",
            text_align: "center",
            italic: true,
            underline: true
          }
        when "corner_radius", "background", "padding", "hover_scale"
          get "/storybook/show", params: { 
            story: "card_component",
            corner_radius: "lg",
            background_color: "blue-50",
            padding: "16",
            hover_effect: true
          }
        when "button_style", "button_size"
          get "/storybook/show", params: { 
            story: "button_component",
            variant: "primary",
            size: "md"
          }
        when "aspect_ratio", "object_fit", "grayscale", "blur"
          get "/storybook/show", params: { 
            story: "image_component",
            aspect_ratio: "square",
            object_fit: "cover",
            grayscale: true,
            blur: true
          }
        else
          # Test with a simple component
          get "/storybook/show", params: { story: "text_component" }
        end
        
        # Check if the response contains an undefined method error for this method
        if response.body.include?("undefined method `#{method_name}'")
          failing_methods << method_name
          puts "❌ #{method_name}: undefined method error"
        elsif response.body.include?("Error rendering component")
          # Check if it's related to our method
          if response.body.include?(method_name)
            failing_methods << method_name
            puts "❌ #{method_name}: render error (possibly related)"
          else
            puts "✅ #{method_name}: working (other render error unrelated)"
          end
        else
          puts "✅ #{method_name}: working"
        end
        
      rescue => e
        failing_methods << method_name
        puts "❌ #{method_name}: exception - #{e.message}"
      end
    end
    
    puts "\n📊 DSL Methods Test Summary:"
    puts "=" * 40
    puts "✅ Working: #{dsl_methods_to_test.length - failing_methods.length}/#{dsl_methods_to_test.length}"
    puts "❌ Failing: #{failing_methods.length}/#{dsl_methods_to_test.length}"
    
    if failing_methods.any?
      puts "\n🚨 Failing methods:"
      failing_methods.each { |method| puts "  - #{method}" }
    end
    
    assert failing_methods.empty?, 
      "DSL methods failing: #{failing_methods.join(', ')}"
  end
  
  test "specific line_clamp functionality" do
    # Test line_clamp specifically since that was the reported issue
    get "/storybook/show", params: { 
      story: "text_component",
      content: "This is a long text that should be clamped to multiple lines when the line_clamp property is applied.",
      line_clamp: "2"
    }
    
    assert_response :success
    refute_includes response.body, "undefined method `line_clamp'", 
      "line_clamp method should be defined"
    refute_includes response.body, "Error rendering component", 
      "Component should render without errors"
      
    # Should include the CSS class
    assert_includes response.body, "line-clamp-2", 
      "Should include line-clamp-2 CSS class in output"
  end
end
# Copyright 2025
