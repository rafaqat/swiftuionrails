require "test_helper"

class StorySessionSecurityTest < ActiveSupport::TestCase
  setup do
    @valid_session_id = "session-123"
    @valid_variant = "default"
  end
  
  test "prevents RCE by rejecting arbitrary story class names" do
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
      "Admin"
    ]
    
    dangerous_names.each do |name|
      story_session = StorySession.new(
        story_name: name,
        variant: @valid_variant,
        session_id: @valid_session_id
      )
      
      assert_raises(SecurityError, "Should reject dangerous story name: #{name}") do
        story_session.component_instance
      end
    end
  end
  
  test "allows only whitelisted story classes" do
    # Test with allowed story (if exists)
    allowed_story = "button_component"
    
    story_session = StorySession.new(
      story_name: allowed_story,
      variant: @valid_variant,
      session_id: @valid_session_id
    )
    
    if Object.const_defined?("ButtonComponentStories")
      # Should not raise SecurityError
      begin
        story_session.component_instance
      rescue SecurityError => e
        assert false, "Should allow ButtonComponentStories but got: #{e.message}"
      rescue => e
        # Other errors are OK (like missing methods)
        assert true
      end
    else
      # If class doesn't exist, should get ArgumentError, not SecurityError
      error = assert_raises(ArgumentError) do
        story_session.component_instance
      end
      assert_match(/not found/, error.message)
    end
  end
  
  test "validates story class inheritance" do
    # Create a fake stories class that's not valid
    fake_stories = Class.new
    Object.const_set("FakeStories", fake_stories)
    
    # Add to whitelist temporarily
    StorySession::ALLOWED_STORIES << "FakeStories"
    
    story_session = StorySession.new(
      story_name: "fake",
      variant: @valid_variant,
      session_id: @valid_session_id
    )
    
    assert_raises(SecurityError) do
      story_session.component_instance
    end
  ensure
    Object.send(:remove_const, "FakeStories") if Object.const_defined?("FakeStories")
    StorySession::ALLOWED_STORIES.delete("FakeStories")
  end
  
  test "logs security events for unauthorized story attempts" do
    logged_messages = []
    Rails.logger.stub :error, ->(msg) { logged_messages << msg } do
      story_session = StorySession.new(
        story_name: "kernel",
        variant: @valid_variant,
        session_id: @valid_session_id
      )
      
      assert_raises(SecurityError) do
        story_session.component_instance
      end
    end
    
    # Verify security event was logged
    assert logged_messages.any? { |msg| msg.include?("[SECURITY]") }
    assert logged_messages.any? { |msg| msg.include?("Attempted to instantiate unauthorized story class") }
    assert logged_messages.any? { |msg| msg.include?("KernelStories") }
  end
  
  test "broadcast_prop_change validates story class" do
    story_session = StorySession.new(
      story_name: "evil",
      variant: @valid_variant,
      session_id: @valid_session_id
    )
    
    # Should not raise error but should be caught internally
    story_session.broadcast_prop_change
    
    # Check that it logged the error
    logged = false
    Rails.logger.stub :error, ->(msg) { logged = true if msg.include?("Error broadcasting") } do
      story_session.broadcast_prop_change
    end
    assert logged
  end
  
  test "protects against injection in story_name" do
    injection_attempts = [
      "button'; system('touch /tmp/hacked'); '",
      "button\"; exec('ls'); \"",
      "button`.touch /tmp/hacked2`",
      "button || Kernel",
      "button && Process"
    ]
    
    injection_attempts.each do |injection|
      story_session = StorySession.new(
        story_name: injection,
        variant: @valid_variant,
        session_id: @valid_session_id
      )
      
      assert_raises(SecurityError) do
        story_session.component_instance
      end
      
      # Verify no files were created
      assert_not File.exist?("/tmp/hacked")
      assert_not File.exist?("/tmp/hacked2")
    end
  end
  
  test "handles missing story classes gracefully" do
    story_session = StorySession.new(
      story_name: "non_existent",
      variant: @valid_variant,
      session_id: @valid_session_id
    )
    
    # Should raise SecurityError for unauthorized class
    assert_raises(SecurityError) do
      story_session.component_instance
    end
  end
end