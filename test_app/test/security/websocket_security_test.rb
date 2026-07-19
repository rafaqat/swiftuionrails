require "test_helper"
require "minitest/mock"

class WebSocketSecurityTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  tests SwiftUIRails::Reactive::ReactiveChannel

  setup do
    clear_enqueued_jobs
    component = ReactiveCounterComponent.new
    markup = ApplicationController.render(component, layout: false)
    root = Nokogiri::HTML.fragment(markup).at_css("[data-sui-root='1']")
    @component_id = root["id"]
    @component_class = root["data-sui-component"]
    @stream_token = root["data-sui-stream"]
    @snapshot_token = root["data-sui-snapshot"]
  end

  test "keeps the websocket subscription read-only for every browser mutation payload" do
    subscribe_to_component
    dangerous_payloads = [
      { "component_class" => "Kernel", "component_id" => @component_id, "props" => {} },
      { "component_class" => "eval('malicious')", "component_id" => @component_id, "props" => {} },
      { "component_class" => @component_class, "component_id" => @component_id,
        "props" => { "title" => "<script>secret()</script>" } },
      { "component_class" => @component_class, "component_id" => "swift-ui-other-456", "props" => {} }
    ]

    dangerous_payloads.each do |payload|
      perform :request_update, payload
    end

    assert subscription.confirmed?
    assert_enqueued_jobs 0, only: SwiftUIRails::Reactive::ReactiveUpdateJob
    assert_equal dangerous_payloads.length, transmissions.length
    assert transmissions.all? { |payload| payload["action"] == "request_update_unsupported" }
    refute_includes transmissions.to_json, "secret"
  end

  test "rejects subscriptions with invalid component identifiers" do
    component_id = "../../private-stream"
    subscribe_to_component(component_id: component_id)

    assert subscription.rejected?
    assert_no_streams
  end

  test "accepts a valid component-bound stream token" do
    subscribe_to_component

    assert subscription.confirmed?
    assert_equal 1, subscription.streams.size
  end

  test "rejects subscriptions without a stream token" do
    subscribe_to_component(stream_token: nil)

    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects subscriptions with a forged stream token" do
    subscribe_to_component(stream_token: "forged-#{@stream_token}")

    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects subscriptions with a token bound to another component" do
    subscribe_to_component(stream_token: stream_token_for("swift-ui-other-456"))

    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects subscriptions with an expired stream token" do
    expired_token = stream_token_for(@component_id, expires_in: -1.second)
    subscribe_to_component(stream_token: expired_token)

    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects subscriptions without the encrypted component snapshot" do
    subscribe_to_component(snapshot_token: nil)

    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects forged snapshots" do
    subscribe_to_component(snapshot_token: "forged")
    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects snapshots bound to another component class" do
    subscribe_to_component(component_class: "ButtonComponent")
    assert subscription.rejected?
    assert_no_streams
  end

  test "logs rejected browser mutation attempts without reflecting their content" do
    subscribe_to_component
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)

    perform :request_update, {
      "component_class" => "Kernel",
      "component_id" => @component_id,
      "props" => { "secret" => "do-not-reflect" }
    }

    log_content = log_output.string
    assert_match /\[SECURITY\]/, log_content
    assert_match /Unsupported WebSocket component mutation/, log_content
    refute_includes log_content, "do-not-reflect"
  ensure
    Rails.logger = original_logger
  end

  private

  def subscribe_to_component(component_id: @component_id, component_class: @component_class,
    stream_token: @stream_token, snapshot_token: @snapshot_token)
    subscribe(
      component_id: component_id,
      component_class: component_class,
      stream_token: stream_token,
      snapshot_token: snapshot_token
    )
  end

  def stream_token_for(component_id, expires_in: 10.minutes)
    SwiftUIRails::Reactive::ReactiveStreamToken.generate(component_id, expires_in: expires_in)
  end
end


class ReactiveUpdateJobSecurityTest < ActiveSupport::TestCase
  test "rejects blank, non-string, and non-allowlisted component inputs" do
    job = SwiftUIRails::Reactive::ReactiveUpdateJob.new

    [nil, "", 123, "Kernel", "TextComponent"].each do |component_name|
      assert_raises(SwiftUIRails::SecurityError) do
        job.perform(component_name, "swift-ui-test-123", {})
      end
    end

    [nil, 123, "../../stream", "swift-ui-#{'a' * 200}-1"].each do |component_id|
      assert_raises(SwiftUIRails::SecurityError) do
        job.perform("ButtonComponent", component_id, {})
      end
    end
  end

  test "sanitizes nested broadcast props at the job boundary" do
    payload = nil
    broadcast = ->(_component_id, value) { payload = value }

    SwiftUIRails::Reactive::ReactiveChannel.stub(:broadcast_to, broadcast) do
      SwiftUIRails::Reactive::ReactiveUpdateJob.new.perform(
        "ButtonComponent",
        "swift-ui-test-123",
        {
          label: "<script>alert('xss')</script>Safe",
          href: "javascript:alert('xss')",
          nested: [{ html: "<img src=x onerror=alert(1)>" }]
        }
      )
    end

    assert_not_includes payload.dig(:props, "label"), "<script"
    assert payload.dig(:props, "label").end_with?("Safe")
    assert_equal "", payload.dig(:props, "href")
    refute_includes payload.dig(:props, "nested", 0, "html"), "onerror"
  end
end

# Test the module-level request_update method
class ReactiveRenderingSecurityTest < ActiveSupport::TestCase
  class RenderingProbe
    include SwiftUIRails::Reactive::Rendering
  end

  setup do
    @controller = Class.new(ApplicationController) do
      include SwiftUIRails::Reactive::ReactiveController
    end.new
  end
  
  test "request_update rejects every direct server-side call" do
    error = assert_raises(SwiftUIRails::Error) do
      @controller.send(:request_update, "Kernel", "swift-ui-test-123", {})
    end

    assert_match(/unsupported/, error.message)
  end
  
  test "component registry only includes safe components" do
    registry = @controller.send(:component_registry)
    
    # Registry should not include dangerous classes
    registry.values.each do |klass|
      assert klass < SwiftUIRails::Component::Base || klass < ApplicationComponent,
        "Registry contains non-component class: #{klass}"
    end
    
    # Should not include system classes
    assert_nil registry["kernel"]
    assert_nil registry["object"]
    assert_nil registry["file"]
    assert_nil registry["dir"]
  end

  test "reactive rendering emits one component-bound semantic root" do
    component_id = "swift-ui-rendering-probe-123"
    stream_token = SwiftUIRails::Reactive::ReactiveStreamToken.generate(component_id)
    probe = RenderingProbe.new

    markup = probe.send(:wrap_with_reactive_container, "<span>Safe</span>".html_safe, component_id, stream_token)
    element = Nokogiri::HTML.fragment(markup).at_css("[data-sui-root='1']")

    assert_equal component_id, element["data-sui-id"]
    assert_equal stream_token, element["data-sui-stream"]
    assert SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?(stream_token, component_id)

    assert_nil Nokogiri::HTML.fragment(markup).at_css("script")
    assert_equal "/swift_ui/components/update", element["data-sui-update-url"]
    assert_nil element["data-controller"]
  end

  test "reactive rendering compatibility wrapper escapes untrusted content through RenderIR" do
    component_id = "swift-ui-rendering-probe-unsafe-123"
    probe = RenderingProbe.new

    markup = probe.send(
      :wrap_with_reactive_container,
      '<img src=x onerror="alert(1)">',
      component_id
    )
    fragment = Nokogiri::HTML.fragment(markup)

    assert_nil fragment.at_css("img")
    assert_includes markup, "&lt;img src=x onerror=&quot;alert(1)&quot;&gt;"
    assert_equal component_id, fragment.at_css("[data-sui-root]")["id"]
  end

  test "stream tokens cannot be forged, replayed for another component, or used after expiry" do
    component_id = "swift-ui-rendering-probe-123"
    token = SwiftUIRails::Reactive::ReactiveStreamToken.generate(component_id)
    expired_token = SwiftUIRails::Reactive::ReactiveStreamToken.generate(component_id, expires_in: -1.second)

    assert SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?(token, component_id)
    refute SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?("forged-#{token}", component_id)
    refute SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?(token, "swift-ui-other-456")
    refute SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?(expired_token, component_id)
  end
end
