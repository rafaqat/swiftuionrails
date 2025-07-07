# Copyright 2025
require "test_helper"

class StorySessionSecurityTest < ActiveSupport::TestCase
  setup do
    @valid_session_id = "session-123".freeze
    @valid_variant = "default".freeze
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
    Object.const_set("NonExistentStories", fake_stories)

    story_session = StorySession.new(
      story_name: "non_existent",
      variant: @valid_variant,
      session_id: @valid_session_id
    )

    # Should fail because it's not in the whitelist
    assert_raises(SecurityError) do
      story_session.component_instance
    end
  ensure
    Object.send(:remove_const, "NonExistentStories") if Object.const_defined?("NonExistentStories")
  end

  test "logs security events for unauthorized story attempts" do
    # Create a custom logger to capture messages
    test_logger = ActiveSupport::Logger.new(StringIO.new)
    original_logger = Rails.logger

    begin
      Rails.logger = test_logger

      story_session = StorySession.new(
        story_name: "kernel",
        variant: @valid_variant,
        session_id: @valid_session_id
      )

      assert_raises(SecurityError) do
        story_session.component_instance
      end

      log_output = test_logger.instance_variable_get(:@logdev).dev.string

      # Verify security event was logged
      assert log_output.include?("[SECURITY]")
      assert log_output.include?("Attempted to instantiate unauthorized story class")
      assert log_output.include?("KernelStories")
    ensure
      Rails.logger = original_logger
    end
  end

  test "broadcast_prop_change validates story class" do
    # Test that broadcast_prop_change handles unauthorized story classes gracefully
    # by logging the error but not raising it externally

    # Create a test logger to capture messages
    test_logger = ActiveSupport::Logger.new(StringIO.new)
    original_logger = Rails.logger

    begin
      Rails.logger = test_logger

      # Create a story session with an unauthorized story name
      story_session = StorySession.new(
        story_name: "evil",
        variant: @valid_variant,
        session_id: @valid_session_id
      )

      # The broadcast_prop_change method should catch and log the error
      # without raising it externally
      story_session.send(:broadcast_prop_change)

      log_output = test_logger.instance_variable_get(:@logdev).dev.string

      # Verify that the security error was logged
      assert log_output.include?("[SECURITY]"), "Expected security log message"
      assert log_output.include?("Attempted to instantiate unauthorized story class"), "Expected unauthorized class message"
      assert log_output.include?("Error broadcasting prop change"), "Expected broadcast error message"
    ensure
      Rails.logger = original_logger
    end
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
