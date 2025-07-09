# frozen_string_literal: true

# Copyright 2025

SwiftUIRails.configure do |config|
  # Default animation duration in milliseconds
  config.default_transition_duration = 300

  # Default animation easing function
  config.default_animation_easing = 'ease-out'

  # Component class prefix (e.g., "Swift" would make "SwiftButtonComponent")
  config.component_prefix = ''

  # Enable Tailwind CSS integration
  config.tailwind_enabled = true

  # Stimulus controller suffix
  config.stimulus_controller_suffix = 'component'
end
# Copyright 2025
