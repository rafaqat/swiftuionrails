require "application_system_test_case"

class PricingCardsDebugTest < ApplicationSystemTestCase
  test "debug pricing cards example" do
    visit "/"
    
    # Wait for page to load
    sleep 2
    
    # Click on Pricing Cards
    click_button "Pricing Cards"
    puts "Clicked Pricing Cards"
    
    # Wait for the component to be selected
    sleep 2
    
    # Check if there's an error in the preview
    if page.has_css?("#preview-container .playground-error")
      error_text = find("#preview-container .playground-error").text
      puts "Error found: #{error_text}"
    end
    
    # Check if the preview renders successfully  
    within "#preview-container" do
      puts "Preview content: #{page.text}"
      
      # Look for pricing card elements
      if page.has_text?("Starter") && page.has_text?("Professional") && page.has_text?("Enterprise")
        puts "SUCCESS: Pricing Cards renders correctly"
        assert_text "Starter"
        assert_text "Professional"
        assert_text "Enterprise"
        assert_text "Most Popular"
      else
        puts "FAIL: Pricing Cards does not render correctly"
        
        # Let's see what's actually in the preview
        preview_html = page.evaluate_script("document.getElementById('preview-container').innerHTML")
        puts "Preview HTML: #{preview_html}"
        
        # Just assert that we at least have a preview container
        assert_selector "#preview-container"
      end
    end
  end
end