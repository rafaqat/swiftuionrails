# frozen_string_literal: true

module SwiftUIRails
  module Introspection
    # ModelReflector provides introspection utilities for ActiveRecord models.
    # It helps discover column metadata, associations, and guess display names.
    class ModelReflector
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      # Returns columns excluding id, created_at, and updated_at
      def columns
        @model_class.columns.reject { |c| ["id", "created_at", "updated_at"].include?(c.name) }
      end

      def associations
        @model_class.reflect_on_all_associations(:has_many)
      end

      def belongs_to_associations
        @model_class.reflect_on_all_associations(:belongs_to)
      end

      # Guess the "display name" column of a record
      def title_column
        columns.find { |c| ["name", "title", "email", "username", "slug"].include?(c.name) }&.name || "id"
      end
    end

    # SystemScanner discovers all ActiveRecord models in the application.
    # It handles eager loading and filters out internal Rails classes.
    class SystemScanner
      # Cache eager_load status to avoid repeated calls
      @eager_loaded = false

      class << self
        # Returns an array of all model class names, sorted alphabetically
        def all_models
          ensure_eager_loaded

          ActiveRecord::Base.descendants
            .reject { |m| should_exclude?(m) }
            .map(&:name)
            .compact  # Filter out nil names from anonymous classes
            .sort
        end

        private

        # Ensure models are eager loaded so descendants are populated.
        # In production, models are typically already loaded at boot.
        # In development/test, we need to eager load to discover all models.
        def ensure_eager_loaded
          return if @eager_loaded

          # Only eager load if not already done (production usually has this at boot)
          if defined?(Rails.application) && Rails.application.respond_to?(:eager_load!)
            Rails.application.eager_load!
          end
          @eager_loaded = true
        end

        def should_exclude?(model)
          return true if model.abstract_class?

          name = model.name
          return true if name.nil?  # Anonymous classes have nil names
          return true if name.include?("HABTM_")  # Has-and-belongs-to-many join models
          return true if name.start_with?("ActiveStorage")

          false
        end
      end
    end
  end
end
