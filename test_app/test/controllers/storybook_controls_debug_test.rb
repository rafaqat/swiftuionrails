# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class StorybookControlsDebugTest < ActionDispatch::IntegrationTest
  test "debug controls extraction for card component" do
    story_name = "card_component"
    story_file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")

    # Load the story file
    load story_file
    story_class_name = "#{story_name.camelize}Stories"
    story_class = story_class_name.safe_constantize

    puts "\n=== CONTROLS EXTRACTION DEBUG ==="
    puts "Story class: #{story_class}"
    puts "Story class methods: #{story_class.instance_methods(false)}"

    # Get component class
    base_name = story_name.gsub(/_component(_stories)?$/, "")
    component_name = "#{base_name}_component"
    component_class = component_name.camelize.safe_constantize

    puts "Component class: #{component_class}"

    # Test controls extraction (same logic as storybook controller)
    begin
      controls_collection = story_class.send(:controls)
      puts "Controls collection: #{controls_collection.class}"
      puts "Controls collection methods: #{controls_collection.class.instance_methods(false)}"

      # Try to access the controls data
      controls_data = controls_collection.instance_variable_get(:@controls) || []
      puts "Controls data: #{controls_data}"

      controls_hash = {}
      controls_data.each do |control_data|
        puts "Processing control: #{control_data}"
        control_hash = control_data.except(:only, :except)
        control_hash[:type] = control_hash.delete(:as)
        controls_hash[control_data[:param]] = control_hash
      end

      puts "Final controls hash: #{controls_hash}"

    rescue => e
      puts "❌ Error extracting controls: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(5)}"
    end

    puts "=== END CONTROLS DEBUG ==="
  end
end
# Copyright 2025
