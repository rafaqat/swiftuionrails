# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class StateDebugTest < ViewComponent::TestCase
  def test_counter_state_initialization
    component = CounterComponent.new(initial_count: 5)

    # Check if state_values was initialized
    puts "State values: #{component.instance_variable_get(:@state_values).inspect}"

    # Check if count method works
    puts "Count method exists: #{component.respond_to?(:count)}"
    puts "Count value: #{component.count.inspect}" rescue puts "Error getting count: #{$!}"

    # Check if the call method works
    puts "Calling component..."
    result = component.call
    puts "Result class: #{result.class}"
    puts "Result empty?: #{result.empty?}"
    puts "Result: #{result.inspect[0..200]}"

    # Try to execute the swift_ui block manually
    puts "\nTrying swift_ui block manually..."
    begin
      block = component.class.instance_variable_get(:@swift_ui_block)
      puts "Block exists: #{!block.nil?}"
      if block
        manual_result = component.instance_eval(&block)
        puts "Manual result class: #{manual_result.class}"
        puts "Manual result: #{manual_result.inspect[0..200]}" if manual_result

        # Check if Element is defined
        puts "\nElement class defined?: #{defined?(SwiftUIRails::DSL::Element)}"
        puts "Is Element?: #{manual_result.is_a?(SwiftUIRails::DSL::Element)}"

        # Try to convert to string
        puts "To string: #{manual_result.to_s[0..200]}"

        # Check what the call method sees
        puts "\nInside call method:"
        puts "Defined check: #{component.instance_eval { defined?(SwiftUIRails::DSL::Element) }}"

        # Check if we can render it manually
        puts "\nManual rendering:"
        manual_result.view_context = component
        puts "View context set: #{manual_result.view_context.class}"
        puts "Has block?: #{manual_result.instance_variable_get(:@block).nil? ? 'NO' : 'YES'}"
        puts "Has content?: #{manual_result.instance_variable_get(:@content).nil? ? 'NO' : 'YES'}"
        puts "Tag name: #{manual_result.tag_name}"

        # Try logging the actual rendering
        puts "\nDebugging to_s:"
        begin
          manual_html = manual_result.to_s
          puts "Manual HTML: #{manual_html.inspect}"
        rescue => e
          puts "Error in to_s: #{e.message}"
          puts e.backtrace[0..3]
        end
      end
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace[0..5]
    end
    
    # Add assertions to make this a valid test
    assert_not_nil component, "Component should be created"
    assert_respond_to component, :call, "Component should respond to call"
    assert_kind_of String, result, "Component call should return a string-like object"
    assert_match(/data-controller="counter"/, result, "Should include counter stimulus controller")
  end
end
# Copyright 2025
