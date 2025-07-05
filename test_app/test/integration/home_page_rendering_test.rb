require "test_helper"

class HomePageRenderingTest < ActionDispatch::IntegrationTest
  test "check home page HTML" do
    get "/"
    
    puts "\n=== Response Status ==="
    puts "Status: #{response.status}"
    
    if response.status == 200
      puts "\n=== Full Response Body ==="
      puts response.body
      
      puts "\n=== Page Analysis ==="
      # Look for key elements
      if response.body.include?("Welcome to SwiftUI Rails")
        puts "✓ Found welcome text"
      end
      
      if response.body.include?("Example Component")
        puts "✓ Found example component"
      else
        puts "✗ Example Component NOT found"
      end
      
      # Look for buttons
      button_matches = response.body.scan(/<button[^>]*>.*?<\/button>/m)
      puts "\nButtons found: #{button_matches.count}"
      
      # Check what swift_ui rendered
      swift_ui_start = response.body.index("<div class=\"min-h-screen bg-gray-50\">")
      if swift_ui_start
        swift_ui_section = response.body[swift_ui_start..swift_ui_start+500]
        puts "\n=== SwiftUI Section (first 500 chars) ==="
        puts swift_ui_section
      end
    else
      puts "\n=== Error Response ==="
      puts response.body[0..1000]
    end
  end
end
# Copyright 2025
