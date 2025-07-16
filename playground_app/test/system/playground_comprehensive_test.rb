# frozen_string_literal: true

require "application_system_test_case"

class PlaygroundComprehensiveTest < ApplicationSystemTestCase
  test "sidebar menu links all render properly and showcase DSL features" do
    visit root_path
    
    # Wait for page to load
    assert_selector "[data-controller='playground']"
    
    # Test Components Section
    test_components_section
    
    # Test Examples Section with table showcase
    test_examples_section
    
    # Test Favorites Section
    test_favorites_section
    
    # Test Search Functionality
    test_search_functionality
  end

  private

  def test_components_section
    within("[data-playground-target='componentsContainer']") do
      # Test Basic components
      assert_text "Basic"
      
      # Test Text component
      click_on "Text"
      wait_for_preview_update
      assert_preview_contains "Your text here"
      
      # Test Button component
      click_on "Button"
      wait_for_preview_update
      assert_preview_contains "Click Me"
      
      # Test Image component
      click_on "Image"
      wait_for_preview_update
      assert_preview_contains "img"
      
      # Test Layout components
      assert_text "Layout"
      
      # Test VStack component
      click_on "VStack"
      wait_for_preview_update
      assert_preview_contains "Add content here"
      
      # Test HStack component
      click_on "HStack"
      wait_for_preview_update
      assert_preview_contains "Left"
      assert_preview_contains "Right"
      
      # Test Grid component
      click_on "Grid"
      wait_for_preview_update
      assert_preview_contains "Add grid items here"
      
      # Test Components section
      assert_text "Components"
      
      # Test Card component
      click_on "Card"
      wait_for_preview_update
      assert_preview_contains "Add content here"
      
      # Test List component
      click_on "List"
      wait_for_preview_update
      assert_preview_contains "Item 1"
      assert_preview_contains "Item 5"
      
      # Test Forms section
      assert_text "Forms"
      
      # Test Form component
      click_on "Form"
      wait_for_preview_update
      assert_preview_contains "form"
      
      # Test TextField component
      click_on "TextField"
      wait_for_preview_update
      assert_preview_contains "Enter email"
      
      # Test Tables section - this is the new powerful DSL feature
      assert_text "Tables"
      
      # Test Simple Table component
      click_on "Simple Table"
      wait_for_preview_update
      assert_preview_contains "table"
      assert_preview_contains "Name"
      assert_preview_contains "Role"
      assert_preview_contains "Status"
      assert_preview_contains "John Doe"
      assert_preview_contains "Jane Smith"
      
      # Test Data Table component - showcase rich formatting
      click_on "Data Table"
      wait_for_preview_update
      assert_preview_contains "Users"
      assert_preview_contains "table"
      assert_preview_contains "Name"
      assert_preview_contains "Role"
      assert_preview_contains "Status"
      # Should show badge formatting for roles and status
      assert_preview_contains "badge"
      
      # Test raw Table component
      click_on "Table"
      wait_for_preview_update
      assert_preview_contains "table"
      assert_preview_contains "thead"
      assert_preview_contains "tbody"
      assert_preview_contains "Header"
      assert_preview_contains "Data"
    end
  end

  def test_examples_section
    within("[data-playground-target='examplesContainer']") do
      # Test Layout Demo
      click_on "Layout Demo"
      wait_for_preview_update
      assert_preview_contains "HStack Justification Examples"
      assert_preview_contains "justify: :start"
      assert_preview_contains "justify: :center"
      assert_preview_contains "justify: :between"
      assert_preview_contains "justify: :around"
      assert_preview_contains "justify: :evenly"
      
      # Test Product Grid
      click_on "Product Grid"
      wait_for_preview_update
      assert_preview_contains "Premium Product"
      assert_preview_contains "grid"
      assert_preview_contains "hover"
      assert_preview_contains "Quick View"
      
      # Test Dashboard Stats
      click_on "Dashboard Stats"
      wait_for_preview_update
      assert_preview_contains "Total Revenue"
      assert_preview_contains "Active Users"
      assert_preview_contains "grid"
      assert_preview_contains "$45,678"
      
      # Test Pricing Cards
      click_on "Pricing Cards"
      wait_for_preview_update
      assert_preview_contains "Starter"
      assert_preview_contains "Professional"
      assert_preview_contains "Enterprise"
      assert_preview_contains "Most Popular"
      assert_preview_contains "Get Started"
      
      # Test Todo List
      click_on "Todo List"
      wait_for_preview_update
      assert_preview_contains "My Tasks"
      assert_preview_contains "data-controller=\"todo-list\""
      assert_preview_contains "What needs to be done?"
      
      # Test Navigation Bar
      click_on "Navigation Bar"
      wait_for_preview_update
      assert_preview_contains "SwiftUI Rails"
      assert_preview_contains "Home"
      assert_preview_contains "Components"
      assert_preview_contains "Documentation"
      
      # Test NEW Table Examples - showcase the powerful DSL
      
      # Test Simple Table Example
      click_on "Simple Table"
      wait_for_preview_update
      assert_preview_contains "Simple Table Example"
      assert_preview_contains "table"
      assert_preview_contains "Name"
      assert_preview_contains "Role"
      assert_preview_contains "Email"
      assert_preview_contains "Status"
      assert_preview_contains "John Doe"
      assert_preview_contains "jane@example.com"
      
      # Test Data Table Example - advanced features
      click_on "Data Table"
      wait_for_preview_update
      assert_preview_contains "Advanced Data Table"
      assert_preview_contains "User Management"
      assert_preview_contains "Add User"
      assert_preview_contains "Search users..."
      assert_preview_contains "avatar"
      assert_preview_contains "badge"
      assert_preview_contains "Last Login"
      assert_preview_contains "Actions"
      assert_preview_contains "Edit"
      assert_preview_contains "Delete"
      
      # Test Sales Report Table - currency formatting
      click_on "Sales Report"
      wait_for_preview_update
      assert_preview_contains "Sales Report Table"
      assert_preview_contains "Q1 2024 Sales Report"
      assert_preview_contains "iPhone 15"
      assert_preview_contains "MacBook Pro"
      assert_preview_contains "Revenue"
      assert_preview_contains "Growth %"
      assert_preview_contains "↑" # Growth indicators
      assert_preview_contains "↓"
      assert_preview_contains "Electronics"
      assert_preview_contains "Audio"
      
      # Test Employee Directory - pagination and avatars
      click_on "Employee Directory"
      wait_for_preview_update
      assert_preview_contains "Employee Directory"
      assert_preview_contains "Company Directory"
      assert_preview_contains "Add Employee"
      assert_preview_contains "Search employees..."
      assert_preview_contains "Sarah Connor"
      assert_preview_contains "Engineering"
      assert_preview_contains "Senior Developer"
      assert_preview_contains "Salary"
      assert_preview_contains "$95,000"
      assert_preview_contains "Hire Date"
      assert_preview_contains "Mar 15, 2022"
      # Should show pagination controls
      assert_preview_contains "Showing 1 to 5 of 50 results"
      assert_preview_contains "Previous"
      assert_preview_contains "Next"
    end
  end

  def test_favorites_section
    within("[data-playground-target='favoritesList']") do
      assert_text "No favorites yet"
    end
    
    # Test add favorite button
    find("[data-action='click->playground#saveFavorite']").click
    # Note: This would require additional implementation for full functionality
  end

  def test_search_functionality
    # Test search input
    search_input = find("[data-playground-target='searchInput']")
    search_input.fill_in with: "table"
    
    # Should filter components to show only table-related items
    # This would require additional implementation for real filtering
  end

  def wait_for_preview_update
    # Wait for Turbo to update the preview
    sleep 0.5 # Simple wait, in real app might use more sophisticated waiting
  end

  def assert_preview_contains(text)
    within("#preview-container") do
      assert_text text, wait: 2
    end
  rescue Capybara::ElementNotFound
    # If text not found, check the HTML content for elements
    within("#preview-container") do
      assert_selector "*", text: text, wait: 2
    end
  rescue
    # Fallback: check if the text appears anywhere in the preview HTML
    preview_html = find("#preview-container").native.inner_html
    assert_includes preview_html, text, "Expected preview to contain '#{text}'"
  end
end