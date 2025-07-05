# Copyright 2025
require "test_helper"

class BlockBindingTest < ActiveSupport::TestCase
  test "demonstrate block binding issue and workarounds" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # Problem: block binds to last method
    puts "=== Problem: Block binds to mx(), not vstack ==="
    result1 = view.swift_ui do
      vstack(spacing: 24).p(8).mx("auto") { 
        text("This won't work as expected")
      }
    end
    puts result1
    puts "vstack is empty? #{!result1.include?('This won')}"
    
    # Workaround 1: Use parentheses
    puts "\n=== Workaround 1: Parentheses ==="
    result2 = view.swift_ui do
      (vstack(spacing: 24) { 
        text("This works!")
      }).p(8).mx("auto")
    end
    puts result2
    
    # Workaround 2: Store intermediate result
    puts "\n=== Workaround 2: Store intermediate ==="
    result3 = view.swift_ui do
      container = vstack(spacing: 24) { 
        text("This also works!")
      }
      container.p(8).mx("auto")
    end
    puts result3
    
    # Workaround 3: Chain after block
    puts "\n=== Workaround 3: Chain after block ==="
    result4 = view.swift_ui do
      vstack(spacing: 24) { 
        text("Chain after block")
      }.p(8).mx("auto")
    end
    puts result4
  end
  
  test "fix home page pattern" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # Fixed version of home page pattern
    result = view.swift_ui do
      vstack(spacing: 24) { 
        text("Header")
        
        card(elevation: 2) { 
          vstack(spacing: 16) { 
            text("Inside nested vstack")
            button("Button 1")
          }
        }.p(6)  # Chain padding after the block
      }.p(8).max_w("4xl").mx("auto")  # Chain these after the block
    end
    
    puts "\n=== Fixed home page pattern ==="
    puts result
    
    assert result.include?("Header")
    assert result.include?("Inside nested vstack")
    assert result.include?("Button 1")
    assert result.include?("p-8")
    assert result.include?("max-w-4xl")
  end
end
# Copyright 2025
