# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  # SwiftUI-inspired orientation support for responsive layouts
  module Orientation
    ORIENTATIONS = %i[portrait landscape].freeze

    # Helper methods for orientation-based layouts
    module Helpers
      # Conditionally render content based on orientation
      def if_portrait(&block)
        return unless orientation == :portrait
        yield if block_given?
      end

      def if_landscape(&block)
        return unless orientation == :landscape
        yield if block_given?
      end

      # Layout helper that switches between vstack/hstack based on orientation
      def orientation_stack(spacing: nil, alignment: nil, &block)
        if orientation == :landscape
          hstack(spacing: spacing, alignment: alignment, &block)
        else
          vstack(spacing: spacing, alignment: alignment, &block)
        end
      end

      # Adaptive padding based on orientation
      def orientation_padding(portrait: nil, landscape: nil)
        padding_value = orientation == :portrait ? portrait : landscape
        padding(padding_value) if padding_value
      end

      # Adaptive spacing based on orientation
      def orientation_spacing(portrait: nil, landscape: nil)
        spacing_value = orientation == :portrait ? portrait : landscape
        spacing(spacing_value) if spacing_value
      end
    end

    # Size class helpers (similar to SwiftUI)
    module SizeClasses
      # Simulate SwiftUI's size classes
      def horizontal_size_class
        orientation == :landscape ? :regular : :compact
      end

      def vertical_size_class
        orientation == :portrait ? :regular : :compact
      end

      # Helper to check size classes
      def compact_width?
        horizontal_size_class == :compact
      end

      def regular_width?
        horizontal_size_class == :regular
      end

      def compact_height?
        vertical_size_class == :compact
      end

      def regular_height?
        vertical_size_class == :regular
      end
    end
  end
end
# Copyright 2025