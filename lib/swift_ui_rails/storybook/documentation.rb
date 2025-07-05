# frozen_string_literal: true

module SwiftUIRails
  module Storybook
    # Provides documentation helpers for Storybook stories
    module Documentation
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        # Add documentation to a story
        def story_doc(description)
          @story_documentation ||= {}
          @story_documentation[:description] = description
        end
        
        # Add usage examples
        def story_example(name, code)
          @story_documentation ||= {}
          @story_documentation[:examples] ||= {}
          @story_documentation[:examples][name] = code
        end
        
        # Add parameter documentation
        def param_doc(param_name, description)
          @story_documentation ||= {}
          @story_documentation[:params] ||= {}
          @story_documentation[:params][param_name] = description
        end
        
        # Get all documentation
        def get_documentation
          @story_documentation || {}
        end
      end
      
      # Instance methods for documentation rendering
      def render_documentation
        docs = self.class.get_documentation
        return "" if docs.empty?
        
        content_tag(:div, class: "story-documentation") do
          safe_join([
            render_description(docs[:description]),
            render_parameters(docs[:params]),
            render_examples(docs[:examples])
          ].compact)
        end
      end
      
      private
      
      def render_description(description)
        return nil unless description
        
        content_tag(:div, class: "story-description") do
          content_tag(:p, description)
        end
      end
      
      def render_parameters(params)
        return nil unless params && params.any?
        
        content_tag(:div, class: "story-parameters") do
          safe_join([
            content_tag(:h4, "Parameters"),
            content_tag(:dl) do
              safe_join(params.map do |name, desc|
                safe_join([
                  content_tag(:dt, name.to_s, class: "param-name"),
                  content_tag(:dd, desc, class: "param-description")
                ])
              end)
            end
          ])
        end
      end
      
      def render_examples(examples)
        return nil unless examples && examples.any?
        
        content_tag(:div, class: "story-examples") do
          safe_join([
            content_tag(:h4, "Examples"),
            safe_join(examples.map do |name, code|
              content_tag(:div, class: "story-example") do
                safe_join([
                  content_tag(:h5, name.to_s),
                  content_tag(:pre) do
                    content_tag(:code, code, class: "language-ruby")
                  end
                ])
              end
            end)
          ])
        end
      end
    end
  end
end