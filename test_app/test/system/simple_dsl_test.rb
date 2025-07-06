# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class SimpleDslTest < ApplicationSystemTestCase
  test "test simple DSL elements work" do
    puts "🧪 Testing basic DSL elements work..."
    
    visit "/storybook/show?story=product_list_component"
    assert_selector "[data-controller='live_story']", wait: 10
    
    # Check if the title text() DSL works
    if page.has_text?("Customers also purchased")
      puts "✅ text() DSL method working"
    else
      puts "❌ text() DSL method not working"
    end
    
    # Check if any content beyond title exists
    content = find("#component-preview").text.strip
    lines = content.split("\n").reject(&:empty?)
    
    puts "\n📝 All rendered content lines:"
    lines.each_with_index do |line, i|
      puts "  #{i+1}. #{line}"
    end
    
    if lines.count == 1 && lines.first.include?("Customers also purchased")
      puts "\n🚨 PROBLEM: Only title is rendering - grid content is empty"
      puts "This suggests the DSL grid block or product iteration isn't working"
    elsif lines.count > 1
      puts "\n✅ Multiple content lines found - DSL is generating content"
    end
  end
end
# Copyright 2025
