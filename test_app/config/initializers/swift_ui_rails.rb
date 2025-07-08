# frozen_string_literal: true

# Copyright 2025

SwiftUIRails.configure do |config|
  # Security Settings

  # Enable Content Security Policy
  config.content_security_policy_enabled = true

  # Maximum component nesting depth to prevent stack overflow attacks
  config.maximum_component_depth = 50

  # Rate limiting for action handlers
  config.rate_limit_actions = true
  config.rate_limit_threshold = 30  # Max 30 actions
  config.rate_limit_window = 60     # Per 60 seconds

  # Add custom approved domains for your application
  # config.add_approved_domain('cdn.myapp.com')
  # config.add_approved_domain('assets.myapp.com')

  # Component Settings

  # Default animation duration in milliseconds
  config.default_transition_duration = 300

  # Default animation easing function
  config.default_animation_easing = "ease-out"

  # Component class prefix (e.g., "Swift" would make "SwiftButtonComponent")
  config.component_prefix = ""

  # Enable Tailwind CSS integration
  config.tailwind_enabled = true

  # Stimulus controller suffix
  config.stimulus_controller_suffix = "component"
end

# Rate limiting middleware will be configured in config/application.rb or environment files
# to ensure Rails.cache is properly initialized
# Copyright 2025
