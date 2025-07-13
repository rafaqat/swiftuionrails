# Copyright 2025
require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  test "home page renders without errors" do
    visit root_path

    # Check page loaded with new content
    assert_text "SwiftUI Rails DSL Components"
    assert_text "Pure DSL components showcasing our SwiftUI-inspired syntax"

    # Check for no visible errors
    assert_no_page_errors

    # Check browser console
    assert_no_console_errors

    # Check that DSL component cards are rendered
    assert_text "DSL Button"
    assert_text "Interactive button component with chainable modifiers"

    assert_text "DSL Card"
    assert_text "Composable card component with header, content, and footer"

    assert_text "Product Layout"
    assert_text "E-commerce product grid demonstrating collection rendering"

    # Check for story links
    assert_selector "a[href*='dsl_button']"
    assert_selector "a[href*='dsl_card']"
    assert_selector "a[href*='product_layout']"
  end
end
# Copyright 2025
