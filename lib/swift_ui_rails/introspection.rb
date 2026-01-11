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
      # Cache eager_load status to avoid repeated calls
      @eager_loaded = false

      class << self
        def all_models
          ensure_eager_loaded

          ActiveRecord::Base.descendants
            .reject { |m| should_exclude?(m) }
            .map(&:name)
            .compact  # Filter out nil names from anonymous classes
            .sort
        end

        private

        def ensure_eager_loaded
          return if @eager_loaded || !Rails.env.development?

          Rails.application.eager_load!
          @eager_loaded = true
        end

        def should_exclude?(model)
          return true if model.abstract_class?

          name = model.name
          return true if name.nil?  # Anonymous classes have nil names
          return true if name.include?("HABTM_")  # More specific pattern
          return true if name.start_with?("ActiveStorage")

          false
        end
      end
    end
  end
end
