# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class CounterComponentTest < ViewComponent::TestCase
  include SwiftUIRails::Helpers

  def test_renders_with_default_props
    render_inline(CounterComponent.new)

    # Check for Stimulus controller and data attributes
    assert_selector "[data-controller='counter']"
    assert_selector "[data-counter-count-value='0']"
    assert_selector "[data-counter-step-value='1']"
    assert_selector "[data-counter-label-value='Counter']"
    
    # Check for buttons
    assert_selector "button", text: "-"
    assert_selector "button", text: "Reset"
    assert_selector "button", text: "+"
    
    # Check for targets
    assert_selector "[data-counter-target='label']"
    assert_selector "[data-counter-target='count']"
  end

  def test_renders_with_custom_props
    render_inline(CounterComponent.new(
      initial_count: 10,
      step: 5,
      counter_label: "My Counter"
    ))

    # Check data attributes reflect custom props
    assert_selector "[data-counter-count-value='10']"
    assert_selector "[data-counter-step-value='5']"
    assert_selector "[data-counter-label-value='My Counter']"
  end

  def test_stimulus_actions
    render_inline(CounterComponent.new)

    # Check that buttons have correct Stimulus actions
    assert_selector "button[data-action='click->counter#decrement']", text: "-"
    assert_selector "button[data-action='click->counter#reset']", text: "Reset"
    assert_selector "button[data-action='click->counter#increment']", text: "+"
  end

  def test_component_structure
    render_inline(CounterComponent.new)

    # Check overall structure
    assert_selector "div.flex.flex-col.items-center.space-y-4"
    assert_selector "div.flex.flex-row.items-center.space-x-2" # button container
    assert_selector "[data-counter-target='history']" # history display area
  end
end
# Copyright 2025
