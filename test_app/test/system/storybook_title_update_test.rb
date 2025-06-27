# frozen_string_literal: true

require "application_system_test_case"

class StorybookTitleUpdateTest < ApplicationSystemTestCase
  test "title input updates card in real time" do
    puts "🧪 Testing real-time title updates..."
    
    # Navigate to card component storybook
    visit "/storybook/show?story=card_component"
    
    # Wait for page to load
    assert_selector "[data-controller='live_story']", wait: 5
    puts "✅ Page loaded with live_story controller"
    
    # Find the title input
    title_input = find("input[name='title']", wait: 5)
    initial_title = title_input.value
    puts "📝 Found title input with value: '#{initial_title}'"
    
    # Check initial card title
    initial_card_title = find("#component-preview .text-lg", wait: 5)
    puts "🎯 Initial card title: '#{initial_card_title.text}'"
    
    # Change the title
    new_title = "Live Update Test Title"
    title_input.fill_in with: new_title
    
    # Trigger the input event explicitly
    page.execute_script("arguments[0].dispatchEvent(new Event('input', { bubbles: true }));", title_input)
    
    puts "⏳ Waiting for title update..."
    
    # Wait for the card to update with new title
    assert_text new_title, wait: 10
    
    puts "✅ Title successfully updated to: '#{new_title}'"
    
    # Verify the card title changed
    updated_card_title = find("#component-preview .text-lg", wait: 5)
    assert_equal new_title, updated_card_title.text
    
    puts "🎉 Real-time title update test passed!"
  end
  
  test "javascript errors check" do
    puts "🔍 Checking for JavaScript errors..."
    
    visit "/storybook/show?story=card_component"
    
    # Check for any JavaScript errors
    errors = page.driver.browser.logs.get(:browser)
    console_errors = errors.select { |e| e.level == "SEVERE" }
    
    if console_errors.any?
      puts "❌ JavaScript errors found:"
      console_errors.each do |error|
        puts "  - #{error.message}"
      end
      assert false, "JavaScript errors detected"
    else
      puts "✅ No JavaScript errors found"
    end
  end
  
  test "stimulus controller connection check" do
    puts "🎛️ Testing Stimulus controller connection..."
    
    visit "/storybook/show?story=card_component"
    
    # Check that the controller is connected
    controller_element = find("[data-controller='live_story']", wait: 5)
    assert controller_element.present?
    
    # Check that targets are properly registered
    controls = all("[data-live-story-target='control']")
    assert controls.count > 0, "Should have control targets"
    puts "✅ Found #{controls.count} control targets"
    
    # Check specific title input
    title_input = find("input[name='title'][data-live-story-target='control']")
    assert title_input.present?
    puts "✅ Title input has correct Stimulus target"
    
    # Check action attribute
    action_attr = title_input['data-action']
    assert action_attr.include?("input->live_story#controlChanged"), "Should have correct action"
    puts "✅ Title input has correct Stimulus action: #{action_attr}"
  end
end