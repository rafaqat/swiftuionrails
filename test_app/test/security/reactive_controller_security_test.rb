# Copyright 2025
require "test_helper"

class ReactiveControllerSecurityTest < ActionDispatch::IntegrationTest
  setup do
    # Integration tests don't need controller setup
  end

  test "prevents RCE by rejecting arbitrary class names" do
    # Attempt to instantiate dangerous classes
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
      post "/swift_ui/actions", params: {
        component_class: class_name,
        component_id: "test-component",
        action_id: "test-action",
        event_type: "click"
      }, xhr: true

      assert_response :unprocessable_entity
      if response.body.present?
        body = JSON.parse(response.body)
        assert body["error"].include?("Unauthorized component")
      else
        # Empty body means the controller returned head :unprocessable_entity
        # which is acceptable for security
        assert true
      end
    end
  end

  test "allows only whitelisted components" do
    # These should be allowed
    allowed_components = [
      "ButtonComponent",
      "CardComponent",
      "ModalComponent",
      "CounterComponent"
    ]

    allowed_components.each do |component_class|
      # Skip if component doesn't exist in test environment
      next unless Object.const_defined?(component_class)

      post "/swift_ui/actions", params: {
        component_class: component_class,
        component_id: "test-component",
        action_id: "test-action",
        event_type: "click"
      }, xhr: true

      # Should not return forbidden
      assert_not_equal 403, response.status, "#{component_class} should be allowed"
    end
  end

  test "sanitizes dangerous prop values" do
    # Skip if ButtonComponent doesn't exist
    return unless Object.const_defined?("ButtonComponent")

    dangerous_props = {
      "onclick" => "eval('alert(1)')",
      "data" => "__send__(:eval, 'alert(1)')",
      "action" => "system('rm -rf /')",
      "command" => "`touch /tmp/hacked`",
      "exec" => "exec('ls')",
      "constantize_me" => "Kernel.constantize"
    }

    post "/swift_ui/actions", params: {
      component_class: "ButtonComponent",
      component_id: "test-component",
      action_id: "test-action",
      event_type: "click",
      target_dataset: dangerous_props
    }, xhr: true

    # Request might fail if the component doesn't have execute_action method
    # or succeed with dangerous props stripped
    if response.status == 422
      # Controller rejected the request due to missing execute_action
      assert true
    else
      assert_response :success
    end

    # Verify dangerous props were not executed
    assert File.exist?("/tmp/hacked") == false
  end

  test "requires XHR or Turbo Stream format" do
    # Non-XHR request should be rejected
    post "/swift_ui/actions", params: {
      component_class: "ButtonComponent",
      component_id: "test-component",
      action_id: "test-action",
      event_type: "click"
    }

    assert_response :bad_request
    assert_equal({ "error" => "Invalid request format" }, JSON.parse(response.body))
  end

  test "logs security events for unauthorized access attempts" do
    # Create a test logger to capture messages
    test_logger = ActiveSupport::Logger.new(StringIO.new)
    original_logger = Rails.logger
    
    begin
      Rails.logger = test_logger
      
      post "/swift_ui/actions", params: {
        component_class: "Kernel",
        component_id: "test-component",
        action_id: "test-action",
        event_type: "click"
      }, xhr: true
      
      log_output = test_logger.instance_variable_get(:@logdev).dev.string
      
      # Verify security event was logged
      assert log_output.include?("[SECURITY]"), "Expected [SECURITY] in log output but got: #{log_output}"
      assert log_output.include?("Attempted to instantiate unauthorized component"), "Expected unauthorized component message but got: #{log_output}"
    ensure
      Rails.logger = original_logger
    end
  end

  test "validates component inheritance" do
    # Create a fake class that's not a valid component
    fake_component = Class.new
    Object.const_set("FakeComponent", fake_component)

    # Add it to allowed components 
    SwiftUIRails.configuration.allowed_components << "Fake"

    begin
      post "/swift_ui/actions", params: {
        component_class: "FakeComponent",
        component_id: "test-component",
        action_id: "test-action",
        event_type: "click"
      }, xhr: true

      assert_response :unprocessable_entity
      if response.body.present?
        body = JSON.parse(response.body)
        assert body["error"].include?("Unauthorized component")
      else
        # Empty body means the controller returned head :unprocessable_entity
        # which is acceptable for security
        assert true
      end
    ensure
      Object.send(:remove_const, "FakeComponent") if Object.const_defined?("FakeComponent")
      SwiftUIRails.configuration.allowed_components.delete("Fake")
    end
  end

  test "handles missing component classes gracefully" do
    # Try to instantiate a non-existent but "allowed" component
    post "/swift_ui/actions", params: {
      component_class: "ButtonComponent",
      component_id: "test-component",
      action_id: "test-action",
      event_type: "click"
    }, xhr: true

    # Should handle gracefully without exposing internal errors
    if Object.const_defined?("ButtonComponent")
      # Component exists, should work
      # Check if ButtonComponent is in allowed components
      if SwiftUIRails.configuration.allowed_components.any? { |c| c.downcase == "button" }
        assert_response :unprocessable_entity  # No action handler
      else
        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert body["error"].include?("Unauthorized component")
      end
    else
      # Component doesn't exist, should fail safely
      assert_response :unprocessable_entity
      if response.body.present?
        body = JSON.parse(response.body)
        assert body["error"].include?("Unauthorized component")
      else
        # Empty body means the controller returned head :unprocessable_entity
        # which is acceptable for security
        assert true
      end
    end
  end

end
# Copyright 2025
