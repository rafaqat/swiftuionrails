#!/usr/bin/env ruby

# Debug script to test hstack justify: :between HTML generation

require_relative 'config/environment'

# Create a simple test component to check hstack rendering
class TestComponent < SwiftUIRails::Component::Base
  swift_ui do
    div.border.border_color("red-500").p(0) do
      hstack(justify: :between) do
        text("LEFT")
        text("RIGHT")
      end
    end
  end
end

# Test rendering
puts "=== TESTING HSTACK HTML GENERATION ==="
puts

# Create component instance
component = TestComponent.new

# Use Rails console to render it  
html = ApplicationController.render(component)
puts "Generated HTML:"
puts html
puts

# Check for expected classes
if html.include?("justify-between")
  puts "✅ SUCCESS: Contains justify-between class"
else
  puts "❌ FAILED: Missing justify-between class"
end

if html.include?("w-full")
  puts "✅ SUCCESS: Contains w-full class"
else
  puts "❌ FAILED: Missing w-full class"
end

if html.include?("LEFT") && html.include?("RIGHT")
  puts "✅ SUCCESS: Contains LEFT and RIGHT text"
else
  puts "❌ FAILED: Missing LEFT/RIGHT text"
end

if html.include?("flex flex-row")
  puts "✅ SUCCESS: Contains flex flex-row classes"
else
  puts "❌ FAILED: Missing flex flex-row classes"
end

puts
puts "=== PARSING HTML FOR DETAILED ANALYSIS ==="

# Try to parse the HTML to understand the structure
require 'nokogiri'

begin
  doc = Nokogiri::HTML(html)
  
  # Find the hstack element
  hstack_element = doc.at_css('.justify-between')
  
  if hstack_element
    puts "✅ Found hstack element with justify-between class"
    puts "Full classes: #{hstack_element[:class]}"
    puts "Inner HTML: #{hstack_element.inner_html}"
    
    # Check for text elements
    text_elements = hstack_element.css('span')
    puts "Text elements found: #{text_elements.length}"
    text_elements.each_with_index do |elem, i|
      puts "  Element #{i + 1}: '#{elem.text}'"
    end
  else
    puts "❌ No element with justify-between class found"
    
    # Check what classes are actually present
    all_divs = doc.css('div')
    puts "All div elements and their classes:"
    all_divs.each_with_index do |div, i|
      classes = div[:class] || "no-class"
      puts "  Div #{i + 1}: #{classes}"
    end
  end
rescue => e
  puts "Error parsing HTML: #{e.message}"
end

puts
puts "=== END DEBUG ==="