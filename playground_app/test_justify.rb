#!/usr/bin/env ruby

# Test the hstack justify functionality in the playground context
require_relative 'config/environment'

# Test code that should work in the playground
test_code = <<~RUBY
  swift_ui do
    vstack(spacing: 16) do
      text("Testing hstack justify parameter")
        .font_size("xl")
        .font_weight("bold")
        .text_color("blue-600")
        .mb(4)
      
      # Test different justify values
      hstack(justify: :between) do
        text("Left")
          .bg("red-200")
          .p(2)
          .rounded("md")
        text("Right")
          .bg("blue-200")
          .p(2)
          .rounded("md")
      end
      .bg("gray-100")
      .p(4)
      .rounded("lg")
      .mb(4)
      
      hstack(justify: :center) do
        text("Center")
          .bg("green-200")
          .p(2)
          .rounded("md")
      end
      .bg("gray-100")
      .p(4)
      .rounded("lg")
      .mb(4)
      
      hstack(justify: :start) do
        text("Start")
          .bg("purple-200")
          .p(2)
          .rounded("md")
      end
      .bg("gray-100")
      .p(4)
      .rounded("lg")
    end
  end
RUBY

puts "Test code:"
puts test_code
puts ""
puts "=" * 50
puts ""

# Create a component class like the playground does
temp_class_name = "TestJustifyComponent"
component_class = Class.new(ApplicationComponent) do
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  class_eval <<-RUBY
    def call
      #{test_code}
    end
  RUBY
end

# Give the class a name
Object.const_set(temp_class_name, component_class)

# Render the component
begin
  rendered_html = component_class.new.call.to_s
  puts "Rendered HTML:"
  puts rendered_html
  puts ""
  
  # Check for expected classes
  if rendered_html.include?('justify-between') && rendered_html.include?('w-full')
    puts "✅ SUCCESS: hstack with justify: :between works correctly"
  else
    puts "❌ FAILED: hstack with justify: :between not working"
  end
  
  if rendered_html.include?('justify-center')
    puts "✅ SUCCESS: hstack with justify: :center works correctly"
  else
    puts "❌ FAILED: hstack with justify: :center not working"
  end
  
  if rendered_html.include?('justify-start')
    puts "✅ SUCCESS: hstack with justify: :start works correctly"
  else
    puts "❌ FAILED: hstack with justify: :start not working"
  end
  
rescue => e
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.first(5)
ensure
  # Clean up
  Object.send(:remove_const, temp_class_name) if defined?(Object.const_defined?(temp_class_name))
end