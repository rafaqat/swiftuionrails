# frozen_string_literal: true

# Copyright 2025

require_relative 'swift_ui_rails/version'
require_relative 'swift_ui_rails/engine'
require_relative 'swift_ui_rails/tailwind'
require_relative 'swift_ui_rails/dsl'
require_relative 'swift_ui_rails/component'
require_relative 'swift_ui_rails/helpers'
require_relative 'swift_ui_rails/storybook'

# Playground module
require_relative 'swift_ui_rails/playground/executor'

# Require security modules
module SwiftUIRails
  module Security
    # Autoload security modules
  end
end

require_relative 'swift_ui_rails/security/content_security_policy'
require_relative 'swift_ui_rails/security/rate_limiter'
require_relative 'swift_ui_rails/dev_tools/error_boundary' if Rails.env.local?
require_relative 'swift_ui_rails/dev_tools/component_tree_debugger' if Rails.env.local?
require_relative 'swift_ui_rails/dev_tools/debug_helpers' if Rails.env.local?

module SwiftUIRails
  class Error < StandardError; end
  class SecurityError < Error; end

  class << self
    # rubocop:disable ThreadSafety/ClassAndModuleAttributes
    # This is a standard Rails pattern for gem configuration that is set once at boot time
    attr_accessor :configuration
    # rubocop:enable ThreadSafety/ClassAndModuleAttributes
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :default_transition_duration, :default_animation_easing, :component_prefix, :tailwind_enabled,
                  :stimulus_controller_suffix, :allowed_components, :content_security_policy_enabled, :maximum_component_depth, :approved_image_domains, :rate_limit_actions, :rate_limit_threshold, :rate_limit_window

    def initialize
      @default_transition_duration = 300
      @default_animation_easing = 'ease-out'
      @component_prefix = ''
      @tailwind_enabled = true
      @stimulus_controller_suffix = 'component'

      # SECURITY: Content Security Policy
      @content_security_policy_enabled = true
      @maximum_component_depth = 50 # Prevent stack overflow attacks

      # SECURITY: Approved domains for external resources
      @approved_image_domains = Set.new([
                                          'picsum.photos',
                                          'via.placeholder.com',
                                          'placehold.co',
                                          'placeholder.com',
                                          'cdn.jsdelivr.net',
                                          'unpkg.com',
                                          'cdnjs.cloudflare.com',
                                          'images.unsplash.com',
                                          'i.imgur.com',
                                          'gravatar.com',
                                          'tailwindui.com',
                                          'tailwindcss.com'
                                        ])

      # SECURITY: Rate limiting for action handlers
      @rate_limit_actions = true
      @rate_limit_threshold = 10 # Max actions per window
      @rate_limit_window = 60 # Window in seconds

      # SECURITY: Whitelist of allowed components to prevent RCE
      # Components must be explicitly added to this list
      @allowed_components = Set.new([
                                      'Button',
                                      'Card',
                                      'Modal',
                                      'Counter',
                                      'ProductCard',
                                      'ProductList',
                                      'AuthForm',
                                      'EnhancedLogin',
                                      'EnhancedRegister',
                                      'AuthError',
                                      'AuthLayout',
                                      'Text',
                                      'Image',
                                      'List',
                                      'ListItem',
                                      'ScrollView',
                                      'VStack',
                                      'HStack',
                                      'ZStack',
                                      'Grid',
                                      'Divider',
                                      'Spacer',
                                      'SimpleButton'
                                      # Add new components here after security review
                                    ])
    end

    # Helper method to check if a component is allowed
    def component_allowed?(component_name)
      allowed_components.include?(component_name.to_s)
    end

    # Add approved domain at runtime
    def add_approved_domain(domain)
      return false if domain.blank?

      # Validate domain format
      unless domain.match?(/\A[a-z0-9\-\.]+\z/i)
        Rails.logger.warn "Invalid domain format: #{domain}"
        return false
      end

      @approved_image_domains << domain.downcase
      true
    end

    # Check if domain is approved
    def domain_approved?(domain)
      return false if domain.nil?

      domain_lower = domain.downcase
      @approved_image_domains.any? do |approved|
        domain_lower == approved || domain_lower.end_with?(".#{approved}")
      end
    end
  end
end
# Copyright 2025
