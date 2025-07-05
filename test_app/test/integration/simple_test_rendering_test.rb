require "test_helper"

class SimpleTestRenderingTest < ActionDispatch::IntegrationTest
  test "check simple test page HTML" do
    get "/home/simple_test"
    
    puts "\n=== Full Response Body ==="
    puts response.body
    
    # Check what each test section contains
    body_lines = response.body.split("\n")
    
    test1_index = body_lines.index { |line| line.include?("Test 1: Basic text") }
    test2_index = body_lines.index { |line| line.include?("Test 2: Basic vstack") }
    test3_index = body_lines.index { |line| line.include?("Test 3: Vstack with padding") }
    test4_index = body_lines.index { |line| line.include?("Test 4: Full example") }
    
    if test1_index && test2_index
      puts "\n=== Test 1 output ==="
      puts body_lines[test1_index..test2_index-1].join("\n")
    end
    
    if test2_index && test3_index
      puts "\n=== Test 2 output ==="
      puts body_lines[test2_index..test3_index-1].join("\n")
    end
    
    if test3_index && test4_index
      puts "\n=== Test 3 output ==="
      puts body_lines[test3_index..test4_index-1].join("\n")
    end
    
    if test4_index
      puts "\n=== Test 4 output ==="
      puts body_lines[test4_index..-1].take(20).join("\n")
    end
  end
end
# Copyright 2025
