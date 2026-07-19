# frozen_string_literal: true

require "test_helper"

class SwiftUIRails::EnvironmentInteractionTest < ViewComponent::TestCase
  class EnvironmentChildComponent < SwiftUIRails::Component::Base
    environment :theme, default: :light, type: Symbol
    environment :locale
    environment :account, required: true

    swift_ui do
      text("#{theme}|#{locale}|#{account.fetch(:name)}")
    end
  end

  class EnvironmentParentComponent < SwiftUIRails::Component::Base
    swift_ui do
      environment_scope(theme: :dark, locale: :fr, account: { name: "Ada", token: "private-token" }) do
        render EnvironmentChildComponent.new
      end
    end
  end

  class FocusComponent < SwiftUIRails::Component::Base
    focus_state :focused_field, values: %i[email password]

    swift_ui do
      focus_scope(:login) do
        textfield(placeholder: "Email").focused(:focused_field, equals: :email)
        textfield(placeholder: "Password").focused(focused_field_focus_binding, equals: :password)
      end
    end
  end

  class InteractionComponent < SwiftUIRails::Component::Base
    attr_reader :tap_seen, :long_press_seen, :drag_seen, :key_seen

    swift_ui do
      div("Tap target").on_tap { @tap_seen = true }
      div("Preset tabindex", tabindex: -1).on_tap { @tap_seen = true }
      button("Combined", type: "button")
        .on_tap { @tap_seen = true }
        .on_long_press(minimum_duration: 0.25) { @long_press_seen = true }
      div("Drag target").on_drag(axis: :horizontal, keyboard_step: 5) { @drag_seen = true }
      div("Keyboard target").on_key_press(keys: %i[enter escape], modifiers: :shift) { @key_seen = true }
      div("Task fallback").task(url: "/", id: "profile-load")
    end
  end

  test "environment scopes inherit through nested component renders without serializing values" do
    render_inline(EnvironmentParentComponent.new)

    assert_text "dark|fr|Ada"
    assert_no_selector "[data-controller], [data-action], [data-swift-ui-environment-scope]"
    refute_includes rendered_content, "private-token"
  end

  test "component environment overrides are typed and visible after rendering" do
    component = EnvironmentChildComponent.new.with_environment(
      theme: :high_contrast,
      locale: :de,
      account: { name: "Grace" }
    )

    render_inline(component)

    assert_text "high_contrast|de|Grace"
    assert_equal :high_contrast, component.environment_values.fetch(:theme)
    assert_raises(TypeError) { EnvironmentChildComponent.new.with_environment(theme: "dark") }
    assert_raises(SwiftUIRails::Environment::MissingValueError) do
      EnvironmentChildComponent.new.with_environment(account: nil)
    end
  end

  test "environment contexts restore after exceptions and isolate concurrent renders" do
    assert_raises(RuntimeError) do
      SwiftUIRails::Environment.with(theme: :temporary) do
        assert_equal :temporary, SwiftUIRails::Environment.fetch(:theme)
        raise "stop"
      end
    end
    assert_raises(SwiftUIRails::Environment::MissingValueError) do
      SwiftUIRails::Environment.fetch(:theme)
    end

    SwiftUIRails::Environment.with(theme: :preserved) do
      assert_raises(TypeError) { SwiftUIRails::Environment.with_context("invalid") {} }
      assert_equal :preserved, SwiftUIRails::Environment.fetch(:theme)
    end

    ready = Queue.new
    release = Queue.new
    values = %i[first second].map do |value|
      Thread.new do
        SwiftUIRails::Environment.with(theme: value) do
          ready << true
          release.pop
          SwiftUIRails::Environment.fetch(:theme)
        end
      end
    end
    2.times { ready.pop }
    2.times { release << true }

    assert_equal %i[first second], values.map(&:value)
  end

  test "environment contexts remain isolated when fibers interleave on one thread" do
    first = Fiber.new do
      SwiftUIRails::Environment.with(account: :first) do
        Fiber.yield
        SwiftUIRails::Environment.fetch(:account)
      end
    end
    second = Fiber.new do
      SwiftUIRails::Environment.with(account: :second) do
        Fiber.yield
        SwiftUIRails::Environment.fetch(:account)
      end
    end

    first.resume
    second.resume

    assert_equal :first, first.resume
    assert_equal :second, second.resume
    assert_raises(SwiftUIRails::Environment::MissingValueError) do
      SwiftUIRails::Environment.fetch(:account)
    end
  end

  test "focus state produces native initial focus intent and scoped browser metadata" do
    component = FocusComponent.new
    component.focused_field = :password
    render_inline(component)

    assert_selector "[data-sui-focus-scope='login']"
    assert_selector "input[placeholder='Email'][data-sui-focus-state='unfocused']"
    assert_selector "input[placeholder='Password'][autofocus][data-sui-focus-state='focused']"
    assert_equal :password, component.focused_field_focus_binding.value
    assert_raises(ArgumentError) { component.focused_field = :search }

    assert_raises(ArgumentError) do
      Class.new(SwiftUIRails::Component::Base) do
        focus_state :invalid_default, default: :search, values: %i[email password]
      end
    end
  end

  test "interaction modifiers render accessible progressive behavior and event-specific action maps" do
    component = InteractionComponent.new
    render_inline(component)

    assert_selector "div[role='button'][tabindex='0']", text: "Tap target"
    assert_selector "div[role='button'][tabindex='-1'][data-sui-keyboard-activate='1']", text: "Preset tabindex"
    assert_selector "button[data-sui-long-press]"
    assert_selector "div[style*='touch-action: pan-y'][data-sui-drag]", text: "Drag target"
    assert_selector "div[tabindex='0'][data-sui-keypress]", text: "Keyboard target"
    assert_selector "div[data-sui-task]", text: "Task fallback"
    refute_selector "[data-controller], [data-action]"

    combined = page.find("button", text: "Combined", visible: :all)
    action_map = JSON.parse(combined["data-sui-actions"])
    assert action_map.key?("click")
    assert action_map.key?("swift-ui-long-press")
    refute_equal action_map.fetch("click"), action_map.fetch("swift-ui-long-press")
  end

  test "registered gesture actions still execute on the server" do
    component = InteractionComponent.new
    render_inline(component)

    component.registered_actions.each { |action_id| component.execute_action(action_id) }

    assert component.tap_seen
    assert component.long_press_seen
    assert component.drag_seen
    assert component.key_seen
  end
end
