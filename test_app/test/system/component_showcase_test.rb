# Copyright 2025
require "application_system_test_case"

class ComponentShowcaseTest < ApplicationSystemTestCase
  test "home page shows component showcase" do
    visit root_path

    # Page header
    assert_text "SwiftUI Rails Components"
    assert_text "Interactive component showcase using our Rails-first architecture"

    # Counter component card
    assert_selector "a[href='#{storybook_show_path(story: 'counter_component')}']"
    within "a[href='#{storybook_show_path(story: 'counter_component')}']" do
      assert_text "Counter"
      assert_text "Interactive counter with Stimulus-managed state"
      assert_text "View Component →"
    end

    # Placeholder for future components
    assert_text "More components coming soon..."
  end

  test "counter page shows component demo and documentation" do
    visit counter_path

    # Header
    assert_text "Counter Component"
    assert_text "A simple counter demonstrating client-side state management with Stimulus"

    # Back link
    assert_selector "a[href='#{root_path}']", text: "Back to Components"

    # Live demo section
    assert_text "Live Demo"
    assert_selector "[data-controller='counter']"

    # Usage section
    assert_text "Usage"
    assert_text "render CounterComponent.new"

    # Props documentation
    assert_text "Props"
    assert_text "initial_count"
    assert_text "step"
    assert_text "label"

    # Architecture section
    assert_text "Architecture"
    assert_text "Stateless Component"
    assert_text "Stimulus Controller"

    # Multiple counter examples
    assert_text "Try Different Configurations"
    assert_text "Steps"
    assert_text "Score"
    assert_text "Items"

    # Should have 4 counters total (1 main + 3 examples)
    assert_selector "[data-controller='counter']", count: 4
  end

  test "navigation from home to storybook works" do
    visit root_path

    # Click on counter card
    click_link "Counter"

    # Should be on storybook page
    assert_current_path storybook_show_path(story: "counter_component")

    # Should see the properties panel and story content
    assert_selector "[data-live-story-target='controls']"
    assert_text "Live Controls"
  end

  test "counter demos work independently" do
    visit counter_path

    # Find the steps counter (step: 5)
    within all("[data-controller='counter']")[1] do
      assert_text "Steps: 0"
      click_button "+"
      assert_text "Steps: 5"
      click_button "+"
      assert_text "Steps: 10"
    end

    # Find the score counter (initial: 100, step: 10)
    within all("[data-controller='counter']")[2] do
      assert_text "Score: 100"
      click_button "+"
      assert_text "Score: 110"
      click_button "-"
      assert_text "Score: 100"
    end

    # Find the items counter
    within all("[data-controller='counter']")[3] do
      assert_text "Items: 50"
      click_button "-"
      assert_text "Items: 49"
    end

    take_screenshot
  end
end
# Copyright 2025
