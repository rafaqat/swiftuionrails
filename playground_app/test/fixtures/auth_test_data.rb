# frozen_string_literal: true

# Test data fixtures for auth component testing
module AuthTestData
  # Valid user data for successful tests
  VALID_USER = {
    first_name: "John",
    last_name: "Doe",
    email: "user@example.com",
    password: "validpassword123",
    password_confirmation: "validpassword123",
    remember_me: false,
    terms_accepted: true
  }.freeze

  # User data that triggers validation errors
  INVALID_USER = {
    first_name: "",
    last_name: "",
    email: "invalid-email",
    password: "123",
    password_confirmation: "456",
    remember_me: false,
    terms_accepted: false
  }.freeze

  # Pre-filled form data for testing
  PREFILLED_LOGIN = {
    email: "prefilled@example.com",
    password: "",
    remember_me: true
  }.freeze

  PREFILLED_REGISTER = {
    first_name: "Jane",
    last_name: "Smith",
    email: "jane.smith@example.com",
    password: "",
    password_confirmation: "",
    remember_me: false,
    terms_accepted: false
  }.freeze

  # Special test emails that trigger specific responses
  SUCCESS_EMAIL = "success@example.com"
  ERROR_EMAIL = "error@example.com"
  EXISTING_EMAIL = "existing@example.com"
  NETWORK_ERROR_EMAIL = "network@example.com"
  SERVER_ERROR_EMAIL = "server@example.com"

  # Password strength test cases
  WEAK_PASSWORDS = [
    "123",
    "password",
    "abc123",
    "qwerty"
  ].freeze

  MEDIUM_PASSWORDS = [
    "password123",
    "mypassword1",
    "test12345"
  ].freeze

  STRONG_PASSWORDS = [
    "SecurePass123!",
    "MyStr0ng&Password",
    "C0mplex!P@ssw0rd"
  ].freeze

  # Common validation error messages
  VALIDATION_ERRORS = {
    first_name_required: "First name is required",
    last_name_required: "Last name is required",
    email_required: "Email is required",
    email_invalid: "Please enter a valid email address",
    email_taken: "Email is already taken",
    password_required: "Password is required",
    password_too_short: "Password must be at least 8 characters",
    password_mismatch: "Passwords do not match",
    terms_required: "You must accept the terms of service"
  }.freeze

  # Social login providers for testing
  SOCIAL_PROVIDERS = %w[google github facebook twitter].freeze

  # Test scenarios for comprehensive coverage
  TEST_SCENARIOS = {
    # Login scenarios
    login_empty_form: {
      data: { email: "", password: "" },
      expected_errors: [:email_required, :password_required]
    },
    login_invalid_email: {
      data: { email: "invalid", password: "validpassword123" },
      expected_errors: [:email_invalid]
    },
    login_success: {
      data: { email: SUCCESS_EMAIL, password: "validpassword123" },
      expected_result: :success
    },
    login_error: {
      data: { email: ERROR_EMAIL, password: "wrongpassword" },
      expected_errors: [:invalid_credentials]
    },

    # Register scenarios
    register_empty_form: {
      data: {
        first_name: "", last_name: "", email: "", 
        password: "", password_confirmation: "", terms_accepted: false
      },
      expected_errors: [
        :first_name_required, :last_name_required, :email_required,
        :password_required, :terms_required
      ]
    },
    register_password_mismatch: {
      data: {
        first_name: "John", last_name: "Doe", email: "test@example.com",
        password: "password123", password_confirmation: "differentpassword",
        terms_accepted: true
      },
      expected_errors: [:password_mismatch]
    },
    register_existing_email: {
      data: {
        first_name: "John", last_name: "Doe", email: EXISTING_EMAIL,
        password: "validpassword123", password_confirmation: "validpassword123",
        terms_accepted: true
      },
      expected_errors: [:email_taken]
    },
    register_success: {
      data: {
        first_name: "John", last_name: "Doe", email: "new@example.com",
        password: "SecurePass123!", password_confirmation: "SecurePass123!",
        terms_accepted: true
      },
      expected_result: :success
    }
  }.freeze

  # Device sizes for responsive testing
  DEVICE_SIZES = {
    mobile: { width: 375, height: 667 },     # iPhone 6/7/8
    tablet: { width: 768, height: 1024 },    # iPad
    desktop: { width: 1200, height: 800 },   # Desktop
    large: { width: 1920, height: 1080 }     # Large desktop
  }.freeze

  # Accessibility test requirements
  ACCESSIBILITY_REQUIREMENTS = {
    aria_labels: %w[
      aria-label aria-labelledby aria-describedby
      role tabindex aria-hidden aria-expanded
    ],
    keyboard_navigation: {
      tab: :tab,
      shift_tab: [:shift, :tab],
      enter: :return,
      escape: :escape,
      space: :space
    },
    focus_indicators: %w[
      focus:ring focus:outline focus:border
      focus-visible:ring focus-visible:outline
    ]
  }.freeze

  # Performance benchmarks
  PERFORMANCE_BENCHMARKS = {
    modal_open_time: 200,      # milliseconds
    form_submission_time: 500, # milliseconds
    component_render_time: 100, # milliseconds
    memory_usage_limit: 50     # MB
  }.freeze

  # Security test cases
  SECURITY_TESTS = {
    xss_payloads: [
      "<script>alert('xss')</script>",
      "javascript:alert('xss')",
      "<img src=x onerror=alert('xss')>",
      "'; DROP TABLE users; --"
    ],
    csrf_scenarios: [
      :missing_token,
      :invalid_token,
      :expired_token
    ],
    injection_attempts: [
      "' OR '1'='1",
      "'; DROP TABLE users; --",
      "<script>document.location='http://evil.com'</script>"
    ]
  }.freeze
end