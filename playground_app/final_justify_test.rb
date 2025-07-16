#!/usr/bin/env ruby

# Final test to verify justify options work correctly

require_relative 'config/environment'

puts "=== TESTING HSTACK JUSTIFY OPTIONS ==="

# Test each justify option
[:start, :center, :end, :between, :around, :evenly].each do |justify|
  puts "\n--- Testing hstack justify: #{justify} ---"
  
  # Create a temporary component class
  temp_class_name = "TestComponent#{SecureRandom.hex(4)}"
  
  component_class = Class.new(SwiftUIRails::Component::Base) do
    define_method :initialize do |justify_option|
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
  
  # Give the class a name
  Object.const_set(temp_class_name, component_class)
  
  # Generate HTML and extract the hstack classes
  component = component_class.new(justify)
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
      
      puts has_space_x ? "✅ Has space-x-8 (correct)" : "❌ Missing space-x-8"
      puts has_w_full ? "⚠️  Has w-full (unexpected but not harmful)" : "✅ No w-full (correct)"
    when :between, :around, :evenly
      has_space_x = classes.include?("space-x-8")
      has_w_full = classes.include?("w-full")
      
      puts has_space_x ? "❌ Has space-x-8 (BUG: should not have this)" : "✅ No space-x-8 (correct)"
      puts has_w_full ? "✅ Has w-full (correct)" : "❌ Missing w-full"
    end
  else
    puts "❌ Could not find justify-#{justify} class"
  end
  
  # Clean up
  Object.send(:remove_const, temp_class_name)
end

puts "\n=== TESTING VSTACK JUSTIFY OPTIONS ==="

# Test vstack justify options
[:start, :center, :end, :between, :around, :evenly].each do |justify|
  puts "\n--- Testing vstack justify: #{justify} ---"
  
  # Create a temporary component class
  temp_class_name = "TestVStackComponent#{SecureRandom.hex(4)}"
  
  component_class = Class.new(SwiftUIRails::Component::Base) do
    define_method :initialize do |justify_option|
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
  
  # Give the class a name
  Object.const_set(temp_class_name, component_class)
  
  # Generate HTML and extract the vstack classes
  component = component_class.new(justify)
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
      
      puts has_space_y ? "✅ Has space-y-8 (correct)" : "❌ Missing space-y-8"
      puts has_h_full ? "⚠️  Has h-full (unexpected but not harmful)" : "✅ No h-full (correct)"
    when :between, :around, :evenly
      has_space_y = classes.include?("space-y-8")
      has_h_full = classes.include?("h-full")
      
      puts has_space_y ? "❌ Has space-y-8 (BUG: should not have this)" : "✅ No space-y-8 (correct)"
      puts has_h_full ? "✅ Has h-full (correct)" : "❌ Missing h-full"
    end
  else
    puts "❌ Could not find justify-#{justify} class"
  end
  
  # Clean up
  Object.send(:remove_const, temp_class_name)
end

puts "\n=== TEST COMPLETE ==="