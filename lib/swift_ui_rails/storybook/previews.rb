# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Storybook
    # Provides preview functionality for Storybook stories
    module Previews
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        ##
        # Sets or updates preview parameters for the story.
        # Merges the provided parameters into the existing preview parameters hash.
        # @param params [Hash] Key-value pairs representing preview parameters.
        def preview_params(**params)
          @preview_params ||= {}
          @preview_params.merge!(params)
        end

        ##
        # Returns the current preview parameters as a hash, or an empty hash if none are set.
        # @return [Hash] The preview parameters for the class.
        def get_preview_params
          @preview_params || {}
        end
      end

      ##
      # Wraps the given block content in HTML elements styled for a specific device type preview.
      # @param [Symbol] device_type The type of device to preview (:desktop, :mobile, etc.). Defaults to :desktop.
      # @yield The content to be displayed within the device frame.
      # @return [String] HTML markup for the device-specific preview.
      def preview_with_device(device_type = :desktop, &block)
        content_tag(:div, class: "preview-device preview-#{device_type}") do
          content_tag(:div, class: 'device-frame', &block)
        end
      end

      ##
      # Renders the given block inside preview containers for mobile, tablet, and desktop device sizes.
      # The previews are displayed together within a responsive layout.
      def preview_responsive(&block)
        content_tag(:div, class: 'preview-responsive') do
          safe_join([
                      preview_with_device(:mobile, &block),
                      preview_with_device(:tablet, &block),
                      preview_with_device(:desktop, &block)
                    ])
        end
      end

      ##
      # Wraps preview content in a container with a dark mode toggle button.
      # The preview can be toggled between light and dark themes using the included button.
      # @yield The content to be previewed within the theme toggle container.
      def preview_with_theme_toggle(&block)
        content_tag(:div, class: 'preview-theme-toggle', data: { controller: 'theme-toggle' }) do
          safe_join([
                      content_tag(:button, 'Toggle Theme',
                                  class: 'theme-toggle-button',
                                  data: { action: 'click->theme-toggle#toggle' }),
                      content_tag(:div, class: 'preview-content', &block)
                    ])
        end
      end
    end
  end
end
# Copyright 2025
