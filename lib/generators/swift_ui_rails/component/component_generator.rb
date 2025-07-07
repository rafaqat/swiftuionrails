# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :props, type: :array, default: [], banner: 'prop:type prop:type'

      ##
      # Validates the component name to ensure it is safe and conforms to naming rules.
      # Raises a Thor::Error if the name is invalid, contains forbidden keywords, or includes suspicious characters.
      def validate_component_name!
        unless name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*\z/)
          raise Thor::Error,
                "Invalid component name '#{name}'. Component names must start with a letter and contain only letters, numbers, and underscores."
        end

        # Additional check for suspicious patterns
        if name.match?(/\b(system|exec|eval|constantize|send|public_send|instance_eval|class_eval|module_eval)\b/i)
          raise Thor::Error, "Component name '#{name}' contains forbidden keywords."
        end

        # Warn if name looks suspicious
        return unless name.match?(/[;\|&`$(){}]/)

        raise Thor::Error, "Component name '#{name}' contains suspicious characters."
      end

      ##
      # Generates a SwiftUI component Ruby file in the app/components directory using the provided name and properties.
      # Skips file creation if the file already exists unless the force option is specified, in which case it overwrites the file.
      def create_component_file
        validate_component_name!
        validate_props!

        component_path = File.join('app/components', class_path, "#{file_name}_component.rb")

        # Check if file already exists
        if File.exist?(destination_root.join(component_path))
          if options[:force]
            say_status :overwrite, component_path, :yellow
          else
            say_status :skip, "#{component_path} (already exists)", :yellow
            return
          end
        end

        template 'component.rb.erb', component_path
      end

      ##
      # Generates a spec file for the component using the provided name and properties.
      # The spec file is created under `spec/components` using a template.
      def create_component_spec
        validate_component_name!
        validate_props!
        template 'component_spec.rb.erb', File.join('spec/components', class_path, "#{file_name}_component_spec.rb")
      end

      private

      ##
      # Parses the provided prop definitions into a list of hashes with validated names and sanitized types.
      # Raises a Thor::Error if any prop is invalid.
      # @return [Array<Hash>] An array of hashes, each containing :name and :type keys for a prop.
      def parsed_props
        props.map do |prop|
          parts = prop.split(':', 2)
          name = parts[0]&.strip
          type = parts[1]&.strip || 'String'

          # Handle missing prop name
          raise Thor::Error, "Invalid prop definition: '#{prop}'. Expected format: 'name:type'" if name.blank?

          # SECURITY: Validate and sanitize prop names and types
          validate_prop_name!(name)
          type = sanitize_type(type)

          { name: name, type: type }
        end
      end

      ##
      # Validates each property definition to ensure it does not contain suspicious characters or forbidden keywords.
      # Raises a Thor::Error if any property is potentially unsafe.
      def validate_props!
        props.each do |prop|
          if prop.match?(/[;\|&`$(){}]/) || prop.match?(/\b(system|exec|eval)\b/i)
            raise Thor::Error, "Property definition '#{prop}' contains suspicious characters or keywords."
          end
        end
      end

      ##
      # Validates that a prop name is a valid Ruby identifier and not a reserved word.
      # Raises a Thor::Error if the name is invalid or reserved.
      # @param [String] name The prop name to validate.
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

      ##
      # Sanitizes and validates a property type, allowing only whitelisted or properly formatted types.
      # Defaults to 'String' and issues a warning if the type is invalid.
      # @param [String] type The property type to sanitize and validate.
      # @return [String] The sanitized and validated type name.
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

        # Clean the type string first
        cleaned_type = type.to_s.strip.gsub(/[^A-Za-z0-9:_]/, '')

        # Check if it's an allowed type
        if all_allowed.include?(cleaned_type) || cleaned_type.match?(/\A[A-Z][A-Za-z0-9]*(::[A-Z][A-Za-z0-9]*)*\z/)
          cleaned_type
        else
          # Default to String for invalid types with a warning
          say_status :warning, "Invalid type '#{type}' - defaulting to String", :yellow
          'String'
        end
      end

      ##
      # Returns a sanitized class name for the component, ensuring it contains only alphanumeric characters and appends 'Component' to the end.
      # @return [String] The safe component class name.
      def component_class_name
        # SECURITY: Ensure class name is safe (additional protection)
        sanitized_class_name = class_name.gsub(/[^A-Za-z0-9]/, '')
        "#{sanitized_class_name}Component"
      end

      ##
      # Returns a sanitized and camelized version of the component name suitable for use as a Ruby class name.
      # Removes all non-alphanumeric and non-underscore characters before camelizing.
      def class_name
        # Override to ensure sanitization
        @class_name ||= name.gsub(/[^A-Za-z0-9_]/, '').camelize
      end

      ##
      # Returns a sanitized, underscored file name derived from the component name, replacing invalid characters with underscores.
      # @return [String] The safe file name for the component.
      def file_name
        # Override to ensure safe file names
        @file_name ||= name.gsub(/[^a-z0-9_]/, '_').underscore
      end
    end
  end
end
# Copyright 2025
