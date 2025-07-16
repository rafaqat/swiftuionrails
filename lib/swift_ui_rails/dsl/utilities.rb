# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Utility methods and helpers for SwiftUI Rails DSL
    module Utilities
      # Loading Components
      def spinner(size: :md, border_color: nil, spinner_color: nil)
        size_classes = {
          xs: 'h-3 w-3',
          sm: 'h-4 w-4',
          md: 'h-6 w-6',
          lg: 'h-8 w-8',
          xl: 'h-12 w-12'
        }

        border_color ||= 'border-gray-200'
        spinner_color ||= 'border-blue-600'

        create_element(:div,
                       nil,
                       class: "#{size_classes[size]} animate-spin rounded-full border-2 #{border_color} #{spinner_color} border-t-transparent",
                       role: 'status',
                       'aria-label': 'Loading')
      end

      # Component slot helpers - these are used in stories for composition
      def with_form(**attrs, &block)
        # Slot helper for forms
        create_element(:div, nil, **attrs, &block)
      end

      def with_sidebar(**attrs, &block)
        # Slot helper for sidebars
        create_element(:div, nil, **attrs, &block)
      end

      def with_header(**attrs, &block)
        # Slot helper for headers
        create_element(:div, nil, **attrs, &block)
      end

      def with_footer(**attrs, &block)
        # Slot helper for footers
        create_element(:div, nil, **attrs, &block)
      end

      # Helper method to merge CSS classes safely  
      def class_names(*args)
        # Convert all args to strings and filter out blank/nil values
        args.flatten.compact.map(&:to_s).reject(&:blank?).uniq.join(' ')
      end

      private

      # Access the form authenticity token
      def get_form_authenticity_token
        if respond_to?(:form_authenticity_token)
          form_authenticity_token
        elsif view_context&.respond_to?(:form_authenticity_token)
          view_context.form_authenticity_token
        else
          nil
        end
      end
    end
  end
end