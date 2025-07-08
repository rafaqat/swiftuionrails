# Copyright 2025
require "application_system_test_case"

class NewDslMethodsSystemTest < ApplicationSystemTestCase
  test "new DSL methods render correctly in storybook" do
    visit "/storybook/index"

    # Navigate to the new DSL methods stories
    click_on "new_dsl_methods"

    # Test form controls story
    click_on "form_controls"

    # Verify select and label elements are rendered
    assert_selector "label", text: "Choose a color:"
    assert_selector "select[name='color']"
    assert_selector "option[value='red']", text: "Red"
    assert_selector "option[value='blue']", text: "Blue"

    # Test advanced styling story
    click_on "advanced_styling"

    # Verify elements with new modifiers are rendered
    assert_selector ".group"
    assert_selector ".group-hover\\:opacity-75"
    assert_selector ".break-inside-avoid"
    assert_selector ".hover\\:ring-2"

    # Test flex and styles story
    click_on "flex_and_styles"

    # Verify flex shrink and custom styles
    assert_selector ".flex-shrink-0"
    assert_selector "[title='This is a custom tooltip']"
    assert_selector "[style*='background: linear-gradient']"
  end

  test "select dropdown interaction works" do
    visit "/storybook/index"
    click_on "new_dsl_methods"
    click_on "form_controls"

    # Change the selected color using the control
    select "green", from: "Selected color"

    # Wait for update and verify the select element updated
    sleep 0.5 # Give time for the update

    within ".swift-ui-preview" do
      select_element = find("select[name='color']")
      assert_equal "green", select_element.value
    end
  end
end
# Copyright 2025
