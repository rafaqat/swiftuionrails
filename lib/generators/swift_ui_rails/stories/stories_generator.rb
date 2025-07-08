# frozen_string_literal: true

# Copyright 2025

require_relative '../base_generator'

module SwiftUIRails
  module Generators
    class StoriesGenerator < BaseGenerator
      source_root File.expand_path('templates', __dir__)

      argument :stories, type: :array, default: [], banner: 'story_name story_name'

      def create_stories_file
        template 'stories.rb.erb', File.join('test/components/stories', class_path, "#{file_name}_component_stories.rb")
      end

      def create_preview_file
        template 'preview.html.erb',
                 File.join('test/components/stories', class_path, "#{file_name}_component_preview.html.erb")
      end

      protected

      # Override from BaseGenerator to add story names validation
      def validate_additional_inputs!
        validate_story_names!(stories)
      end

      private


      def story_names
        # SECURITY: Sanitize story names
        validated_stories = stories.grep(/\A[a-z_][a-z0-9_]*\z/)
        validated_stories.presence || %w[default playground]
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
