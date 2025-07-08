# frozen_string_literal: true

# Copyright 2025

require_relative '../base_generator'

module SwiftUIRails
  module Generators
    class ComponentGenerator < BaseGenerator
      source_root File.expand_path('templates', __dir__)

      argument :props, type: :array, default: [], banner: 'prop:type prop:type'

      def create_component_file
        component_path = File.join('app/components', class_path, "#{file_name}_component.rb")

        # Check if file already exists
        full_path = File.join(destination_root, component_path)
        if File.exist?(full_path)
          if options[:force]
            say_status :overwrite, component_path, :yellow
          else
            say_status :skip, "#{component_path} (already exists)", :yellow
            return
          end
        end

        template 'component.rb.erb', component_path
      end

      def create_component_spec
        template 'component_spec.rb.erb', File.join('spec/components', class_path, "#{file_name}_component_spec.rb")
      end

      protected

      # Override from BaseGenerator to add props validation
      def validate_additional_inputs!
        validate_props!(props)
        # Also validate prop parsing to catch format errors early
        parsed_props
      end

      private

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




    end
  end
end
# Copyright 2025
