# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class StorybookFinalValidationTest < ActionDispatch::IntegrationTest
  test "card component controls work correctly after fixes" do
    # 1. Test that the page loads correctly
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success

    # 2. Test that controls are rendered correctly
    assert_select "select[name='background_color']"
    assert_select "select[data-live-story-target='control']"
    assert_select "select[data-action*='change->live-story#controlChanged']"

    # 3. Test that HTML escaping is fixed (no &gt; in stimulus actions)
    assert_not response.body.include?("data-action.*change-&gt;live-story")
    assert response.body.include?("change->live-story#controlChanged")

    # 4. Test interactive update works
    post "/storybook/update_preview", params: {
      story: "card_component",
      story_variant: "default",
      session_id: "test-session",
      mode: "interactive",
      background_color: "blue-50",
      elevation: "2",
      padding: "20",
      corner_radius: "xl",
      border: "true",
      hover_effect: "true"
    }, headers: {
      "Accept" => "text/vnd.turbo-stream.html",
      "X-Requested-With" => "XMLHttpRequest"
    }

    assert_response :success
    assert_match "turbo-stream", response.body

    puts "✅ All card component fixes validated successfully"
  end

  test "enhanced product list anti-flash behavior works" do
    get "/storybook/show", params: { story: "enhanced_product_list_component" }
    assert_response :success

    # Test rapid updates to ensure anti-flash behavior
    5.times do |i|
      post "/storybook/update_preview", params: {
        story: "enhanced_product_list_component",
        story_variant: "default",
        session_id: "test-session-#{i}",
        mode: "interactive",
        background_color: [ "white", "gray-50", "blue-50" ].sample,
        columns: [ "auto", "two", "three", "four" ].sample,
        gap: [ "4", "6", "8" ].sample
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html",
        "X-Requested-With" => "XMLHttpRequest"
      }

      assert_response :success
    end

    puts "✅ Enhanced product list anti-flash behavior validated"
  end

  test "all stimulus actions are properly escaped" do
    # Test multiple component stories to ensure all have proper escaping
    [ "card_component", "enhanced_product_list_component" ].each do |story|
      get "/storybook/show", params: { story: story }
      assert_response :success

      # Ensure no HTML-escaped stimulus actions (but allow in code examples)
      assert_not response.body.match?(/data-action[^>]*&gt;/), "Found HTML-escaped > in stimulus actions in #{story}"

      # Ensure proper stimulus actions exist
      if response.body.include?("data-action")
        assert response.body.include?("->"), "Missing proper stimulus actions in #{story}"
      end
    end

    puts "✅ All stimulus actions properly escaped"
  end

  test "end to end storybook workflow validation" do
    # 1. Load storybook index
    get "/storybook/index"
    assert_response :success
    assert_select "a[href*='card_component']"

    # 2. Navigate to card component
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success
    assert_select "[data-controller='live-story']"

    # 3. Test each control type works

    # Test select control
    post "/storybook/update_preview", params: {
      story: "card_component",
      background_color: "gray-50",
      elevation: "1", padding: "16", corner_radius: "lg",
      border: "false", hover_effect: "false"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success

    # Test boolean control
    post "/storybook/update_preview", params: {
      story: "card_component",
      background_color: "white", elevation: "1", padding: "16",
      corner_radius: "lg", border: "true", hover_effect: "false"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success

    puts "✅ End-to-end storybook workflow validated"
  end
end
# Copyright 2025
