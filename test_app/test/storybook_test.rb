# Copyright 2025
require "test_helper"

class StorybookTest < ActionDispatch::IntegrationTest
  test "storybook index page loads" do
    get "/storybook/index"
    assert_response :success
    assert_select "h1", "🎭 Interactive Storybook"
  end

  test "component stories are listed" do
    get "/storybook/index"
    assert_response :success

    # Check that our SwiftUI Rails stories are listed
    assert_match "DSL Button", response.body
    assert_match "DSL Card", response.body
    assert_match "Card Component", response.body
  end

  test "button component story loads" do
    get "/storybook/show", params: { story: "dsl_button" }
    assert_response :success

    # Check for the interactive controls
    assert_select "[data-controller='live-story']"
    assert_match "text", response.body
    assert_match "background_color", response.body
  end

  test "story variants are shown" do
    get "/storybook/show", params: { story: "dsl_button" }
    assert_response :success

    # Check for story variants section - only shown when multiple stories exist
    # dsl_button has 'default' and 'interactive_showcase' methods
    assert_match "Story Variants", response.body
    assert_match "default", response.body
  end

  test "controls update component preview" do
    get "/storybook/show", params: {
      story: "dsl_button",
      button_text: "Custom Button",
      button_style: "primary"
    }
    assert_response :success

    # Check that the component preview is rendered
    assert_select "#component-preview"
  end
end
# Copyright 2025
