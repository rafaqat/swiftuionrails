#!/usr/bin/env ruby

# Simple test to verify justify options work correctly

require_relative 'config/environment'

puts "=== TESTING JUSTIFY OPTIONS ==="

# Test each justify option
[:start, :center, :end, :between, :around, :evenly].each do |justify|
  puts "\n--- Testing justify: #{justify} ---"
  
  # Create a simple test component
  class TestComponent < SwiftUIRails::Component::Base
    def initialize(justify_option)
      @justify_option = justify_option
    end
    
    swift_ui do
      hstack(justify: @justify_option) do
        text("A")
        text("B")
        text("C")
      end
    end
  end
  
  # Generate HTML and extract the hstack classes
  component = TestComponent.new(justify)
  html = component.call.to_s
  
  # Extract classes
  if html =~ /class="([^"]*justify-#{justify}[^"]*)"/
    classes = $1
    puts "Classes: #{classes}"
    
    # Check expectations
    case justify
    when :start, :center, :end
      has_space_x = classes.include?("space-x-8")
      has_w_full = classes.include?("w-full")
      
      puts has_space_x ? "✅ Has space-x-8" : "❌ Missing space-x-8"
      puts has_w_full ? "⚠️  Has w-full (unexpected)" : "✅ No w-full"
    when :between, :around, :evenly
      has_space_x = classes.include?("space-x-8")
      has_w_full = classes.include?("w-full")
      
      puts has_space_x ? "❌ Has space-x-8 (should not)" : "✅ No space-x-8"
      puts has_w_full ? "✅ Has w-full" : "❌ Missing w-full"
    end
  else
    puts "❌ Could not find justify-#{justify} class"
  end
end

puts "\n=== TESTING VSTACK OPTIONS ==="

# Test vstack justify options
[:start, :center, :end, :between, :around, :evenly].each do |justify|
  puts "\n--- Testing vstack justify: #{justify} ---"
  
  class TestVStackComponent < SwiftUIRails::Component::Base
    def initialize(justify_option)
      @justify_option = justify_option
    end
    
    swift_ui do
      vstack(justify: @justify_option) do
        text("A")
        text("B")
        text("C")
      end
    end
  end
  
  # Generate HTML and extract the vstack classes
  component = TestVStackComponent.new(justify)
  html = component.call.to_s
  
  # Extract classes
  if html =~ /class="([^"]*justify-#{justify}[^"]*)"/
    classes = $1
    puts "Classes: #{classes}"
    
    # Check expectations
    case justify
    when :start, :center, :end
      has_space_y = classes.include?("space-y-8")
      has_h_full = classes.include?("h-full")
      
      puts has_space_y ? "✅ Has space-y-8" : "❌ Missing space-y-8"
      puts has_h_full ? "⚠️  Has h-full (unexpected)" : "✅ No h-full"
    when :between, :around, :evenly
      has_space_y = classes.include?("space-y-8")
      has_h_full = classes.include?("h-full")
      
      puts has_space_y ? "❌ Has space-y-8 (should not)" : "✅ No space-y-8"
      puts has_h_full ? "✅ Has h-full" : "❌ Missing h-full"
    end
  else
    puts "❌ Could not find justify-#{justify} class"
  end
end

puts "\n=== TEST COMPLETE ==="