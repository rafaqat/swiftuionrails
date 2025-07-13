# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class StorybookHtmlDebugTest < ActionDispatch::IntegrationTest
  test "print actual HTML for debugging" do
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success

    puts "\n=== ACTUAL HTML OUTPUT ==="

    # Extract and print the form section
    doc = Nokogiri::HTML(response.body)
    form = doc.css('form[data-live_story_target="form"]').first

    if form
      puts "Found form with correct target"

      # Print all controls
      controls = form.css('select, input[type="checkbox"], input[type="text"]')
      controls.each_with_index do |control, index|
        puts "\n--- Control #{index + 1} ---"
        puts "Tag: #{control.name}"
        puts "Name: #{control['name']}"
        puts "Data attributes:"
        control.attributes.each do |name, attr|
          puts "  #{name}: #{attr.value}" if name.start_with?("data-")
        end
      end
    else
      puts "❌ Form not found!"
    end

    # Check for the main controller
    main_controller = doc.css('[data-controller*="live_story"]').first
    if main_controller
      puts "\n--- Main Controller ---"
      puts "Controller: #{main_controller['data-controller']}"
      main_controller.attributes.each do |name, attr|
        puts "  #{name}: #{attr.value}" if name.start_with?("data-")
      end
    else
      puts "❌ Main controller not found!"
    end

    puts "\n=== END HTML DEBUG ==="
  end
end
# Copyright 2025
