require "application_system_test_case"

class SimpleTestPageTest < ApplicationSystemTestCase
  test "simple swift ui tests" do
    visit "/home/simple_test"
    
    # Check page loaded
    assert_text "Simple SwiftUI Test"
    
    # Check Test 1
    assert_text "Test 1: Basic text"
    assert_text "Hello World"
    
    # Check Test 2
    assert_text "Test 2: Basic vstack"
    assert_text "Line 1"
    assert_text "Line 2"
    
    # Check Test 3
    assert_text "Test 3: Vstack with padding"
    assert_text "Padded content"
    
    # Check Test 4
    assert_text "Test 4: Full example"
    assert_text "SwiftUI Rails"
    assert_text "This is a test"
    assert_selector "button", text: "Click me"
    
    # Check for no errors
    assert_no_page_errors
    assert_no_console_errors
  end
end
# Copyright 2025
