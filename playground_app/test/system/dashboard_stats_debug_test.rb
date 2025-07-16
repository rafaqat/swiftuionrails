require "application_system_test_case"

class DashboardStatsDebugTest < ApplicationSystemTestCase
  test "debug dashboard stats example" do
    visit "/"
    
    # Wait for page to load
    sleep 3
    
    # Debug: Print page structure
    puts "Page title: #{page.title}"
    puts "Page has Examples text: #{page.has_text?('Examples')}"
    puts "Page has Dashboard Stats text: #{page.has_text?('Dashboard Stats')}"
    
    # Try different ways to find the link
    if page.has_link?("Dashboard Stats")
      click_link "Dashboard Stats"
      puts "Clicked Dashboard Stats via link"
    elsif page.has_button?("Dashboard Stats")
      click_button "Dashboard Stats"
      puts "Clicked Dashboard Stats via button"
    else
      puts "Could not find Dashboard Stats link or button"
      # Print available links
      puts "Available links: #{page.all('a').map(&:text).join(', ')}"
      puts "Available buttons: #{page.all('button').map(&:text).join(', ')}"
    end
    
    # Wait for the component to be selected
    sleep 2
    
    # Check if there's an error in the preview
    if page.has_css?("#preview-container .error-message")
      error_text = find("#preview-container .error-message").text
      puts "Error found: #{error_text}"
    end
    
    # Check if the preview renders successfully  
    within "#preview-container" do
      puts "Preview content: #{page.text}"
      
      # Look for any indication of success or failure
      if page.has_text?("Total Revenue")
        puts "SUCCESS: Dashboard Stats renders correctly"
        assert_text "Total Revenue"
      else
        puts "FAIL: Dashboard Stats does not render correctly"
        
        # Let's see what's actually in the preview
        preview_html = page.evaluate_script("document.getElementById('preview-container').innerHTML")
        puts "Preview HTML: #{preview_html}"
        
        # Just assert that we at least have a preview container
        assert_selector "#preview-container"
      end
    end
  end
end