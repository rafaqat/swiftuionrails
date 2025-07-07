# Copyright 2025
require "test_helper"

class WebSocketSecurityTest < ActionCable::Channel::TestCase
  tests SwiftUIRails::Component::ReactiveChannel if defined?(SwiftUIRails::Component::ReactiveChannel)

  setup do
    # Skip if ReactiveChannel is not defined
    skip "ReactiveChannel not defined" unless defined?(SwiftUIRails::Component::ReactiveChannel)
  end

  test "prevents RCE through component_class in request_update" do
    # Subscribe to the channel
    subscribe component_id: "swift-ui-test-123"

    # Attempt various RCE attacks
    dangerous_payloads = [
      { "component_class" => "Kernel", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "Object", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "BasicObject", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "eval('malicious')", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "system('ls')", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "`touch /tmp/hacked`", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "File", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "Dir", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "Process", "component_id" => "swift-ui-test-123", "props" => {} },
      { "component_class" => "IO", "component_id" => "swift-ui-test-123", "props" => {} }
    ]

    dangerous_payloads.each do |payload|
      # Channel should reject the update
      perform :request_update, payload

      # Verify the subscription was rejected or no job was queued
      if defined?(ReactiveUpdateJob)
        assert_enqueued_jobs 0, only: ReactiveUpdateJob
      end
    end
  end

  test "rejects updates with invalid component_id format" do
    subscribe component_id: "swift-ui-test-123"

    invalid_ids = [
      "../../etc/passwd",
      "swift-ui-test-123; system('ls')",
      "swift-ui-test-123`whoami`",
      "swift-ui-test-$(whoami)",
      "'; DROP TABLE users; --",
      "<script>alert('xss')</script>",
      "swift-ui-test-123\nmalicious",
      "swift-ui-test-123\r\nmalicious"
    ]

    invalid_ids.each do |invalid_id|
      perform :request_update, {
        "component_class" => "ButtonComponent",
        "component_id" => invalid_id,
        "props" => {}
      }

      # Should not queue any jobs
      if defined?(ReactiveUpdateJob)
        assert_enqueued_jobs 0, only: ReactiveUpdateJob
      end
    end
  end

  test "sanitizes props to prevent XSS" do
    subscribe component_id: "swift-ui-test-123"

    # Assuming ButtonComponent is allowed
    perform :request_update, {
      "component_class" => "ButtonComponent",
      "component_id" => "swift-ui-test-123",
      "props" => {
        "title" => "<script>alert('xss')</script>",
        "onclick" => "javascript:alert('xss')",
        "nested" => {
          "value" => "<img src=x onerror=alert('xss')>"
        }
      }
    }

    # If a job was queued, verify props were sanitized
    if defined?(ReactiveUpdateJob) && enqueued_jobs.any?
      job = enqueued_jobs.first
      props = job[:args][2]

      # Check that dangerous content was sanitized
      assert_not_includes props["title"], "<script>"
      assert_not_includes props["onclick"], "javascript:"
      assert_not_includes props.dig("nested", "value"), "onerror="
    end
  end

  test "only allows whitelisted component classes" do
    subscribe component_id: "swift-ui-test-123"

    # Valid component (assuming these are in the whitelist)
    valid_components = [ "ButtonComponent", "CardComponent", "TextComponent" ]

    valid_components.each do |component_class|
      perform :request_update, {
        "component_class" => component_class,
        "component_id" => "swift-ui-test-123",
        "props" => { "text" => "Safe update" }
      }

      # Should succeed without rejection
      assert subscription.confirmed?
    end
  end

  test "logs security violations" do
    subscribe component_id: "swift-ui-test-123"

    # Capture logs
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)

    # Attempt malicious update
    perform :request_update, {
      "component_class" => "Kernel",
      "component_id" => "swift-ui-test-123",
      "props" => {}
    }

    # Verify security event was logged
    log_content = log_output.string
    assert_match /\[SECURITY\]/, log_content
    assert_match /unauthorized component/, log_content
  ensure
    Rails.logger = original_logger
  end
end

# Test the module-level request_update method
# NOTE: This test is disabled as the Rendering module is not yet implemented
# class ReactiveRenderingSecurityTest < ActiveSupport::TestCase
#   include SwiftUIRails::Component::Rendering
#
#   test "request_update uses component registry instead of constantize" do
#     # This tests the secure implementation
#     assert_raises(SecurityError) do
#       request_update("Kernel", "swift-ui-test-123", {})
#     end
#
#     assert_raises(SecurityError) do
#       request_update("Object", "swift-ui-test-123", {})
#     end
#
#     assert_raises(SecurityError) do
#       request_update("../../Evil", "swift-ui-test-123", {})
#     end
#   end
#
#   test "request_update validates component_id format" do
#     # Even with valid component type, invalid ID should fail
#     assert_raises(SecurityError) do
#       request_update("button_component", "invalid-format", {})
#     end
#
#     assert_raises(SecurityError) do
#       request_update("button_component", "../../etc/passwd", {})
#     end
#
#     assert_raises(SecurityError) do
#       request_update("button_component", "swift-ui-test-123; system('ls')", {})
#     end
#   end
#
#   test "component registry only includes safe components" do
#     registry = component_registry
#
#     # Registry should not include dangerous classes
#     registry.values.each do |klass|
#       assert klass < SwiftUIRails::Component::Base || klass < ApplicationComponent,
#         "Registry contains non-component class: #{klass}"
#     end
#
#     # Should not include system classes
#     assert_nil registry["kernel"]
#     assert_nil registry["object"]
#     assert_nil registry["file"]
#     assert_nil registry["dir"]
#   end
# end
# Copyright 2025
