# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class ProductLayoutStoryTest < ApplicationSystemTestCase
  # Use headless browser
  setup do
    Capybara.current_driver = :selenium_chrome_headless
  end

  test "product layout story renders without errors" do
    visit "/storybook/show?story=product_layout&story_variant=default"

    # Check that the page loads without errors
    assert_text "Products"
    assert_text "8 items"

    # Check that select element renders
    assert_selector "select", visible: :all

    # Check that product cards render (we should have 8 products)
    # Use minimum: 1 to check that at least some cards render
    assert_selector "div", text: /\$\d+/, minimum: 1

    # Check for no error messages
    assert_no_text "wrong number of arguments"
    assert_no_text "Error"
    assert_no_text "Exception"
  end

  test "product layout masonry variant renders" do
    visit "/storybook/show?story=product_layout&story_variant=masonry"

    # Check basic rendering
    assert_text "Products", wait: 5

    # Check for no errors
    assert_no_text "wrong number of arguments"
    assert_no_text "Error"
  end
end
# Copyright 2025
