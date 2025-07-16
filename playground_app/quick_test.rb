#!/usr/bin/env ruby

# Quick test to verify justify-between now works correctly

require_relative 'config/environment'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'

puts "=== TESTING JUSTIFY-BETWEEN FIX ==="

# Test the DSL directly
class TestJustifyBetween < SwiftUIRails::Component::Base
  swift_ui do
    div.bg("red-100").w("full").p(4) do
      # Test justify-between (should NOT have space-x-8)
      hstack(justify: :between) do
        div.bg("blue-500").text_color("white").p(2) do
          text("LEFT")
        end
        div.bg("green-500").text_color("white").p(2) do
          text("RIGHT")
        end
      end
    end
  end
end

# Test HTML generation
html = ApplicationController.render(TestJustifyBetween.new)
puts "Generated HTML for justify-between:"
puts html

# Check for the fix
if html.include?("justify-between") && !html.include?("space-x-8")
  puts "✅ SUCCESS: justify-between class found without space-x-8"
else
  puts "❌ FAILED: Still has space-x-8 or missing justify-between"
end

# Test that justify-start still gets space-x-8
class TestJustifyStart < SwiftUIRails::Component::Base
  swift_ui do
    div.bg("red-100").w("full").p(4) do
      # Test justify-start (should have space-x-8)
      hstack(justify: :start) do
        div.bg("blue-500").text_color("white").p(2) do
          text("LEFT")
        end
        div.bg("green-500").text_color("white").p(2) do
          text("RIGHT")
        end
      end
    end
  end
end

html_start = ApplicationController.render(TestJustifyStart.new)
puts "\nGenerated HTML for justify-start:"
puts html_start

# Check that justify-start still has spacing
if html_start.include?("justify-start") && html_start.include?("space-x-8")
  puts "✅ SUCCESS: justify-start class found with space-x-8"
else
  puts "❌ FAILED: Missing space-x-8 for justify-start"
end

puts "\n=== END TEST ==="