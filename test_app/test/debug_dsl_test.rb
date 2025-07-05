require "test_helper"

class DebugDslTest < ViewComponent::TestCase
  class TestComponent < ApplicationComponent
    swift_ui do
      puts "=== Debug swift_ui block ==="
      puts "self.class: #{self.class}"
      puts "self.respond_to?(:div): #{self.respond_to?(:div)}"
      puts "self.respond_to?(:create_element): #{self.respond_to?(:create_element, true)}"
      
      # Check ancestors
      puts "Ancestors:"
      self.class.ancestors.each do |a|
        puts "  - #{a}"
      end
      
      # Check if DSL methods are available through method source
      if self.class.included_modules.include?(SwiftUIRails::DSL)
        puts "SwiftUIRails::DSL is included"
      end
      
      # Check where div method comes from
      if respond_to?(:div)
        puts "div method source: #{method(:div).source_location}"
      end
      
      # Try calling create_element directly
      begin
        elem = create_element(:div, nil, {})
        puts "create_element returned: #{elem.class}"
        puts "elem.respond_to?(:tw): #{elem.respond_to?(:tw)}"
        
        # Try to build the same structure ProductCardComponent wants
        chained_elem = elem.tw("group").relative
        puts "After chaining: #{chained_elem.class}"
        
        # Just return the element
        chained_elem
      rescue => e
        puts "create_element Error: #{e.class} - #{e.message}"
        puts e.backtrace.first(3).join("\n")
        text("Debug test fallback")
      end
    end
  end
  
  def test_debug_dsl
    component = TestComponent.new
    render_inline(component)
    
    assert_selector "div"  # Should have at least one div
  end
end