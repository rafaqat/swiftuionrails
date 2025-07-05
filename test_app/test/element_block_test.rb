require "test_helper"

class ElementBlockTest < ActiveSupport::TestCase
  test "element block execution" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    dsl_context = SwiftUIRails::DSLContext.new(view)
    
    # Test 1: Simple block
    puts "=== Test 1: Simple block ==="
    element = dsl_context.vstack { 
      puts "Inside vstack block - self.class: #{self.class}"
      dsl_context.text("Test content")
    }
    puts "Element class: #{element.class}"
    html = element.to_s
    puts "HTML: #{html}"
    puts "Contains 'Test content': #{html.include?('Test content')}"
    
    # Test 2: Block with multiple elements
    puts "\n=== Test 2: Multiple elements ==="
    element2 = dsl_context.vstack { 
      dsl_context.text("Line 1")
      dsl_context.text("Line 2")
    }
    html2 = element2.to_s
    puts "HTML: #{html2}"
    puts "Contains 'Line 1': #{html2.include?('Line 1')}"
    puts "Contains 'Line 2': #{html2.include?('Line 2')}"
    
    # Test 3: Check what the block returns
    puts "\n=== Test 3: Block return value ==="
    element3 = dsl_context.vstack do
      result1 = dsl_context.text("First")
      result2 = dsl_context.text("Second")
      puts "result1 class: #{result1.class}"
      puts "result2 class: #{result2.class}"
      # What does the block return?
      [result1, result2]
    end
    html3 = element3.to_s
    puts "HTML: #{html3}"
  end
end
# Copyright 2025
