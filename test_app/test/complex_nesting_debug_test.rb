# Copyright 2025
require "test_helper"

class ComplexNestingDebugTest < ActiveSupport::TestCase
  test "trace complex nesting execution" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)

    # Monkey patch to add debugging
    original_create_element = SwiftUIRails::DSL.instance_method(:create_element)
    SwiftUIRails::DSL.define_method(:create_element) do |tag_name, content = nil, options = {}, &block|
      puts "=== create_element called ==="
      puts "  tag_name: #{tag_name}"
      puts "  content: #{content.inspect}"
      puts "  has block?: #{block_given?}"
      puts "  caller: #{caller[0]}"
      result = original_create_element.bind(self).call(tag_name, content, options, &block)
      puts "  result: #{result.to_s[0..100]}..."
      result
    end

    result = view.swift_ui do
      puts "\n>>> Starting vstack"
      vstack(spacing: 24).p(8).max_w("4xl").mx("auto") {
        puts "\n>>> Inside vstack block"
        text("Header")

        puts "\n>>> Creating card"
        card(elevation: 2).p(6) {
          puts "\n>>> Inside card block"
          text("Inside card")
        }
        puts "\n>>> After card"
      }
      puts "\n>>> After vstack"
    end

    puts "\n=== FINAL RESULT ==="
    puts result

    # Restore original method
    SwiftUIRails::DSL.define_method(:create_element, original_create_element)
    
    # Add assertion to verify the result contains expected structure
    assert_match %r{<div class="flex flex-col}, result.to_s
    assert_match %r{Header}, result.to_s
    assert_match %r{Inside card}, result.to_s
  end
end
# Copyright 2025
