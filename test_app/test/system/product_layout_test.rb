# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class ProductLayoutTest < ApplicationSystemTestCase
  test "product layout renders with DSL content" do
    visit "/storybook/show?story=product_layout"

    # Wait for the page to load
    assert_selector "[data-live-story-target='preview']", wait: 5

    # Check that the product card renders with content
    within "[data-live-story-target='preview']" do
      # Should have the wrapper div
      assert_selector "div.p-8"

      # Should have product content
      assert_text "Basic Tee"
      assert_text "Black"
      assert_text "$35"

      # Should have image
      assert_selector "img[alt='Basic Tee in Black']"
    end

    # Take a screenshot for debugging
    take_screenshot
  end

  test "product layout interactive controls work" do
    visit "/storybook/show?story=product_layout"

    # Change product name
    fill_in "product_name", with: "Premium Shirt"

    # Wait for update
    sleep 0.5

    # Check that the content updated
    within "[data-live-story-target='preview']" do
      assert_text "Premium Shirt"
      assert_selector "img[alt='Premium Shirt in Black']"
    end

    # Change price
    fill_in "price", with: "99"
    sleep 0.5

    within "[data-live-story-target='preview']" do
      assert_text "$99"
    end
  end
end
# Copyright 2025
