# frozen_string_literal: true

require "test_helper"
require Rails.root.join("..", "lib/swift_ui_rails/dsl/accessibility_animation").expand_path

class SwiftUIRails::AccessibilityAnimationTest < ViewComponent::TestCase
  class AccessibleComponent < SwiftUIRails::Component::Base
    swift_ui do
      text("42")
        .accessibility_identifier("sample-reading")
        .accessibility_label("Current reading")
        .accessibility_value("42 volts")
        .accessibility_hint("Updated every minute")
        .accessibility_role(:status)
        .accessibility_live(:polite, atomic: true)
        .accessibility_state(busy: false, current: :step)
        .animation(:ease_in_out, duration: 0.25, value: 42, properties: :colors)
        .content_transition(:numeric_text)
    end
  end

  test "renders first-class accessibility semantics and value animation metadata" do
    render_inline(AccessibleComponent.new)

    assert_selector "#sample-reading[role='status'][aria-label='Current reading']"
    assert_selector "[aria-valuetext='42 volts'][aria-description='Updated every minute']"
    assert_selector "[aria-live='polite'][aria-atomic='true'][aria-busy='false'][aria-current='step']"
    assert_selector ".swift-ui-value-animation.tabular-nums[data-sui-animation-value='42']" \
      "[data-sui-content-transition='numeric-text']"
    style = page.find("#sample-reading")[:style]
    assert_includes style, "transition-property: color, background-color"
    assert_includes style, "transition-duration: 0.25s"
  end

  test "heading traits and reversible hidden state map to ARIA" do
    heading = SwiftUIRails::DSL::Element.new(:div, "Heading")
      .accessibility_traits(:header, :selected)
      .accessibility_hidden(false)
    heading.view_context = ApplicationController.helpers

    document = Nokogiri::HTML.fragment(heading.to_s)
    node = document.at_css("div")
    assert_equal "heading", node["role"]
    assert_equal "2", node["aria-level"]
    assert_equal "true", node["aria-selected"]
    assert_equal "false", node["aria-hidden"]
  end

  test "rejects unsafe or misleading accessibility and animation values" do
    element = SwiftUIRails::DSL::Element.new(:div)

    assert_raises(ArgumentError) { element.accessibility_role(:made_up_role) }
    assert_raises(ArgumentError) { element.accessibility_identifier("bad id") }
    assert_raises(ArgumentError) { element.accessibility_heading(level: 8) }
    assert_raises(ArgumentError) { element.accessibility_state(selected: "yes") }
    assert_raises(ArgumentError) { element.accessibility_state(current: :tomorrow) }
    assert_raises(ArgumentError) { element.animation(:bounce, duration: 1) }
    assert_raises(ArgumentError) { element.animation(:linear, duration: "1; color:red") }
    assert_raises(ArgumentError) { element.content_transition(:magic) }
  end
end
