require "test_helper"

class ReactiveControllerSecurityTest < ActionDispatch::IntegrationTest
  include SwiftUIRails::Reactive::ReactiveController
  
  setup do
    # Mock a controller that includes ReactiveController
    @controller = Class.new(ApplicationController) do
      include SwiftUIRails::Reactive::ReactiveController
      
      def update_component
        super
      end
    end
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
      post "/swift_ui/components/update", params: {
        component_class: class_name,
        component_id: "test-component",
        props: {}
      }, xhr: true
      
      assert_response :forbidden
      assert_equal({ "error" => "Unauthorized component" }, JSON.parse(response.body))
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
      
      post "/swift_ui/components/update", params: {
        component_class: component_class,
        component_id: "test-component",
        props: {}
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
    
    post "/swift_ui/components/update", params: {
      component_class: "ButtonComponent",
      component_id: "test-component", 
      props: dangerous_props
    }, xhr: true
    
    # Request should succeed but dangerous props should be stripped
    assert_response :success
    
    # Verify dangerous props were not executed
    assert File.exist?("/tmp/hacked") == false
  end
  
  test "requires XHR or Turbo Stream format" do
    # Non-XHR request should be rejected
    post "/swift_ui/components/update", params: {
      component_class: "ButtonComponent",
      component_id: "test-component",
      props: {}
    }
    
    assert_response :bad_request
    assert_equal({ "error" => "Invalid request format" }, JSON.parse(response.body))
  end
  
  test "logs security events for unauthorized access attempts" do
    # Capture logs
    logged_messages = []
    Rails.logger.stub :error, ->(msg) { logged_messages << msg } do
      post "/swift_ui/components/update", params: {
        component_class: "Kernel",
        component_id: "test-component",
        props: {}
      }, xhr: true
    end
    
    # Verify security event was logged
    assert logged_messages.any? { |msg| msg.include?("[SECURITY]") }
    assert logged_messages.any? { |msg| msg.include?("Attempted to instantiate unauthorized component: Kernel") }
    assert logged_messages.any? { |msg| msg.include?("[SECURITY AUDIT]") }
  end
  
  test "validates component inheritance" do
    # Create a fake class that's not a valid component
    stub_const("FakeComponent", Class.new)
    
    # Add it to allowed components (simulating a misconfiguration)
    allowed_components = SwiftUIRails::Reactive::ReactiveController::ALLOWED_COMPONENTS.dup
    allowed_components << "FakeComponent"
    
    SwiftUIRails::Reactive::ReactiveController.stub_const(:ALLOWED_COMPONENTS, allowed_components) do
      post "/swift_ui/components/update", params: {
        component_class: "FakeComponent",
        component_id: "test-component",
        props: {}
      }, xhr: true
      
      assert_response :internal_server_error
      assert_equal({ "error" => "Component update failed" }, JSON.parse(response.body))
    end
  end
  
  test "handles missing component classes gracefully" do
    # Try to instantiate a non-existent but "allowed" component
    post "/swift_ui/components/update", params: {
      component_class: "ButtonComponent",
      component_id: "test-component",
      props: {}
    }, xhr: true
    
    # Should handle gracefully without exposing internal errors
    if Object.const_defined?("ButtonComponent")
      # Component exists, should work
      assert_response :success
    else
      # Component doesn't exist, should fail safely
      assert_response :internal_server_error
      assert_equal({ "error" => "Component update failed" }, JSON.parse(response.body))
    end
  end
  
  private
  
  def stub_const(name, value)
    # Helper to temporarily define a constant
    Object.const_set(name, value)
    yield
  ensure
    Object.send(:remove_const, name) if Object.const_defined?(name)
  end
end
# Copyright 2025
