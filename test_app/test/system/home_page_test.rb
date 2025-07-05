require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  test "home page renders without errors" do
    visit root_path
    
    # Check page loaded
    assert_text "Welcome to SwiftUI Rails"
    assert_text "Build beautiful Rails views with SwiftUI-inspired syntax"
    
    # Check for no visible errors
    assert_no_page_errors
    
    # Check browser console
    assert_no_console_errors
    
    # Check that SwiftUI components rendered
    assert_selector "button", text: "Primary Button"
    assert_selector "button", text: "Secondary Button"
    
    # Check the example component rendered
    assert_text "Interactive Example"
    assert_text "Click the buttons to see state management in action!"
  end
end
# Copyright 2025
