#!/usr/bin/env ruby
require_relative 'config/environment'

puts "Testing SimpleButtonComponent with Swift DSL..."
puts "=" * 60

# Create a mock view context
controller = ApplicationController.new
controller.request = ActionDispatch::Request.new('rack.input' => StringIO.new)
view_context = controller.view_context

# Test 1: Basic button
puts "\n1. Basic Button:"
button = SimpleButtonComponent.new(title: "Click Me", variant: :primary)
html = button.render_in(view_context)
puts "HTML: #{html}"
puts "✅ Basic button rendered successfully!" if html.include?("Click Me")

# Test 2: Different variants
puts "\n2. Button Variants:"
[:primary, :secondary, :danger].each do |variant|
  button = SimpleButtonComponent.new(title: "#{variant.to_s.capitalize}", variant: variant)
  html = button.render_in(view_context)
  puts "#{variant}: #{html.include?("bg-") ? '✅' : '❌'}"
end

puts "\n" + "=" * 60
puts "Test completed!"