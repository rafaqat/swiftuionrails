# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Storybook
    # Provides documentation helpers for Storybook stories
    module Documentation
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        ##
        # Sets the description for the current story's documentation.
        # @param [String] description - The description text to associate with the story.
        def story_doc(description)
          @story_documentation ||= {}
          @story_documentation[:description] = description
        end

        ##
        # Adds a usage example to the story documentation.
        # @param [String] name - The name of the example.
        # @param [String] code - The code snippet demonstrating usage.
        def story_example(name, code)
          @story_documentation ||= {}
          @story_documentation[:examples] ||= {}
          @story_documentation[:examples][name] = code
        end

        ##
        # Adds documentation for a parameter to the story.
        # @param param_name The name of the parameter.
        # @param description The description of the parameter.
        def param_doc(param_name, description)
          @story_documentation ||= {}
          @story_documentation[:params] ||= {}
          @story_documentation[:params][param_name] = description
        end

        ##
        # Returns the current story documentation as a hash, or an empty hash if none exists.
        # @return [Hash] The documentation data for the story.
        def get_documentation
          @story_documentation || {}
        end
      end

      ##
      # Renders the story documentation as HTML, including description, parameters, and examples if available.
      # @return [String] The HTML string for the documentation, or an empty string if no documentation exists.
      def render_documentation
        docs = self.class.get_documentation
        return '' if docs.empty?

        content_tag(:div, class: 'story-documentation') do
          safe_join([
            render_description(docs[:description]),
            render_parameters(docs[:params]),
            render_examples(docs[:examples])
          ].compact)
        end
      end

      private

      ##
      # Renders the story description as an HTML div element.
      # Returns nil if no description is provided.
      # @param [String, nil] description - The story description text.
      # @return [String, nil] HTML markup for the description, or nil if absent.
      def render_description(description)
        return nil unless description

        content_tag(:div, class: 'story-description') do
          content_tag(:p, description)
        end
      end

      ##
      # Renders a section of HTML displaying documented parameters and their descriptions.
      # @param [Hash] params - A hash mapping parameter names to their descriptions.
      # @return [String, nil] HTML markup for the parameters section, or nil if no parameters are provided.
      def render_parameters(params)
        return nil unless params&.any?

        content_tag(:div, class: 'story-parameters') do
          safe_join([
                      content_tag(:h4, 'Parameters'),
                      content_tag(:dl) do
                        safe_join(params.map do |name, desc|
                          safe_join([
                                      content_tag(:dt, name.to_s, class: 'param-name'),
                                      content_tag(:dd, desc, class: 'param-description')
                                    ])
                        end)
                      end
                    ])
        end
      end

      ##
      # Renders a section of HTML displaying example usage blocks for a story.
      # Returns a div containing each example's name and code snippet, or nil if no examples are provided.
      # @param [Hash] examples - A hash mapping example names to Ruby code snippets.
      # @return [String, nil] HTML-safe string with rendered examples, or nil if no examples exist.
      def render_examples(examples)
        return nil unless examples&.any?

        content_tag(:div, class: 'story-examples') do
          safe_join([
                      content_tag(:h4, 'Examples'),
                      safe_join(examples.map do |name, code|
                        content_tag(:div, class: 'story-example') do
                          safe_join([
                                      content_tag(:h5, name.to_s),
                                      content_tag(:pre) do
                                        content_tag(:code, code, class: 'language-ruby')
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
# Copyright 2025
