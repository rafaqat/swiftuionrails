require "application_system_test_case"

class NavbarTest < ApplicationSystemTestCase
  def setup
    if ENV['CI'] || ENV['HEADLESS']
      Capybara.current_driver = :selenium_chrome_headless
    end
    
    visit "/"
    sleep 2
  end

  test "navbar example renders without errors" do
    # Click on Navigation Bar
    click_button "Navigation Bar"
    sleep 2
    
    # Check for errors
    if page.has_css?("#preview-container .playground-error")
      error_text = find("#preview-container .playground-error").text
      puts "Error found: #{error_text}"
      
      # Try to get backtrace
      if page.has_css?("#preview-container .playground-error details")
        find("#preview-container .playground-error details summary").click
        sleep 1
        if page.has_css?("#preview-container .playground-error details pre")
          puts "Backtrace: #{find("#preview-container .playground-error details pre").text}"
        end
      end
      
      flunk "Navigation Bar has error: #{error_text}"
    end
    
    # Check expected content
    within "#preview-container" do
      assert_text "SwiftUI Rails", wait: 5
      
      # Check for navigation links (hidden on mobile, visible on desktop)
      assert_selector "a[href='#']", text: "Home", visible: false, wait: 5
      assert_selector "a[href='#']", text: "Components", visible: false, wait: 5
      assert_selector "a[href='#']", text: "Documentation", visible: false, wait: 5
      assert_selector "a[href='#']", text: "Examples", visible: false, wait: 5
      
      # Check for notification badge
      assert_text "3", wait: 5
      
      # Check dropdown menu items (hidden by default)
      assert_selector "a[href='#']", text: "Profile", visible: false, wait: 5
      assert_selector "a[href='#']", text: "Settings", visible: false, wait: 5
      assert_selector "a[href='#']", text: "Sign out", visible: false, wait: 5
    end
    
    puts "✅ Navigation Bar example renders correctly"
  end
end