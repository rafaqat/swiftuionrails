# frozen_string_literal: true

require "application_system_test_case"

class HstackJustifyBasicTest < ApplicationSystemTestCase
  def setup
    # Visit the unified playground 
    visit root_path
    
    # Wait for page to load
    assert_selector '[data-controller="playground"]', wait: 10
    
    # Give page time to fully load
    sleep 2
  end

  test "Layout Demo example shows all justify behaviors" do
    # Click on the Layout Demo example
    within_examples_section do
      click_on "Layout Demo"
    end
    
    # Wait for preview to update
    sleep 4
    
    # Verify the preview shows all justify options
    within_preview_container do
      # Check for the main heading
      assert_selector "span", text: "HStack Justification Examples", wait: 10
      
      # Check for each justify option demonstration
      justify_labels = [
        "justify: :start (default)",
        "justify: :center", 
        "justify: :end",
        "justify: :between",
        "justify: :around",
        "justify: :evenly"
      ]
      
      justify_labels.each do |label|
        assert_selector "span", text: label, wait: 5
      end
      
      # Verify that each demo section has the appropriate CSS classes
      [
        "justify-start", 
        "justify-center", 
        "justify-end", 
        "justify-between", 
        "justify-around", 
        "justify-evenly"
      ].each do |css_class|
        assert_selector "div.#{css_class}", wait: 5
      end
      
      # Check that the demo boxes are rendered
      assert_selector "div", text: "A", count: 6, wait: 5
      assert_selector "div", text: "B", count: 6, wait: 5
      assert_selector "div", text: "C", count: 6, wait: 5
    end
    
    # Take screenshot
    save_screenshot("layout_demo_complete.png")
  end

  test "justify between specifically spreads elements to edges" do
    # Click on the Layout Demo example
    within_examples_section do
      click_on "Layout Demo"
    end
    
    # Wait for preview to update
    sleep 4
    
    within_preview_container do
      # Find the specific justify-between section
      justify_between_container = find("div.justify-between")
      
      # Verify it has the w-full class for proper distribution
      assert_selector "div.justify-between.w-full", wait: 5
      
      # Verify the elements are positioned correctly
      within justify_between_container do
        # Should have exactly 3 elements (A, B, C)
        assert_selector "div", count: 3
        assert_selector "div", text: "A"
        assert_selector "div", text: "B"
        assert_selector "div", text: "C"
      end
    end
    
    # Take screenshot
    save_screenshot("justify_between_verification.png")
  end
  
  test "sidebar shows available components including HStack" do
    # Check that the sidebar contains HStack component
    within_sidebar_components do
      assert_selector "button", text: "HStack", wait: 5
    end
    
    # Check that examples section contains Layout Demo
    within_examples_section do
      assert_selector "button", text: "Layout Demo", wait: 5
    end
    
    # Take screenshot
    save_screenshot("sidebar_components.png")
  end
  
  test "page loads without errors and has proper structure" do
    # Verify basic page structure
    assert_selector "h1", text: "SwiftUI Rails Playground", wait: 10
    assert_selector "#monaco-editor", wait: 10
    assert_selector "#preview-container", wait: 10
    
    # Verify sidebar sections
    assert_selector "span", text: "Components", wait: 5
    assert_selector "span", text: "Examples", wait: 5
    assert_selector "span", text: "Favorites", wait: 5
    
    # Take screenshot
    save_screenshot("page_structure.png")
  end

  private

  def within_preview_container(&block)
    within "#preview-container", &block
  end

  def within_examples_section(&block)
    within "[data-playground-target='examplesContainer']", &block
  end

  def within_sidebar_components(&block)
    within "[data-playground-target='componentsContainer']", &block
  end
end