# frozen_string_literal: true

module SwiftUIRails
  module Tailwind
    module Modifiers
      # Spacing utilities
      %i[p px py pt pr pb pl m mx my mt mr mb ml].each do |method|
        define_method method do |value|
          add_class("#{method}-#{value}")
          self
        end
      end

      # Width and height
      %i[w h min_w min_h max_w max_h].each do |method|
        define_method method do |value|
          css_method = method.to_s.gsub("_", "-")
          add_class("#{css_method}-#{value}")
          self
        end
      end

      # Flexbox
      def flex(value = nil)
        add_class(value ? "flex-#{value}" : "flex")
        self
      end

      def items(value)
        add_class("items-#{value}")
        self
      end

      def justify(value)
        add_class("justify-#{value}")
        self
      end

      # Colors
      def bg(color)
        add_class("bg-#{color}")
        self
      end

      def text_color(color)
        add_class("text-#{color}")
        self
      end

      # Typography
      def text_size(size)
        add_class("text-#{size}")
        self
      end

      def font_weight(weight)
        add_class("font-#{weight}")
        self
      end

      # Borders
      def border(width = nil)
        add_class(width ? "border-#{width}" : "border")
        self
      end

      def rounded(size = nil)
        add_class(size ? "rounded-#{size}" : "rounded")
        self
      end

      # Effects
      def shadow(size = nil)
        add_class(size ? "shadow-#{size}" : "shadow")
        self
      end

      # Custom Tailwind classes
      def tw(classes)
        add_class(classes)
        self
      end

      private

      def add_class(class_name)
        @attributes ||= {}
        @attributes[:class] = [@attributes[:class], class_name].compact.join(" ")
      end
    end
  end
end