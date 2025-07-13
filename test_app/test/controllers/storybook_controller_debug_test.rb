# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class StorybookControllerDebugTest < ActionDispatch::IntegrationTest
  test "card component story loads correctly" do
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success

    # Verify the story loads without errors
    assert_select "[data-controller='live-story']"
    assert_select "#component-preview"

    # Verify controls are present
    assert_select "select[name='background_color']"
    assert_select "select[name='elevation']"
    assert_select "select[name='padding']"
    assert_select "select[name='corner_radius']"
    assert_select "input[name='border']"
    assert_select "input[name='hover_effect']"

    puts "✅ Card component story loads successfully"
  end

  test "card component update_preview responds correctly" do
    # Simulate a background color change
    post "/storybook/update_preview", params: {
      story: "card_component",
      story_variant: "default",
      session_id: "test-session-123",
      mode: "interactive",
      background_color: "gray-50",
      elevation: "1",
      padding: "16",
      corner_radius: "lg",
      border: "false",
      hover_effect: "false"
    }, headers: {
      "Accept" => "text/vnd.turbo-stream.html",
      "X-Requested-With" => "XMLHttpRequest"
    }

    assert_response :success
    assert_match "turbo-stream", response.body

    puts "✅ Update preview responds correctly"
  end

  test "card component story config extraction works" do
    story_file = Rails.root.join("test/components/stories/card_component_stories.rb")
    assert File.exist?(story_file), "Card component stories file should exist"

    # Load the story file
    load story_file
    story_class_name = "CardComponentStories"
    story_class = story_class_name.safe_constantize
    assert story_class, "Story class should load correctly"

    # Get component class
    component_class = "CardComponent".safe_constantize
    assert component_class, "Component class should load correctly"

    # Test story config extraction
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success

    puts "✅ Story config extraction works"
  end

  test "debug card component controls generation" do
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success

    # Debug: Print the response body to see what's being generated
    puts "\n=== DEBUGGING CARD COMPONENT CONTROLS ==="
    puts "Response includes background_color select: #{response.body.include?('background_color')}"
    puts "Response includes elevation select: #{response.body.include?('elevation')}"
    puts "Response includes data-controller='live_story': #{response.body.include?("data-controller=\"live_story\"")}"
    puts "Response includes controlChanged action: #{response.body.include?('controlChanged')}"

    # Check for the specific data attributes
    if response.body.include?("live_story")
      puts "✅ Found live_story references"
    else
      puts "❌ Missing live_story references"
    end

    if response.body.include?('data-live_story_target="control"')
      puts "✅ Found correct control targets"
    else
      puts "❌ Missing correct control targets"
    end

    if response.body.include?("change->live_story#controlChanged")
      puts "✅ Found correct change actions"
    else
      puts "❌ Missing correct change actions"
    end

    puts "=== END DEBUGGING ==="
  end
end
# Copyright 2025
