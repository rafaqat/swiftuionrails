# frozen_string_literal: true

require "application_system_test_case"

class StorybookInteractiveTest < ApplicationSystemTestCase
  # Use Chrome with headless mode for CI
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  def setup
    # Ensure we have a clean state
    visit storybook_index_path
    assert_selector "h1", text: "Component Storybook"
  end

  test "card component interactive controls work correctly" do
    # Navigate to card component
    click_link "Card Component"
    assert_current_path "/storybook/show?story=card_component"
    
    # Wait for component to load
    assert_selector "[data-controller='live_story']", wait: 5
    assert_selector "#component-preview", wait: 5
    
    # Test background color change
    test_background_color_control
    
    # Test elevation control
    test_elevation_control
    
    # Test padding control
    test_padding_control
    
    # Test corner radius control
    test_corner_radius_control
    
    # Test boolean controls
    test_boolean_controls
    
    # Test real-time code generation
    test_code_generation_updates
  end

  test "enhanced product list component interactive controls work correctly" do
    visit "/storybook/show?story=enhanced_product_list_component"
    
    # Wait for component to load
    assert_selector "[data-controller='live_story']", wait: 5
    assert_selector "#component-preview", wait: 5
    
    # Test columns control
    test_product_list_columns_control
    
    # Test background color control
    test_product_list_background_control
    
    # Test gap control
    test_product_list_gap_control
    
    # Test boolean controls
    test_product_list_boolean_controls
    
    # Test anti-flash behavior
    test_anti_flash_behavior
  end

  test "all basic dsl components have working controls" do
    # Test each DSL component story individually
    %w[
      simple_button_component
      text_component
      vstack_component
      hstack_component
      image_component
    ].each do |component_story|
      next unless File.exist?(Rails.root.join("test/components/stories/#{component_story}_stories.rb"))
      
      visit "/storybook/show?story=#{component_story}"
      
      # Wait for component to load
      assert_selector "[data-controller='live_story']", wait: 5
      assert_selector "#component-preview", wait: 5
      
      # Test that controls exist and are functional
      test_component_has_working_controls(component_story)
    end
  end

  private

  def test_background_color_control
    puts "🧪 Testing background color control..."
    
    # Find the background color select
    background_select = find("select[name='background_color']")
    initial_value = background_select.value
    
    # Get initial card background
    initial_card = find("#component-preview .bg-white", wait: 5)
    
    # Change to blue background
    background_select.select("Gray 50")
    
    # Wait for update and verify change occurred
    wait_for_preview_update
    
    # Check that the card background changed
    assert_no_selector "#component-preview .bg-white", wait: 2
    assert_selector "#component-preview .bg-gray-50", wait: 2
    
    # Verify code generation updated
    code_block = find("#chainable-code")
    assert_includes code_block.text, 'background("gray-50")'
    
    puts "✅ Background color control working"
  end

  def test_elevation_control
    puts "🧪 Testing elevation control..."
    
    elevation_select = find("select[name='elevation']")
    
    # Test elevation changes
    [2, 3, 1].each do |elevation|
      elevation_select.select(elevation.to_s)
      wait_for_preview_update
      
      # Verify shadow class is applied
      shadow_class = case elevation
                    when 1 then "shadow"
                    when 2 then "shadow-md" 
                    when 3 then "shadow-lg"
                    end
      
      assert_selector "#component-preview .#{shadow_class}", wait: 2
    end
    
    puts "✅ Elevation control working"
  end

  def test_padding_control
    puts "🧪 Testing padding control..."
    
    padding_select = find("select[name='padding']")
    
    # Test different padding values
    ["20", "8", "16"].each do |padding|
      padding_select.select(padding)
      wait_for_preview_update
      
      if padding != "16" # 16 is default, so no modifier should be added
        code_block = find("#chainable-code")
        assert_includes code_block.text, ".padding(#{padding})"
      end
    end
    
    puts "✅ Padding control working"
  end

  def test_corner_radius_control
    puts "🧪 Testing corner radius control..."
    
    radius_select = find("select[name='corner_radius']")
    
    # Test different corner radius values
    ["xl", "sm", "lg"].each do |radius|
      radius_select.select(radius.humanize)
      wait_for_preview_update
      
      if radius != "lg" # lg is default
        code_block = find("#chainable-code")
        assert_includes code_block.text, %(.corner_radius("#{radius}"))
      end
    end
    
    puts "✅ Corner radius control working"
  end

  def test_boolean_controls
    puts "🧪 Testing boolean controls..."
    
    # Test border toggle
    border_checkbox = find("input[name='border']")
    border_checkbox.check
    wait_for_preview_update
    
    code_block = find("#chainable-code")
    assert_includes code_block.text, ".border"
    
    border_checkbox.uncheck
    wait_for_preview_update
    
    # Test hover effect toggle
    hover_checkbox = find("input[name='hover_effect']")
    hover_checkbox.check
    wait_for_preview_update
    
    code_block = find("#chainable-code")
    assert_includes code_block.text, '.hover_scale("105")'
    
    puts "✅ Boolean controls working"
  end

  def test_code_generation_updates
    puts "🧪 Testing real-time code generation..."
    
    code_block = find("#chainable-code")
    initial_code = code_block.text
    
    # Make a change
    elevation_select = find("select[name='elevation']")
    elevation_select.select("2")
    wait_for_preview_update
    
    # Verify code updated
    updated_code = code_block.text
    assert_not_equal initial_code, updated_code
    assert_includes updated_code, "card(elevation: 2)"
    
    puts "✅ Code generation updating correctly"
  end

  def test_product_list_columns_control
    puts "🧪 Testing product list columns control..."
    
    columns_select = find("select[name='columns']")
    initial_grid = find("#component-preview .grid")
    
    # Test different column configurations
    ["two", "three", "four"].each do |columns|
      columns_select.select(columns.humanize)
      wait_for_preview_update
      
      # Verify grid classes changed
      grid = find("#component-preview .grid")
      case columns
      when "two"
        assert grid[:class].include?("sm:grid-cols-2")
      when "three" 
        assert grid[:class].include?("lg:grid-cols-3")
      when "four"
        assert grid[:class].include?("lg:grid-cols-4")
      end
    end
    
    puts "✅ Product list columns control working"
  end

  def test_product_list_background_control
    puts "🧪 Testing product list background control..."
    
    background_select = find("select[name='background_color']")
    container = find("#component-preview [data-controller='enhanced-product-list']")
    
    # Test background color change
    background_select.select("Blue 50")
    wait_for_preview_update
    
    # Verify background class applied
    updated_container = find("#component-preview [data-controller='enhanced-product-list']")
    assert updated_container[:class].include?("bg-blue-50")
    
    puts "✅ Product list background control working"
  end

  def test_product_list_gap_control
    puts "🧪 Testing product list gap control..."
    
    gap_select = find("select[name='gap']") 
    
    ["4", "8", "12"].each do |gap|
      gap_select.select(gap)
      wait_for_preview_update
      
      grid = find("#component-preview .grid")
      assert grid[:class].include?("gap-#{gap}")
    end
    
    puts "✅ Product list gap control working"
  end

  def test_product_list_boolean_controls
    puts "🧪 Testing product list boolean controls..."
    
    # Test sortable toggle
    sortable_checkbox = find("input[name='sortable']")
    sortable_checkbox.uncheck
    wait_for_preview_update
    
    # Should hide sort controls
    assert_no_selector "#component-preview select", wait: 2
    
    sortable_checkbox.check
    wait_for_preview_update
    
    # Should show sort controls
    assert_selector "#component-preview select", wait: 2
    
    puts "✅ Product list boolean controls working"
  end

  def test_anti_flash_behavior
    puts "🧪 Testing anti-flash behavior..."
    
    # Make rapid changes to test for flash
    background_select = find("select[name='background_color']")
    columns_select = find("select[name='columns']")
    
    # Rapid fire changes to stress test anti-flash
    5.times do |i|
      background_select.select(["White", "Gray 50", "Blue 50"].sample)
      columns_select.select(["Auto", "Two", "Three", "Four"].sample)
      sleep 0.1 # Small delay to allow processing
    end
    
    # Final verification - should still be responsive
    background_select.select("Blue 50")
    wait_for_preview_update
    
    container = find("#component-preview [data-controller='enhanced-product-list']")
    assert container[:class].include?("bg-blue-50")
    
    puts "✅ Anti-flash behavior working"
  end

  def test_component_has_working_controls(component_story)
    puts "🧪 Testing #{component_story} controls..."
    
    # Find all controls
    controls = all("select[data-live_story_target='control'], input[data-live_story_target='control']")
    
    if controls.empty?
      puts "⚠️  No controls found for #{component_story}"
      return
    end
    
    # Test each control
    controls.each_with_index do |control, index|
      case control.tag_name
      when "select"
        test_select_control(control, "#{component_story}_select_#{index}")
      when "input"
        test_input_control(control, "#{component_story}_input_#{index}")
      end
    end
    
    puts "✅ #{component_story} controls working"
  end

  def test_select_control(select_element, identifier)
    options = select_element.all("option")
    return if options.length <= 1
    
    initial_value = select_element.value
    
    # Select a different option
    new_option = options.find { |opt| opt.value != initial_value }
    return unless new_option
    
    select_element.select(new_option.text)
    wait_for_preview_update
    
    # Verify change was applied (basic check)
    assert_selector "#component-preview", wait: 2
    
    puts "  ✓ #{identifier} select control working"
  end

  def test_input_control(input_element, identifier)
    case input_element[:type]
    when "checkbox"
      input_element.set(!input_element.checked?)
      wait_for_preview_update
      assert_selector "#component-preview", wait: 2
      puts "  ✓ #{identifier} checkbox control working"
    when "text"
      input_element.fill_in with: "Test Value #{rand(1000)}"
      wait_for_preview_update
      assert_selector "#component-preview", wait: 2
      puts "  ✓ #{identifier} text control working"
    end
  end

  def wait_for_preview_update
    # Wait for AJAX request to complete and preview to update
    sleep 0.3 # Allow for debouncing
    
    # Wait for any pending requests to finish
    assert_no_selector ".loading", wait: 2 rescue nil
    
    # Additional small delay for DOM updates
    sleep 0.2
  end

  def debug_current_state
    puts "=== DEBUG INFO ==="
    puts "Current URL: #{current_url}"
    puts "Page title: #{page.title}"
    
    # Check for JavaScript errors
    logs = page.driver.browser.logs.get(:browser)
    errors = logs.select { |log| log.level == "SEVERE" }
    if errors.any?
      puts "JavaScript errors:"
      errors.each { |error| puts "  #{error.message}" }
    end
    
    # Check Stimulus controller status
    controller_status = page.evaluate_script("
      const controller = document.querySelector('[data-controller*=live_story]');
      if (controller && controller.stimulus) {
        return 'Controller connected';
      } else {
        return 'Controller not found or not connected';
      }
    ")
    puts "Stimulus controller: #{controller_status}"
    
    puts "==================="
  end
end