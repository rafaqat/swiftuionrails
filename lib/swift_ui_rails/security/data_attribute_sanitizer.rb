# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Security
    # SECURITY: Sanitizes data attributes to prevent XSS attacks
    module DataAttributeSanitizer
      extend ActiveSupport::Concern

      # List of allowed data attribute prefixes
      ALLOWED_DATA_PREFIXES = %w[
        action
        controller
        target
        value
        id
        index
        url
        method
        confirm
        turbo
        stimulus
      ].freeze

      # List of potentially dangerous values that should be escaped
      DANGEROUS_PATTERNS = [
        /javascript:/i,
        %r{data:text/html}i,
        /vbscript:/i,
        /onload=/i,
        /onerror=/i,
        /onclick=/i,
        /onmouse/i,
        /<script/i,
        /<iframe/i,
        /<object/i,
        /<embed/i,
        /document\./i,
        /window\./i,
        /eval\(/i,
        /setTimeout/i,
        /setInterval/i
      ].freeze

      class << self
        # SECURITY: Sanitize a single data attribute
        def sanitize_data_attribute(key, value)
          # Ensure key is safe
          safe_key = sanitize_data_key(key)

          # Special handling for Stimulus actions
          safe_value = if key.to_s == 'action' || safe_key == 'data-action'
                         sanitize_stimulus_action(value)
                       else
                         sanitize_data_value(value)
                       end

          [safe_key, safe_value]
        end

        # SECURITY: Sanitize a hash of data attributes
        def sanitize_data_attributes(attributes)
          return {} unless attributes.is_a?(Hash)

          sanitized = {}
          attributes.each do |key, value|
            safe_key, safe_value = sanitize_data_attribute(key, value)
            sanitized[safe_key] = safe_value
          end

          sanitized
        end

        # SECURITY: Create safe data attributes for common patterns
        def safe_data_attributes(options = {})
          attrs = {}

          # Stimulus action
          attrs['data-action'] = sanitize_stimulus_action(options[:action]) if options[:action]

          # Stimulus controller
          attrs['data-controller'] = sanitize_stimulus_controller(options[:controller]) if options[:controller]

          # Stimulus target
          attrs["data-#{options[:controller]}-target"] = sanitize_stimulus_target(options[:target]) if options[:target]

          # Stimulus values
          if options[:values].is_a?(Hash)
            options[:values].each do |key, value|
              controller = options[:controller] || 'component'
              attrs["data-#{controller}-#{key.to_s.dasherize}-value"] = sanitize_value(value)
            end
          end

          # Generic data attributes
          if options[:data].is_a?(Hash)
            options[:data].each do |key, value|
              safe_key = "data-#{key.to_s.dasherize}"
              attrs[safe_key] = sanitize_value(value)
            end
          end

          attrs
        end

        private

        # Sanitize data attribute keys
        def sanitize_data_key(key)
          # Convert to string and dasherize
          key_str = key.to_s.dasherize

          # Remove data- prefix if present (we'll add it back)
          key_str = key_str.gsub(/^data-/, '')

          # Only allow alphanumeric, dash, and underscore
          key_str = key_str.gsub(/[^a-zA-Z0-9\-_]/, '')

          # Ensure it starts with a letter
          key_str = "x-#{key_str}" unless key_str.match?(/^[a-zA-Z]/)

          "data-#{key_str}"
        end

        # Sanitize data attribute values
        def sanitize_data_value(value)
          return '' if value.nil?

          # Convert to string
          value_str = value.to_s

          # Check for dangerous patterns
          DANGEROUS_PATTERNS.each do |pattern|
            next unless value_str.match?(pattern)

            # Log potential XSS attempt
            Rails.logger.warn "Potential XSS attempt blocked in data attribute: #{value_str}"
            return ''
          end

          # HTML escape the value
          ERB::Util.html_escape(value_str)
        end

        # Sanitize Stimulus action strings
        def sanitize_stimulus_action(action)
          return '' unless action

          # Stimulus actions should be in format: event->controller#method
          parts = action.to_s.split('->')
          return '' unless parts.length == 2

          event_part = parts[0].strip
          controller_method = parts[1].strip

          # Validate event
          allowed_events = %w[
            click dblclick mousedown mouseup mouseover mouseout mousemove
            keydown keyup keypress
            submit change input focus blur
            load unload resize scroll
            touchstart touchend touchmove
            dragstart dragend drop
          ]

          return '' unless allowed_events.include?(event_part)

          # Validate controller#method
          return '' unless controller_method.match?(/\A[a-zA-Z][a-zA-Z0-9\-_]*#[a-zA-Z][a-zA-Z0-9_]*\z/)

          "#{event_part}->#{controller_method}"
        end

        # Sanitize Stimulus controller names
        def sanitize_stimulus_controller(controller)
          return '' unless controller

          # Controller names should be alphanumeric with dashes
          controller.to_s.gsub(/[^a-zA-Z0-9\-_]/, '')
        end

        # Sanitize Stimulus target names
        def sanitize_stimulus_target(target)
          return '' unless target

          # Target names should be alphanumeric with underscores
          target.to_s.gsub(/[^a-zA-Z0-9_]/, '')
        end

        # Sanitize generic values based on type
        def sanitize_value(value)
          case value
          when Integer, Float
            value.to_s
          when TrueClass, FalseClass
            value.to_s
          when Symbol
            value.to_s.gsub(/[^a-zA-Z0-9\-_]/, '')
          when String
            sanitize_data_value(value)
          when Array
            # Convert to JSON and escape
            ERB::Util.html_escape(value.to_json)
          when Hash
            # Convert to JSON and escape
            ERB::Util.html_escape(value.to_json)
          else
            # Unknown type - convert to string and escape
            ERB::Util.html_escape(value.to_s)
          end
        end
      end
    end
  end
end
# Copyright 2025
