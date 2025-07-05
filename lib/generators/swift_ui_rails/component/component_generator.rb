# frozen_string_literal: true
# Copyright 2025

module SwiftUIRails
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      
      argument :props, type: :array, default: [], banner: "prop:type prop:type"
      
      # SECURITY: Validate component name to prevent code injection
      def validate_component_name!
        unless name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*\z/)
          raise Thor::Error, "Invalid component name '#{name}'. Component names must start with a letter and contain only letters, numbers, and underscores."
        end
        
        # Additional check for suspicious patterns
        if name.match?(/\b(system|exec|eval|constantize|send|public_send|instance_eval|class_eval|module_eval)\b/i)
          raise Thor::Error, "Component name '#{name}' contains forbidden keywords."
        end
        
        # Warn if name looks suspicious
        if name.match?(/[;\|&`$(){}]/)
          raise Thor::Error, "Component name '#{name}' contains suspicious characters."
        end
      end
      
      def create_component_file
        validate_component_name!
        validate_props!
        
        component_path = File.join("app/components", class_path, "#{file_name}_component.rb")
        
        # Check if file already exists
        if File.exist?(destination_root.join(component_path))
          if options[:force]
            say_status :overwrite, component_path, :yellow
          else
            say_status :skip, "#{component_path} (already exists)", :yellow
            return
          end
        end
        
        template "component.rb.erb", component_path
      end
      
      def create_component_spec
        validate_component_name!
        validate_props!
        template "component_spec.rb.erb", File.join("spec/components", class_path, "#{file_name}_component_spec.rb")
      end
      
      private
      
      def parsed_props
        props.map do |prop|
          parts = prop.split(":", 2)
          name = parts[0]&.strip
          type = parts[1]&.strip || "String"
          
          # Handle missing prop name
          unless name && !name.empty?
            raise Thor::Error, "Invalid prop definition: '#{prop}'. Expected format: 'name:type'"
          end
          
          # SECURITY: Validate and sanitize prop names and types
          validate_prop_name!(name)
          type = sanitize_type(type)
          
          { name: name, type: type }
        end
      end
      
      def validate_props!
        props.each do |prop|
          if prop.match?(/[;\|&`$(){}]/) || prop.match?(/\b(system|exec|eval)\b/i)
            raise Thor::Error, "Property definition '#{prop}' contains suspicious characters or keywords."
          end
        end
      end
      
      def validate_prop_name!(name)
        unless name && name.match?(/\A[a-z_][a-z0-9_]*\z/)
          raise Thor::Error, "Invalid prop name '#{name}'. Prop names must start with a lowercase letter or underscore and contain only lowercase letters, numbers, and underscores."
        end
        
        # Check for Ruby reserved words
        reserved_words = %w[
          alias and begin break case class def defined do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield
          __FILE__ __LINE__ __ENCODING__ BEGIN END
        ]
        
        if reserved_words.include?(name)
          raise Thor::Error, "Prop name '#{name}' is a Ruby reserved word."
        end
      end
      
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
          "String"
        end
      end
      
      def component_class_name
        # SECURITY: Ensure class name is safe (additional protection)
        sanitized_class_name = class_name.gsub(/[^A-Za-z0-9]/, '')
        "#{sanitized_class_name}Component"
      end
      
      def class_name
        # Override to ensure sanitization
        @class_name ||= name.gsub(/[^A-Za-z0-9_]/, '').camelize
      end
      
      def file_name
        # Override to ensure safe file names
        @file_name ||= name.gsub(/[^a-z0-9_]/, '_').underscore
      end
    end
  end
end
# Copyright 2025
