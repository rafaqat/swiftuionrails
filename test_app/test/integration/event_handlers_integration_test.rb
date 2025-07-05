# frozen_string_literal: true

require "test_helper"

class EventHandlersIntegrationTest < ActionDispatch::IntegrationTest
  test "counter component renders with event handlers" do
    # Visit a page that renders the counter component
    get "/home/event_test"
    assert_response :success
    
    # Check that Stimulus controller is properly set up
    assert_select "[data-controller*='swift-ui-component']"
    assert_select "[data-action*='click->swift-ui-component#handleAction']"
  end
  
  test "swift UI actions endpoint handles events" do
    # First establish a session by visiting a page with the component
    get "/home/event_test"
    assert_response :success
    
    # Now test the actions endpoint
    post "/swift_ui/actions", params: {
      action_id: "test_action",
      component_id: "test_component",
      component_class: "CounterComponent",
      event_type: "click"
    }, as: :json
    
    # Should return success with component state
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert json_response["component_id"] == "test_component"
  end
end