require "test_helper"

class SwiftComponentHelperSecurityTest < ActionView::TestCase
  include SwiftUIRails::Helpers
  
  setup do
    # Ensure we have a clean configuration
    SwiftUIRails.configuration = SwiftUIRails::Configuration.new
  end
  
  test "prevents RCE by rejecting arbitrary class names" do
    # Attempt to instantiate dangerous classes
    dangerous_names = [
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
      # Special injection attempts
      "'; system('rm -rf /'); '",
      "../../../../../../etc/passwd",
      "__send__",
      "eval",
      "constantize"
    ]
    
    dangerous_names.each do |name|
      assert_raises(SecurityError, "Should reject dangerous component name: #{name}") do
        swift_component(name, title: "Test")
      end
    end
  end
  
  test "allows only whitelisted components" do
    # These should be allowed (if they exist)
    allowed_names = ["button", "card", "modal", "counter"]
    
    allowed_names.each do |name|
      component_class_name = "#{name.camelize}Component"
      
      # Skip if component doesn't exist in test environment
      if Object.const_defined?(component_class_name)
        # Should not raise SecurityError
        begin
          swift_component(name, title: "Test")
        rescue => e
          # Only SecurityError means it was blocked
          assert_not_instance_of SecurityError, e, "#{name} should be allowed"
        end
      else
        # If component doesn't exist, it should raise ArgumentError, not SecurityError
        error = assert_raises(ArgumentError) do
          swift_component(name, title: "Test")
        end
        assert_match(/not found/, error.message)
      end
    end
  end
  
  test "validates component inheritance" do
    # Create a fake class that's not a valid component
    Object.const_set("FakeComponent", Class.new)
    
    # Add "Fake" to allowed components
    SwiftUIRails.configuration.allowed_components << "Fake"
    
    # Should still reject because it's not a valid component
    assert_raises(SecurityError) do
      swift_component("fake")
    end
  ensure
    Object.send(:remove_const, "FakeComponent") if Object.const_defined?("FakeComponent")
  end
  
  test "handles various input types safely" do
    # Test with symbols
    assert_raises(SecurityError) do
      swift_component(:kernel)
    end
    
    # Test with mixed case
    assert_raises(SecurityError) do
      swift_component("KerNEL")
    end
    
    # Test with underscored names
    assert_raises(SecurityError) do
      swift_component("active_record_base")
    end
  end
  
  test "logs security events" do
    logged_messages = []
    Rails.logger.stub :error, ->(msg) { logged_messages << msg } do
      assert_raises(SecurityError) do
        swift_component("Kernel")
      end
    end
    
    # Verify security event was logged
    assert logged_messages.any? { |msg| msg.include?("[SECURITY]") }
    assert logged_messages.any? { |msg| msg.include?("Attempted to instantiate unauthorized component") }
    assert logged_messages.any? { |msg| msg.include?("Kernel") }
  end
  
  test "provides helpful error messages" do
    # For unauthorized components
    error = assert_raises(SecurityError) do
      swift_component("evil")
    end
    assert_match(/Unauthorized component: Evil/, error.message)
    assert_match(/must be added to the allowed_components list/, error.message)
    
    # For non-existent but allowed components
    SwiftUIRails.configuration.allowed_components << "NonExistent"
    error = assert_raises(ArgumentError) do
      swift_component("non_existent")
    end
    assert_match(/Component NonExistentComponent not found/, error.message)
  end
  
  test "configuration can be customized" do
    # Add a custom component to the whitelist
    SwiftUIRails.configuration.allowed_components << "Custom"
    
    # Create a valid component class
    custom_component = Class.new(ViewComponent::Base) do
      def call
        "<div>Custom Component</div>".html_safe
      end
    end
    Object.const_set("CustomComponent", custom_component)
    
    # Should now be allowed
    result = swift_component("custom")
    assert_instance_of String, result
  ensure
    Object.send(:remove_const, "CustomComponent") if Object.const_defined?("CustomComponent")
  end
  
  test "handles edge cases safely" do
    # Empty string
    assert_raises(SecurityError) do
      swift_component("")
    end
    
    # Nil (gets converted to empty string)
    assert_raises(SecurityError) do
      swift_component(nil)
    end
    
    # Component name with special characters
    assert_raises(SecurityError) do
      swift_component("button'; system('ls'); '")
    end
  end
end