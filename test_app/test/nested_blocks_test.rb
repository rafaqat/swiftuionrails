# Copyright 2025
require "test_helper"

class NestedBlocksTest < ActiveSupport::TestCase
  test "nested blocks work correctly" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # Test nested blocks
    result = view.swift_ui do
      vstack do
        puts "=== In vstack block ==="
        text("Level 1")
        
        card do
          puts "=== In card block ==="
          text("Level 2 - inside card")
          
          hstack do
            puts "=== In hstack block ==="
            text("Level 3 - inside hstack")
          end
        end
      end
    end
    
    puts "\n=== Result HTML ==="
    puts result
    
    # Check for content at each level
    assert result.include?("Level 1"), "Should contain Level 1 text"
    assert result.include?("Level 2"), "Should contain Level 2 text"
    assert result.include?("Level 3"), "Should contain Level 3 text"
  end
  
  test "home page example simplified" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    result = view.swift_ui do
      vstack do
        text("Header")
        card(elevation: 2) do
          text("Inside card")
        end
      end
    end
    
    puts "\n=== Simplified home page result ==="
    puts result
    
    assert result.include?("Header")
    assert result.include?("Inside card")
    assert result.include?("shadow-md") # card with elevation 2
  end
end
# Copyright 2025
