require "application_system_test_case"

class TestSyntaxPageTest < ApplicationSystemTestCase
  test "test syntax variations" do
    visit "/home/test_syntax"
    
    # Print the page content for debugging
    puts "=== Page HTML ==="
    puts page.html
    
    # Check what worked and what didn't
    assert_text "Test 1: Original syntax"
    assert_text "Test 2: Proper block syntax"
    assert_text "Test 3: Single line"
  end
end