#!/usr/bin/env ruby

# Comprehensive test to verify all justify options work correctly

require_relative 'config/environment'

puts "=== COMPREHENSIVE JUSTIFY OPTION TEST ==="

# Test each justify option
[:start, :center, :end, :between, :around, :evenly].each do |justify|
  puts "\n--- Testing justify: #{justify} ---"
  
  # Create a test component for each justify option
  test_class = Class.new(SwiftUIRails::Component::Base) do
    define_method :call do
      swift_ui do
        div.bg("gray-100").w("full").p(4) do
          hstack(justify: justify) do
            div.bg("blue-500").text_color("white").p(2) do
              text("A")
            end
            div.bg("green-500").text_color("white").p(2) do
              text("B")
            end
            div.bg("purple-500").text_color("white").p(2) do
              text("C")
            end
          end
        end
      end
    end
  end
  
  # Generate HTML
  html = ApplicationController.render(test_class.new)
  
  # Extract just the hstack part
  if html =~ /<div class="([^"]*justify-#{justify}[^"]*)">/
    classes = $1
    puts "Classes: #{classes}"
    
    # Check expected behavior
    case justify
    when :start, :center, :end
      if classes.include?("space-x-8")
        puts "✅ CORRECT: Has space-x-8 for justify-#{justify}"
      else
        puts "❌ ERROR: Missing space-x-8 for justify-#{justify}"
      end
      
      if classes.include?("w-full")
        puts "⚠️  UNEXPECTED: Has w-full for justify-#{justify} (not needed but harmless)"
      else
        puts "✅ CORRECT: No w-full for justify-#{justify}"
      end
    when :between, :around, :evenly
      if classes.include?("space-x-8")
        puts "❌ ERROR: Has space-x-8 for justify-#{justify} (should not have it)"
      else
        puts "✅ CORRECT: No space-x-8 for justify-#{justify}"
      end
      
      if classes.include?("w-full")
        puts "✅ CORRECT: Has w-full for justify-#{justify}"
      else
        puts "❌ ERROR: Missing w-full for justify-#{justify}"
      end
    end
  else
    puts "❌ ERROR: Could not find justify-#{justify} class in HTML"
  end
end

puts "\n=== TESTING VSTACK JUSTIFY OPTIONS ==="

# Test vstack justify options too
[:start, :center, :end, :between, :around, :evenly].each do |justify|
  puts "\n--- Testing vstack justify: #{justify} ---"
  
  test_class = Class.new(SwiftUIRails::Component::Base) do
    define_method :call do
      swift_ui do
        div.bg("gray-100").w("full").h("64").p(4) do
          vstack(justify: justify) do
            div.bg("blue-500").text_color("white").p(2) do
              text("A")
            end
            div.bg("green-500").text_color("white").p(2) do
              text("B")
            end
            div.bg("purple-500").text_color("white").p(2) do
              text("C")
            end
          end
        end
      end
    end
  end
  
  # Generate HTML  
  html = ApplicationController.render(test_class.new)
  
  # Extract just the vstack part
  if html =~ /<div class="([^"]*justify-#{justify}[^"]*)">/
    classes = $1
    puts "Classes: #{classes}"
    
    # Check expected behavior
    case justify
    when :start, :center, :end
      if classes.include?("space-y-8")
        puts "✅ CORRECT: Has space-y-8 for vstack justify-#{justify}"
      else
        puts "❌ ERROR: Missing space-y-8 for vstack justify-#{justify}"
      end
      
      if classes.include?("h-full")
        puts "⚠️  UNEXPECTED: Has h-full for vstack justify-#{justify} (not needed but harmless)"
      else
        puts "✅ CORRECT: No h-full for vstack justify-#{justify}"
      end
    when :between, :around, :evenly
      if classes.include?("space-y-8")
        puts "❌ ERROR: Has space-y-8 for vstack justify-#{justify} (should not have it)"
      else
        puts "✅ CORRECT: No space-y-8 for vstack justify-#{justify}"
      end
      
      if classes.include?("h-full")
        puts "✅ CORRECT: Has h-full for vstack justify-#{justify}"
      else
        puts "❌ ERROR: Missing h-full for vstack justify-#{justify}"
      end
    end
  else
    puts "❌ ERROR: Could not find justify-#{justify} class in HTML"
  end
end

puts "\n=== TEST COMPLETE ==="