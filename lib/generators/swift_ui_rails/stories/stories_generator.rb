# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Generators
    class StoriesGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :stories, type: :array, default: [], banner: 'story_name story_name'

      ##
      # Validates the component name to ensure it is safe and conforms to naming rules.
      # Raises a Thor::Error if the name is invalid or contains forbidden keywords.
      def validate_component_name!
        unless name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*\z/)
          raise Thor::Error,
                "Invalid component name '#{name}'. Component names must start with a letter and contain only letters, numbers, and underscores."
        end

        # Additional check for suspicious patterns
        if name.match?(/\b(system|exec|eval|constantize|send|public_send|instance_eval|class_eval|module_eval)\b/i)
          raise Thor::Error, "Component name '#{name}' contains forbidden keywords."
        end
      end

      ##
      # Validates each story name to ensure it follows naming conventions and does not contain forbidden keywords.
      # Raises a Thor::Error if a story name is invalid or potentially unsafe.
      def validate_story_names!
        stories.each do |story|
          unless story.match?(/\A[a-z_][a-z0-9_]*\z/)
            raise Thor::Error,
                  "Invalid story name '#{story}'. Story names must start with a lowercase letter or underscore and contain only lowercase letters, numbers, and underscores."
          end

          if story.match?(/\b(system|exec|eval)\b/i)
            raise Thor::Error, "Story name '#{story}' contains forbidden keywords."
          end
        end
      end

      ##
      # Generates a stories Ruby file for the specified component using validated names.
      # The file is created from a template and placed in the test/components/stories directory.
      def create_stories_file
        validate_component_name!
        validate_story_names!
        template 'stories.rb.erb', File.join('test/components/stories', class_path, "#{file_name}_component_stories.rb")
      end

      ##
      # Generates a preview HTML file for the specified component using validated names.
      # The file is created from the 'preview.html.erb' template and placed in the test/components/stories directory.
      def create_preview_file
        validate_component_name!
        validate_story_names!
        template 'preview.html.erb',
                 File.join('test/components/stories', class_path, "#{file_name}_component_preview.html.erb")
      end

      private

      ##
      # Returns a sanitized component class name by removing non-alphanumeric characters and appending 'Component'.
      # @return [String] The safe component class name.
      def component_class_name
        # SECURITY: Ensure class name is safe
        sanitized_class_name = class_name.gsub(/[^A-Za-z0-9]/, '')
        "#{sanitized_class_name}Component"
      end

      ##
      # Returns a list of valid story names, filtered to include only those matching the required pattern.
      # If no valid names are found, returns ['default', 'playground'].
      # @return [Array<String>] The filtered or default list of story names.
      def story_names
        # SECURITY: Sanitize story names
        validated_stories = stories.grep(/\A[a-z_][a-z0-9_]*\z/)
        validated_stories.presence || %w[default playground]
      end

      ##
      # Returns a sanitized and camelized version of the component name suitable for use as a Ruby class name.
      # Removes all non-alphanumeric and non-underscore characters before camelizing.
      def class_name
        # Override to ensure sanitization
        @class_name ||= name.gsub(/[^A-Za-z0-9_]/, '').camelize
      end

      ##
      # Returns a sanitized version of the component name suitable for use as a file name.
      # Replaces invalid characters with underscores and converts to snake_case.
      # @return [String] The safe, underscored file name.
      def file_name
        # Override to ensure safe file names
        @file_name ||= name.gsub(/[^a-z0-9_]/, '_').underscore
      end

      ##
      # Retrieves the Swift properties for the component class.
      # @return [Hash] A hash of property names and their configurations, or an empty hash if retrieval fails.
      def component_props
        component_class.swift_props
      rescue StandardError
        {}
      end

      ##
      # Attempts to resolve and return the component class for the given name if it is valid and inherits from ApplicationComponent or ViewComponent::Base.
      # Returns nil if the class name is invalid, not found, or does not inherit from an allowed base class.
      # @return [Class, nil] The resolved component class or nil if not found or invalid.
      def component_class
        # SECURITY: Safe constantize with validation
        class_name = component_class_name

        # Only allow valid component class names
        return nil unless class_name.match?(/\A[A-Z][A-Za-z0-9]*Component\z/)

        # Additional safety check - ensure it's in the allowed namespace
        begin
          klass = class_name.constantize
          # Verify it's actually a component
          if defined?(ApplicationComponent) && klass < ApplicationComponent
            klass
          elsif defined?(ViewComponent::Base) && klass < ViewComponent::Base
            klass
          end
        rescue NameError
          nil
        end
      end

      ##
      # Returns a default value for a component property based on its type or explicit default.
      # @param [Hash] prop_config The property configuration, including type and optional default.
      # @return [String] A string representation of the property's default value, or 'nil' if the type is unrecognized.
      def default_prop_value(prop_config)
        return prop_config[:default] if prop_config[:default]

        case prop_config[:type]&.to_s
        when 'String'
          "'Sample Text'"
        when 'Symbol'
          ':default'
        when 'Integer', 'Fixnum'
          '42'
        when 'Float'
          '3.14'
        when 'TrueClass', 'FalseClass', '[TrueClass, FalseClass]'
          'false'
        when 'Array'
          '[]'
        when 'Hash'
          '{}'
        else
          'nil'
        end
      end
    end
  end
end
# Copyright 2025
