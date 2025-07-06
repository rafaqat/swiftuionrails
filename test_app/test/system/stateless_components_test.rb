# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class StatelessComponentsTest < ApplicationSystemTestCase
  test "filters update URL and content" do
    visit stateless_demo_path
    
    # Initially shows all products
    assert_text "iPhone 15 Pro"
    assert_text "Nike Air Max"
    assert_text "Levi's 501"
    
    # Filter by category
    select "Electronics", from: "filter_category"
    
    # URL should update
    assert_current_path(/filters\[category\]=electronics/)
    
    # Only electronics should show
    assert_text "iPhone 15 Pro"
    assert_text "MacBook Air M2"
    assert_no_text "Nike Air Max"
    assert_no_text "Levi's 501"
  end
  
  test "pagination works through URL params" do
    visit stateless_demo_path
    
    # First page shows first 3 products
    products_on_page = all(".bg-white.p-6.rounded-lg.shadow-sm").count
    assert_equal 3, products_on_page
    
    # Click next page
    click_link "Next →"
    
    # URL should update
    assert_current_path(/page=2/)
    
    # Different products should show
    products_on_page = all(".bg-white.p-6.rounded-lg.shadow-sm").count
    assert products_on_page > 0
  end
  
  test "search works without JavaScript" do
    visit stateless_demo_path
    
    # Search for "nike"
    fill_in "q", with: "nike"
    click_button "Search"
    
    # URL should include search query
    assert_current_path(/q=nike/)
    
    # Search results should show
    within "#search_results" do
      assert_text "Nike Air Max"
      assert_text "Nike Hoodie"
      assert_no_text "iPhone"
    end
  end
  
  test "tabs navigate through URL" do
    visit stateless_demo_path
    
    # Default tab is products
    assert_text "Filter Products"
    
    # Click About tab
    click_link "About"
    
    # URL should update
    assert_current_path(/tab=about/)
    
    # About content should show
    assert_text "About Rails-First Components"
    assert_no_text "Filter Products"
    
    # Click Help tab
    click_link "Help"
    
    # URL should update
    assert_current_path(/tab=help/)
    
    # Help content should show
    assert_text "How It Works"
  end
  
  test "modal controlled by URL params" do
    visit stateless_demo_path(tab: "about")
    
    # No modal initially
    assert_no_selector "#modal-backdrop"
    
    # Click to open modal
    click_link "Open Info Modal"
    
    # URL should include modal param
    assert_current_path(/modal=info/)
    
    # Modal should be visible
    assert_selector "#modal-backdrop"
    assert_text "Stateless Modal Example"
    
    # Click close button
    within '[role="dialog"]' do
      click_link "Close"
    end
    
    # Modal param should be removed
    refute_current_path(/modal=/)
    
    # Modal should be gone
    assert_no_selector "#modal-backdrop"
  end
  
  test "combined filters and pagination maintain state" do
    visit stateless_demo_path
    
    # Apply filter
    select "Shoes", from: "filter_category"
    
    # Should show filtered results
    assert_text "Nike Air Max"
    assert_text "Adidas Ultraboost"
    assert_no_text "iPhone"
    
    # Navigate to next page (if available)
    if page.has_link?("Next →")
      click_link "Next →"
      
      # URL should have both filter and page params
      assert_current_path(/filters\[category\]=shoes/)
      assert_current_path(/page=2/)
    end
  end
  
  test "progressive enhancement with search" do
    visit stateless_demo_path
    
    # Type in search box (simulating live search)
    fill_in "q", with: "app"
    
    # Wait a bit for debounced search (if JS is enabled)
    sleep 0.5
    
    # Should still work by clicking Search button
    click_button "Search"
    
    # Results should show
    within "#search_results" do
      assert_text "Apple"
    end
  end
end
# Copyright 2025
