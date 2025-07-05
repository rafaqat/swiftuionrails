# Copyright 2025
require "application_system_test_case"

class StorybookLiveUpdatesTest < ApplicationSystemTestCase
  test "updates preview without page refresh when changing text input" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Initial button text
    within "#component-preview" do
      assert_selector "button", text: "Click Me"
    end
    
    # Change the title
    fill_in "title", with: "Updated Button"
    
    # Wait for live update (debounced)
    sleep 0.5
    
    # Check that preview updated without page refresh
    within "#component-preview" do
      assert_selector "button", text: "Updated Button"
    end
    
    # Ensure page didn't refresh (check for persistent element)
    assert_selector "[data-controller='storybook']"
  end

  test "updates preview immediately when changing select dropdown" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Check initial variant
    within "#component-preview" do
      assert_selector "button.bg-blue-600"
    end
    
    # Change variant to danger
    select "danger", from: "variant"
    
    # Should update immediately
    within "#component-preview" do
      assert_selector "button.bg-red-600"
      assert_no_selector "button.bg-blue-600"
    end
  end

  test "updates preview when toggling checkbox" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Initially not disabled
    within "#component-preview" do
      assert_no_selector "button[disabled]"
      assert_no_selector "button.opacity-50"
    end
    
    # Enable disabled state
    check "disabled"
    
    # Should update immediately
    within "#component-preview" do
      assert_selector "button[disabled]"
      assert_selector "button.opacity-50"
    end
  end

  test "switches between story variants without page refresh" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Click on all_variants
    click_link "All variants"
    
    # Wait for update
    sleep 0.5
    
    # Should show all three button variants
    within "#component-preview" do
      assert_selector "button", count: 3
      assert_selector "button", text: "Primary"
      assert_selector "button", text: "Secondary"
      assert_selector "button", text: "Danger"
    end
    
    # Click back to default
    click_link "Default"
    
    sleep 0.5
    
    # Should show single button again
    within "#component-preview" do
      assert_selector "button", count: 1
      assert_selector "button", text: "Click Me"
    end
  end

  test "shows update indicator briefly after changes" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Change title
    fill_in "title", with: "Test Update"
    
    # Wait for update indicator to appear
    sleep 0.5
    
    # Update indicator should be visible briefly
    # Note: This might be tricky to catch in tests due to timing
    # Could check for the element existence instead
    assert_selector "#update-indicator"
  end

  test "shows live indicator" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Check for live indicator
    assert_selector "span", text: "Live"
    assert_selector ".animate-pulse"
    assert_text "Live preview updates automatically"
  end

  test "copy button works for code examples" do
    visit storybook_show_path(story: "simple_button_component")
    
    # Check copy button exists
    assert_selector "button", text: "Copy"
    
    # Click copy button
    click_button "Copy"
    
    # Button text should change to "Copied!"
    assert_selector "button", text: "Copied!"
    
    # After 2 seconds it should revert
    sleep 2.5
    assert_selector "button", text: "Copy"
  end
end
# Copyright 2025
