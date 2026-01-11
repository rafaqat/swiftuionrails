require "application_system_test_case"

class DebugDialogComponentTest < ApplicationSystemTestCase
  test "auth_test page shows expected content for debugging" do
    expected_url = auth_test_login_path(show_login: true)
    puts "=== DEBUG: Expected URL ==="
    puts expected_url
    
    visit expected_url
    
    puts "=== DEBUG: URL visited ==="
    puts current_url
    
    puts "=== DEBUG: Page title ==="
    puts page.title
    
    puts "=== DEBUG: Page HTML (first 1000 chars) ==="
    puts page.html[0..1000]
    
    puts "=== DEBUG: Looking for data-controller attributes ==="
    page.all("[data-controller]").each do |element|
      puts "Found data-controller: #{element['data-controller']}"
    end
    
    puts "=== DEBUG: Looking for dialog-related elements ==="
    if page.has_css?("[data-controller='login-dialog']", wait: 1)
      puts "Found login-dialog controller"
    else
      puts "No login-dialog controller found"
    end
    
    puts "=== DEBUG: All input fields ==="
    page.all("input").each do |input|
      puts "Input: name=#{input['name']}, type=#{input['type']}, id=#{input['id']}"
    end
    
    puts "=== DEBUG: All forms ==="
    page.all("form").each do |form|
      puts "Form: action=#{form['action']}, method=#{form['method']}"
    end
    
    # This will always pass - we're just debugging
    assert true
  end
end