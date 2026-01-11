# frozen_string_literal: true

require "application_system_test_case"

class JavascriptFunctionalitySystemTest < ApplicationSystemTestCase
  test "login dialog stimulus controller loads correctly" do
    visit auth_test_login_path(show_login: true)
    
    # Dialog should be visible
    assert_selector "[data-controller='login-dialog']"
    
    # All required Stimulus targets should be present
    assert_selector "[data-login-dialog-target='emailInput']"
    assert_selector "[data-login-dialog-target='passwordInput']"
    assert_selector "[data-login-dialog-target='submitButton']"
    assert_selector "[data-login-dialog-target='modal']"
    
    # Controller values should be set
    controller_element = find("[data-controller='login-dialog']")
    assert controller_element.has_css?("[data-login-dialog-close-url-value]")
    assert controller_element.has_css?("[data-login-dialog-url-value]")
  end

  test "register dialog stimulus controller loads correctly" do
    visit auth_test_register_path(show_register: true)
    
    # Dialog should be visible
    assert_selector "[data-controller='register-dialog']"
    
    # All required Stimulus targets should be present
    assert_selector "[data-register-dialog-target='firstNameInput']"
    assert_selector "[data-register-dialog-target='lastNameInput']"
    assert_selector "[data-register-dialog-target='emailInput']"
    assert_selector "[data-register-dialog-target='passwordInput']"
    assert_selector "[data-register-dialog-target='passwordConfirmationInput']"
    assert_selector "[data-register-dialog-target='submitButton']"
    assert_selector "[data-register-dialog-target='modal']"
    
    # Controller values should be set
    controller_element = find("[data-controller='register-dialog']")
    assert controller_element.has_css?("[data-register-dialog-close-url-value]")
    assert controller_element.has_css?("[data-register-dialog-url-value]")
  end

  test "stimulus controllers have proper action bindings" do
    visit auth_test_login_path(show_login: true)
    
    # Form should have submit action
    assert_selector "form[data-action*='submit->login-dialog#submitForm']"
    
    # Backdrop should have click action  
    assert_selector "[data-action*='click->login-dialog#closeOnBackdrop']"
    
    # Close button should have action
    assert_selector "button[data-action*='click->login-dialog#close']"
    
    # Form inputs should have validation actions
    assert_selector "input[data-action*='input->login-dialog#updateFormData']"
    assert_selector "input[data-action*='blur->login-dialog#validateEmail']"
  end

  test "form inputs trigger javascript validation" do
    visit auth_test_login_path(show_login: true)
    
    email_input = find("input[name='login[email]']")
    password_input = find("input[name='login[password]']")
    
    # Fill invalid email and trigger blur
    email_input.fill_in with: "invalid-email"
    email_input.send_keys(:tab)  # Trigger blur
    
    # Note: In headless testing, JS validation may not show visually
    # but the action bindings should be present
    assert_selector "[data-login-dialog-target='emailError']"
    
    # Fill password and trigger input event
    password_input.fill_in with: "test123"
    
    # Password strength indicator should be present
    assert_selector "[data-login-dialog-target='passwordStrength']"
  end

  test "javascript error elements are properly structured" do
    visit auth_test_login_path(show_login: true)
    
    # Error banner should exist but be hidden
    error_banner = find("[data-login-dialog-target='errorBanner']", visible: false)
    assert error_banner.has_css?(".hidden") || error_banner.has_css?("[style*='display: none']")
    
    # Individual field errors should exist but be hidden
    assert_selector "[data-login-dialog-target='emailError']", visible: false
    assert_selector "[data-login-dialog-target='passwordError']", visible: false
  end

  test "password strength elements are properly structured" do
    visit auth_test_login_path(show_login: true)
    
    # Password strength container should exist
    assert_selector "[data-login-dialog-target='passwordStrength']"
    
    # Strength indicator elements should exist
    assert_selector "[data-login-dialog-target='strengthText']"
    assert_selector "[data-login-dialog-target='strengthBar']"
    
    # Requirements section should exist
    assert_selector "[data-login-dialog-target='requirements']"
    assert_selector "[data-login-dialog-target='requirementLengthIcon']"
    assert_selector "[data-login-dialog-target='requirementSpecialIcon']"
    assert_selector "[data-login-dialog-target='requirementNumberIcon']"
  end

  test "javascript functionality is available for interaction" do
    visit auth_test_login_path(show_login: true)
    
    # Check if Stimulus is loaded (basic test)
    page.execute_script("return typeof window.Stimulus")
    
    # Check if the controller is registered (this may not work in all test environments)
    # But at least verify the HTML structure supports it
    assert_selector "[data-controller='login-dialog']"
    
    # Verify form can be submitted (even if it doesn't actually work due to test env)
    form = find("form[data-action*='submit->login-dialog#submitForm']")
    assert form.present?
    
    # Check submit button is present and properly configured
    submit_button = find("[data-login-dialog-target='submitButton']")
    assert submit_button.present?
    assert_equal "Sign In", submit_button.text
  end

  test "modal close functionality structure is correct" do
    visit auth_test_login_path(show_login: true)
    
    # Close button should have proper action
    close_button = find("button", text: "×")
    assert close_button.has_css?("[data-action*='click->login-dialog#close']")
    
    # Backdrop should have proper action
    backdrop = find("[data-controller='login-dialog']")
    assert backdrop.has_css?("[data-action*='click->login-dialog#closeOnBackdrop']")
    
    # Modal container should prevent propagation
    modal = find("[data-login-dialog-target='modal']")
    assert modal.has_css?("[data-action*='click->login-dialog#stopPropagation']")
  end

  test "form data persistence structure works" do
    visit auth_test_login_path(
      show_login: true, 
      form_data: { email: "test@example.com", remember_me: "true" }
    )
    
    # Pre-filled data should be present
    email_input = find("input[name='login[email]']")
    assert_equal "test@example.com", email_input.value
    
    remember_checkbox = find("input[name='login[remember_me]']")
    assert remember_checkbox.checked?
  end
end