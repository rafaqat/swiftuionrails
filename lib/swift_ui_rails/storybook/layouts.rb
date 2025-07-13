# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Storybook
    # Provides layout helpers for Storybook stories
    module Layouts
      def default_layout
        :storybook
      end

      def story_layout(layout_name = nil)
        @story_layout = layout_name if layout_name
        @story_layout || default_layout
      end

      # Helper to wrap story content in a consistent container
      def story_container(**options, &block)
        content_tag(:div, class: "story-container #{options[:class]}", &block)
      end

      # Helper for responsive story layouts
      def responsive_story(**options, &block)
        content_tag(:div, class: "story-responsive #{options[:class]}") do
          content_tag(:div, class: 'story-content', &block)
        end
      end
    end
  end
end
# Copyright 2025
