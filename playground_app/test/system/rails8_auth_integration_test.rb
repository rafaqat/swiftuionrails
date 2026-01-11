require "application_system_test_case"

class Rails8AuthIntegrationTest < ApplicationSystemTestCase
  setup do
    # Clean up any existing test users
    User.where(email_address: ['test@example.com', 'newuser@example.com']).destroy_all
  end
  
  test "can access login page with SwiftUI Rails component" do
    visit new_session_path
    
    # Check that the SwiftUI Rails component rendered correctly
    assert_text "Welcome Back"
    assert_field "Email address"
    assert_field "Password"
    assert_button "Sign In"
    assert_link "Sign up"
    assert_link "Forgot your password?"
  end
  
  test "can access registration page with SwiftUI Rails component" do
    visit new_registration_path
    
    # Check that the SwiftUI Rails component rendered correctly
    assert_text "Create Account"
    assert_field "Email address"
    assert_field "Password"
    assert_field "Confirm Password"
    assert_button "Create Account"
    assert_link "Sign in"
    assert_text "Minimum 8 characters"
  end
  
  test "can successfully register a new user through SwiftUI Rails component" do
    visit new_registration_path
    
    fill_in "Email address", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm Password", with: "password123"
    
    click_button "Create Account"
    
    # Should redirect to root after successful registration
    assert_current_path root_path
    
    # User should be created in database
    user = User.find_by(email_address: "newuser@example.com")
    assert user.present?
    assert user.authenticate("password123")
  end
  
  test "displays validation errors for invalid registration" do
    # Create a user first to test uniqueness validation
    User.create!(email_address: "existing@example.com", password: "password123", password_confirmation: "password123")
    
    visit new_registration_path
    
    fill_in "Email address", with: "existing@example.com"  # Email already exists - will fail uniqueness validation
    fill_in "Password", with: "password123"  # Valid password
    fill_in "Confirm Password", with: "different456"  # Different confirmation - will fail confirmation validation
    
    click_button "Create Account"
    
    # Wait for form submission and re-render
    assert_no_text "Loading..." # Wait for any potential loading states
    
    # Should show validation errors (URL can be either /registrations or /registrations/new)
    assert_text "Email address has already been taken", wait: 5
    assert_text "Password confirmation doesn't match Password", wait: 5
    
    # Verify we're still on a registration-related page
    assert [registrations_path, new_registration_path].include?(current_path),
           "Expected to be on registration page, but was on #{current_path}"
  end
  
  test "can successfully login through SwiftUI Rails component" do
    # Create a test user
    User.create!(
      email_address: "test@example.com", 
      password: "password123", 
      password_confirmation: "password123"
    )
    
    visit new_session_path
    
    fill_in "Email address", with: "test@example.com"
    fill_in "Password", with: "password123"
    
    click_button "Sign In"
    
    # Should redirect to root after successful login
    assert_current_path root_path
  end
  
  test "displays error for invalid login credentials" do
    visit new_session_path
    
    fill_in "Email address", with: "nonexistent@example.com"
    fill_in "Password", with: "wrongpassword"
    
    click_button "Sign In"
    
    # Should redirect back to login with error
    assert_current_path new_session_path
    assert_text "Try another email address or password"
  end
  
  test "form styling is applied correctly through Tailwind DSL" do
    visit new_session_path
    
    # Check that Tailwind classes are applied (SwiftUI Rails DSL generates these)
    email_field = find_field("Email address")
    assert email_field[:class].include?("border-gray-300"), "Email field should have border-gray-300 class"
    assert email_field[:class].include?("focus:border-blue-500"), "Email field should have focus:border-blue-500 class"
    
    submit_button = find_button("Sign In")
    assert submit_button[:class].include?("bg-blue-600"), "Submit button should have bg-blue-600 class"
    assert submit_button[:class].include?("hover:bg-blue-700"), "Submit button should have hover:bg-blue-700 class"
  end
  
  test "links between login and registration work correctly" do
    visit new_session_path
    assert_text "Welcome Back"
    
    click_link "Sign up"
    assert_current_path new_registration_path
    assert_text "Create Account"
    
    click_link "Sign in"
    assert_current_path new_session_path
    assert_text "Welcome Back"
  end
end