require "application_system_test_case"

class SimpleAuthTest < ApplicationSystemTestCase
  test "login page renders correctly" do
    visit new_session_path
    
    # Check basic structure
    assert page.has_content?("Welcome Back"), "Should have login title"
    assert page.has_selector?("form[action='/session']"), "Should have login form"
    assert page.has_selector?("input[name='email_address']"), "Should have email field"
    assert page.has_selector?("input[name='password']"), "Should have password field"
    assert page.has_selector?("button[type='submit']"), "Should have submit button"
    
    # Debug links specifically
    puts "\n=== CHECKING FOR LINKS ==="
    puts "Has forgot password href: #{page.has_selector?('a[href="/passwords/new"]')}"
    puts "Has sign up href: #{page.has_selector?('a[href="/registrations/new"]')}"
    puts "Has forgot password text: #{page.has_link?('Forgot your password?')}"
    puts "Has sign up text: #{page.has_link?('Sign up')}"
    
    # Show just the links section
    link_section = page.find('div.flex.items-center.justify-between', wait: 1)
    puts "Link section HTML: #{link_section.native.inner_html}"
    puts "=== END LINK DEBUG ==="
  end
end