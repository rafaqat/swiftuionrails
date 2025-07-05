require "test_helper"

class ChainedBlocksTest < ActiveSupport::TestCase
  test "card with chained padding and block" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # This is exactly how it's used in the home page
    result = view.swift_ui do
      card(elevation: 2).p(6) { 
        text("Inside card with padding")
      }
    end
    
    puts "\n=== Card with chained padding result ==="
    puts result
    
    assert result.include?("Inside card with padding"), "Should contain text inside card"
    assert result.include?("p-6"), "Should have padding class"
    assert result.include?("shadow-md"), "Should have elevation shadow"
  end
  
  test "complex nested structure like home page" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    result = view.swift_ui do
      vstack(spacing: 24).p(8).max_w("4xl").mx("auto") { 
        text("Header")
        
        card(elevation: 2).p(6) { 
          vstack(spacing: 16) { 
            text("Inside nested vstack")
            
            hstack(spacing: 12) { 
              button("Button 1")
              button("Button 2")
            }
          }
        }
      }
    end
    
    puts "\n=== Complex nested structure result ==="
    puts result
    
    assert result.include?("Header"), "Should include header text"
    assert result.include?("bg-white rounded-lg shadow-md"), "Should include card styling"
    assert result.include?("flex flex-col"), "Should include vstack styling"
    assert result.include?("p-8"), "Should include padding"
  end
end
# Copyright 2025
