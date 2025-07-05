# frozen_string_literal: true

module SwiftUIRails
  module Storybook
    # Provides preview functionality for Storybook stories
    module Previews
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        # Define preview parameters for a story
        def preview_params(**params)
          @preview_params ||= {}
          @preview_params.merge!(params)
        end
        
        # Get all preview parameters
        def get_preview_params
          @preview_params || {}
        end
      end
      
      # Instance methods for preview handling
      def preview_with_device(device_type = :desktop, &block)
        content_tag(:div, class: "preview-device preview-#{device_type}") do
          content_tag(:div, class: "device-frame", &block)
        end
      end
      
      # Preview in different viewport sizes
      def preview_responsive(&block)
        content_tag(:div, class: "preview-responsive") do
          safe_join([
            preview_with_device(:mobile, &block),
            preview_with_device(:tablet, &block),
            preview_with_device(:desktop, &block)
          ])
        end
      end
      
      # Preview with dark mode toggle
      def preview_with_theme_toggle(&block)
        content_tag(:div, class: "preview-theme-toggle", data: { controller: "theme-toggle" }) do
          safe_join([
            content_tag(:button, "Toggle Theme", 
              class: "theme-toggle-button",
              data: { action: "click->theme-toggle#toggle" }
            ),
            content_tag(:div, class: "preview-content", &block)
          ])
        end
      end
    end
  end
end
# Copyright 2025
