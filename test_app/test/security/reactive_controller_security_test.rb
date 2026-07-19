require "test_helper"
require "minitest/mock"

class ReactiveControllerSecurityTest < ActiveSupport::TestCase
  class UpdateProbeComponent < SwiftUIRails::Component::Base
    prop :label, type: String, default: "Default"
    prop :description, type: String, default: nil
    prop :mode, type: Symbol, default: :safe, enum: %i[safe fast]
    binding :selected, type: [TrueClass, FalseClass], default: true

    def call
      "<span>#{ERB::Util.html_escape(label)}</span>".html_safe
    end
  end

  setup do
    @controller = Class.new(ApplicationController) do
      include SwiftUIRails::Reactive::ReactiveController
    end.new
  end

  test "prevents RCE by rejecting arbitrary class names" do
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
      error = assert_raises(SwiftUIRails::SecurityError) do
        @controller.send(:safe_constantize, class_name)
      end

      assert_match(/Invalid component class/, error.message)
    end
  end

  test "allows only whitelisted components" do
    allowed_components = %w[
      ButtonComponent
      CardComponent
      ModalComponent
      CounterComponent
    ]

    allowed_components.each do |component_class_name|
      component_class = component_class_name.constantize

      assert_same component_class,
        @controller.send(:safe_constantize, component_class_name)
    end
  end

  test "application configuration extends the component registry explicitly" do
    configured = SwiftUIRails.configuration.allowed_components

    with_object_constant("ConfiguredProbeComponent", Class.new(SwiftUIRails::Component::Base)) do
      configured.add("ConfiguredProbeComponent")

      assert_same ConfiguredProbeComponent,
        @controller.send(:safe_constantize, "ConfiguredProbeComponent")
      assert_includes SwiftUIRails::Reactive::ReactiveController.allowed_component_names,
        "ConfiguredProbeComponent"
    ensure
      configured.delete("ConfiguredProbeComponent")
    end
  end

  test "component registry is populated from the controller allowlist" do
    registry = @controller.send(:component_registry)

    assert_same ButtonComponent, registry.fetch("button_component")
    assert_same CounterComponent, registry.fetch("counter_component")
    assert_nil registry["kernel"]
  end

  test "sanitizes dangerous prop values" do
    dangerous_props = {
      "onclick" => "eval('alert(1)')",
      "data" => "__send__(:eval, 'alert(1)')",
      "action" => "system('rm -rf /')",
      "command" => "`touch /tmp/hacked`",
      "exec" => "exec('ls')",
      "constantize_me" => "Kernel.constantize",
      "label" => "Safe label"
    }

    sanitized = @controller.send(:sanitize_component_props, dangerous_props)

    assert_equal "Safe label", sanitized["label"]
    dangerous_props.except("label").each_key do |key|
      refute sanitized.key?(key), "Expected dangerous prop #{key.inspect} to be removed"
    end
    refute File.exist?("/tmp/hacked")
  end

  test "recursively sanitizes dangerous prop values" do
    props = {
      "config" => {
        "label" => "Safe nested label",
        "callback" => "Object.__send__(:eval, 'malicious')"
      },
      "items" => [
        "Safe item",
        "Kernel.constantize",
        { "command" => "exec('malicious')", "count" => 2 }
      ],
      "description" => "Send evaluation results through the system"
    }

    sanitized = @controller.send(:sanitize_component_props, props)

    assert_equal({ "label" => "Safe nested label" }, sanitized["config"])
    assert_equal ["Safe item", { "count" => 2 }], sanitized["items"]
    assert_equal "Send evaluation results through the system", sanitized["description"]
  end

  test "sanitizes unpermitted ActionController parameter hashes instead of discarding them" do
    parameters = ActionController::Parameters.new(
      label: "Safe label",
      nested: {
        description: "Safe nested value",
        callback: "Kernel.constantize"
      }
    )

    sanitized = @controller.send(:sanitize_component_props, parameters)

    assert_equal "Safe label", sanitized["label"]
    assert_equal({ "description" => "Safe nested value" }, sanitized["nested"])
  end

  test "update_component applies only declared and type-valid prop and binding changes" do
    rendered_component = nil
    component_id = "swift-ui-update-probe-123"
    source_component = UpdateProbeComponent.new(label: "Before")
    prepare_controller(
      params: {
        component_class: UpdateProbeComponent.name,
        component_id: component_id,
        stream_token: stream_token_for(component_id),
        snapshot_token: snapshot_for(source_component, component_id),
        props: {
          label: "Browser supplied value is ignored",
          undeclared_constructor_argument: "ignored"
        },
        changes: {
          "prop.label" => { new: "After" },
          "binding.selected" => { new: false },
          "prop.undeclared" => { new: "ignored" },
          "binding.admin" => { new: true },
          "state.admin" => { new: true }
        }
      }
    )

    with_allowed_component(UpdateProbeComponent.name) do
      @controller.stub(:render_to_string, ->(component) { rendered_component = component; "<span>rendered</span>" }) do
        @controller.update_component
      end
    end

    assert_equal 200, @controller.response.status
    assert_equal "Before", rendered_component.label
    assert_equal false, rendered_component.selected_value
    refute rendered_component.instance_variable_defined?(:@undeclared)
    refute rendered_component.instance_variable_defined?(:@admin)
  end

  test "update_component requires a valid token bound to its component identifier" do
    component_id = "swift-ui-update-probe-123"
    invalid_capabilities = [
      [component_id, nil],
      [component_id, "forged-#{stream_token_for(component_id)}"],
      [component_id, stream_token_for("swift-ui-other-456")],
      [component_id, stream_token_for(component_id, expires_in: -1.second)],
      ["invalid-component-id", stream_token_for("invalid-component-id")]
    ]

    invalid_capabilities.each do |requested_component_id, stream_token|
      @controller = @controller.class.new
      source_component = CounterComponent.new
      prepare_controller(
        params: {
          component_class: "CounterComponent",
          component_id: requested_component_id,
          stream_token: stream_token,
          snapshot_token: snapshot_for(source_component, requested_component_id),
          props: {}
        }
      )

      @controller.update_component

      assert_equal 403, @controller.response.status
      assert_equal({ "error" => "Unauthorized component update" }, JSON.parse(@controller.response.body))
    end
  end

  test "update_component ignores type-invalid and dangerous declared changes" do
    component_props, binding_changes = @controller.send(
      :component_update_attributes,
      UpdateProbeComponent,
      ActionController::Parameters.new(label: "Before"),
      ActionController::Parameters.new(
        "prop.label" => { new: 123 },
        "binding.selected" => { new: "yes" },
        "prop.description" => { new: "eval('unsafe')" }
      )
    )

    assert_equal({ "label" => "Before" }, component_props)
    assert_empty binding_changes
  end

  test "snapshot props restore only enum-backed symbol values before type filtering" do
    component_props, = @controller.send(
      :component_update_attributes,
      UpdateProbeComponent,
      ActionController::Parameters.new(mode: "fast"),
      ActionController::Parameters.new
    )

    assert_equal :fast, component_props.fetch("mode")

    rejected_props, = @controller.send(
      :component_update_attributes,
      UpdateProbeComponent,
      ActionController::Parameters.new(mode: "untrusted"),
      ActionController::Parameters.new
    )
    assert_empty rejected_props
  end

  test "requires XHR or Turbo Stream format" do
    prepare_controller(xhr: false)

    refute @controller.send(:verify_component_security)
    assert_equal 400, @controller.response.status
    assert_equal({ "error" => "Invalid request format" }, JSON.parse(@controller.response.body))
  end

  test "logs security events for snapshots bound to another component class" do
    component_id = "swift-ui-unauthorized-123"
    source_component = CounterComponent.new
    prepare_controller(
      params: {
        component_class: "Kernel",
        component_id: component_id,
        stream_token: stream_token_for(component_id),
        snapshot_token: snapshot_for(source_component, component_id),
        props: {}
      }
    )

    log_output = capture_rails_logs { @controller.update_component }

    assert_equal 403, @controller.response.status
    assert_equal({ "error" => "Unauthorized component snapshot" }, JSON.parse(@controller.response.body))
    assert_includes log_output, "[SECURITY]"
    assert_includes log_output, "invalid component snapshot"
    assert_includes log_output, "[SECURITY AUDIT]"
  end

  test "validates component inheritance" do
    with_object_constant("FakeComponent", Class.new) do
      with_allowed_component("FakeComponent") do
        error = assert_raises(SwiftUIRails::SecurityError) do
          @controller.send(:safe_constantize, "FakeComponent")
        end

        assert_match(/not a valid SwiftUI Rails component/, error.message)
      end
    end
  end

  test "handles missing component classes gracefully" do
    with_allowed_component("NonExistentComponent") do
      error = assert_raises(SwiftUIRails::SecurityError) do
        @controller.send(:safe_constantize, "NonExistentComponent")
      end

      assert_match(/Component class not found/, error.message)
    end
  end

  private

  def prepare_controller(params: {}, xhr: true)
    request = ActionController::TestRequest.create(@controller.class)
    request.headers["HTTP_X_REQUESTED_WITH"] = "XMLHttpRequest" if xhr
    request.headers["HTTP_ACCEPT"] = "application/json"

    @controller.set_request!(request)
    @controller.set_response!(ActionDispatch::TestResponse.new)
    @controller.params = ActionController::Parameters.new(params)
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

  def stream_token_for(component_id, expires_in: 10.minutes)
    SwiftUIRails::Reactive::ReactiveStreamToken.generate(component_id, expires_in: expires_in)
  end

  def snapshot_for(component, component_id)
    SwiftUIRails::Reactive::ReactiveComponentSnapshot.generate(
      component,
      component_id: component_id
    )
  end

  def with_allowed_component(component_class_name)
    owner = SwiftUIRails::Reactive::ReactiveController
    original = owner.const_get(:ALLOWED_COMPONENTS, false)
    replacement = original.dup.add(component_class_name).freeze

    owner.send(:remove_const, :ALLOWED_COMPONENTS)
    owner.const_set(:ALLOWED_COMPONENTS, replacement)
    yield
  ensure
    if owner
      owner.send(:remove_const, :ALLOWED_COMPONENTS) if owner.const_defined?(:ALLOWED_COMPONENTS, false)
      owner.const_set(:ALLOWED_COMPONENTS, original) if original
    end
  end

  def with_object_constant(name, value)
    raise "Constant #{name} is already defined" if Object.const_defined?(name, false)

    Object.const_set(name, value)
    yield
  ensure
    Object.send(:remove_const, name) if Object.const_defined?(name, false)
  end
end
