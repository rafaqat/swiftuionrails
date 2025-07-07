# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Security
    # SECURITY: Validates component props to prevent security issues
    module ComponentValidator
      extend ActiveSupport::Concern

      # Common validation patterns
      VALID_VARIANTS = %w[primary secondary success danger warning info light dark].freeze
      VALID_SIZES = %w[xs sm md lg xl].freeze
      VALID_POSITIONS = %w[top bottom left right center].freeze
      VALID_ALIGNMENTS = %w[start center end stretch baseline].freeze

      included do
        # Add validation methods to components
        class_attribute :prop_validations, default: {}

        # Override prop setter to add validation
        class << self
          ##
          # Declares a component prop with optional validation rules.
          # Supports validation for inclusion, format, and range based on provided options.
          # Validation rules are stored for use during prop validation.
          def prop(name, type: String, required: false, default: nil, **options)
            # Extract validation options before passing to parent
            validate = options.delete(:validate)
            enum = options.delete(:enum)
            pattern = options.delete(:pattern)
            range = options.delete(:range)

            # Call parent with remaining options
            super(name, type: type, required: required, default: default)

            # Add validation if specified
            if validate
              prop_validations[name] = validate
            elsif enum
              prop_validations[name] = { inclusion: { in: enum } }
            elsif pattern
              prop_validations[name] = { format: { with: pattern } }
            elsif range
              prop_validations[name] = { inclusion: { in: range } }
            end
          end
        end
      end

      # Validation methods
      module ClassMethods
        ##
        # Adds a validation rule to ensure the specified prop value is included in the allowed variants.
        # @param [Symbol] prop_name The name of the prop to validate.
        # @param [Array] allowed The list of permitted variant values. Defaults to VALID_VARIANTS.
        def validates_variant(prop_name, allowed: VALID_VARIANTS)
          prop_validations[prop_name] = {
            inclusion: {
              in: allowed,
              message: "must be one of: #{allowed.join(', ')}"
            }
          }
        end

        ##
        # Adds a validation rule to ensure the specified prop value is included in the allowed list of sizes.
        # @param [Symbol] prop_name The name of the prop to validate.
        # @param [Array<String>] allowed The list of valid size values. Defaults to VALID_SIZES.
        def validates_size(prop_name, allowed: VALID_SIZES)
          prop_validations[prop_name] = {
            inclusion: {
              in: allowed,
              message: "must be one of: #{allowed.join(', ')}"
            }
          }
        end

        ##
        # Adds a validation rule to ensure the specified prop contains only alphanumeric characters and dashes, suitable for color names.
        # @param [Symbol, String] prop_name - The name of the prop to validate.
        def validates_color(prop_name)
          prop_validations[prop_name] = {
            format: {
              with: /\A[a-zA-Z0-9\-]+\z/,
              message: 'must be a valid color name'
            }
          }
        end

        ##
        # Adds numericality validation to a prop, enforcing optional minimum and maximum values.
        # @param [Symbol] prop_name The name of the prop to validate.
        # @param [Numeric, nil] min The minimum allowed value (inclusive), or nil for no minimum.
        # @param [Numeric, nil] max The maximum allowed value (inclusive), or nil for no maximum.
        def validates_number(prop_name, min: nil, max: nil)
          validations = {}
          validations[:numericality] = { greater_than_or_equal_to: min } if min
          validations[:numericality] ||= {}
          validations[:numericality][:less_than_or_equal_to] = max if max
          prop_validations[prop_name] = validations
        end

        ##
        # Adds a URL validation rule to the specified prop.
        # The prop will be validated to ensure its value is a valid HTTP or HTTPS URL.
        # @param [Symbol] prop_name The name of the prop to validate.
        # @param [Boolean] allow_blank Whether to allow blank values as valid (default: false).
        def validates_url(prop_name, allow_blank: false)
          prop_validations[prop_name] = {
            url: { allow_blank: allow_blank }
          }
        end

        ##
        # Adds a validation rule to ensure the specified prop contains a valid email address.
        # @param [Symbol] prop_name The name of the prop to validate.
        # @param [Boolean] allow_blank Whether to allow blank values as valid (default: false).
        def validates_email(prop_name, allow_blank: false)
          prop_validations[prop_name] = {
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: 'must be a valid email address',
              allow_blank: allow_blank
            }
          }
        end

        ##
        # Adds a validation rule to ensure the specified prop is callable, optionally allowing nil values.
        # @param [Symbol] prop_name - The name of the prop to validate.
        # @param [Boolean] allow_nil - Whether nil is accepted as a valid value (default: true).
        def validates_callable(prop_name, allow_nil: true)
          prop_validations[prop_name] = {
            callable: { allow_nil: allow_nil }
          }
        end
      end

      ##
      # Validates all component props against their defined validation rules.
      # Raises an ArgumentError with details if any validations fail.
      # @return [Boolean] true if all validations pass.
      def validate_props!
        return true if self.class.prop_validations.empty?

        errors = self.class.prop_validations.each_with_object([]) do |(prop_name, validations), error_list|
          value = send(prop_name)

          validations.each do |validation_type, options|
            case validation_type
            when :inclusion
              # Convert both the value and the allowed list to strings for comparison
              unless options[:in].map(&:to_s).include?(value.to_s)
                error_list << "#{prop_name} #{options[:message] || 'is not included in the list'}"
              end
            when :format
              error_list << "#{prop_name} #{options[:message] || 'is invalid'}" unless value.to_s.match?(options[:with])
            when :numericality
              if options[:greater_than_or_equal_to] && value < options[:greater_than_or_equal_to]
                error_list << "#{prop_name} must be greater than or equal to #{options[:greater_than_or_equal_to]}"
              end
              if options[:less_than_or_equal_to] && value > options[:less_than_or_equal_to]
                error_list << "#{prop_name} must be less than or equal to #{options[:less_than_or_equal_to]}"
              end
            when :url
              unless valid_url?(value, allow_blank: options[:allow_blank])
                error_list << "#{prop_name} must be a valid URL"
              end
            when :callable
              unless valid_callable?(value, allow_nil: options[:allow_nil])
                error_list << "#{prop_name} must be a callable (Proc or method)"
              end
            end
          end
        end

        raise ArgumentError, "Component validation failed: #{errors.join(', ')}" if errors.any?

        true
      end

      ##
      # Checks if the given URL is a valid HTTP or HTTPS URL.
      # Returns true if the URL is valid, or if blank URLs are allowed and the URL is blank.
      # @param [String] url - The URL to validate.
      # @param [Boolean] allow_blank - Whether to consider blank URLs as valid.
      # @return [Boolean] True if the URL is valid or blank (when allowed), false otherwise.
      def valid_url?(url, allow_blank: false)
        return true if allow_blank && url.blank?
        return false if url.blank?

        begin
          uri = URI.parse(url)
          uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        rescue URI::InvalidURIError
          false
        end
      end

      ##
      # Checks if the given value is callable, optionally allowing nil values.
      # @param value The value to check for callability.
      # @param allow_nil [Boolean] Whether to consider nil as valid (default: true).
      # @return [Boolean] True if the value is callable or nil (when allowed), false otherwise.
      def valid_callable?(value, allow_nil: true)
        return true if allow_nil && value.nil?

        value.respond_to?(:call)
      end

      ##
      # Sanitizes HTML content for safe rendering.
      # Uses Rails' sanitize helper if available; otherwise, falls back to basic HTML escaping.
      # @param content The HTML content to sanitize.
      # @return [String] The sanitized HTML string, or an empty string if input is nil.
      def sanitize_html(content)
        return '' if content.nil?

        # Use Rails' sanitize helper if available
        if respond_to?(:helpers) && helpers.respond_to?(:sanitize)
          helpers.sanitize(content)
        else
          # Basic HTML escaping
          ERB::Util.html_escape(content)
        end
      end

      ##
      # Sanitizes a CSS class name by removing all characters except alphanumeric, dash, underscore, and space.
      # @param [String, nil] class_name The CSS class name to sanitize.
      # @return [String] The sanitized CSS class name, or an empty string if input is nil.
      def sanitize_css_class(class_name)
        return '' if class_name.nil?

        # Remove any non-alphanumeric characters except dash, underscore, and space
        class_name.to_s.gsub(/[^a-zA-Z0-9\-_ ]/, '')
      end

      ##
      # Sanitizes an element ID by removing invalid characters and ensuring it starts with a letter.
      # Returns an empty string if the input is nil.
      # @param [String, nil] id - The input ID to sanitize.
      # @return [String] The sanitized ID, safe for use in HTML elements.
      def sanitize_id(id)
        return '' if id.nil?

        # IDs should start with letter and contain only alphanumeric, dash, underscore
        id = id.to_s.gsub(/[^a-zA-Z0-9\-_]/, '')
        id = "id-#{id}" unless id.match?(/^[a-zA-Z]/)
        id
      end
    end
  end
end
# Copyright 2025
