# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class EventHandlersIntegrationTest < ActionDispatch::IntegrationTest
  test "counter component renders with event handlers" do
    # Visit a page that renders the counter component
    get "/counter"
    assert_response :success

    # Check that Stimulus controller is properly set up
    assert_select "[data-controller*='counter']"
    assert_select "[data-action*='click->counter#increment']"
  end

  test "swift UI actions endpoint handles events" do
    # First establish a session by visiting a page with the component
    get "/counter"
    assert_response :success

    # Now test the actions endpoint
    post "/swift_ui/actions", params: {
      action_id: "test_action",
      component_id: "test_component",
      component_class: "CounterComponent",
      event_type: "click"
    }, as: :json, headers: { "X-Requested-With" => "XMLHttpRequest" }

    # Should return success with component state
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "test_component", json_response["component_id"]
  end
end
# Copyright 2025
