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
        # Use class instance variable instead of class_attribute to ensure complete isolation
        # This prevents any inheritance or sharing between classes
        @prop_validations = {}

        # Define accessor methods at the class level
        class << self
          attr_accessor :prop_validations
        end
      end

      # Ensure each component class gets its own isolated prop_validations
      def self.included(base)
        super
        base.instance_eval do
          # Create a fresh hash for each class using class instance variable
          @prop_validations = {}
        end

        # Also ensure that subclasses get their own prop_validations
        base.singleton_class.prepend(Module.new do
          def inherited(subclass)
            super
            subclass.instance_eval do
              @prop_validations = {}
            end
          end
        end)
      end

      # Validation methods
      module ClassMethods
        # Define common prop validations
        def validates_variant(prop_name, allowed: VALID_VARIANTS)
          # Initialize if needed (for dynamically created classes)
          @prop_validations ||= {}
          prop_validations[prop_name] = {
            inclusion: {
              in: allowed,
              message: "must be one of: #{allowed.join(', ')}"
            }
          }
        end

        def validates_size(prop_name, allowed: VALID_SIZES)
          @prop_validations ||= {}
          prop_validations[prop_name] = {
            inclusion: {
              in: allowed,
              message: "must be one of: #{allowed.join(', ')}"
            }
          }
        end

        def validates_color(prop_name)
          @prop_validations ||= {}

          prop_validations[prop_name] = {
            format: {
              with: /\A[a-zA-Z0-9\-]+\z/,
              message: 'must be a valid color name'
            }
          }
        end

        def validates_inclusion(prop_name, options = {})
          @prop_validations ||= {}

          allowed_values = options[:in] || []
          allow_blank = options[:allow_blank] || false

          prop_validations[prop_name] = {
            inclusion: {
              in: allowed_values,
              message: "must be one of: #{allowed_values.join(', ')}",
              allow_blank: allow_blank
            }
          }
        end

        def validates_number(prop_name, min: nil, max: nil)
          @prop_validations ||= {}

          validations = {}
          validations[:numericality] = { greater_than_or_equal_to: min } if min
          validations[:numericality] ||= {}
          validations[:numericality][:less_than_or_equal_to] = max if max
          prop_validations[prop_name] = validations
        end

        def validates_url(prop_name, allow_blank: false)
          @prop_validations ||= {}

          prop_validations[prop_name] = {
            url: { allow_blank: allow_blank }
          }
        end

        def validates_email(prop_name, allow_blank: false)
          @prop_validations ||= {}

          prop_validations[prop_name] = {
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: 'must be a valid email address',
              allow_blank: allow_blank
            }
          }
        end

        def validates_callable(prop_name, allow_nil: true)
          @prop_validations ||= {}

          prop_validations[prop_name] = {
            callable: { allow_nil: allow_nil }
          }
        end

        def validates_presence(prop_name, allow_blank: false)
          @prop_validations ||= {}

          prop_validations[prop_name] = {
            presence: { allow_blank: allow_blank }
          }
        end

        def validate_options(prop_name, options = {})
          # Support custom validation callbacks
          return unless options[:validate] && options[:validate].respond_to?(:call)

          @prop_validations ||= {}
          prop_validations[prop_name] ||= {}
          prop_validations[prop_name][:custom] = {
            validator: options[:validate],
            message: options[:message] || 'is invalid'
          }
        end
      end

      # Instance methods for validation
      def validate_props!
        # Access prop_validations through the class
        validations_to_check = self.class.prop_validations
        return true if validations_to_check.nil? || validations_to_check.empty?

        errors = validations_to_check.each_with_object([]) do |(prop_name, validations), error_list|
          value = send(prop_name)

          validations.each do |validation_type, options|
            case validation_type
            when :inclusion
              # Skip validation if allow_blank is true and value is blank
              next if options[:allow_blank] && value.to_s.strip.empty?

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
            when :presence
              unless valid_presence?(value, allow_blank: options[:allow_blank])
                error_list << "#{prop_name} can't be blank"
              end
            when :custom
              error_list << "#{prop_name} #{options[:message]}" unless options[:validator].call(value)
            end
          end
        end

        raise ArgumentError, "Component validation failed: #{errors.join(', ')}" if errors.any?

        true
      end

      # Common validation helpers
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

      def valid_callable?(value, allow_nil: true)
        return true if allow_nil && value.nil?

        value.respond_to?(:call)
      end

      def valid_presence?(value, allow_blank: false)
        return true if allow_blank && value.to_s.strip.empty?

        !value.nil? && !value.to_s.strip.empty?
      end

      # Sanitization helpers
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

      def sanitize_css_class(class_name)
        return '' if class_name.nil?

        # Remove any non-alphanumeric characters except dash, underscore, and space
        class_name.to_s.gsub(/[^a-zA-Z0-9\-_ ]/, '')
      end

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
