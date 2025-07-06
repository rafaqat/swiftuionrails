# Copyright 2025
require "test_helper"

class SwiftUIRails::ComponentFeaturesTest < ViewComponent::TestCase
  # Test component with various features
  class TestComponent < SwiftUIRails::Component::Base
    # Props with different types and validations
    prop :title, type: String, required: true
    prop :count, type: Integer, default: 0
    prop :enabled, type: [TrueClass, FalseClass], default: true
    prop :options, type: Array, default: []
    prop :variant, type: Symbol, default: :primary
    
    # State management
    state :clicks, 0
    state :is_open, false
    
    # Computed properties
    computed :double_count do
      count * 2
    end
    
    computed :status_message do
      enabled ? "Active" : "Inactive"
    end
    
    computed :total_clicks do
      clicks + count
    end
    
    # Effects
    effect :clicks do |new_value, old_value|
      @effect_called = true
      @effect_values = { new: new_value, old: old_value }
    end
    
    # For testing effect calls
    attr_reader :effect_called, :effect_values
    
    def call
      content_tag(:div, class: "p-4") do
        safe_join([
          content_tag(:span, title),
          content_tag(:span, "Count: #{count}"),
          content_tag(:span, "Double: #{double_count}"),
          content_tag(:span, "Status: #{status_message}")
        ])
      end
    end
  end
  
  # Test Props System
  
  test "props with required validation" do
    # Should raise error without required prop
    assert_raises(ArgumentError) do
      TestComponent.new
    end
    
    # Should work with required prop
    component = TestComponent.new(title: "Test")
    assert_equal "Test", component.title
  end
  
  test "props with default values" do
    component = TestComponent.new(title: "Test")
    
    assert_equal 0, component.count
    assert_equal true, component.enabled
    assert_equal [], component.options
    assert_equal :primary, component.variant
  end
  
  test "props with type validation" do
    # String type
    assert_raises(TypeError) do
      TestComponent.new(title: 123)
    end
    
    # Integer type
    assert_raises(TypeError) do
      TestComponent.new(title: "Test", count: "not a number")
    end
    
    # Boolean type (TrueClass/FalseClass union)
    assert_raises(TypeError) do
      TestComponent.new(title: "Test", enabled: "yes")
    end
    
    # Symbol type
    assert_raises(TypeError) do
      TestComponent.new(title: "Test", variant: "primary")
    end
  end
  
  test "props can be set through initialization" do
    component = TestComponent.new(
      title: "Custom Title",
      count: 42,
      enabled: false,
      options: ["a", "b", "c"],
      variant: :secondary
    )
    
    assert_equal "Custom Title", component.title
    assert_equal 42, component.count
    assert_equal false, component.enabled
    assert_equal ["a", "b", "c"], component.options
    assert_equal :secondary, component.variant
  end
  
  # Test State Management
  
  test "state initialization with defaults" do
    component = TestComponent.new(title: "Test")
    
    assert_equal 0, component.clicks
    assert_equal false, component.is_open
  end
  
  test "state can be modified" do
    component = TestComponent.new(title: "Test")
    
    component.clicks = 5
    assert_equal 5, component.clicks
    
    component.is_open = true
    assert_equal true, component.is_open
  end
  
  test "state changes trigger effects" do
    component = TestComponent.new(title: "Test")
    
    # Effect should not be called on initialization
    assert_nil component.effect_called
    
    # Change state
    component.clicks = 10
    
    # Effect should be called
    assert component.effect_called
    assert_equal({ new: 10, old: 0 }, component.effect_values)
  end
  
  # Test Computed Properties
  
  test "computed properties calculate correctly" do
    component = TestComponent.new(title: "Test", count: 5)
    
    assert_equal 10, component.double_count
  end
  
  test "computed properties update when dependencies change" do
    component = TestComponent.new(title: "Test", count: 5)
    
    assert_equal 10, component.double_count
    
    # This would need to be implemented in the actual gem
    # For now, computed properties are calculated on each call
    component.instance_variable_set(:@count, 7)
    assert_equal 14, component.double_count
  end
  
  test "computed properties with multiple dependencies" do
    component = TestComponent.new(title: "Test", count: 5)
    component.clicks = 3
    
    assert_equal 8, component.total_clicks
  end
  
  test "computed properties based on props" do
    component1 = TestComponent.new(title: "Test", enabled: true)
    assert_equal "Active", component1.status_message
    
    component2 = TestComponent.new(title: "Test", enabled: false)
    assert_equal "Inactive", component2.status_message
  end
  
  # Test Component Rendering
  
  test "component renders with swift_ui block" do
    component = TestComponent.new(title: "Hello", count: 10)
    result = render_inline(component)
    
    assert_selector "div.p-4"
    assert_text "Hello"
    assert_text "Count: 10"
    assert_text "Double: 20"
    assert_text "Status: Active"
  end
  
  # Test Component without swift_ui block
  
  class MinimalComponent < SwiftUIRails::Component::Base
    prop :name, type: String, default: "Minimal"
    
    def call
      # Component without content - return empty string
      ""
    end
  end
  
  test "component without swift_ui block renders empty" do
    component = MinimalComponent.new
    result = render_inline(component)
    
    assert_empty result.to_html.strip
  end
  
  # Test Complex Component
  
  class ComplexComponent < SwiftUIRails::Component::Base
    prop :items, type: Array, default: []
    
    state :selected_index, nil
    state :search_query, ""
    
    computed :filtered_items do
      return items if search_query.empty?
      items.select { |item| item.downcase.include?(search_query.downcase) }
    end
    
    computed :selected_item do
      selected_index ? items[selected_index] : nil
    end
    
    def call
      content_tag(:div, class: "flex flex-col space-y-16") do
        safe_join([
          # Search input
          tag(:input, type: "text", placeholder: "Search...", value: search_query, "data-bind": "search_query"),
          
          # Items list
          if filtered_items.any?
            content_tag(:ul) do
              safe_join(filtered_items.map do |item|
                content_tag(:li) do
                  content_tag(:button, item)
                end
              end)
            end
          else
            content_tag(:span, "No items found", class: "text-gray-500")
          end,
          
          # Selected item display
          if selected_item
            content_tag(:div, class: "bg-white rounded-lg shadow p-4") do
              content_tag(:span, "Selected: #{selected_item}")
            end
          end
        ].compact)
      end
    end
  end
  
  test "complex component with arrays and filtering" do
    items = ["Apple", "Banana", "Cherry", "Date"]
    component = ComplexComponent.new(items: items)
    
    render_inline(component)
    
    # Check all items are rendered
    items.each do |item|
      assert_selector "button", text: item
    end
    
    # Check structure
    assert_selector "input[placeholder='Search...']"
    assert_selector "ul"
    assert_selector "li", count: 4
  end
  
  test "complex component computed properties" do
    items = ["Apple", "Banana", "Cherry"]
    component = ComplexComponent.new(items: items)
    
    # Test filtering
    component.search_query = "a"
    assert_equal ["Apple", "Banana"], component.filtered_items
    
    # Test selection
    component.selected_index = 1
    assert_equal "Banana", component.selected_item
  end
  
  # Test Component Inheritance
  
  class BaseComponent < SwiftUIRails::Component::Base
    prop :base_prop, type: String, default: "base"
    state :base_state, 0
    
    computed :base_computed do
      "Base: #{base_prop}"
    end
  end
  
  class ExtendedComponent < BaseComponent
    prop :extended_prop, type: String, default: "extended"
    state :extended_state, 0
    
    computed :extended_computed do
      "#{base_computed}, Extended: #{extended_prop}"
    end
    
    def call
      content_tag(:div) do
        content_tag(:span, extended_computed)
      end
    end
  end
  
  test "component inheritance preserves parent features" do
    component = ExtendedComponent.new
    
    # Has both base and extended props
    assert_equal "base", component.base_prop
    assert_equal "extended", component.extended_prop
    
    # Has both base and extended state
    assert_equal 0, component.base_state
    assert_equal 0, component.extended_state
    
    # Computed properties work across inheritance
    assert_equal "Base: base", component.base_computed
    assert_equal "Base: base, Extended: extended", component.extended_computed
  end
end
# Copyright 2025
