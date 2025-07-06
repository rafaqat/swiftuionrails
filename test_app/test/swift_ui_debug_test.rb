# Copyright 2025
require "test_helper"

class SwiftUIDebugTest < ActiveSupport::TestCase
  test "debug swift_ui block execution" do
    # Create a proper view context
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # Test the exact code from the home view
    result = view.swift_ui do
      puts "=== Inside swift_ui block ==="
      puts "self.class: #{self.class}"
      puts "respond_to?(:vstack): #{respond_to?(:vstack)}"
      
      vstack_result = vstack(spacing: 24)
      puts "vstack_result.class: #{vstack_result.class}"
      puts "vstack_result.respond_to?(:p): #{vstack_result.respond_to?(:p)}"
      
      # Try to chain methods
      begin
        chained = vstack_result.p(8)
        puts "Chaining succeeded! chained.class: #{chained.class}"
        chained
      rescue => e
        puts "Chaining failed: #{e.class} - #{e.message}"
        puts e.backtrace[0..3].join("\n")
        raise
      end
    end
    
    puts "=== Result ==="
    puts "result.class: #{result.class}"
    puts "result: #{result.inspect}"
  end
  
  test "direct DSL usage" do
    # Test DSL directly without swift_ui helper
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    dsl_context = SwiftUIRails::DSLContext.new(view)
    
    vstack_result = dsl_context.vstack(spacing: 24)
    puts "Direct DSL vstack result: #{vstack_result.class}"
    
    chained = vstack_result.p(8).max_w("4xl").mx("auto")
    puts "Direct DSL chained result: #{chained.class}"
    
    html = chained.to_s
    puts "Direct DSL HTML: #{html}"
  end
end
# Copyright 2025
