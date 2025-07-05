require "application_system_test_case"

class HomeCounterTest < ApplicationSystemTestCase
  test "counter works on home page" do
    visit root_path
    
    # Counter should be visible
    assert_selector "[data-controller='counter']"
    
    # Initial state
    within "[data-controller='counter']" do
      assert_text "Counter: 0"
      assert_text "0"
      
      # Click increment
      click_button "+"
      assert_text "Counter: 1"
      assert_text "1"
      
      # Click increment again
      click_button "+"
      assert_text "Counter: 2"
      
      # Click decrement
      click_button "-"
      assert_text "Counter: 1"
      
      # Click reset
      click_button "Reset"
      assert_text "Counter: 0"
    end
    
    take_screenshot
  end
end
# Copyright 2025
