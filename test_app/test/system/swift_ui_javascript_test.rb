require "application_system_test_case"

class SwiftUIJavascriptTest < ApplicationSystemTestCase
  # Test component with JavaScript integration
  class InteractiveComponent < SwiftUIRails::Component::Base
    prop :initial_count, type: Integer, default: 0
    
    def call
      content_tag(:div, 
        data: { 
          controller: "swift-ui",
          swift_ui_state_value: { count: initial_count }.to_json,
          swift_ui_component_id_value: "counter-#{object_id}"
        }
      ) do
        safe_join([
          content_tag(:h2, "Interactive Counter", class: "text-xl font-bold mb-4"),
          content_tag(:div, class: "flex items-center space-x-4") do
            safe_join([
              content_tag(:button, 
                "-", 
                class: "px-4 py-2 bg-red-500 text-white rounded",
                data: { action: "click->swift-ui#decrement" }
              ),
              content_tag(:span, initial_count, class: "count-display text-2xl font-semibold"),
              content_tag(:button, 
                "+", 
                class: "px-4 py-2 bg-green-500 text-white rounded",
                data: { action: "click->swift-ui#increment" }
              )
            ])
          end,
          content_tag(:div, class: "mt-4") do
            content_tag(:button,
              "Reset",
              class: "px-4 py-2 bg-gray-500 text-white rounded",
              data: { action: "click->swift-ui#reset" }
            )
          end
        ])
      end
    end
  end
  
  test "interactive components respond to user actions" do
    # Create a test page with our component
    visit "/storybook/interactive_test"
    
    # Initial state
    assert_selector ".count-display", text: "0"
    
    # Test increment
    click_button "+"
    assert_selector ".count-display", text: "1"
    
    click_button "+"
    assert_selector ".count-display", text: "2"
    
    # Test decrement
    click_button "-"
    assert_selector ".count-display", text: "1"
    
    # Test reset
    click_button "Reset"
    assert_selector ".count-display", text: "0"
  end
  
  test "multiple components maintain independent state" do
    visit "/storybook/multiple_counters"
    
    within "#counter-1" do
      assert_selector ".count-display", text: "0"
      click_button "+"
      assert_selector ".count-display", text: "1"
    end
    
    within "#counter-2" do
      assert_selector ".count-display", text: "5" # Different initial value
      click_button "+"
      assert_selector ".count-display", text: "6"
    end
    
    # First counter should still be 1
    within "#counter-1" do
      assert_selector ".count-display", text: "1"
    end
  end
  
  test "state changes trigger custom events" do
    visit "/storybook/event_test"
    
    # The page should have an event log
    assert_selector "#event-log", text: "Events will appear here"
    
    # Click increment - should log event
    click_button "+"
    assert_selector "#event-log", text: "State changed: count from 0 to 1"
    
    click_button "+"
    assert_selector "#event-log", text: "State changed: count from 1 to 2"
  end
  
  test "components handle rapid clicks" do
    visit "/storybook/stress_test"
    
    # Rapidly click increment
    10.times { click_button "+" }
    
    # Should end up at 10
    assert_selector ".count-display", text: "10"
  end
  
  test "components preserve state through DOM updates" do
    visit "/storybook/dom_update_test"
    
    # Set initial state
    click_button "+"
    click_button "+"
    assert_selector ".count-display", text: "2"
    
    # Trigger DOM update (e.g., adding a class)
    click_button "Toggle Style"
    
    # State should be preserved
    assert_selector ".count-display", text: "2"
    
    # Should still be interactive
    click_button "+"
    assert_selector ".count-display", text: "3"
  end
  
  test "keyboard navigation works" do
    visit "/storybook/keyboard_test"
    
    # Focus on increment button
    find_button("+").send_keys(:tab)
    
    # Press space to activate
    page.send_keys(:space)
    
    assert_selector ".count-display", text: "1"
  end
  
  private
  
  # Helper to set up test routes
  def setup_test_routes
    Rails.application.routes.draw do
      namespace :storybook do
        get "interactive_test", to: proc { |env|
          component = InteractiveComponent.new
          html = ApplicationController.renderer.render(
            inline: component.call,
            layout: "application"
          )
          [200, { "Content-Type" => "text/html" }, [html]]
        }
        
        # Add other test routes as needed
      end
    end
  end
end
# Copyright 2025
