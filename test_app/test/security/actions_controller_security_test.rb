# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class ActionsControllerSecurityTest < ActionDispatch::IntegrationTest
  class ReplayActionComponent < SwiftUIRails::Component::Base
    class_attribute :executions, default: 0
    class_attribute :received_detail, default: nil
    state :count, 0, type: Integer

    swift_ui do
      component = @component
      button("Increment once").on_click do |event|
        component.class.executions += 1
        component.class.received_detail = event.detail
        component.count += 1
      end
      text("Count: #{component.count}")
    end
  end

  class BranchDriftActionComponent < SwiftUIRails::Component::Base
    class_attribute :alternate_branch, default: false
    class_attribute :executions, default: 0
    state :ready, true

    swift_ui do
      component = @component
      if component.class.alternate_branch
        button("Alternate action").on_click do |_event|
          component.class.executions += 10
        end
      else
        button("Original action").on_click do |_event|
          component.class.executions += 1
        end
      end
    end
  end

  setup do
    @valid_action_id = "action-456"
    @capabilities = capabilities_for(CounterComponent.new)
  end

  test "requires both encrypted component capabilities" do
    post_action(snapshot_token: nil)
    assert_response :forbidden
    assert_equal({ "error" => "Action is not authorized" }, response.parsed_body)

    post_action(stream_token: nil)
    assert_response :forbidden
    assert_equal({ "error" => "Action is not authorized" }, response.parsed_body)

    post_action(snapshot_token: "forged")
    assert_response :forbidden

    post_action(stream_token: "forged")
    assert_response :forbidden
  end

  test "capabilities are bound to the component id and class" do
    post_action(component_id: "component-elsewhere")
    assert_response :forbidden

    post_action(component_class: "ButtonComponent")
    assert_response :forbidden
  end

  test "prevents RCE and does not reveal the component registry" do
    dangerous_classes = [
      "Kernel",
      "Object",
      "File",
      "Process",
      "ApplicationController",
      "ActiveRecord::Base",
      "eval",
      "__send__",
      "ButtonComponent'; system('id'); '"
    ]

    dangerous_classes.each do |component_class|
      post_action(component_class: component_class)
      assert_response :unprocessable_entity
      assert_equal({ "error" => "Action is not authorized" }, response.parsed_body)
    end
  end

  test "uses the shared deny-by-default component registry" do
    controller = SwiftUi::ActionsController.new

    assert_equal ButtonComponent, controller.send(:safe_constantize_component, "ButtonComponent")
    assert_raises(SwiftUIRails::SecurityError) do
      controller.send(:safe_constantize_component, "Kernel")
    end
  end

  test "validates component inheritance after allowlisting" do
    Object.const_set("FakeComponent", Class.new)
    configured = SwiftUIRails.configuration.allowed_components
    configured << "FakeComponent"
    controller = SwiftUi::ActionsController.new

    assert_raises(SwiftUIRails::SecurityError) do
      controller.send(:safe_constantize_component, "FakeComponent")
    end
  ensure
    configured&.delete("FakeComponent")
    Object.send(:remove_const, "FakeComponent") if Object.const_defined?("FakeComponent")
  end

  test "requires XHR or Turbo Stream format" do
    post swift_ui_actions_path, params: action_params

    assert_response :bad_request
    assert_equal({ "error" => "Invalid request format" }, response.parsed_body)
  end

  test "rejects malformed identifiers and events" do
    invalid_identifiers = [
      "",
      "../component",
      "component/name",
      "component;system",
      "component\nforged-header",
      " component",
      "a" * 129,
      nil,
      123,
      ["nested"]
    ]

    invalid_identifiers.each do |value|
      post_action(action_id: value)
      assert_response :unprocessable_entity

      post_action(component_id: value)
      assert_response :unprocessable_entity
    end

    post_action(event_type: "click;system")
    assert_response :unprocessable_entity
  end

  test "does not expose unexpected exception details" do
    CounterComponent.stub(:new, ->(**_props) { raise "database password leaked" }) do
      post_action
    end

    assert_response :unprocessable_entity
    assert_equal({ "error" => "Action could not be completed" }, response.parsed_body)
    refute_includes response.body, "database password leaked"
  end

  test "logs bounded audit context for rejected actions" do
    log_output = capture_rails_logs { post_action(snapshot_token: "forged") }

    assert_includes log_output, "[SECURITY AUDIT]"
    assert_includes log_output, "swift_ui_action_rejected"
    assert_includes log_output, "CounterComponent"
    refute_includes log_output, @capabilities.fetch(:snapshot_token)
  end

  test "CSRF and action security callbacks are enabled" do
    callbacks = SwiftUi::ActionsController._process_action_callbacks
      .select { |callback| callback.kind == :before }
      .map(&:filter)

    assert_includes callbacks, :verify_authenticity_token
    assert_includes callbacks, :verify_component_security
    assert_includes callbacks, :check_swift_ui_action_rate_limit
  end

  test "storybook actions cannot mutate a session owned by another browser" do
    get storybook_show_path, params: { story: "counter_component" }
    owned_session_id = request.session.fetch(:storybook_session_id)
    cache_accessed = false

    StorySession.stub(:find_or_create, ->(*) { cache_accessed = true }) do
      post_action(
        story_session_id: "#{owned_session_id}-other",
        story_name: "counter_component",
        story_variant: "default"
      )
    end

    assert_response :forbidden
    assert_equal({ "error" => "Action is not authorized" }, response.parsed_body)
    assert_not cache_accessed
  end

  test "component snapshots are single use so an action executes at most once" do
    with_configured_component(ReplayActionComponent) do
      ReplayActionComponent.executions = 0
      capabilities = rendered_action_capabilities(ReplayActionComponent.new, button_text: "Increment once")

      post_rendered_action(capabilities)
      assert_response :success
      assert_equal 1, ReplayActionComponent.executions
      assert_includes response.parsed_body.fetch("html"), "Count: 1"

      post_rendered_action(capabilities)
      assert_response :conflict
      assert_equal 1, ReplayActionComponent.executions
    end
  ensure
    ReplayActionComponent.executions = 0
    ReplayActionComponent.received_detail = nil
  end


  test "a negotiated component action returns a keyed patch without full html" do
    with_configured_component(ReplayActionComponent) do
      with_patch_cache do
        ReplayActionComponent.executions = 0
        capabilities = rendered_action_capabilities(ReplayActionComponent.new, button_text: "Increment once")

        post_rendered_action(capabilities, render_patch_version: 1)

        assert_response :success
        payload = response.parsed_body
        assert_equal 1, ReplayActionComponent.executions
        assert_equal 1, payload.dig("patch", "version")
        assert_equal capabilities.fetch(:component_id), payload.dig("patch", "component_id")
        assert_operator payload.dig("patch", "operations").length, :>, 0
        refute payload.key?("html")
      end
    end
  ensure
    ReplayActionComponent.executions = 0
    ReplayActionComponent.received_detail = nil
  end


  test "custom event detail reaches the component as a bounded native-style detail object" do
    with_configured_component(ReplayActionComponent) do
      ReplayActionComponent.executions = 0
      ReplayActionComponent.received_detail = nil
      capabilities = rendered_action_capabilities(ReplayActionComponent.new, button_text: "Increment once")

      post_rendered_action(
        capabilities,
        event_detail: {
          "gesture" => "drag",
          "translation" => { "x" => 12.5, "y" => -4 },
          "modifiers" => ["shift"]
        }
      )

      assert_response :success
      assert_equal "drag", ReplayActionComponent.received_detail.fetch("gesture")
      assert_equal 12.5, ReplayActionComponent.received_detail.dig("translation", "x")
    end
  ensure
    ReplayActionComponent.executions = 0
    ReplayActionComponent.received_detail = nil
  end

  test "oversized custom event detail is rejected before its snapshot is consumed" do
    with_configured_component(ReplayActionComponent) do
      ReplayActionComponent.executions = 0
      capabilities = rendered_action_capabilities(ReplayActionComponent.new, button_text: "Increment once")

      post_rendered_action(capabilities, event_detail: { "value" => "x" * 3.kilobytes })
      assert_response :unprocessable_entity
      assert_equal 0, ReplayActionComponent.executions

      post_rendered_action(capabilities, event_detail: { "value" => "safe" })
      assert_response :success
      assert_equal 1, ReplayActionComponent.executions
    end
  ensure
    ReplayActionComponent.executions = 0
    ReplayActionComponent.received_detail = nil
  end

  test "an action is rejected when conditional composition changes its identity" do
    with_configured_component(BranchDriftActionComponent) do
      BranchDriftActionComponent.alternate_branch = false
      BranchDriftActionComponent.executions = 0
      capabilities = rendered_action_capabilities(
        BranchDriftActionComponent.new,
        button_text: "Original action"
      )
      BranchDriftActionComponent.alternate_branch = true

      post_rendered_action(capabilities)

      assert_response :unprocessable_entity
      assert_equal 0, BranchDriftActionComponent.executions
      assert_equal({ "error" => "Action is not authorized" }, response.parsed_body)
    end
  ensure
    BranchDriftActionComponent.alternate_branch = false
    BranchDriftActionComponent.executions = 0
  end

  private

  def rendered_action_capabilities(component, button_text:)
    html = ApplicationController.render(component, layout: false)
    fragment = Nokogiri::HTML.fragment(html)
    root = fragment.at_css("[data-sui-root='1']")
    button = fragment.css("button").find { |candidate| candidate.text == button_text }
    action_id = JSON.parse(button["data-sui-actions"]).fetch("click")

    {
      action_id: action_id,
      component_id: root["id"],
      component_class: root["data-sui-component"],
      snapshot_token: root["data-sui-snapshot"],
      stream_token: root["data-sui-stream"],
      event_type: "click"
    }
  end

  def post_rendered_action(capabilities, **event_data)
    post swift_ui_actions_path,
      params: capabilities.merge(event_data),
      as: :json,
      headers: { "X-Requested-With" => "XMLHttpRequest" }
  end

  def with_configured_component(component_class)
    configured = SwiftUIRails.configuration.allowed_components
    configured.add(component_class.name)
    yield
  ensure
    configured&.delete(component_class.name)
  end

  def with_patch_cache(&block)
    cache = ActiveSupport::Cache::MemoryStore.new
    SwiftUIRails::RenderIR::PatchBaseline.stub(:cache, cache, &block)
  end

  def capabilities_for(component)
    component.register_component_action(@valid_action_id, ->(_event) {})
    html = ApplicationController.render(component, layout: false)
    root = Nokogiri::HTML.fragment(html).at_css("[data-sui-root='1']")

    {
      component_id: root["id"],
      component_class: component.class.name,
      snapshot_token: root["data-sui-snapshot"],
      stream_token: root["data-sui-stream"]
    }
  end

  def action_params
    @capabilities.merge(action_id: @valid_action_id, event_type: "click")
  end

  def post_action(**overrides)
    post swift_ui_actions_path,
      params: action_params.merge(overrides),
      as: :json,
      headers: { "X-Requested-With" => "XMLHttpRequest" }
  end

  def capture_rails_logs
    previous_logger = Rails.logger
    output = StringIO.new
    Rails.logger = ActiveSupport::Logger.new(output)
    yield
    output.string
  ensure
    Rails.logger = previous_logger
  end
end
