#!/usr/bin/env ruby

# Debug script to test playground DSL processing vs component rendering

require_relative 'config/environment'

# Test the playground's DSL processing
puts "=== TESTING PLAYGROUND DSL PROCESSING ==="
puts

# Create the same temp class as playground does
temp_class_name = "PlaygroundComponent#{SecureRandom.hex(8)}"
code = <<~RUBY
  swift_ui do
    div.border.border_color("red-500").p(0) do
      hstack(justify: :between) do
        text("LEFT")
        text("RIGHT")
      end
    end
  end
RUBY

component_class = Class.new(ApplicationComponent) do
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  class_eval <<-RUBY
    def call
      #{code}
    end
  RUBY
end

# Give the class a name to avoid nil name issues
Object.const_set(temp_class_name, component_class)

# Test rendering the way playground does
puts "=== PLAYGROUND RENDERING (.to_s) ==="
playground_html = component_class.new.call.to_s
puts "Generated HTML:"
puts playground_html
puts

# Test rendering the way Rails would
puts "=== RAILS RENDERING (ApplicationController.render) ==="
begin
  rails_html = ApplicationController.render(component_class.new)
  puts "Generated HTML:"
  puts rails_html
  puts
rescue => e
  puts "Error: #{e.message}"
end

# Clean up the temporary constant
Object.send(:remove_const, temp_class_name)

puts
puts "=== COMPARISON ==="
puts "Playground method length: #{playground_html.length}"
puts "Rails method length: #{rails_html.length rescue 'N/A'}"

# Check if they contain the same classes
if playground_html.include?("justify-between")
  puts "✅ Playground: Contains justify-between class"
else
  puts "❌ Playground: Missing justify-between class"
end

if playground_html.include?("w-full")
  puts "✅ Playground: Contains w-full class"
else
  puts "❌ Playground: Missing w-full class"
end

if playground_html.include?("space-x-8")
  puts "✅ Playground: Contains space-x-8 class"
else
  puts "❌ Playground: Missing space-x-8 class"
end

puts
puts "=== PARSING PLAYGROUND HTML ==="

# Parse the HTML to understand the structure
require 'nokogiri'

begin
  doc = Nokogiri::HTML::DocumentFragment.parse(playground_html)
  
  # Find the hstack element
  hstack_element = doc.at_css('.justify-between')
  
  if hstack_element
    puts "✅ Found hstack element with justify-between class"
    puts "Full classes: #{hstack_element[:class]}"
    puts "Inner HTML: #{hstack_element.inner_html}"
    puts "Text content: '#{hstack_element.text}'"
    
    # Check for text elements
    text_elements = hstack_element.css('span')
    puts "Text elements found: #{text_elements.length}"
    text_elements.each_with_index do |elem, i|
      puts "  Element #{i + 1}: '#{elem.text}'"
    end
  else
    puts "❌ No element with justify-between class found"
    puts "Full HTML: #{playground_html}"
  end
rescue => e
  puts "Error parsing HTML: #{e.message}"
end

puts
puts "=== END DEBUG ==="