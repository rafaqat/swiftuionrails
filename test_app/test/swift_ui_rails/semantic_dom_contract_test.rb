# frozen_string_literal: true

require "test_helper"

class SwiftUIRails::SemanticDOMContractTest < ViewComponent::TestCase
  class ProtocolComponent < SwiftUIRails::Component::Base
    state :count, 0
    binding :query, type: String, default: "Ada"

    swift_ui do
      textfield(**query.input_attributes(placeholder: "Search"))
        .on_focus { @count += 100 }
        .on_blur { @count += 1_000 }
      button("Run")
        .on_tap { @count += 1 }
        .on_keydown { @count += 10 }
        .on_hover { @count += 100_000 }
    end
  end

  test "reactive roots actions and bindings use only the semantic DOM protocol" do
    first = ProtocolComponent.new
    render_inline(first)

    root = page.find("[data-sui-root='1']")
    button = page.find("button", text: "Run")
    actions = JSON.parse(button["data-sui-actions"])

    assert_equal first.component_id, root["data-sui-id"]
    assert_equal first.class.name, root["data-sui-component"]
    assert root["data-sui-snapshot"].present?
    assert root["data-sui-stream"].present?
    assert_equal "/swift_ui/components/update", root["data-sui-update-url"]
    assert_equal %w[click keydown mouseover], actions.keys
    assert actions.values.all? { |action_id| action_id.match?(/\Aa_[0-9a-f]{32}\z/) }
    assert_equal actions.values.uniq, actions.values
    input = page.find("input[data-sui-binding='query'][data-sui-binding-type='string']")
    assert_equal %w[focusin focusout], JSON.parse(input["data-sui-actions"]).keys
    refute_selector "[data-controller], [data-action], [data-binding]"

    second = ProtocolComponent.new
    render_inline(second)
    @page = nil
    second_actions = JSON.parse(page.all("button", text: "Run").last["data-sui-actions"])
    assert_equal actions, second_actions
  end

  test "server action events are finite delegated vocabulary" do
    unsupported = %w[focus blur mouseenter mouseleave keypress resize scroll unload touchstart invented]
    unsupported.each do |event_name|
      error = assert_raises(ArgumentError, event_name) do
        dsl_context.div.add_server_action(event_name) { nil }
      end
      assert_includes error.message, "delegated semantic action event"
    end

    assert_raises(ArgumentError) { dsl_context.div.on_mouse_enter { nil } }
    assert_raises(ArgumentError) { dsl_context.div.on_mouse_leave { nil } }

    error = assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.button("Invented").attr(
        "data-sui-actions",
        JSON.generate("swift-ui-invented" => "a_0123456789abcdef0123456789abcdef")
      ).to_s
    end
    assert_includes error.message, "invalid event or action id"
  end

  test "legacy controller modifier shims fail with deterministic repair guidance" do
    element = dsl_context.button("Legacy")

    %i[stimulus_controller stimulus_target stimulus_action].each do |method_name|
      error = assert_raises(SwiftUIRails::Error) { element.public_send(method_name, "legacy") }
      assert_includes error.message, "declare a Ruby action"
    end
    error = assert_raises(SwiftUIRails::Error) { element.stimulus_param(:id, 1) }
    assert_includes error.message, "finite SwiftUI Rails semantic behavior"
  end

  test "RenderIR rejects raw application JavaScript and invented semantic commands" do
    error = assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.div(data: { controller: "legacy" }).to_s
    end
    assert_includes error.message, "Application JavaScript metadata"

    assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.button("Legacy", data: { action: "click->legacy#run" }).to_s
    end
    assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.div(data: { legacy_target: "panel" }).to_s
    end
    assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.div(data: { legacy_count_value: 1 }).to_s
    end

    error = assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.div.attr("data-sui-eval", "applicationMethod").to_s
    end
    assert_includes error.message, "not in the finite browser vocabulary"
  end

  test "RenderIR accepts only bounded server-owned Storybook context" do
    html = dsl_context.div(
      data: {
        sui_story: "counter_component",
        sui_story_session: "a1b2c3d4",
        sui_story_variant: "interactive"
      }
    ).to_s

    assert_includes html, 'data-sui-story="counter_component"'
    assert_includes html, 'data-sui-story-session="a1b2c3d4"'
    assert_includes html, 'data-sui-story-variant="interactive"'

    error = assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      dsl_context.div(data: { sui_story: "../untrusted" }).to_s
    end
    assert_includes error.message, "invalid story context"
  end

  test "RenderIR validates the shape and finite values of semantic descriptors" do
    invalid_descriptors = {
      "data-sui-task" => { url: "/safe", method: "EVAL", trigger: "appear", response: "event" },
      "data-sui-toolbar" => {
        orientation: "diagonal", overflow: true, minimizeOnScroll: false, minimizeThreshold: 24
      },
      "data-sui-workflow" => { kind: "script", source: "generated" },
      "data-sui-canvas" => {
        width: 100, height: 100, commands: [{ type: "eval", source: "applicationMethod()" }]
      }
    }

    invalid_descriptors.each do |attribute, descriptor|
      error = assert_raises(SwiftUIRails::RenderIR::InvalidStructure, attribute) do
        dsl_context.div.attr(attribute, JSON.generate(descriptor)).to_s
      end
      assert_match(/RenderIR/, error.message)
    end
  end

  private

  def dsl_context
    @dsl_context ||= SwiftUIRails::DSLContext.new(
      ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    )
  end
end
