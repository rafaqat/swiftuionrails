require "application_system_test_case"

class SimpleTableTest < ApplicationSystemTestCase
  def setup
    if ENV['CI'] || ENV['HEADLESS']
      Capybara.current_driver = :selenium_chrome_headless
    end
    
    visit "/"
    sleep 2
  end

  test "simple table example renders without errors" do
    # Wait for page to load completely
    sleep 3
    
    # Find all Simple Table buttons and click the last one (should be examples section)
    buttons = all(:button, "Simple Table")
    puts "Found #{buttons.length} Simple Table buttons"
    
    # Click the last one (examples section)
    buttons.last.click
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
      
      flunk "Simple Table has error: #{error_text}"
    end
    
    # Check expected content
    within "#preview-container" do
      assert_text "Simple Table Example", wait: 5
      
      # Debug: Check what's actually rendered
      page_content = page.text
      puts "Page content: #{page_content}"
      
      # Let's check if the table HTML elements are present
      if page.has_css?("table")
        puts "✅ Table element found"
        
        if page.has_css?("th")
          puts "✅ Table headers found"
          th_elements = all("th")
          puts "Found #{th_elements.length} table headers: #{th_elements.map(&:text).join(', ')}"
        else
          puts "❌ No table headers found"
        end
        
        if page.has_css?("td")
          puts "✅ Table data cells found"
          td_elements = all("td")
          puts "Found #{td_elements.length} table data cells: #{td_elements.map(&:text).join(', ')}"
        else
          puts "❌ No table data cells found"
        end
        
        # Let's also check the HTML structure
        table_html = find("table")[:outerHTML]
        puts "Table HTML: #{table_html}"
        
      else
        puts "❌ No table element found"
      end
      
      # Check for basic table content
      assert_text "Name", wait: 5
      assert_text "Role", wait: 5
      assert_text "Email", wait: 5
      assert_text "Status", wait: 5
      assert_text "John Doe", wait: 5
    end
    
    puts "✅ Simple Table example renders correctly"
  end
end