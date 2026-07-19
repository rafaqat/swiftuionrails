# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class SwiftUIRails::CoreRegressionsTest < ViewComponent::TestCase
  class ReactiveSwiftUIComponent < SwiftUIRails::Component::Base
    state :count, 0

    swift_ui do
      text("Count: #{count}")
    end
  end

  class InheritedSwiftUIComponent < SwiftUIRails::Component::Base
    swift_ui do
      text("Inherited Swift UI")
    end
  end

  class SwiftUIChildComponent < InheritedSwiftUIComponent
  end

  class ActionComponent < SwiftUIRails::Component::Base
    attr_reader :received_event_value

    swift_ui do
      button("Run").on_click do |event|
        @received_event_value = event.value
      end
    end
  end

  class ReactivePropsComponent < SwiftUIRails::Component::Base
    prop :enabled, type: [TrueClass, FalseClass], default: true
    prop :count, type: Integer, default: 0
    prop :mode, type: Symbol, default: :safe, enum: %i[safe fast]

    def trigger_update
      # Keep this unit test independent from the Active Job adapter.
    end
  end

  class UnboundedSymbolPropComponent < SwiftUIRails::Component::Base
    prop :mode, type: Symbol, default: :safe
  end

  class FocusRestoreComponent < SwiftUIRails::Component::Base
    focus_state :focused_field, values: %i[email password]
  end

  class MutableDefaultsComponent < SwiftUIRails::Component::Base
    prop :options, type: Array, default: []
    state :items, []
    state :owner_id, -> { object_id }
  end

  class PersistentStateComponent < SwiftUIRails::Component::Base
    state :count, 0
    state :items, []
  end

  class CallableRestoreComponent < SwiftUIRails::Component::Base
    class_attribute :initializer_calls, default: 0

    state :nonce, -> {
      self.class.initializer_calls += 1
      "nonce-#{self.class.initializer_calls}"
    }
  end

  class OversizedSnapshotComponent < SwiftUIRails::Component::Base
    prop :payload, type: String, default: ""
    state :enabled, true

    swift_ui do
      text("Oversized snapshot probe")
    end
  end

  class CrossValidatedPropsComponent < SwiftUIRails::Component::Base
    prop :lower, type: Integer, default: 1, validate: ->(value) { value <= upper }
    prop :upper, type: Integer, default: 5

    def trigger_update
      # Keep this unit test independent from the Active Job adapter.
    end
  end

  class PrivateValidatedPropsComponent < SwiftUIRails::Component::Base
    prop :lower, type: Integer, default: 1
    prop :upper, type: Integer, default: 5

    def trigger_update
      # Keep this unit test independent from the Active Job adapter.
    end

    private

    def validate_props!
      raise ArgumentError, "lower must not exceed upper" if lower > upper
    end
  end

  class BindingOwnerComponent < SwiftUIRails::Component::Base
    binding :enabled, default: true
    binding :profile, default: { user: { name: "Ada" } }
    binding :token, default: -> { SecureRandom.hex(4) }
    binding :count, type: Integer, default: 0
  end

  class BindingChildComponent < SwiftUIRails::Component::Base
    binding :enabled, default: false
    binding :count, type: Integer, default: 0
  end

  class BindingSiblingComponent < SwiftUIRails::Component::Base
  end

  class ObservedOwnerComponent < SwiftUIRails::Component::Base
    observed_object :shared_store
  end

  class ObservedSiblingComponent < SwiftUIRails::Component::Base
  end

  class BindingMetadataComponent < SwiftUIRails::Component::Base
    binding :query, type: String, default: "Ada"
    binding :enabled, type: [TrueClass, FalseClass], default: true

    swift_ui do
      vstack do
        textfield(**query.input_attributes(placeholder: "Search"))
        input(type: "checkbox", **enabled.checkbox_attributes)
      end
    end
  end

  class ObservedLifecycleComponent < SwiftUIRails::Component::Base
    observed_object :lifecycle_store, store: :reactive_lifecycle

    attr_reader :subscription_count_during_render, :change_seen_during_render

    def call
      @subscription_count_during_render = lifecycle_store.subscription_count
      lifecycle_store.set(:count, lifecycle_store.get(:count).to_i + 1)
      @change_seen_during_render = needs_rerender?
      "<span>Observed</span>".html_safe
    end
  end

  class AuthoritativeObservedComponent < SwiftUIRails::Component::Base
    class_attribute :authoritative_count, default: 0

    observed_resource :metrics, stream: :authoritative_metrics do
      { count: self.class.authoritative_count }
    end

    swift_ui do
      text("Authoritative: #{@component.metrics.data.fetch(:count)}")
    end
  end

  class PrivateObservedComponent < SwiftUIRails::Component::Base
    observed_object :private_metrics,
      stream: :private_metrics,
      store: -> { SwiftUIRails::Reactive::ObservableStore.new(:private_metrics, secret: "server-only-value") }

    swift_ui do
      text("Metrics are ready")
    end
  end

  class StandaloneReactiveState
    include SwiftUIRails::Reactive

    state :items, []
    state :contextual_items, -> { build_items }

    private

    def build_items
      [object_id]
    end
  end

  class NestedHelperComponent < SwiftUIRails::Component::Base
    swift_ui do
      div.relative do
        render_helper_content
      end
    end

    private

    def render_helper_content
      text("Nested helper content")
    end
  end

  test "stateful swift_ui components render their reactive container" do
    render_inline(ReactiveSwiftUIComponent.new)

    assert_selector "div[data-sui-root='1'][data-sui-component='SwiftUIRails::CoreRegressionsTest::ReactiveSwiftUIComponent']", text: "Count: 0"
    refute_selector "[data-controller], [data-action]"
  end

  test "subclasses inherit their parent's swift_ui definition" do
    render_inline(SwiftUIChildComponent.new)

    assert_text "Inherited Swift UI"
  end

  test "registered component actions execute with event data" do
    component = ActionComponent.new
    render_inline(component)

    action_id = component.registered_actions.fetch(0)
    component.execute_action(action_id, value: "received")

    assert_equal "received", component.received_event_value
  end

  test "reactive prop updates support union types" do
    component = ReactivePropsComponent.new(enabled: true)

    component.update_reactive_state(enabled: false)

    assert_equal false, component.enabled
  end

  test "reactive prop updates preserve declared validation rules" do
    component = ReactivePropsComponent.new(mode: :safe)

    component.update_reactive_state(mode: :unsafe)

    assert_equal :safe, component.mode
  end

  test "reactive prop batches validate atomically and roll back together" do
    component = CrossValidatedPropsComponent.new(lower: 1, upper: 5)

    component.update_reactive_state(lower: 10, upper: 12)
    assert_equal [10, 12], [component.lower, component.upper]

    component.update_reactive_state(lower: 20, upper: 15)
    assert_equal [10, 12], [component.lower, component.upper]
  end

  test "private component validation hooks run during construction and reactive updates" do
    assert_raises(ArgumentError) do
      PrivateValidatedPropsComponent.new(lower: 6, upper: 5)
    end

    component = PrivateValidatedPropsComponent.new(lower: 1, upper: 5)
    component.update_reactive_state(lower: 9)

    assert_equal 1, component.lower
    assert_equal 5, component.upper
  end

  test "reactive prop comparison and serialization use swift prop definitions" do
    component = ReactivePropsComponent.new(enabled: false, count: 3)

    assert_equal({ enabled: false, count: 3, mode: :safe }, component.send(:serialize_props))
    assert component.should_update?(enabled: true)
    refute component.should_update?(enabled: false, count: 3)
  end

  test "snapshot restoration rehydrates only allowlisted symbol props" do
    restored = ReactivePropsComponent.restore_reactive_snapshot(
      props: JSON.parse({ mode: :fast }.to_json),
      state: {},
      bindings: {},
      component_id: "swift-ui-reactive-props-123"
    )

    assert_equal :fast, restored.mode

    assert_raises(TypeError) do
      ReactivePropsComponent.restore_reactive_snapshot(
        props: { "mode" => "unsafe" },
        state: {},
        bindings: {},
        component_id: "swift-ui-reactive-props-124"
      )
    end

    assert_raises(TypeError) do
      UnboundedSymbolPropComponent.restore_reactive_snapshot(
        props: { "mode" => "attacker_controlled" },
        state: {},
        bindings: {},
        component_id: "swift-ui-unbounded-symbol-123"
      )
    end
  end

  test "snapshot restoration rehydrates and validates declared focus values" do
    source = FocusRestoreComponent.new
    source.focused_field = :password
    component_id = "swift-ui-focus-restore-123"
    token = SwiftUIRails::Reactive::ReactiveComponentSnapshot.generate(
      source,
      component_id: component_id
    )
    snapshot = SwiftUIRails::Reactive::ReactiveComponentSnapshot.verified(
      token,
      component_id: component_id,
      component_class: FocusRestoreComponent.name
    )

    assert_equal "password", snapshot.dig("state", "focused_field")
    restored = FocusRestoreComponent.restore_reactive_snapshot(
      props: {},
      state: snapshot.fetch("state"),
      bindings: {},
      component_id: component_id
    )

    assert_equal :password, restored.focused_field

    error = assert_raises(ArgumentError) do
      FocusRestoreComponent.restore_reactive_snapshot(
        props: {},
        state: { "focused_field" => "admin" },
        bindings: {},
        component_id: "swift-ui-focus-restore-124"
      )
    end
    assert_includes error.message, "must be one of"
  end

  test "mutable prop and state defaults are isolated per component" do
    first = MutableDefaultsComponent.new
    second = MutableDefaultsComponent.new

    first.options << :first
    first.items << :first

    assert_equal [:first], first.options
    assert_equal [], second.options
    assert_equal [:first], first.items
    assert_equal [], second.items
    assert_equal first.object_id, first.owner_id
    assert_equal second.object_id, second.owner_id
  end

  test "persisted state restores declared keys without exposing internal storage" do
    component = PersistentStateComponent.new
    component.state_values = { "count" => 4, "unknown" => "ignored" }

    assert_equal 4, component.count
    refute_includes component.state_values, :unknown

    snapshot = component.state_values
    snapshot[:count] = 99
    assert_equal 4, component.count
    assert_raises(TypeError) { component.state_values = "not a hash" }
  end

  test "bindings retain false instead of falling back to their default" do
    component = BindingOwnerComponent.new
    changes = []

    assert_equal true, component.enabled.value
    component.enabled.on_change { |new_value, old_value| changes << [old_value, new_value] }
    component.enabled.value = false

    assert_equal false, component.enabled.value
    assert_equal [[true, false]], changes
  end

  test "binding projections read hashes and remain reusable for writes" do
    component = BindingOwnerComponent.new
    name = component.profile.project("user.name")

    assert_equal "Ada", name.value
    name.value = "Grace"
    assert_equal "Grace", name.value
    name.value = "Matz"

    assert_equal "Matz", name.value
    assert_equal "Matz", component.profile.value.dig(:user, :name)
  end

  test "callable binding defaults are evaluated once per component" do
    component = BindingOwnerComponent.new

    assert_equal component.token.value, component.token.value
  end

  test "mutable binding defaults are isolated per component" do
    first = BindingOwnerComponent.new
    second = BindingOwnerComponent.new

    first.profile.value[:user][:name] = "Grace"

    assert_equal "Grace", first.profile.value.dig(:user, :name)
    assert_equal "Ada", second.profile.value.dig(:user, :name)
  end

  test "typed bindings reject incompatible values without changing state" do
    component = BindingOwnerComponent.new

    assert_raises(TypeError) { component.count.value = "one" }
    assert_equal 0, component.count.value
  end

  test "multiple child bindings remain synchronized with their parent" do
    parent = BindingOwnerComponent.new
    child = BindingChildComponent.new
    parent.send(:pass_binding, child, :enabled)
    parent.send(:pass_binding, child, :count)

    child.enabled.value = false
    child.count.value = 3

    assert_equal false, child.enabled.value
    assert_equal false, parent.enabled.value
    assert_equal 3, child.count.value
    assert_equal 3, parent.count.value
  end

  test "reactive definitions do not leak into sibling component classes" do
    assert_includes BindingOwnerComponent.binding_definitions, :enabled
    refute_includes BindingSiblingComponent.binding_definitions, :enabled
    refute_includes SwiftUIRails::Component::Base.binding_definitions, :enabled

    assert_includes ObservedOwnerComponent.observed_object_definitions, :shared_store
    refute_includes ObservedSiblingComponent.observed_object_definitions, :shared_store
    refute_includes SwiftUIRails::Component::Base.observed_object_definitions, :shared_store
  end

  test "standalone callable state is evaluated per instance without class-time side effects" do
    first = StandaloneReactiveState.new
    second = StandaloneReactiveState.new

    first.items << :first
    first.contextual_items << :changed

    assert_equal [:first], first.items
    assert_equal [], second.items
    assert_equal [first.object_id, :changed], first.contextual_items
    assert_equal [second.object_id], second.contextual_items
    assert_includes first.state_dependencies, "state.contextual_items"
    assert first.send(:generate_state_fingerprint).present?
  end

  test "component state definitions and fingerprints share one reactive source" do
    component = ReactiveSwiftUIComponent.new
    initial_fingerprint = component.send(:generate_state_fingerprint)

    assert_equal component.class.swift_states.keys, component.class.state_definitions.keys
    refute component.should_update?

    component.count = 1

    assert component.should_update?
    refute_equal initial_fingerprint, component.send(:generate_state_fingerprint)
    component.capture_reactive_dependency_snapshot!
    refute component.should_update?
  end

  test "snapshot restoration does not rerun callable state initializers" do
    CallableRestoreComponent.initializer_calls = 0
    source = CallableRestoreComponent.new

    restored = CallableRestoreComponent.restore_reactive_snapshot(
      props: {},
      state: source.state_values,
      bindings: {},
      component_id: "swift-ui-callable-restore-123"
    )

    assert_equal 1, CallableRestoreComponent.initializer_calls
    assert_equal "nonce-1", source.nonce
    assert_equal source.nonce, restored.nonce
  ensure
    CallableRestoreComponent.initializer_calls = 0
  end

  test "reactive capabilities are bound to the configured authorization context" do
    component = ReactiveSwiftUIComponent.new
    component_id = component.component_id
    stream_token = SwiftUIRails::Reactive::ReactiveStreamToken.generate(
      component_id,
      authorization_context: "session-a:tenant-1"
    )
    snapshot_token = SwiftUIRails::Reactive::ReactiveComponentSnapshot.generate(
      component,
      component_id: component_id,
      authorization_context: "session-a:tenant-1"
    )

    assert SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?(
      stream_token,
      component_id,
      authorization_context: "session-a:tenant-1"
    )
    refute SwiftUIRails::Reactive::ReactiveStreamToken.valid_for?(
      stream_token,
      component_id,
      authorization_context: "session-b:tenant-1"
    )
    assert SwiftUIRails::Reactive::ReactiveComponentSnapshot.verified(
      snapshot_token,
      component_id: component_id,
      component_class: component.class.name,
      authorization_context: "session-a:tenant-1"
    )
    assert_nil SwiftUIRails::Reactive::ReactiveComponentSnapshot.verified(
      snapshot_token,
      component_id: component_id,
      component_class: component.class.name,
      authorization_context: "session-a:tenant-2"
    )
  end

  test "authorization context hook failures fail closed instead of issuing unbound capabilities" do
    configuration = SwiftUIRails.configuration
    original = configuration.reactive_authorization_context
    configuration.reactive_authorization_context = ->(_subject) { raise "tenant resolver failed" }

    error = assert_raises(RuntimeError) do
      SwiftUIRails::Reactive::ReactiveAuthorizationContext.resolve(Object.new)
    end

    assert_equal "tenant resolver failed", error.message
  ensure
    configuration.reactive_authorization_context = original if configuration
  end

  test "custom authorization context augments the built-in session scope" do
    configuration = SwiftUIRails.configuration
    original = configuration.reactive_authorization_context
    session = Struct.new(:id).new("session-a")
    request = Struct.new(:session).new(session)
    subject = Struct.new(:request).new(request)
    configuration.reactive_authorization_context = ->(_subject) { "tenant-a" }

    initial = SwiftUIRails::Reactive::ReactiveAuthorizationContext.resolve(subject)
    session.id = "session-b"
    changed_session = SwiftUIRails::Reactive::ReactiveAuthorizationContext.resolve(subject)
    session.id = "session-a"
    configuration.reactive_authorization_context = ->(_subject) { "tenant-b" }
    changed_tenant = SwiftUIRails::Reactive::ReactiveAuthorizationContext.resolve(subject)

    assert_includes initial, "session-a"
    assert_includes initial, "tenant-a"
    refute_equal initial, changed_session
    refute_equal initial, changed_tenant
  ensure
    configuration.reactive_authorization_context = original if configuration
  end

  test "oversized reactive snapshots fail before markup can carry an unusable token" do
    component = OversizedSnapshotComponent.new(payload: "x" * 200.kilobytes)

    error = assert_raises(SwiftUIRails::Reactive::ReactiveComponentSnapshot::SnapshotTooLargeError) do
      component.call
    end

    assert_match(/exceeds/, error.message)
    assert_nil component.send(:reactive_snapshot_token)
  end

  test "reactive snapshots reject Active Record instances instead of changing their prop type" do
    record = ActiveRecord::Base.allocate

    error = assert_raises(SwiftUIRails::Reactive::ReactiveComponentSnapshot::UnsupportedValueError) do
      ReactiveSwiftUIComponent.new.send(:serialize_value, record)
    end

    assert_match(/stable identifier/, error.message)
  end

  test "state invalidation metadata never embeds old or new state values" do
    component = ReactiveSwiftUIComponent.new
    component.count = 42
    component.instance_variable_set(:@_content, "<span>Safe</span>")

    component.send(:generate_state_updates)
    markup = component.instance_variable_get(:@_content).to_s
    element = Nokogiri::HTML5.fragment(markup).at_css("span")
    attribute_names = element.attribute_nodes.map(&:name)
    attribute_values = element.attribute_nodes.map(&:value)

    assert_equal "true", element["data-state-invalidated"]
    assert element["data-state-generation"].present?
    refute attribute_names.any? { |name| name.match?(/old|new|count/) }
    refute_includes attribute_values, "42"
    assert_equal "Safe", element.text
  end

  test "dependency invalidation detects in-place state collection changes" do
    component = MutableDefaultsComponent.new

    refute component.should_update?
    component.items << :changed_without_a_setter

    assert component.should_update?
    assert component.send(:dependency_changed?, "state.items")
  end

  test "binding metadata wires typed DSL controls with HTML fallback values" do
    render_inline(BindingMetadataComponent.new)

    assert_selector "input[name='query'][value='Ada'][data-sui-binding='query'][data-sui-binding-type='string']"
    assert_selector "input[type='checkbox'][name='enabled'][checked][data-sui-binding='enabled'][data-sui-binding-type='boolean']"
    assert_raises(ArgumentError) { BindingMetadataComponent.new.query.project(:length).metadata }
  end

  test "observed object subscriptions are active during render and always released" do
    store = SwiftUIRails::Reactive::ObservableStore.find_or_create(:reactive_lifecycle)
    store.reset(count: 0)
    component = ObservedLifecycleComponent.new

    assert_equal 0, store.subscription_count
    render_inline(component)

    assert_equal 1, component.subscription_count_during_render
    assert component.change_seen_during_render
    assert_equal 0, store.subscription_count
  end

  test "observable store zero-arity updates do not recursively lock" do
    store = SwiftUIRails::Reactive::ObservableStore.new(:core_regression, count: 1)

    store.update do
      self.count = count + 1
    end

    assert_equal 2, store.get(:count)
  end

  test "observable store data access returns an isolated snapshot" do
    store = SwiftUIRails::Reactive::ObservableStore.new(:snapshot_regression, count: 1)
    snapshot = store.data

    snapshot[:count] = 99

    assert_equal 1, store.get(:count)
  end

  test "observable store getters do not expose nested mutable values" do
    store = SwiftUIRails::Reactive::ObservableStore.new(
      :nested_snapshot_regression,
      profile: { preferences: { theme: "light" } }
    )

    profile = store.get(:profile)
    profile[:preferences][:theme] = "dark"

    assert_equal "light", store.get(:profile).dig(:preferences, :theme)
  end

  test "observable store updates do not expose mutable internal data" do
    store = SwiftUIRails::Reactive::ObservableStore.new(:update_snapshot_regression, count: 1)

    result = store.update { |data| data[:count] = 2 }
    result[:count] = 99

    assert_equal 2, store.get(:count)
  end

  test "observed store broadcasts invalidate authorized views without leaking store data" do
    broadcasts = []
    server = Object.new
    server.define_singleton_method(:broadcast) do |stream, payload|
      broadcasts << [stream, payload]
    end
    store = SwiftUIRails::Reactive::ObservableStore.new(:private_metrics, secret: "server-only")

    ActionCable.stub(:server, server) do
      store.set(:secret, "still-server-only")
    end

    stream, payload = broadcasts.fetch(0)
    assert_equal SwiftUIRails::Reactive::ObservableStore.stream_name(:private_metrics), stream
    assert_equal "observed_change", payload.fetch(:action)
    assert_equal "private_metrics", payload.fetch(:store)
    assert payload.fetch(:revision).present?
    refute_includes payload.to_json, "server-only"
  end

  test "reactive component markup never serializes observed store contents" do
    render_inline(PrivateObservedComponent.new)

    assert_selector "[data-sui-observed-stores='[\"private_metrics\"]']"
    refute_selector "[data-observed-snapshot]"
    refute_includes page.native.to_html, "server-only-value"
  end

  test "observed resources reload authoritative data and use an explicit shared stream" do
    AuthoritativeObservedComponent.authoritative_count = 7
    component = AuthoritativeObservedComponent.new
    render_inline(component)

    assert_text "Authoritative: 7"
    token = page.find("[data-sui-root='1']")["data-sui-snapshot"]
    payload = SwiftUIRails::Reactive::ReactiveComponentSnapshot.verified(
      token,
      component_id: component.component_id,
      component_class: component.class.name,
      authorization_context: SwiftUIRails::Reactive::ReactiveAuthorizationContext.resolve(component)
    )
    assert_equal ["authoritative_metrics"], payload.fetch("observed_stores")
    assert_equal 7, payload.dig("observed", "metrics", "count") if payload.key?("observed")

    AuthoritativeObservedComponent.authoritative_count = 9
    assert_equal 9, component.metrics.data.fetch(:count)
  ensure
    AuthoritativeObservedComponent.authoritative_count = 0
  end

  test "component helpers retain elements in their active nested DSL context" do
    render_inline(NestedHelperComponent.new)

    assert_selector "div.relative > span", text: "Nested helper content"
  end
end
