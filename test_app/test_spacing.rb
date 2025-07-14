#!/usr/bin/env ruby

require_relative '../lib/swift_ui_rails'

# Test the SpacingConverter directly
converter = SwiftUIRails::Tailwind::SpacingConverter

puts "Testing SpacingConverter:"
puts "pixel_value?(16): #{converter.pixel_value?(16)}"
puts "convert(16): #{converter.convert(16)}"
puts "pixel_value?(8): #{converter.pixel_value?(8)}"
puts "convert(8): #{converter.convert(8)}"
puts "pixel_value?(4): #{converter.pixel_value?(4)}"
puts "convert(4): #{converter.convert(4)}"

# Now test the DSL
class TestComponent < SwiftUIRails::Component::Base
  include SwiftUIRails::DSL
  
  def call
    swift_ui do
      button("Test")
        .px(16)
        .py(8)
        .bg("blue")
    end
  end
end

puts "\nTesting DSL output:"
html = TestComponent.new.call.to_s
puts html