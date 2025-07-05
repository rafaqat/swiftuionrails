require "test_helper"

class DSLContextTest < ActiveSupport::TestCase
  include ActionView::Helpers
  include SwiftUIRails::Helpers
  
  test "DSL context returns Element instances" do
    # Simulate a view context
    view_context = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view_context.extend(SwiftUIRails::Helpers)
    
    # Test the DSL directly
    dsl_context = SwiftUIRails::DSLContext.new(view_context)
    
    # Test that vstack returns an Element
    result = dsl_context.vstack(spacing: 24)
    puts "vstack result class: #{result.class}"
    assert_instance_of SwiftUIRails::DSL::Element, result
    
    # Test method chaining
    result_with_padding = result.p(8)
    puts "vstack.p(8) result class: #{result_with_padding.class}"
    assert_instance_of SwiftUIRails::DSL::Element, result_with_padding
    
    # Test that it renders to HTML
    html = result_with_padding.to_s
    puts "HTML output: #{html}"
    assert_match /class="[^"]*flex flex-col/, html
    assert_match /p-8/, html
  end
  
  test "swift_ui helper works correctly" do
    view_context = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view_context.extend(SwiftUIRails::Helpers)
    
    result = view_context.swift_ui do
      vstack(spacing: 24).p(8).max_w("4xl").mx("auto") do
        text("Test")
      end
    end
    
    puts "swift_ui result: #{result.inspect}"
    assert result.html_safe?
  end
end
# Copyright 2025
