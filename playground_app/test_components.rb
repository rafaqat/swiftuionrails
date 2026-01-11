#!/usr/bin/env ruby
require_relative 'config/environment'

puts "Testing SwiftUI Rails authentication components..."

begin
  puts "\n1. Testing Login Form Component"
  login_component = Auth::LoginFormComponent.new
  rendered = ApplicationController.renderer.render(login_component)
  puts "✅ Login component rendered successfully (#{rendered.length} chars)"
rescue => e
  puts "❌ Login component error: #{e.message}"
  puts e.backtrace.first(3)
end

begin
  puts "\n2. Testing Register Form Component"
  register_component = Auth::RegisterFormComponent.new
  rendered = ApplicationController.renderer.render(register_component)
  puts "✅ Register component rendered successfully (#{rendered.length} chars)"
rescue => e
  puts "❌ Register component error: #{e.message}"
  puts e.backtrace.first(3)
end

begin
  puts "\n3. Testing DSL methods directly"
  test_component = Class.new(ApplicationComponent) do
    swift_ui do
      div.w("full").text_color("red-500") do
        text("Hello World")
      end
    end
  end
  
  rendered = ApplicationController.renderer.render(test_component.new)
  puts "✅ Basic DSL methods work (#{rendered.length} chars)"
rescue => e
  puts "❌ DSL methods error: #{e.message}"
  puts e.backtrace.first(3)
end