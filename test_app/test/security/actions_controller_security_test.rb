# Copyright 2025
require "test_helper"

class ActionsControllerSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @valid_component_id = "component-123"
    @valid_action_id = "action-456"
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
      # In test environment, exceptions might be re-raised
      # We verify the SecurityError is raised, which would be caught in production
      assert_raises(SecurityError) do
        post swift_ui_actions_path, params: {
          action_id: @valid_action_id,
          component_id: @valid_component_id,
          component_class: class_name,
          event_type: "click"
        }, xhr: true
      end
    end
  end

  test "allows only whitelisted components" do
    # This test verifies that ButtonComponent is in the whitelist
    # The actual functionality test would require a full component setup
    # with registered actions, which is beyond the scope of security testing

    # Verify ButtonComponent is whitelisted
    controller = ::SwiftUi::ActionsController.new
    assert controller.send(:allowed_component?, "ButtonComponent"),
           "ButtonComponent should be in the whitelist"

    # Verify a non-whitelisted component is rejected
    refute controller.send(:allowed_component?, "EvilComponent"),
           "Non-whitelisted components should be rejected"
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
    # Capture logs using StringIO
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)

    # Expect SecurityError to be raised
    assert_raises(SecurityError) do
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: "Kernel",
        event_type: "click"
      }, xhr: true
    end

    # Get logged messages
    log_content = log_output.string

    # Verify security event was logged before the exception
    assert log_content.include?("[SECURITY]"), "Should log security marker"
    assert log_content.include?("Attempted to instantiate unauthorized component in ActionsController"), "Should log security message"
    assert log_content.include?("Kernel"), "Should log component name"
    assert log_content.include?("[SECURITY AUDIT]"), "Should log security audit marker"
  ensure
    Rails.logger = original_logger
  end

  test "validates component inheritance" do
    # Create a fake component that's not a valid SwiftUI component
    fake_component = Class.new
    Object.const_set("FakeComponent", fake_component)

    # Expect SecurityError for non-whitelisted component
    assert_raises(SecurityError) do
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: "FakeComponent",
        event_type: "click"
      }, xhr: true
    end
  ensure
    Object.send(:remove_const, "FakeComponent") if Object.const_defined?("FakeComponent")
  end

  test "handles missing component classes gracefully" do
    # Expect SecurityError for non-whitelisted component
    assert_raises(SecurityError) do
      post swift_ui_actions_path, params: {
        action_id: @valid_action_id,
        component_id: @valid_component_id,
        component_class: "NonExistentComponent",
        event_type: "click"
      }, xhr: true
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
      # Expect SecurityError for malicious input
      assert_raises(SecurityError) do
        post swift_ui_actions_path, params: {
          action_id: @valid_action_id,
          component_id: @valid_component_id,
          component_class: injection,
          event_type: "click"
        }, xhr: true
      end

      # Verify no files were created
      assert_not File.exist?("/tmp/hacked")
      assert_not File.exist?("/tmp/hacked2")
    end
  end

  test "CSRF protection is enabled" do
    # This test verifies that CSRF protection is enabled in the controller
    # In test environment, Rails disables forgery protection by default,
    # but we can verify the controller doesn't explicitly skip it

    # Read the controller source to verify no skip_before_action
    controller_source = File.read(Rails.root.join("app/controllers/swift_ui/actions_controller.rb"))

    # Verify the controller doesn't skip CSRF protection
    refute controller_source.include?("skip_before_action :verify_authenticity_token"),
           "ActionsController should not skip CSRF verification"

    # Also verify the ApplicationController doesn't skip it
    app_controller_source = File.read(Rails.root.join("app/controllers/application_controller.rb"))
    refute app_controller_source.include?("skip_forgery_protection"),
           "ApplicationController should not skip forgery protection"
  end
end
# Copyright 2025
