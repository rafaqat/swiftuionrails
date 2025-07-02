# frozen_string_literal: true

module SwiftUIRails
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      
      argument :props, type: :array, default: [], banner: "prop:type prop:type"
      
      def create_component_file
        template "component.rb.erb", File.join("app/components", class_path, "#{file_name}_component.rb")
      end
      
      def create_component_spec
        template "component_spec.rb.erb", File.join("spec/components", class_path, "#{file_name}_component_spec.rb")
      end
      
      private
      
      def parsed_props
        props.map do |prop|
          name, type = prop.split(":")
          type ||= "String"
          { name: name, type: type }
        end
      end
      
      def component_class_name
        "#{class_name}Component"
      end
    end
  end
end