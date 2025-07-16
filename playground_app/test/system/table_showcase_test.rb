# frozen_string_literal: true

require "application_system_test_case"

class TableShowcaseTest < ApplicationSystemTestCase
  test "table examples showcase the powerful DSL features" do
    visit root_path
    
    # Wait for page to load
    assert_selector "[data-controller='playground']", wait: 10
    
    # Check if table examples are available in sidebar
    within(".playground-sidebar") do
      assert_text "Simple Table", wait: 5
      assert_text "Data Table", wait: 5
      assert_text "Sales Report", wait: 5
      assert_text "Employee Directory", wait: 5
    end
    
    # Test Simple Table example
    click_link "Simple Table"
    
    # Wait for preview to update
    sleep 2
    
    # Check if table is rendered in preview
    within("#preview-container") do
      assert_text "Simple Table Example", wait: 5
      assert_selector "table", wait: 5
      assert_text "Name", wait: 5
      assert_text "John Doe", wait: 5
    end
    
    # Test Data Table example
    click_link "Data Table"
    
    # Wait for preview to update
    sleep 2
    
    # Check if advanced table is rendered
    within("#preview-container") do
      assert_text "Advanced Data Table", wait: 5
      assert_text "User Management", wait: 5
      assert_selector "table", wait: 5
      assert_text "Add User", wait: 5
      assert_text "Search users...", wait: 5
    end
    
    # Test Sales Report example
    click_link "Sales Report"
    
    # Wait for preview to update
    sleep 2
    
    # Check if sales table is rendered
    within("#preview-container") do
      assert_text "Sales Report Table", wait: 5
      assert_text "Q1 2024 Sales Report", wait: 5
      assert_selector "table", wait: 5
      assert_text "iPhone 15", wait: 5
      assert_text "Revenue", wait: 5
    end
    
    # Test Employee Directory example
    click_link "Employee Directory"
    
    # Wait for preview to update
    sleep 2
    
    # Check if employee table is rendered
    within("#preview-container") do
      assert_text "Employee Directory", wait: 5
      assert_text "Company Directory", wait: 5
      assert_selector "table", wait: 5
      assert_text "Sarah Connor", wait: 5
      assert_text "Engineering", wait: 5
      assert_text "Salary", wait: 5
    end
  end
end