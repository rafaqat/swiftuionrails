require "application_system_test_case"

class PricingCardsErrorTest < ApplicationSystemTestCase
  test "check for errors in pricing cards" do
    visit "/"
    
    # Wait for page to load
    sleep 2
    
    # Click on Pricing Cards
    click_button "Pricing Cards"
    
    # Wait for the component to be selected
    sleep 2
    
    # Check if there's an error in the preview
    if page.has_css?("#preview-container .playground-error")
      error_detail = find("#preview-container .playground-error")
      puts "Error found in preview:"
      puts error_detail.text
      
      # Try to click the "View backtrace" link if it exists
      if error_detail.has_css?("details summary")
        error_detail.find("details summary").click
        sleep 1
        if error_detail.has_css?("details pre")
          puts "Backtrace:"
          puts error_detail.find("details pre").text
        end
      end
    else
      puts "No error found in preview"
    end
    
    # Check the actual HTML structure
    html = page.evaluate_script("document.getElementById('preview-container').innerHTML")
    puts "Preview HTML structure:"
    puts html
  end
end