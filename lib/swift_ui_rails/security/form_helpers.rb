# frozen_string_literal: true

module SwiftUIRails
  module Security
    # SECURITY: Secure form helpers for CSRF protection
    module FormHelpers
      extend ActiveSupport::Concern
      
      included do
        # Ensure we have access to Rails form helpers
        if respond_to?(:helper_method)
          helper_method :render_csrf_protection, :csrf_meta_tags_dsl
        end
      end
      
      # SECURITY: Render CSRF protection token field
      # Uses Rails' built-in helpers to ensure proper CSRF protection
      def render_csrf_protection
        return "" unless protect_against_forgery?
        
        # Get the token and parameter name from Rails
        token = form_authenticity_token
        param = request_forgery_protection_token
        
        # Return a hidden input element
        create_element(:input, nil,
          type: "hidden",
          name: param.to_s,
          value: token,
          autocomplete: "off"
        )
      end
      
      # SECURITY: Render CSRF meta tags for AJAX requests
      def csrf_meta_tags_dsl
        return [] unless protect_against_forgery?
        
        [
          create_element(:meta, nil,
            name: "csrf-param",
            content: request_forgery_protection_token.to_s
          ),
          create_element(:meta, nil,
            name: "csrf-token", 
            content: form_authenticity_token
          )
        ]
      end
      
      # SECURITY: Create a secure form with automatic CSRF protection
      def secure_form(action:, method: "POST", **attrs, &block)
        # Ensure method is uppercase
        method = method.to_s.upcase
        
        # Build form attributes
        attrs[:action] = action
        attrs[:method] = method == "GET" ? "GET" : "POST"
        attrs[:accept_charset] ||= "UTF-8"
        
        # Add data-turbo attributes if not disabled
        unless attrs.delete(:turbo) == false
          attrs[:data] ||= {}
          attrs[:data][:turbo] = "true" unless attrs[:data].key?(:turbo)
        end
        
        # Create the form element
        create_element(:form, nil, **attrs) do
          elements = []
          
          # Add CSRF token for non-GET requests
          if method != "GET" && protect_against_forgery?
            elements << render_csrf_protection
          end
          
          # Add method override for non-POST/GET methods
          if %w[PUT PATCH DELETE].include?(method)
            elements << create_element(:input, nil,
              type: "hidden",
              name: "_method",
              value: method.downcase,
              autocomplete: "off"
            )
          end
          
          # Add UTF-8 enforcer for older browsers
          elements << create_element(:input, nil,
            type: "hidden",
            name: "utf8",
            value: "✓",
            autocomplete: "off"
          )
          
          # Add the block content
          if block_given?
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
      
      # SECURITY: Check if forgery protection is enabled
      def protect_against_forgery?
        if defined?(ActionController::Base)
          ActionController::Base.protect_against_forgery? &&
            !Rails.application.config.action_controller.allow_forgery_protection.nil? &&
            Rails.application.config.action_controller.allow_forgery_protection
        else
          false
        end
      end
      
      # SECURITY: Get the CSRF token parameter name
      def request_forgery_protection_token
        if defined?(ActionController::Base)
          ActionController::Base.request_forgery_protection_token || :authenticity_token
        else
          :authenticity_token
        end
      end
      
      # SECURITY: Get the current CSRF token
      def form_authenticity_token(form_options: {})
        if respond_to?(:helpers) && helpers.respond_to?(:form_authenticity_token)
          helpers.form_authenticity_token(form_options: form_options)
        elsif defined?(ActionController::Base) && respond_to?(:session)
          # Generate token using Rails internals
          masked_authenticity_token(session, form_options: form_options)
        else
          # Fallback - should not happen in normal Rails apps
          SecureRandom.base64(32)
        end
      end
      
      private
      
      # Generate a masked authenticity token (Rails internal)
      def masked_authenticity_token(session, form_options: {})
        # This would use Rails' internal token generation
        # For now, we'll rely on the helpers being available
        raise "Cannot generate CSRF token without Rails helpers"
      end
    end
  end
end
# Copyright 2025
