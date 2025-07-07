# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Storybook
    # Provides layout helpers for Storybook stories
    module Layouts
      ##
      # Returns the default layout symbol for Storybook stories.
      # @return [Symbol] The default layout name, :storybook.
      def default_layout
        :storybook
      end

      ##
      # Gets or sets the current layout for a Storybook story.
      # If a layout name is provided, sets the layout; otherwise, returns the current layout or the default layout if none is set.
      # @param [Symbol, String, nil] layout_name The layout to set for the story (optional).
      # @return [Symbol, String] The current or default layout name.
      def story_layout(layout_name = nil)
        @story_layout = layout_name if layout_name
        @story_layout || default_layout
      end

      ##
      # Wraps the given block content in a div with the "story-container" CSS class and any additional classes provided.
      # @param [Hash] options - Optional HTML attributes, including additional CSS classes via :class.
      # @yield The content to be wrapped inside the container.
      # @return [String] HTML-safe string containing the wrapped content.
      def story_container(**options, &block)
        content_tag(:div, class: "story-container #{options[:class]}", &block)
      end

      ##
      # Wraps content in nested divs for a responsive story layout.
      # The outer div uses the "story-responsive" class and any additional classes provided via options.
      # The inner div uses the "story-content" class and contains the given block content.
      # @param [Hash] options - Optional HTML attributes, including additional CSS classes.
      # @yield The content to be wrapped inside the responsive layout.
      # @return [String] HTML-safe string with the responsive layout structure.
      def responsive_story(**options, &block)
        content_tag(:div, class: "story-responsive #{options[:class]}") do
          content_tag(:div, class: 'story-content', &block)
        end
      end
    end
  end
end
# Copyright 2025
