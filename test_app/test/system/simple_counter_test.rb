# Copyright 2025
require "application_system_test_case"

class SimpleCounterTest < ApplicationSystemTestCase
  test "counter increments and decrements" do
    visit root_path

    # Initial state
    assert_text "Counter: 0"

    # Click increment
    click_button "+"
    assert_text "Counter: 1"

    # Click increment again
    click_button "+"
    assert_text "Counter: 2"

    # Click decrement
    click_button "-"
    assert_text "Counter: 1"

    # Reset
    click_button "Reset"
    assert_text "Counter: 0"

    puts "✅ Counter is working correctly!"
  end
end
# Copyright 2025
