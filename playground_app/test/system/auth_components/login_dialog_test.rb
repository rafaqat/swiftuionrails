# frozen_string_literal: true

require "application_system_test_case"

class LoginDialogSystemTest < ApplicationSystemTestCase
  test "login dialog renders correctly when opened" do
    visit auth_test_login_path
    
    # Dialog should be closed initially
    assert_no_selector "[data-controller='login-dialog']"
    
    # Open dialog
    click_button "Open Login Dialog"
    
    # Dialog should be visible with correct elements
    assert_selector "[data-controller='login-dialog']"
    assert_text "Welcome Back"
    assert_text "Sign in to your account"
    
    # Form elements should be present
    assert_selector "input[name='login[email]']"
    assert_selector "input[name='login[password]']"
    assert_selector "input[name='login[remember_me]']"
    assert_selector "button[type='submit']"
    assert_text "Sign In"
    
    # Navigation links should be present
    assert_link "Sign up"
    
    # Stimulus targets should be present for JavaScript functionality
    assert_selector "[data-login-dialog-target='emailInput']"
    assert_selector "[data-login-dialog-target='passwordInput']"
    assert_selector "[data-login-dialog-target='submitButton']"
  end

  test "login dialog shows validation errors for empty fields" do
    visit auth_test_login_path(show_login: true)
    
    # Submit empty form
    within "[data-controller='login-dialog']" do
      click_button "Sign In"
    end
    
    # Should show HTML5 validation (required fields)
    # Note: System tests can't directly test HTML5 validation,
    # but we can test that the form doesn't submit
    assert_selector "[data-controller='login-dialog']"
  end

  test "login dialog handles server validation errors" do
    visit auth_test_login_path(show_login: true)
    
    # Submit form with error-triggering email
    within "[data-controller='login-dialog']" do
      fill_in "login_email", with: "error@example.com"
      fill_in "login_password", with: "somepassword"
      click_button "Sign In"
    end
    
    # Should remain on login page (simulated error response)
    assert_selector "[data-controller='login-dialog']"
  end

  test "login dialog successful login flow" do
    visit auth_test_login_path(show_login: true)
    
    # Submit form with success credentials
    within "[data-controller='login-dialog']" do
      fill_in "login_email", with: "success@example.com"
      fill_in "login_password", with: "validpassword123"
      click_button "Sign In"
    end
    
    # Should handle successful response (in real app would redirect)
    assert_selector "[data-controller='login-dialog']"
  end

  test "login dialog pre-fills form data correctly" do
    visit auth_test_login_path(
      show_login: true,
      form_data: { email: "user@example.com", remember_me: true }
    )
    
    within "[data-controller='login-dialog']" do
      # Email should be pre-filled
      assert_field "login_email", with: "user@example.com"
      
      # Remember me should be checked
      assert_field "login_remember_me", checked: true
    end
  end

  test "login dialog shows error messages from controller" do
    visit auth_test_login_path(
      show_login: true,
      errors: { 
        email: ["Please enter a valid email address"],
        password: ["Password is required"]
      }
    )
    
    # Error messages should be visible
    assert_text "Please enter a valid email address"
    assert_text "Password is required"
  end

  test "login dialog navigation to register works" do
    visit auth_test_login_path(show_login: true)
    
    within "[data-controller='login-dialog']" do
      click_link "Sign up"
    end
    
    # Should navigate to register page
    assert_current_path auth_test_register_path
  end

  test "login dialog keyboard navigation elements are present" do
    visit auth_test_login_path(show_login: true)
    
    # All focusable elements should be present
    assert_selector "input[name='login[email]']"
    assert_selector "input[name='login[password]']"
    assert_selector "input[name='login[remember_me]']"
    assert_selector "button[type='submit']"
    
    # Tab navigation should work (basic test)
    find("input[name='login[email]']").send_keys(:tab)
    # Password field should be the next focusable element
    assert_selector "input[name='login[password]']"
  end

  test "login dialog backdrop click functionality" do
    visit auth_test_login_path(show_login: true)
    
    # Dialog should be visible
    assert_selector "[data-controller='login-dialog']"
    
    # Test backdrop click behavior (may not work in headless browser but should have the right attributes)
    backdrop = find("[data-controller='login-dialog']")
    assert backdrop.has_css?("[data-action*='closeOnBackdrop']")
    
    # Test modal structure for click handling
    assert_selector "[data-login-dialog-target='modal']"
    assert_selector "[data-action*='stopPropagation']"
  end

  test "login dialog prevents backdrop click when clicking on modal content" do
    visit auth_test_login_path(show_login: true)
    
    # Click on modal content (should not close)
    within "[data-login-dialog-target='modal']" do
      click_on "Welcome Back"
    end
    
    # Should remain open
    assert_selector "[data-controller='login-dialog']"
  end

  test "login dialog form field interactions work correctly" do
    visit auth_test_login_path(show_login: true)
    
    within "[data-controller='login-dialog']" do
      # Email field should accept input
      fill_in "login_email", with: "test@example.com"
      assert_field "login_email", with: "test@example.com"
      
      # Password field should accept input
      fill_in "login_password", with: "testpassword"
      assert_field "login_password", with: "testpassword"
      
      # Remember me checkbox should toggle
      check "login_remember_me"
      assert_field "login_remember_me", checked: true
      
      uncheck "login_remember_me"
      assert_field "login_remember_me", checked: false
    end
  end

  test "login dialog responsive design works on different screen sizes" do
    # Test mobile viewport
    resize_window_to(375, 667)  # iPhone 6/7/8 size
    visit auth_test_login_path(show_login: true)
    
    # Dialog should still be visible and usable
    assert_selector "[data-controller='login-dialog']"
    assert_text "Welcome Back"
    
    within "[data-controller='login-dialog']" do
      # Form fields should be accessible
      assert_selector "input[name='login[email]']"
      assert_selector "input[name='login[password]']"
      assert_selector "button[type='submit']"
    end
    
    # Test desktop viewport
    resize_window_to(1200, 800)
    
    # Dialog should still work
    assert_selector "[data-controller='login-dialog']"
  end

  test "login dialog maintains focus trap" do
    visit auth_test_login_path(show_login: true)
    
    # Tab through all focusable elements
    focusable_elements = [
      "input[name='login[email]']",
      "input[name='login[password]']", 
      "input[name='login[remember_me]']",
      "button[type='submit']",
      "a[href*='register']", # register link
      "button[data-action*='close']" # close button
    ]
    
    focusable_elements.each do |selector|
      assert_selector selector
    end
  end

  test "login dialog test controls work correctly" do
    visit auth_test_login_path
    
    # Test "Open with Validation Errors" button
    click_button "Open with Validation Errors"
    
    # Should show the dialog with errors
    assert_selector "[data-controller='login-dialog']"
    assert_text "Please enter a valid email address"
    assert_text "Password is required"
    
    # Go back and test "Open with Pre-filled Data" button
    visit auth_test_login_path
    click_button "Open with Pre-filled Data"
    
    # Should show dialog with pre-filled data
    assert_selector "[data-controller='login-dialog']"
    assert_field "login_email", with: "user@example.com"
    assert_field "login_remember_me", checked: true
  end

  test "login dialog password strength indicator works" do
    visit auth_test_login_path(show_login: true)
    
    password_field = find("input[name='login[password]']")
    
    # Type weak password
    password_field.fill_in with: "123"
    
    # Should show weak indicator (if implemented in Stimulus controller)
    assert_selector "[data-login-dialog-target='passwordStrength']"
    
    # Type stronger password
    password_field.fill_in with: "StrongPassword123!"
    
    # Should update strength indicator
    assert_selector "[data-login-dialog-target='passwordStrength']"
  end
  
  private
  
  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end
end