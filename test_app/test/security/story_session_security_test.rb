# Copyright 2025
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

    # Temporarily modify the allowed stories constant
    original_allowed = StorySession::ALLOWED_STORIES
    StorySession.send(:remove_const, :ALLOWED_STORIES)
    StorySession.const_set(:ALLOWED_STORIES, original_allowed + [ "FakeStories" ])

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
    # Restore original allowed stories
    StorySession.send(:remove_const, :ALLOWED_STORIES)
    StorySession.const_set(:ALLOWED_STORIES, original_allowed)
  end

  test "logs security events for unauthorized story attempts" do
    # Skip if mocha isn't available
    unless defined?(Mocha)
      skip "Mocha not available"
      return
    end

    # Mock Rails.logger
    logged_messages = []
    Rails.logger.stubs(:error).with { |msg| logged_messages << msg; true }

    # Attempt to instantiate an unauthorized story
    session = StorySession.new(
      story_name: "kernel",  # This will try to load KernelStories
      variant: "default",
      session_id: "test-session"
    )

    # Try to get component instance which will trigger security check
    # This should raise SecurityError
    assert_raises(SecurityError) do
      session.component_instance
    end

    # Verify security event was logged
    assert logged_messages.any? { |msg| msg.include?("[SECURITY]") }
    assert logged_messages.any? { |msg| msg.include?("Attempted to instantiate unauthorized story class: KernelStories") }
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
# Copyright 2025
