# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class CounterComponentTest < ViewComponent::TestCase
  include SwiftUIRails::Helpers

  def test_renders_with_default_props
    render_inline(CounterComponent.new)

    # Debug output
    puts "=== Rendered HTML ==="
    puts page.native.to_html
    puts "===================="

    assert_text "Counter: 0"
    assert_text "0" # The large count display
    assert_selector "button", text: "-"
    assert_selector "button", text: "Reset"
    assert_selector "button", text: "+"
  end

  def test_renders_with_custom_props
    render_inline(CounterComponent.new(
      initial_count: 10,
      step: 5,
      label: "My Counter"
    ))

    assert_text "My Counter: 10"
    assert_text "10"
  end

  def test_state_management
    component = CounterComponent.new(initial_count: 5)

    # Test initial state
    assert_equal 5, component.count
    assert_equal [], component.history

    # Test state mutation
    component.count = 10
    assert_equal 10, component.count
    assert_equal 1, component.history.length
    assert_equal({ from: 5, to: 10 }, component.history.first.slice(:from, :to))
  end

  def test_computed_properties
    component = CounterComponent.new(initial_count: 5, label: "Test")

    assert component.is_positive
    assert_equal "Test: 5", component.count_display

    component.count = -3
    refute component.is_positive
    assert_equal "Test: -3", component.count_display
  end

  def test_observed_object_store
    # Create a shared store
    store = SwiftUIRails::Reactive::ObservableStore.find_or_create(:test_store)
    store.reset

    # Set some data
    store.set(:count, 42)
    assert_equal 42, store.get(:count)

    # Update data
    store.update do |data|
      data[:count] = 100
      data[:name] = "Test"
    end

    assert_equal 100, store.get(:count)
    assert_equal "Test", store.get(:name)
  end

  def test_binding_value_wrapper
    component = CounterComponent.new

    # Test binding getter/setter
    if component.respond_to?(:shared_count)
      binding = component.shared_count
      assert_kind_of SwiftUIRails::Reactive::BindingValue, binding

      # Test value access
      binding.value = 42
      assert_equal 42, binding.value
    end
  end

  def test_reactive_rendering_wrapper
    render_inline(CounterComponent.new)

    # Check for reactive wrapper
    assert_selector "[data-swift-ui-reactive='true']"
    assert_selector "[data-controller='swift-ui-reactive']"
  end

  def test_debug_panel_in_development
    # Temporarily enable debug mode
    CounterComponent.state_debugging_enabled = true

    render_inline(CounterComponent.new)

    # Check for debug elements
    assert_selector ".swift-ui-debug-trigger"
    assert_selector ".swift-ui-debug-panel"

  ensure
    CounterComponent.state_debugging_enabled = false
  end
end
# Copyright 2025
