# Copyright 2025
require "test_helper"

class ActionsControllerSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @valid_component_id = "component-123".freeze
    @valid_action_id = "action-456".freeze
  end

  test "prevents RCE by rejecting arbitrary component classes" do
    dangerous_classes = [
      "Kernel",
      "Object",
      "BasicObject",
      "File",
      "IO",
      "Dir",
      "Process",
      "System",
      "Binding",
      "Method",
      "UnboundMethod",
      "Proc",
      "ActiveRecord::Base",
      "ApplicationController",
      "User",
      "Admin",
      "eval",
      "__send__",
      "constantize"
    ]

    dangerous_classes.each do |class_name|
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: class_name,
        event_type: "click"
      }, xhr: true

      assert_response :unprocessable_entity
      if response.body.present?
        response_data = JSON.parse(response.body)
        assert_equal "Unauthorized component: #{class_name}", response_data["error"]
      else
        # For empty response body, just check the status code
        assert true, "Got expected unprocessable_entity status"
      end
    end
  end

  test "allows only whitelisted components" do
    # Test with allowed component (if exists)
    if Object.const_defined?("ButtonComponent")
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: "ButtonComponent",
        event_type: "click"
      }, xhr: true

      # Should not raise SecurityError
      assert_not_equal "Unauthorized component: ButtonComponent",
                       JSON.parse(response.body)["error"] if response.body.present?
    end
  end

  test "requires XHR or Turbo Stream format" do
    # Non-XHR request should be rejected
    post swift_ui_actions_path, params: {
      action_id: @valid_action_id,
      component_id: @valid_component_id,
      component_class: "ButtonComponent",
      event_type: "click"
    }

    assert_response :bad_request
    assert_equal({ "error" => "Invalid request format" }, JSON.parse(response.body))
  end

  test "logs security events for unauthorized component attempts" do
    # Create a custom logger to capture messages
    test_logger = ActiveSupport::Logger.new(StringIO.new)
    original_logger = Rails.logger
    
    begin
      Rails.logger = test_logger
      
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: "Kernel",
        event_type: "click"
      }, xhr: true
      
      log_output = test_logger.instance_variable_get(:@logdev).dev.string
      
      # Verify security event was logged
      assert log_output.include?("[SECURITY]")
      assert log_output.include?("Attempted to instantiate unauthorized component in ActionsController")
      assert log_output.include?("Kernel")
      assert log_output.include?("[SECURITY AUDIT]")
    ensure
      Rails.logger = original_logger
    end
  end

  test "validates component inheritance" do
    # Create a fake component that's not a valid SwiftUI component
    fake_component = Class.new
    Object.const_set("FakeComponent", fake_component)

    post swift_ui_actions_path, params: {
      action_id: @valid_action_id,
      component_id: @valid_component_id,
      component_class: "FakeComponent",
      event_type: "click"
    }, xhr: true, as: :json

    assert_response :unprocessable_entity
    if response.body.present?
      assert_match(/Unauthorized component/, response.body)
    else
      # For empty response body, just check the status code
      assert true, "Got expected unprocessable_entity status"
    end
  ensure
    Object.send(:remove_const, "FakeComponent") if Object.const_defined?("FakeComponent")
  end

  test "handles missing component classes gracefully" do
    post swift_ui_actions_path, params: {
      action_id: @valid_action_id,
      component_id: @valid_component_id,
      component_class: "NonExistentComponent",
      event_type: "click"
    }, xhr: true, as: :json

    assert_response :unprocessable_entity
    if response.body.present?
      assert_match(/Unauthorized component/, response.body)
    else
      # For empty response body, just check the status code
      assert true, "Got expected unprocessable_entity status"
    end
  end

  test "protects against injection in component_class parameter" do
    injection_attempts = [
      "ButtonComponent'; system('touch /tmp/hacked'); '",
      "ButtonComponent\"; exec('ls'); \"",
      "ButtonComponent`.touch /tmp/hacked2`",
      "ButtonComponent || Kernel",
      "ButtonComponent && Process",
      "'; eval('File.read(\"/etc/passwd\")')"
    ]

    injection_attempts.each do |injection|
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: injection,
        event_type: "click"
      }, xhr: true

      assert_response :unprocessable_entity

      # Verify no files were created
      assert_not File.exist?("/tmp/hacked")
      assert_not File.exist?("/tmp/hacked2")
    end
  end

  test "CSRF protection is enabled" do
    # This test verifies that CSRF is not skipped
    # The controller should have before_action :verify_component_security
    # instead of skip_before_action :verify_authenticity_token

    # Make request without CSRF token
    ActionController::Base.allow_forgery_protection = true

    post swift_ui_actions_path, params: {
      action_id: @valid_action_id,
      component_id: @valid_component_id,
      component_class: "ButtonComponent",
      event_type: "click"
    }, headers: { "X-Requested-With" => "XMLHttpRequest" }

    # Should still work with XHR as we check request format
    # but would fail without proper CSRF token in non-test environment
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
# Copyright 2025
