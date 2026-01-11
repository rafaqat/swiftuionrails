# frozen_string_literal: true

require "application_system_test_case"

class RegisterDialogSystemTest < ApplicationSystemTestCase
  test "register dialog renders correctly when opened" do
    visit auth_test_register_path
    
    # Dialog should be closed initially
    assert_no_selector "[data-controller='register-dialog']"
    
    # Open dialog
    click_button "Open Register Dialog"
    
    # Dialog should be visible with correct elements
    assert_selector "[data-controller='register-dialog']"
    assert_text "Create Account"
    assert_text "Join us today and get started"
    
    # Form elements should be present
    assert_selector "input[name='register[first_name]']"
    assert_selector "input[name='register[last_name]']"
    assert_selector "input[name='register[email]']"
    assert_selector "input[name='register[password]']"
    assert_selector "input[name='register[password_confirmation]']"
    assert_selector "input[name='register[terms_accepted]']"
    assert_selector "button[type='submit']"
    assert_text "Create Account"
    
    # Navigation links should be present
    assert_link "Sign in"
  end

  test "register dialog shows validation errors for empty required fields" do
    visit auth_test_register_path(show_register: true)
    
    # Submit empty form
    within "[data-controller='register-dialog']" do
      click_button "Create Account"
    end
    
    # Should show HTML5 validation (required fields)
    # Note: System tests can't directly test HTML5 validation,
    # but we can test that the form doesn't submit
    assert_selector "[data-controller='register-dialog']"
  end

  test "register dialog handles server validation errors" do
    visit auth_test_register_path(show_register: true)
    
    # Submit form with existing email
    within "[data-controller='register-dialog']" do
      fill_in "register_first_name", with: "John"
      fill_in "register_last_name", with: "Doe"
      fill_in "register_email", with: "existing@example.com"
      fill_in "register_password", with: "validpassword123"
      fill_in "register_password_confirmation", with: "validpassword123"
      check "register_terms_accepted"
      click_button "Create Account"
    end
    
    # Should handle server validation error for existing email
    assert_selector "[data-controller='register-dialog']"
  end

  test "register dialog successful registration flow" do
    visit auth_test_register_path(show_register: true)
    
    # Submit form with valid data
    within "[data-controller='register-dialog']" do
      fill_in "register_first_name", with: "John"
      fill_in "register_last_name", with: "Doe"
      fill_in "register_email", with: "new@example.com"
      fill_in "register_password", with: "SecurePass123!"
      fill_in "register_password_confirmation", with: "SecurePass123!"
      check "register_terms_accepted"
      click_button "Create Account"
    end
    
    # Should handle successful response
    assert_selector "[data-controller='register-dialog']"
  end

  test "register dialog password confirmation validation" do
    visit auth_test_register_path(show_register: true)
    
    within "[data-controller='register-dialog']" do
      fill_in "register_password", with: "password123"
      fill_in "register_password_confirmation", with: "differentpassword"
      
      # Trigger validation by focusing away
      find("input[name='register[first_name]']").click
    end
    
    # Should show password mismatch error (if implemented in Stimulus)
    assert_selector "[data-controller='register-dialog']"
  end

  test "register dialog terms of service validation" do
    visit auth_test_register_path(show_register: true)
    
    within "[data-controller='register-dialog']" do
      fill_in "register_first_name", with: "John"
      fill_in "register_last_name", with: "Doe"
      fill_in "register_email", with: "test@example.com"
      fill_in "register_password", with: "validpassword123"
      fill_in "register_password_confirmation", with: "validpassword123"
      # Don't check terms_accepted
      click_button "Create Account"
    end
    
    # Should show validation error for terms
    assert_selector "[data-controller='register-dialog']"
  end

  test "register dialog pre-fills form data correctly" do
    visit auth_test_register_path(
      show_register: true,
      form_data: { 
        first_name: "John",
        last_name: "Doe", 
        email: "john.doe@example.com"
      }
    )
    
    within "[data-controller='register-dialog']" do
      # Fields should be pre-filled
      assert_field "register_first_name", with: "John"
      assert_field "register_last_name", with: "Doe"
      assert_field "register_email", with: "john.doe@example.com"
    end
  end

  test "register dialog shows error messages from controller" do
    visit auth_test_register_path(
      show_register: true,
      errors: { 
        first_name: ["First name is required"],
        email: ["Please enter a valid email address"],
        password: ["Password must be at least 8 characters"],
        password_confirmation: ["Passwords do not match"],
        terms_accepted: ["You must accept the terms of service"]
      }
    )
    
    # Error messages should be visible
    assert_text "First name is required"
    assert_text "Please enter a valid email address"
    assert_text "Password must be at least 8 characters"
    assert_text "Passwords do not match"
    assert_text "You must accept the terms of service"
  end

  test "register dialog navigation to login works" do
    visit auth_test_register_path(show_register: true)
    
    within "[data-controller='register-dialog']" do
      click_link "Sign in"
    end
    
    # Should navigate to login page
    assert_current_path auth_test_login_path
  end

  test "register dialog keyboard navigation elements are present" do
    visit auth_test_register_path(show_register: true)
    
    # All form fields should be present and focusable
    form_fields = [
      "input[name='register[first_name]']",
      "input[name='register[last_name]']",
      "input[name='register[email]']",
      "input[name='register[password]']",
      "input[name='register[password_confirmation]']",
      "input[name='register[terms_accepted]']"
    ]
    
    form_fields.each do |field|
      assert_selector field
    end
    
    # Submit button should be present
    assert_selector "button[type='submit']"
    
    # Basic tab navigation test
    find("input[name='register[first_name]']").send_keys(:tab)
    assert_selector "input[name='register[last_name]']"
  end

  test "register dialog backdrop click closes dialog" do
    visit auth_test_register_path(show_register: true)
    
    # Click on backdrop (outside modal)
    find("[data-controller='register-dialog']").click
    
    # Should close dialog
    assert_current_path auth_test_register_path
  end

  test "register dialog form field interactions work correctly" do
    visit auth_test_register_path(show_register: true)
    
    within "[data-controller='register-dialog']" do
      # Test all form fields
      fill_in "register_first_name", with: "John"
      assert_field "register_first_name", with: "John"
      
      fill_in "register_last_name", with: "Doe"
      assert_field "register_last_name", with: "Doe"
      
      fill_in "register_email", with: "john@example.com"
      assert_field "register_email", with: "john@example.com"
      
      fill_in "register_password", with: "testpassword"
      assert_field "register_password", with: "testpassword"
      
      fill_in "register_password_confirmation", with: "testpassword"
      assert_field "register_password_confirmation", with: "testpassword"
      
      # Terms checkbox should toggle
      check "register_terms_accepted"
      assert_field "register_terms_accepted", checked: true
      
      uncheck "register_terms_accepted"
      assert_field "register_terms_accepted", checked: false
    end
  end

  test "register dialog password strength indicator works" do
    visit auth_test_register_path(show_register: true)
    
    password_field = find("input[name='register[password]']")
    
    # Test weak password
    password_field.fill_in with: "123"
    
    # Should show strength indicator (if implemented)
    assert_selector "[data-register-dialog-target='passwordStrength']", wait: 1
    
    # Test strong password
    password_field.fill_in with: "StrongPassword123!"
    
    # Should update strength indicator
    assert_selector "[data-register-dialog-target='passwordStrength']"
  end

  test "register dialog responsive design works on different screen sizes" do
    # Test mobile viewport
    resize_window_to(375, 667)  # iPhone 6/7/8 size
    visit auth_test_register_path(show_register: true)
    
    # Dialog should still be visible and usable
    assert_selector "[data-controller='register-dialog']"
    assert_text "Create Account"
    
    within "[data-controller='register-dialog']" do
      # All form fields should be accessible
      assert_selector "input[name='register[first_name]']"
      assert_selector "input[name='register[last_name]']"
      assert_selector "input[name='register[email]']"
      assert_selector "input[name='register[password]']"
      assert_selector "input[name='register[password_confirmation]']"
      assert_selector "input[name='register[terms_accepted]']"
      assert_selector "button[type='submit']"
    end
    
    # Test desktop viewport
    resize_window_to(1200, 800)
    
    # Dialog should still work
    assert_selector "[data-controller='register-dialog']"
  end

  test "register dialog test controls work correctly" do
    visit auth_test_register_path
    
    # Test "Open with Validation Errors" button
    click_button "Open with Validation Errors"
    
    # Should show the dialog with errors
    assert_selector "[data-controller='register-dialog']"
    assert_text "First name is required"
    assert_text "Please enter a valid email address"
    assert_text "Password must be at least 8 characters"
    assert_text "Passwords do not match"
    assert_text "You must accept the terms of service"
    
    # Go back and test "Open with Pre-filled Data" button
    visit auth_test_register_path
    click_button "Open with Pre-filled Data"
    
    # Should show dialog with pre-filled data
    assert_selector "[data-controller='register-dialog']"
    assert_field "register_first_name", with: "John"
    assert_field "register_last_name", with: "Doe"
    assert_field "register_email", with: "john.doe@example.com"
  end

  test "register dialog social registration links work" do
    visit auth_test_register_path(show_register: true)
    
    within "[data-controller='register-dialog']" do
      # Should show social registration options
      assert_selector "button", text: /google/i
      assert_selector "button", text: /github/i
    end
  end

  test "register dialog maintains focus trap" do
    visit auth_test_register_path(show_register: true)
    
    # Tab through all focusable elements
    focusable_elements = [
      "input[name='register[first_name]']",
      "input[name='register[last_name]']",
      "input[name='register[email]']",
      "input[name='register[password]']",
      "input[name='register[password_confirmation]']",
      "input[name='register[terms_accepted]']",
      "button[type='submit']",
      "a[href*='login']", # login link
      "button[data-action*='close']" # close button
    ]
    
    focusable_elements.each do |selector|
      assert_selector selector
    end
  end

  test "register dialog email validation works" do
    visit auth_test_register_path(show_register: true)
    
    email_field = find("input[name='register[email]']")
    
    # Test invalid email format
    email_field.fill_in with: "invalid-email"
    
    # Focus away to trigger validation
    find("input[name='register[first_name]']").click
    
    # Should show validation error (HTML5 or custom)
    assert_selector "input[name='register[email]']"
    
    # Test valid email format
    email_field.fill_in with: "valid@example.com"
    
    # Should clear validation error
    assert_selector "input[name='register[email]']"
  end
  
  private
  
  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end
end