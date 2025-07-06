# frozen_string_literal: true
# Copyright 2025

module ViewComponent
  module Storybook
    module Collections
      class StoriesCollection
        include Enumerable

        delegate_missing_to :stories

        attr_reader :stories

        def load(code_objects)
          @stories = Array(code_objects).map { |obj| StoriesCollection.stories_from_code_object(obj) }.compact
        end

        def self.stories_from_code_object(code_object)
          # Check for nil path before attempting to constantize
          if code_object.path.nil?
            Rails.logger.warn "Code object has nil path, skipping"
            return nil
          end
          
          klass = code_object.path.constantize
          # Only set code_object if the class responds to it
          if klass.respond_to?(:code_object=)
            klass.code_object = code_object
          end
          klass
        rescue NameError => e
          # Handle cases where the constant cannot be found
          Rails.logger.warn "Could not load story class: #{code_object.path} - #{e.message}"
          nil
        end

        def self.stories_class?(klass)
          return unless klass.ancestors.include?(ViewComponent::Storybook::Stories)

          !klass.respond_to?(:abstract_class) || klass.abstract_class != true
        end
      end
    end
  end
end
# Copyright 2025
