# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Security
    # SECURITY: Content Security Policy helpers for SwiftUI Rails applications
    module ContentSecurityPolicy
      extend ActiveSupport::Concern

      included do
        # Apply CSP to all actions by default if enabled
        before_action :set_content_security_policy if SwiftUIRails.configuration.content_security_policy_enabled
      end

      private

      ##
      # Sets the Content Security Policy (CSP) headers for the current response based on application configuration.
      #
      # Applies a restrictive CSP by default, allowing only approved sources for scripts, styles, images, fonts, and connections.
      # In development, also sets a report-only CSP header for monitoring violations.
      # Skips setting the policy if CSP is disabled or relaxed for the current request.
      def set_content_security_policy
        return unless SwiftUIRails.configuration.content_security_policy_enabled
        return if @csp_relaxed

        # Get approved domains from configuration
        approved_domains = SwiftUIRails.configuration.approved_image_domains.to_a

        # Build CSP header
        policy = []

        # Default source - self only
        policy << "default-src 'self'"

        # Script source - self and inline for Stimulus
        policy << "script-src 'self' 'unsafe-inline'"

        # Style source - self and inline for Tailwind
        policy << "style-src 'self' 'unsafe-inline'"

        # Image source - self and approved domains
        img_sources = ["'self'"] + approved_domains.map { |d| "https://#{d}" }
        policy << "img-src #{img_sources.join(' ')}"

        # Font source
        policy << "font-src 'self' data:"

        # Connect source for AJAX/fetch
        policy << "connect-src 'self'"

        # Frame ancestors - prevent clickjacking
        policy << "frame-ancestors 'none'"

        # Base URI
        policy << "base-uri 'self'"

        # Form action
        policy << "form-action 'self'"

        # Upgrade insecure requests
        policy << 'upgrade-insecure-requests' if request.ssl?

        # Set the header
        response.set_header('Content-Security-Policy', policy.join('; '))

        # Also set report-only header for monitoring
        return unless Rails.env.development?

        response.set_header('Content-Security-Policy-Report-Only', policy.join('; '))
      end

      # Helper method to temporarily relax CSP for specific actions
      def relax_content_security_policy
        @csp_relaxed = true
      end

      # Helper method to check if CSP should be relaxed
      def should_set_content_security_policy?
        !@csp_relaxed
      end

      module ClassMethods
        # Class-level method to skip CSP for specific actions
        def skip_content_security_policy(options = {})
          skip_before_action :set_content_security_policy, options
        end

        ##
        # Defines a before_action that applies a custom Content Security Policy for specified controller actions.
        # Executes the provided block in the controller instance context to allow per-action CSP customization.
        # @param [Hash] options - Options to control which actions the policy applies to (e.g., :only, :except).
        def content_security_policy(options = {}, &block)
          before_action(options) do
            instance_eval(&block) if block
          end
        end
      end
    end

    # Rails CSP DSL support
    class PolicyBuilder
      attr_reader :directives

      def initialize
        @directives = {}
      end

      def default_src(*sources)
        @directives['default-src'] = sources.join(' ')
      end

      def script_src(*sources)
        @directives['script-src'] = sources.join(' ')
      end

      def style_src(*sources)
        @directives['style-src'] = sources.join(' ')
      end

      def img_src(*sources)
        @directives['img-src'] = sources.join(' ')
      end

      def font_src(*sources)
        @directives['font-src'] = sources.join(' ')
      end

      def connect_src(*sources)
        @directives['connect-src'] = sources.join(' ')
      end

      def frame_src(*sources)
        @directives['frame-src'] = sources.join(' ')
      end

      def frame_ancestors(*sources)
        @directives['frame-ancestors'] = sources.join(' ')
      end

      def base_uri(*sources)
        @directives['base-uri'] = sources.join(' ')
      end

      def form_action(*sources)
        @directives['form-action'] = sources.join(' ')
      end

      def upgrade_insecure_requests
        @directives['upgrade-insecure-requests'] = true
      end

      def to_header
        @directives.map do |directive, value|
          if value == true
            directive
          else
            "#{directive} #{value}"
          end
        end.join('; ')
      end
    end
  end
end
# Copyright 2025
