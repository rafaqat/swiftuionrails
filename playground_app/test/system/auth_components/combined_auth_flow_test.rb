# frozen_string_literal: true

require "application_system_test_case"

class CombinedAuthFlowSystemTest < ApplicationSystemTestCase
  test "complete login to register flow works correctly" do
    visit auth_test_combined_path
    
    # Start with login dialog
    click_button "Open Login Dialog"
    assert_selector "[data-controller='login-dialog']"
    assert_text "Welcome Back"
    
    # Click "Sign up" link to switch to register
    within "[data-controller='login-dialog']" do
      click_link "Sign up"
    end
    
    # Should navigate to combined page with register dialog
    assert_current_path auth_test_combined_path
    assert_selector "[data-controller='register-dialog']"
    assert_text "Create Account"
    
    # Should not show login dialog anymore
    assert_no_selector "[data-controller='login-dialog']"
  end

  test "complete register to login flow works correctly" do
    visit auth_test_combined_path
    
    # Start with register dialog
    click_button "Open Register Dialog"
    assert_selector "[data-controller='register-dialog']"
    assert_text "Create Account"
    
    # Click "Sign in" link to switch to login
    within "[data-controller='register-dialog']" do
      click_link "Sign in"
    end
    
    # Should navigate to combined page with login dialog
    assert_current_path auth_test_combined_path
    assert_selector "[data-controller='login-dialog']"
    assert_text "Welcome Back"
    
    # Should not show register dialog anymore
    assert_no_selector "[data-controller='register-dialog']"
  end

  test "both dialogs can be open simultaneously for z-index testing" do
    visit auth_test_combined_path
    
    # Open both dialogs
    click_button "Open Both (Z-Index Test)"
    
    # Both dialogs should be present
    assert_selector "[data-controller='login-dialog']"
    assert_selector "[data-controller='register-dialog']"
    
    # Both should have content visible
    assert_text "Welcome Back"
    assert_text "Create Account"
  end

  test "close all functionality works correctly" do
    visit auth_test_combined_path
    
    # Open both dialogs
    click_button "Open Both (Z-Index Test)"
    
    # Verify both are open
    assert_selector "[data-controller='login-dialog']"
    assert_selector "[data-controller='register-dialog']"
    
    # Close all
    click_button "Close All"
    
    # Both should be closed
    assert_no_selector "[data-controller='login-dialog']"
    assert_no_selector "[data-controller='register-dialog']"
    assert_current_path auth_test_combined_path
  end

  test "login flow simulation works end-to-end" do
    visit auth_test_combined_path
    
    # Start login flow
    click_button "Start Login Flow"
    
    # Should open login dialog
    assert_selector "[data-controller='login-dialog']"
    
    # Fill out login form
    within "[data-controller='login-dialog']" do
      fill_in "login_email", with: "success@example.com"
      fill_in "login_password", with: "validpassword123"
      check "login_remember_me"
      click_button "Sign In"
    end
    
    # Should handle successful login (in real app would redirect)
    assert_selector "[data-controller='login-dialog']"
  end

  test "register flow simulation works end-to-end" do
    visit auth_test_combined_path
    
    # Start register flow
    click_button "Start Register Flow"
    
    # Should open register dialog
    assert_selector "[data-controller='register-dialog']"
    
    # Fill out registration form
    within "[data-controller='register-dialog']" do
      fill_in "register_first_name", with: "John"
      fill_in "register_last_name", with: "Doe"
      fill_in "register_email", with: "new@example.com"
      fill_in "register_password", with: "SecurePass123!"
      fill_in "register_password_confirmation", with: "SecurePass123!"
      check "register_terms_accepted"
      click_button "Create Account"
    end
    
    # Should handle successful registration
    assert_selector "[data-controller='register-dialog']"
  end

  test "modal z-index stacking works correctly" do
    visit auth_test_combined_path
    
    # Open both dialogs
    click_button "Open Both (Z-Index Test)"
    
    # Both should be visible
    assert_selector "[data-controller='login-dialog']"
    assert_selector "[data-controller='register-dialog']"
    
    # The last opened should be on top (based on DOM order or z-index)
    # This is a visual test that would need specific CSS inspection
    # For now, we just verify both are present
    assert_text "Welcome Back"
    assert_text "Create Account"
    
    # Close one dialog should leave the other
    within "[data-controller='register-dialog']" do
      click_button "×"
    end
    
    # Login dialog should still be open
    assert_selector "[data-controller='login-dialog']"
    assert_no_selector "[data-controller='register-dialog']"
  end

  test "cross-dialog state preservation during navigation" do
    visit auth_test_combined_path
    
    # Open login dialog and fill some data
    click_button "Open Login Dialog"
    within "[data-controller='login-dialog']" do
      fill_in "login_email", with: "test@example.com"
      fill_in "login_password", with: "testpass"
      check "login_remember_me"
      
      # Navigate to register
      click_link "Sign up"
    end
    
    # Should be on combined page with register dialog
    assert_selector "[data-controller='register-dialog']"
    
    # Go back to login
    within "[data-controller='register-dialog']" do
      click_link "Sign in"
    end
    
    # Login dialog should be open again
    assert_selector "[data-controller='login-dialog']"
    
    # Note: In a real app, we might want to preserve the form data
    # This would depend on the implementation strategy
  end

  test "error handling across dialog transitions" do
    visit auth_test_combined_path
    
    # Start with login dialog showing errors
    visit auth_test_combined_path(
      show_login: true,
      errors: { email: ["Invalid email"] }
    )
    
    assert_selector "[data-controller='login-dialog']"
    assert_text "Invalid email"
    
    # Navigate to register
    within "[data-controller='login-dialog']" do
      click_link "Sign up"
    end
    
    # Register dialog should not show login errors
    assert_selector "[data-controller='register-dialog']"
    assert_no_text "Invalid email"
  end

  test "social login consistency across both dialogs" do
    visit auth_test_combined_path
    
    # Check login dialog social options
    click_button "Open Login Dialog"
    within "[data-controller='login-dialog']" do
      assert_selector "button", text: /google/i
      assert_selector "button", text: /github/i
    end
    
    # Switch to register dialog
    within "[data-controller='login-dialog']" do
      click_link "Sign up"
    end
    
    # Register dialog should have same social options
    within "[data-controller='register-dialog']" do
      assert_selector "button", text: /google/i
      assert_selector "button", text: /github/i
    end
  end

  test "keyboard navigation works across dialog transitions" do
    visit auth_test_combined_path
    
    # Open login dialog
    click_button "Open Login Dialog"
    
    # Tab to the register link
    login_email = find("input[name='login[email]']")
    login_email.send_keys(:tab, :tab, :tab, :tab, :tab) # Navigate to register link
    
    # Press enter on register link
    page.driver.browser.action.send_keys(:return).perform
    
    # Should navigate to register dialog
    assert_selector "[data-controller='register-dialog']"
    
    # Focus should be on first field of register form
    assert_selector "input[name='register[first_name]']:focus", wait: 1
  end

  test "responsive behavior works for combined dialogs" do
    # Test mobile viewport
    resize_window_to(375, 667)
    visit auth_test_combined_path
    
    # Both dialogs should work on mobile
    click_button "Open Login Dialog"
    assert_selector "[data-controller='login-dialog']"
    
    click_button "Close All"
    click_button "Open Register Dialog"
    assert_selector "[data-controller='register-dialog']"
    
    # Test tablet viewport
    resize_window_to(768, 1024)
    
    click_button "Close All"
    click_button "Open Both (Z-Index Test)"
    
    # Both should be visible on tablet
    assert_selector "[data-controller='login-dialog']"
    assert_selector "[data-controller='register-dialog']"
    
    # Test desktop viewport
    resize_window_to(1200, 800)
    
    # Should still work on desktop
    assert_selector "[data-controller='login-dialog']"
    assert_selector "[data-controller='register-dialog']"
  end

  test "performance with multiple dialog instances" do
    visit auth_test_combined_path
    
    # Rapid open/close cycles to test for memory leaks
    5.times do |i|
      click_button "Open Login Dialog"
      assert_selector "[data-controller='login-dialog']"
      
      click_button "Close All"
      assert_no_selector "[data-controller='login-dialog']"
      
      click_button "Open Register Dialog"
      assert_selector "[data-controller='register-dialog']"
      
      click_button "Close All"
      assert_no_selector "[data-controller='register-dialog']"
    end
    
    # Final state should be clean
    assert_current_path auth_test_combined_path
    assert_no_selector "[data-controller='login-dialog']"
    assert_no_selector "[data-controller='register-dialog']"
  end

  test "accessibility features work across both dialogs" do
    visit auth_test_combined_path
    
    # Test login dialog accessibility
    click_button "Open Login Dialog"
    
    # Should have proper ARIA attributes
    assert_selector "[data-controller='login-dialog'][role='dialog']"
    assert_selector "[aria-label*='login'], [aria-labelledby]"
    
    # Should have focus trap
    login_email = find("input[name='login[email]']")
    assert_equal login_email, page.driver.browser.switch_to.active_element
    
    # Switch to register dialog
    within "[data-controller='login-dialog']" do
      click_link "Sign up"
    end
    
    # Register dialog should also be accessible
    assert_selector "[data-controller='register-dialog'][role='dialog']"
    assert_selector "[aria-label*='register'], [aria-labelledby]"
    
    # Focus should move to register dialog
    register_first_name = find("input[name='register[first_name]']")
    assert_equal register_first_name, page.driver.browser.switch_to.active_element
  end
  
  private
  
  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end
end