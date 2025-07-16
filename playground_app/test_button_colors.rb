#!/usr/bin/env ruby

# Quick test to verify the bg color handling
require_relative '../lib/swift_ui_rails'

# Test the security validator directly
puts "Testing CSSValidator.safe_bg_class:"
puts "blue -> #{SwiftUIRails::Security::CSSValidator.safe_bg_class('blue')}"
puts "white -> #{SwiftUIRails::Security::CSSValidator.safe_bg_class('white')}"
puts "red -> #{SwiftUIRails::Security::CSSValidator.safe_bg_class('red')}"
puts "blue-600 -> #{SwiftUIRails::Security::CSSValidator.safe_bg_class('blue', '600')}"

puts "\nTesting text colors:"
puts "blue -> #{SwiftUIRails::Security::CSSValidator.safe_text_class('blue')}"
puts "white -> #{SwiftUIRails::Security::CSSValidator.safe_text_class('white')}"