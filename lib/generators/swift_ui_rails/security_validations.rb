# frozen_string_literal: true

# Copyright 2025

require 'active_support/concern'

module SwiftUIRails
  module Generators
    # Shared security validations for generators
    # This module provides validation methods that can be used by generators
    # It does not hook into the lifecycle - generators explicitly call these methods
    module SecurityValidations
      extend ActiveSupport::Concern

      private

      # Validates component/generator names for security issues
      def validate_component_name!(name)
        unless name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*\z/)
          raise Thor::Error,
                "Invalid component name '#{name}'. Component names must start with a letter and contain only letters, numbers, and underscores."
        end

        if name.match?(/\b(system|exec|eval|constantize|send|public_send|instance_eval|class_eval|module_eval)\b/i)
          raise Thor::Error, "Component name '#{name}' contains forbidden keywords."
        end

        return unless name.match?(/[;\|&`$(){}]/)

        raise Thor::Error, "Component name '#{name}' contains suspicious characters."
      end

      # Validates prop definitions for security issues
      def validate_props!(props)
        return unless props && props.respond_to?(:each)

        props.each do |prop|
          if prop.match?(/[;\|&`$(){}]/) || prop.match?(/\b(system|exec|eval)\b/i)
            raise Thor::Error, "Property definition '#{prop}' contains suspicious characters or keywords."
          end
        end
      end

      # Validates story names for security issues
      def validate_story_names!(stories)
        return unless stories && stories.respond_to?(:each)

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

      def say_error(message)
        say message, :red
      end
    end
  end
end
# Copyright 2025
