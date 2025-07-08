# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Generators
    class StoriesGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :stories, type: :array, default: [], banner: 'story_name story_name'

      # SECURITY: Validate component name to prevent code injection
      def validate_component_name!
        unless name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*\z/)
          raise Thor::Error,
                "Invalid component name '#{name}'. Component names must start with a letter and contain only letters, numbers, and underscores."
        end

        # Check for Ruby reserved words
        reserved_words = %w[
          alias and begin break case class def defined do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield
          __FILE__ __LINE__ __ENCODING__ BEGIN END
        ]

        raise Thor::Error, "Component name '#{name}' is a Ruby reserved word." if reserved_words.include?(name.downcase)

        # Additional check for suspicious patterns
        if name.match?(/\b(system|exec|eval|constantize|send|public_send|instance_eval|class_eval|module_eval)\b/i)
          raise Thor::Error, "Component name '#{name}' contains forbidden keywords."
        end
      end

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

      def create_stories_file
        validate_component_name!
        validate_story_names!
        template 'stories.rb.erb', File.join('test/components/stories', class_path, "#{file_name}_component_stories.rb")
      end

      def create_preview_file
        validate_component_name!
        validate_story_names!
        template 'preview.html.erb',
                 File.join('test/components/stories', class_path, "#{file_name}_component_preview.html.erb")
      end

      private

      def component_class_name
        # SECURITY: Ensure class name is safe
        sanitized_class_name = class_name.gsub(/[^A-Za-z0-9]/, '')
        "#{sanitized_class_name}Component"
      end

      def story_names
        # SECURITY: Sanitize story names
        validated_stories = stories.grep(/\A[a-z_][a-z0-9_]*\z/)
        validated_stories.presence || %w[default playground]
      end

      def class_name
        # Override to ensure sanitization
        @class_name ||= name.gsub(/[^A-Za-z0-9_]/, '').camelize
      end

      def file_name
        # Override to ensure safe file names
        @file_name ||= name.gsub(/[^a-z0-9_]/i, '_').underscore
      end

      def component_props
        component_class.swift_props
      rescue StandardError
        {}
      end

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
