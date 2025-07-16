require "application_system_test_case"

class TodoListTest < ApplicationSystemTestCase
  def setup
    if ENV['CI'] || ENV['HEADLESS']
      Capybara.current_driver = :selenium_chrome_headless
    end
    
    visit "/"
    sleep 2
  end

  test "todo list example renders without errors" do
    # Click on Todo List
    click_button "Todo List"
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
      
      flunk "Todo List has error: #{error_text}"
    end
    
    # Check expected content
    within "#preview-container" do
      assert_text "My Tasks", wait: 5
      assert_text "No tasks yet. Click + to add one!", wait: 5
      
      # Check that the hidden form exists with the placeholder text
      assert_selector "input[placeholder='What needs to be done?']", visible: false, wait: 5
    end
    
    puts "✅ Todo List example renders correctly"
  end
end