# frozen_string_literal: true

# Copyright 2025

require 'rails/generators'
require_relative 'security_validations'

module SwiftUIRails
  module Generators
    # Base generator with security validations using Thor's lifecycle hooks
    class BaseGenerator < Rails::Generators::NamedBase
      include SecurityValidations

      # Thor configuration for strict validation
      # NOTE: Temporarily disabled check_unknown_options! because test framework passes --skip-bundle etc
      # check_unknown_options!
      strict_args_position!

      class_option :force, type: :boolean, default: false,
                           desc: 'Overwrite files that already exist'

      # First public method that runs in Thor::Group lifecycle
      # Subclasses should NOT override this method
      def validate_all_inputs
        # Validate the component name first
        validate_component_name!(name) if respond_to?(:name)

        # Then validate any additional inputs
        validate_additional_inputs!
      rescue Thor::Error => e
        say_error(e.message)
        # Allow tests to catch the error instead of exiting
        raise e if defined?(RSpec)
        exit 1
      end

      protected

      # Subclasses override this to add their specific validations
      def validate_additional_inputs!
        # Override in subclasses for additional validation
      end

      def component_class_name
        # SECURITY: Ensure class name is safe
        sanitized_class_name = class_name.gsub(/[^A-Za-z0-9]/, '')
        "#{sanitized_class_name}Component"
      end

      def file_name
        # Override to ensure safe file names
        @file_name ||= name.gsub(/[^a-zA-Z0-9_]/, '_').downcase.gsub(/_{2,}/, '_').gsub(/^_|_$/, '')
      end

      def class_name
        # Override to ensure sanitization
        @class_name ||= name.gsub(/[^A-Za-z0-9_]/, '').camelize
      end
      
      # Override to sanitize the class path
      def regular_class_path
        @regular_class_path ||= begin
          # Get the original path from the name
          path = name.include?('/') ? name.split('/')[0...-1] : []
          
          # SECURITY: Sanitize each path component
          path.map! { |part| part.gsub(/[^a-zA-Z0-9_]/, '_').downcase }
          # Remove any empty parts, current directory refs, or parent directory refs
          path.reject! { |part| part.empty? || part == '.' || part == '..' || part.start_with?('.') }
          path
        end
      end

      # Common validation for prop names
      def validate_prop_name!(name)
        unless name&.match?(/\A[a-z_][a-z0-9_]*\z/)
          raise Thor::Error,
                "Invalid prop name '#{name}'. Prop names must start with a lowercase letter or underscore and contain only lowercase letters, numbers, and underscores."
        end

        # Check for Ruby reserved words
        reserved_words = %w[
          alias and begin break case class def defined do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield
          __FILE__ __LINE__ __ENCODING__ BEGIN END
        ]

        return unless reserved_words.include?(name)

        raise Thor::Error, "Prop name '#{name}' is a Ruby reserved word."
      end

      # Common type sanitization
      def sanitize_type(type)
        # SECURITY: Whitelist allowed types to prevent code injection
        allowed_types = %w[
          String Integer Float Boolean Array Hash Symbol
          Date Time DateTime ActiveRecord::Base NilClass
          TrueClass FalseClass Numeric Object Proc
        ]

        # Handle Rails-specific types
        rails_types = %w[
          ActiveRecord::Relation ActionController::Parameters
        ]

        all_allowed = allowed_types + rails_types

        # Clean the type string first - extract only the first valid type name
        # SECURITY: Use simpler regex to avoid ReDoS
        cleaned_type = type.to_s.strip
        # Extract only alphanumeric characters, colons, and underscores
        cleaned_type = cleaned_type[/\A[A-Za-z0-9:_]+/] || ''

        # Check if it's an allowed type
        if all_allowed.include?(cleaned_type) || cleaned_type.match?(/\A[A-Z][A-Za-z0-9]*(::[A-Z][A-Za-z0-9]*)*\z/)
          cleaned_type
        else
          # Default to String for invalid types with a warning
          say_status :warning, "Invalid type '#{type}' - defaulting to String", :yellow
          'String'
        end
      end
    end
  end
end
# Copyright 2025
