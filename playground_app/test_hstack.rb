#!/usr/bin/env ruby
require_relative 'config/environment'

# Test the hstack method with justify parameter
class TestHstackComponent < SwiftUIRails::Component::Base
  swift_ui do
    hstack(justify: :between) do
      text("Left")
      text("Right")
    end
  end
end

# Render the component
component = TestHstackComponent.new
html = component.call
puts "Generated HTML:"
puts html
puts ""

# Check if the classes include justify-between and w-full
if html.include?('justify-between') && html.include?('w-full')
  puts "✅ SUCCESS: hstack with justify: :between generates correct classes"
else
  puts "❌ FAILED: hstack with justify: :between does not generate correct classes"
end

# Also test if the specific classes are present
expected_classes = ['flex', 'flex-row', 'justify-between', 'w-full']
missing_classes = expected_classes.reject { |cls| html.include?(cls) }

if missing_classes.empty?
  puts "✅ All expected classes are present: #{expected_classes.join(', ')}"
else
  puts "❌ Missing classes: #{missing_classes.join(', ')}"
end