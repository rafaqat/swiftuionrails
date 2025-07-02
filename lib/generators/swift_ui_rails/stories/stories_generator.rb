# frozen_string_literal: true

module SwiftUIRails
  module Generators
    class StoriesGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      
      argument :stories, type: :array, default: [], banner: "story_name story_name"
      
      def create_stories_file
        template "stories.rb.erb", File.join("test/components/stories", class_path, "#{file_name}_component_stories.rb")
      end
      
      def create_preview_file
        template "preview.html.erb", File.join("test/components/stories", class_path, "#{file_name}_component_preview.html.erb")
      end
      
      private
      
      def component_class_name
        "#{class_name}Component"
      end
      
      def story_names
        stories.presence || ["default", "playground"]
      end
      
      def component_props
        component_class.swift_props rescue {}
      end
      
      def component_class
        component_class_name.constantize
      rescue NameError
        nil
      end
      
      def default_prop_value(prop_config)
        return prop_config[:default] if prop_config[:default]
        
        case prop_config[:type]&.to_s
        when "String"
          "'Sample Text'"
        when "Symbol"
          ":default"
        when "Integer", "Fixnum"
          "42"
        when "Float"
          "3.14"
        when "TrueClass", "FalseClass", "[TrueClass, FalseClass]"
          "false"
        when "Array"
          "[]"
        when "Hash"
          "{}"
        else
          "nil"
        end
      end
    end
  end
end