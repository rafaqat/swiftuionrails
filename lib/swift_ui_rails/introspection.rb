# frozen_string_literal: true

module SwiftUIRails
  module Introspection
    class ModelReflector
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      def columns
        @model_class.columns.reject { |c| ["id", "created_at", "updated_at"].include?(c.name) }
      end

      def associations
        @model_class.reflect_on_all_associations(:has_many)
      end

      def belongs_to_associations
        @model_class.reflect_on_all_associations(:belongs_to)
      end

      def title_column
        # Guess the "display name" of a record
        columns.find { |c| ["name", "title", "email", "username", "slug"].include?(c.name) }&.name || "id"
      end
    end

    class SystemScanner
      def self.all_models
        # Eager load models in development to ensure descendants are populated
        Rails.application.eager_load! if Rails.env.development?
        
        ActiveRecord::Base.descendants
          .reject { |m| m.abstract_class? || m.name.include?("HABTM") || m.name.start_with?("ActiveStorage") }
          .map(&:name)
          .sort
      end
    end
  end
end
