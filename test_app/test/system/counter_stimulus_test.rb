require "application_system_test_case"

class CounterStimulusTest < ApplicationSystemTestCase
  test "counter component works with Stimulus controller" do
    visit storybook_show_path(story: "counter_component")
    
    # Wait for counter to render
    assert_selector "[data-controller='counter']", wait: 2
    
    # Check initial state
    within "[data-controller='counter']" do
      # Count display should show 0
      assert_selector "[data-counter-target='count']", text: "0"
      
      # Label should show "Counter: 0"
      assert_selector "[data-counter-target='label']", text: "Counter: 0"
      
      # Click increment button
      find("[data-counter-target='incrementBtn']").click
      
      # Count should update to 1
      assert_selector "[data-counter-target='count']", text: "1"
      assert_selector "[data-counter-target='label']", text: "Counter: 1"
      
      # Label should be green for positive numbers
      label_element = find("[data-counter-target='label']")
      assert label_element[:class].include?("text-green-600")
      
      # Click increment again
      find("[data-counter-target='incrementBtn']").click
      assert_selector "[data-counter-target='count']", text: "2"
      
      # Click decrement
      find("[data-counter-target='decrementBtn']").click
      assert_selector "[data-counter-target='count']", text: "1"
      
      # Click reset
      find("button", text: "Reset").click
      assert_selector "[data-counter-target='count']", text: "0"
      
      # History should be displayed
      assert_selector "[data-counter-target='history']"
      within "[data-counter-target='history']" do
        assert_text "0 → 1"
        assert_text "1 → 2"
        assert_text "2 → 1"
        assert_text "1 → 0"
      end
    end
    
    # Test prop updates from storybook controls
    fill_in "initial_count", with: "10"
    find("[data-live-story-target='control'][name='initial_count']").send_keys(:tab)
    
    sleep 0.5 # Wait for update
    
    # Counter should update to new initial value
    within "[data-controller='counter']" do
      assert_selector "[data-counter-target='count']", text: "10"
      assert_selector "[data-counter-target='label']", text: "Counter: 10"
    end
    
    # Test step control
    fill_in "step", with: "5"
    find("[data-live-story-target='control'][name='step']").send_keys(:tab)
    
    sleep 0.5
    
    # Click increment with new step value
    within "[data-controller='counter']" do
      find("[data-counter-target='incrementBtn']").click
      assert_selector "[data-counter-target='count']", text: "15"
    end
    
    take_screenshot
  end
  
  test "counter maintains client-side state independently" do
    visit storybook_show_path(story: "counter_component")
    
    within "[data-controller='counter']" do
      # Increment counter
      find("[data-counter-target='incrementBtn']").click
      find("[data-counter-target='incrementBtn']").click
      assert_selector "[data-counter-target='count']", text: "2"
      
      # Change a prop - counter value should persist
      fill_in "label", with: "My Counter"
      find("[data-live-story-target='control'][name='label']").send_keys(:tab)
      
      sleep 0.5
      
      # Count should still be 2, only label changed
      assert_selector "[data-counter-target='count']", text: "2"
      assert_selector "[data-counter-target='label']", text: "My Counter: 2"
    end
  end
end
# Copyright 2025
