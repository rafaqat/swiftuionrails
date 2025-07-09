# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class VerifyDslStorySourceTest < ApplicationSystemTestCase
  test "product layout shows DSL story source instead of component definition" do
    visit "/storybook/show?story=product_layout"

    # Should show "DSL Story Source" heading
    assert_selector "h2", text: "DSL Story Source"

    # Should NOT show the generic component definition
    assert_no_text "class ProductLayoutComponent < ApplicationComponent"
    assert_no_text "# Uses SwiftUI Rails DSL for component definition"

    # Should show the actual story source code
    assert_text "def default(columns: 4, show_filters: true"
    assert_text "products = generate_sample_products"
    assert_text "swift_ui do"

    # Should also show the enhanced description
    assert_text "What is the Product Layout DSL Story?"
    assert_text "pure SwiftUI Rails DSL"
    assert_text "Dynamic grid layouts"
    assert_text "Interactive filter systems"
  end

  test "other DSL stories also show source code" do
    visit "/storybook/show?story=dsl_button"

    assert_selector "h2", text: "DSL Story Source"
    assert_text "def default("
    assert_text "swift_ui do"
  end
end
# Copyright 2025
