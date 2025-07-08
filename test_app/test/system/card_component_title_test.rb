# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class CardComponentTitleTest < ApplicationSystemTestCase
  test "card component title changes work in real time" do
    puts "🧪 Testing card component with new working pattern..."

    visit "/storybook/show?story=card_component"

    # Wait for page to load
    assert_selector "[data-controller='live_story']", wait: 5
    puts "✅ Storybook page loaded"

    # Find the title input
    title_input = find("input[name='title']", wait: 5)
    initial_title = title_input.value
    puts "📝 Found title input with value: '#{initial_title}'"

    # Check initial card title
    initial_card_title = find("#component-preview .text-lg", wait: 5)
    puts "🎯 Initial card title: '#{initial_card_title.text}'"

    # Verify the initial title matches
    assert_equal initial_title, initial_card_title.text, "Initial title should match"

    # Change the title
    new_title = "Real Time Update Works!"
    title_input.fill_in with: new_title

    # Trigger change event
    title_input.send_keys(:tab)

    puts "⏳ Waiting for title update..."

    # Wait for the card to update with new title - increased timeout
    begin
      assert_text new_title, wait: 10
      puts "✅ Title successfully updated to: '#{new_title}'"

      # Double check the card title element specifically
      updated_card_title = find("#component-preview .text-lg", wait: 5)
      assert_equal new_title, updated_card_title.text

      puts "🎉 Card component real-time updates are working perfectly!"

    rescue Capybara::ElementNotFound => e
      # Get debug info if it fails
      puts "❌ Title update failed"
      puts "Current page text includes: #{page.text.include?(new_title) ? 'YES' : 'NO'}"

      # Check if any AJAX calls were made
      network_logs = page.driver.browser.logs.get(:browser).select { |l| l.message.include?("POST") || l.message.include?("AJAX") }
      puts "Network activity: #{network_logs.any? ? 'YES' : 'NO'}"

      raise e
    end
  end
end
# Copyright 2025
