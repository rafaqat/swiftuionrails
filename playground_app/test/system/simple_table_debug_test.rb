require "application_system_test_case"

class SimpleTableDebugTest < ApplicationSystemTestCase
  test "debug simple table example" do
    visit "/"
    sleep 2
    
    # Click on Simple Table (first match)
    first(:button, "Simple Table").click
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
    else
      puts "No error found"
    end
    
    # Check what's actually rendered
    within "#preview-container" do
      puts "Preview content: #{page.text}"
    end
  end
end