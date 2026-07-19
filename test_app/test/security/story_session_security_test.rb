# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class StorySessionSecurityTest < ActiveSupport::TestCase
  setup do
    @valid_session_id = "session-123"
    @valid_variant = "default"
  end

  test "rejects arbitrary story names instead of constantizing them" do
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
      error = assert_raises(SwiftUIRails::SecurityError) do
        build_session(story_name: name).component_instance
      end

      assert_equal "Unauthorized story: #{name}", error.message
    end
  end

  test "resolves a registered story through the trusted registry" do
    entry = StorybookStoryRegistry.fetch("counter_component")

    assert_same CounterComponentStories, entry.story_class
    assert_includes entry.variants, :default

    component = build_session(
      story_name: "counter_component",
      props: { "initial_count" => 4, "step" => 2, "label" => "Orders" }
    ).component_instance

    assert_instance_of CounterComponent, component
    assert_equal 4, component.initial_count
    assert_equal 2, component.step
    assert_equal "Orders", component.label
  end

  test "rejects a valid Stories subclass that is not registered" do
    unregistered_class = Class.new(ViewComponent::Storybook::Stories) do
      def default
        "not trusted"
      end
    end
    Object.const_set("UnregisteredStories", unregistered_class)

    error = assert_raises(SwiftUIRails::SecurityError) do
      build_session(story_name: "unregistered").component_instance
    end

    assert_equal "Unauthorized story: unregistered", error.message
  ensure
    Object.send(:remove_const, "UnregisteredStories") if Object.const_defined?("UnregisteredStories", false)
  end

  test "rejects variants not declared by the registered story" do
    log_output = capture_rails_logs do
      error = assert_raises(SwiftUIRails::SecurityError) do
        build_session(story_name: "counter_component", variant: "send").component_instance
      end

      assert_equal "Unauthorized story variant: send", error.message
    end

    assert_includes log_output, "[SECURITY] Attempted to invoke unauthorized story variant: counter_component/send"
  end

  test "logs security events for unregistered story attempts" do
    log_output = capture_rails_logs do
      assert_raises(SwiftUIRails::SecurityError) do
        build_session(story_name: "kernel").component_instance
      end
    end

    assert_includes log_output, "[SECURITY]"
    assert_includes log_output, "Attempted to instantiate unauthorized story: kernel"
  end

  test "story name injection remains inert" do
    injection_attempts = [
      "button'; system('touch /tmp/hacked'); '",
      "button\"; exec('ls'); \"",
      "button`.touch /tmp/hacked2`",
      "button || Kernel",
      "button && Process"
    ]

    injection_attempts.each do |injection|
      assert_raises(SwiftUIRails::SecurityError) do
        build_session(story_name: injection).component_instance
      end

      assert_not File.exist?("/tmp/hacked")
      assert_not File.exist?("/tmp/hacked2")
    end
  end

  test "cache keys validate registry identities and hash the raw session input" do
    key = StorySession.cache_key("counter_component", "default", @valid_session_id)

    assert_match(/\Astory_session:[a-f0-9]{64}\z/, key)
    refute_includes key, @valid_session_id
    assert_raises(SwiftUIRails::SecurityError) do
      StorySession.cache_key("counter_component", "default", "../session")
    end
    assert_raises(SwiftUIRails::SecurityError) do
      StorySession.cache_key("counter_component", "public_send", @valid_session_id)
    end
  end

  test "saving a session writes a validated component lookup" do
    session = build_session(story_name: "counter_component")
    cache = ActiveSupport::Cache::MemoryStore.new

    Rails.stub(:cache, cache) do
      session.save!

      lookup = cache.read("story_session_lookup:#{@valid_session_id}")
      assert_equal "counter_component", lookup.fetch(:story_name)
      assert_equal "default", lookup.fetch(:variant)
    end
  end

  test "prop updates persist without a parallel live-preview channel" do
    cache = ActiveSupport::Cache::MemoryStore.new

    Rails.stub(:cache, cache) do
      session = build_session(story_name: "counter_component")
      session.save!
      session.update_props!("initial_count" => 8)

      persisted = StorySession.find(
        "counter_component",
        @valid_variant,
        @valid_session_id
      )

      assert_equal({ "initial_count" => 8 }, persisted.props)
      refute_respond_to session, :broadcast_prop_change
      refute_respond_to session, :broadcast_state_change
    end
  end

  test "concurrent session state updates merge against the latest cached value" do
    cache = ActiveSupport::Cache::MemoryStore.new
    ready = Queue.new
    release = Queue.new
    failures = Queue.new

    Rails.stub(:cache, cache) do
      build_session(story_name: "counter_component").save!

      threads = %w[first second].map do |state_key|
        Thread.new do
          session = StorySession.find(
            "counter_component",
            @valid_variant,
            @valid_session_id
          )
          ready << true
          release.pop
          session.update_state!(state_key => true)
        rescue StandardError => e
          failures << e
        end
      end

      threads.length.times { ready.pop }
      threads.length.times { release << true }
      threads.each(&:join)

      assert failures.empty?, "Concurrent update failed: #{failures.pop.inspect unless failures.empty?}"
      persisted = StorySession.find(
        "counter_component",
        @valid_variant,
        @valid_session_id
      )
      assert_equal({ "first" => true, "second" => true }, persisted.state)
    end
  end

  test "modern typed component state survives story reconstruction" do
    cache = ActiveSupport::Cache::MemoryStore.new

    Rails.stub(:cache, cache) do
      session = StorySession.find_or_create(
        "atlas_mission_control",
        "command_center",
        @valid_session_id
      )
      component = session.component_instance
      component.precision_tracking = true
      component.orbit_zoom = 3

      session.save_component_state(component)

      persisted = StorySession.find(
        "atlas_mission_control",
        "command_center",
        @valid_session_id
      )
      reconstructed = persisted.component_instance

      assert_equal(
        { "precision_tracking" => true, "orbit_zoom" => 3, "focused_control" => nil },
        persisted.state
      )
      assert_equal true, reconstructed.precision_tracking
      assert_equal 3, reconstructed.orbit_zoom
      assert_equal :storybook, reconstructed.surface
      assert_equal "T−12", reconstructed.value_from(reconstructed.phase, :code)
    end
  end

  test "application components persist through the typed state snapshot contract" do
    component = ExampleComponent.new
    component.counter = 7
    component.show_details = true
    captured = nil
    session = build_session(story_name: "counter_component")

    session.stub(:update_state!, ->(values) { captured = values }) do
      session.save_component_state(component)
    end

    assert_equal({ "counter" => 7, "show_details" => true }, captured)
    assert_equal %i[counter show_details], component.class.state_definitions.keys
    refute_respond_to component, :state_variables
    refute_respond_to component, :story_session_id
  end

  private

  def build_session(story_name:, variant: @valid_variant, props: {})
    StorySession.new(
      story_name: story_name,
      variant: variant,
      session_id: @valid_session_id,
      props: props
    )
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
