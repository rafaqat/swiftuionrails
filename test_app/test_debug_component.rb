#!/usr/bin/env ruby
require_relative 'config/environment'

# Create a simple test component to debug the issue
class SimpleTestComponent < SwiftUIRails::Component::Base
  prop :message, type: String, default: "Hello"
  
  swift_ui do
    puts "In swift_ui block - self: #{self.class}, @component: #{@component.inspect}"
    div do
      puts "In div block - self: #{self.class}, @component: #{@component.inspect}"
      text(message)
    end
  end
end

controller = ApplicationController.new
controller.request = ActionDispatch::Request.new('rack.input' => StringIO.new)
view_context = controller.view_context

component = SimpleTestComponent.new(message: "Test")
puts "Component created: #{component.inspect}"
puts "Component message: #{component.message}"

html = component.render_in(view_context)
puts "\nRendered HTML:"
puts html
# Copyright 2025
