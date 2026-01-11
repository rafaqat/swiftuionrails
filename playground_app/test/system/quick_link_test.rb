require "application_system_test_case"

class QuickLinkTest < ApplicationSystemTestCase
  test "login page has links and fields" do
    visit new_session_path
    
    # Check for form fields using different selectors
    assert page.has_selector?('input[name="email_address"]'), "Should have email field by name"
    assert page.has_selector?('input[type="email"]'), "Should have email field by type"
    assert page.has_selector?('input[name="password"]'), "Should have password field by name"
    assert page.has_selector?('input[type="password"]'), "Should have password field by type"
    
    # Check for submit button
    assert page.has_selector?('button[type="submit"]'), "Should have submit button"
    
    # Check for links
    assert page.has_selector?('a[href="/passwords/new"]'), "Should have forgot password link"
    assert page.has_selector?('a[href="/registrations/new"]'), "Should have sign up link"
    
    # Check link text
    assert page.has_link?("Forgot your password?"), "Should have forgot password link text"
    assert page.has_link?("Sign up"), "Should have sign up link text"
  end
end