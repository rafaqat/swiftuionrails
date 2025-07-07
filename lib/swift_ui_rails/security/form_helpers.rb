# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Security
    # SECURITY: Secure form helpers for CSRF protection
    module FormHelpers
      extend ActiveSupport::Concern

      included do
        # Ensure we have access to Rails form helpers
        helper_method :render_csrf_protection, :csrf_meta_tags_dsl if respond_to?(:helper_method)
      end

      # SECURITY: Render CSRF protection token field
      ##
      # Returns a hidden input element containing the CSRF token for form protection.
      # Returns an empty string if CSRF protection is not enabled.
      def render_csrf_protection
        return '' unless protect_against_forgery?

        # Get the token and parameter name from Rails
        token = get_form_authenticity_token
        param = request_forgery_protection_token

        # Return a hidden input element
        create_element(:input, nil,
                       type: 'hidden',
                       name: param.to_s,
                       value: token,
                       autocomplete: 'off')
      end

      ##
      # Generates CSRF meta tags for inclusion in HTML, enabling AJAX requests to access CSRF protection tokens.
      # @return [Array] An array containing meta tag elements for the CSRF parameter name and token, or an empty array if CSRF protection is disabled.
      def csrf_meta_tags_dsl
        return [] unless protect_against_forgery?

        [
          create_element(:meta, nil,
                         name: 'csrf-param',
                         content: request_forgery_protection_token.to_s),
          create_element(:meta, nil,
                         name: 'csrf-token',
                         content: get_form_authenticity_token)
        ]
      end

      ##
      # Builds a secure HTML form element with automatic CSRF protection and method override handling.
      # For non-GET requests, includes a hidden CSRF token input if protection is enabled.
      # Adds a hidden `_method` input for HTTP verbs PUT, PATCH, or DELETE, and a UTF-8 enforcer input for compatibility.
      # The form's content is provided by the given block.
      # @param action [String] The form submission URL.
      # @param method [String] The HTTP method to use (default: 'POST').
      # @param attrs [Hash] Additional HTML attributes for the form element.
      # @yield Block that generates the form's inner content.
      # @return [Object] The constructed form element with all children.
      def secure_form(action:, method: 'POST', **attrs, &block)
        # Ensure method is uppercase
        method = method.to_s.upcase

        # Build form attributes
        attrs[:action] = action
        attrs[:method] = method == 'GET' ? 'GET' : 'POST'
        attrs[:accept_charset] ||= 'UTF-8'

        # Add data-turbo attributes if not disabled
        unless attrs.delete(:turbo) == false
          attrs[:data] ||= {}
          attrs[:data][:turbo] = 'true' unless attrs[:data].key?(:turbo)
        end

        # Create the form element
        create_element(:form, nil, **attrs) do
          elements = []

          # Add CSRF token for non-GET requests
          elements << render_csrf_protection if method != 'GET' && protect_against_forgery?

          # Add method override for non-POST/GET methods
          if %w[PUT PATCH DELETE].include?(method)
            elements << create_element(:input, nil,
                                       type: 'hidden',
                                       name: '_method',
                                       value: method.downcase,
                                       autocomplete: 'off')
          end

          # Add UTF-8 enforcer for older browsers
          elements << create_element(:input, nil,
                                     type: 'hidden',
                                     name: 'utf8',
                                     value: '✓',
                                     autocomplete: 'off')

          # Add the block content
          if block
            block_content = instance_eval(&block)
            if block_content.is_a?(Array)
              elements.concat(block_content)
            else
              elements << block_content
            end
          end

          elements
        end
      end

      ##
      # Determines whether CSRF (Cross-Site Request Forgery) protection is enabled in the current Rails application.
      # @return [Boolean] true if forgery protection is enabled, false otherwise.
      def protect_against_forgery?
        if defined?(ActionController::Base) && defined?(Rails)
          # Check if forgery protection is configured and enabled
          Rails.application.config.action_controller.allow_forgery_protection != false
        else
          false
        end
      end

      ##
      # Returns the name of the CSRF token parameter used for form authenticity verification.
      # Defaults to :authenticity_token if not defined by ActionController::Base.
      # @return [Symbol] The CSRF parameter name.
      def request_forgery_protection_token
        if defined?(ActionController::Base)
          ActionController::Base.request_forgery_protection_token || :authenticity_token
        else
          :authenticity_token
        end
      end

      # SECURITY: Get the current CSRF token
      ##
      # Retrieves the CSRF authenticity token using available Rails contexts and fallbacks.
      # Attempts to obtain the token from the current context, view context, helpers, or controller.
      # Returns an empty string if the token cannot be generated.
      # @param [Hash] form_options Options to pass to the token generation method.
      # @return [String] The CSRF authenticity token, or an empty string if unavailable.
      def get_form_authenticity_token(form_options: {})
        # Try to use Rails' built-in method if available
        return form_authenticity_token(form_options) if respond_to?(:form_authenticity_token)

        # In view context, delegate to the view's form_authenticity_token
        if defined?(@_view_context) && @_view_context.respond_to?(:form_authenticity_token)
          return @_view_context.form_authenticity_token(form_options)
        end

        # Try helpers
        if respond_to?(:helpers) && helpers.respond_to?(:form_authenticity_token)
          return helpers.form_authenticity_token(form_options: form_options)
        end

        # If we're in a view/template context, try to get the token from there
        if respond_to?(:controller) && controller.respond_to?(:form_authenticity_token)
          return controller.form_authenticity_token(form_options)
        end

        # If all else fails, return empty string
        Rails.logger.warn "Unable to generate CSRF token in #{self.class.name}"
        ''
      end
    end
  end
end
# Copyright 2025
