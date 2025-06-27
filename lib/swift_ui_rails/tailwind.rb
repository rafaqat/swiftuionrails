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
      def flex(value = nil, &block)
        add_class(value ? "flex-#{value}" : "flex")
        @block = block if block_given?
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

      def border_color(color)
        add_class("border-#{color}")
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

      def opacity(value)
        add_class("opacity-#{value}")
        self
      end

      def bg_opacity(value)
        add_class("bg-opacity-#{value}")
        self
      end

      def text_opacity(value)
        add_class("text-opacity-#{value}")
        self
      end

      # Overflow
      def overflow(value)
        add_class("overflow-#{value}")
        self
      end

      def overflow_x(value)
        add_class("overflow-x-#{value}")
        self
      end

      def overflow_y(value)
        add_class("overflow-y-#{value}")
        self
      end

      # Position
      def relative(&block)
        add_class("relative")
        @block = block if block_given?
        self
      end

      def absolute(&block)
        add_class("absolute")
        @block = block if block_given?
        self
      end

      def fixed(&block)
        add_class("fixed")
        @block = block if block_given?
        self
      end

      def sticky(&block)
        add_class("sticky")
        @block = block if block_given?
        self
      end

      def inset(value)
        add_class("inset-#{value}")
        self
      end

      def top(value)
        add_class("top-#{value}")
        self
      end

      def right(value)
        add_class("right-#{value}")
        self
      end

      def bottom(value)
        add_class("bottom-#{value}")
        self
      end

      def left(value)
        add_class("left-#{value}")
        self
      end

      # Display
      def hidden
        add_class("hidden")
        self
      end

      def group(&block)
        add_class("group")
        @block = block if block_given?
        self
      end

      def block(&block)
        add_class("block")
        @block = block if block_given?
        self
      end

      def inline(&block)
        add_class("inline")
        @block = block if block_given?
        self
      end

      def inline_block
        add_class("inline-block")
        self
      end

      def flex_1
        add_class("flex-1")
        self
      end

      def flex_wrap
        add_class("flex-wrap")
        self
      end

      def items_center
        add_class("items-center")
        self
      end

      def items_start
        add_class("items-start")
        self
      end

      def items_end
        add_class("items-end")
        self
      end

      def justify_center
        add_class("justify-center")
        self
      end

      def justify_between(&block)
        add_class("justify-between")
        @block = block if block_given?
        self
      end

      def justify_start
        add_class("justify-start")
        self
      end

      def justify_end
        add_class("justify-end")
        self
      end

      def gap(value)
        add_class("gap-#{value}")
        self
      end

      def gap_x(value)
        add_class("gap-x-#{value}")
        self
      end

      def gap_y(value)
        add_class("gap-y-#{value}")
        self
      end

      # Grid
      def grid
        add_class("grid")
        self
      end

      def grid_cols(value)
        add_class("grid-cols-#{value}")
        self
      end

      # Transitions
      def transition(property = nil)
        add_class(property ? "transition-#{property}" : "transition")
        self
      end

      def duration(value)
        add_class("duration-#{value}")
        self
      end

      # Transform
      def scale(value)
        add_class("scale-#{value}")
        self
      end

      def hover(classes)
        classes.split(' ').each do |cls|
          add_class("hover:#{cls}")
        end
        self
      end
      
      def group_hover(classes)
        classes.split(' ').each do |cls|
          add_class("group-hover:#{cls}")
        end
        self
      end

      def focus(classes)
        classes.split(' ').each do |cls|
          add_class("focus:#{cls}")
        end
        self
      end

      # Responsive
      def sm(classes)
        classes.split(' ').each do |cls|
          add_class("sm:#{cls}")
        end
        self
      end

      def md(classes)
        classes.split(' ').each do |cls|
          add_class("md:#{cls}")
        end
        self
      end

      def lg(classes)
        classes.split(' ').each do |cls|
          add_class("lg:#{cls}")
        end
        self
      end

      def xl(classes)
        classes.split(' ').each do |cls|
          add_class("xl:#{cls}")
        end
        self
      end

      # State
      def disabled(value = true)
        @attributes ||= {}
        @attributes[:disabled] = value
        self
      end

      # Cursor
      def cursor(type)
        add_class("cursor-#{type}")
        self
      end

      # Z-index
      def z(value)
        add_class("z-#{value}")
        self
      end

      # Line height
      def leading(value)
        add_class("leading-#{value}")
        self
      end

      # Letter spacing
      def tracking(value)
        add_class("tracking-#{value}")
        self
      end

      # Text decoration
      def line_through
        add_class("line-through")
        self
      end

      def underline
        add_class("underline")
        self
      end

      def no_underline
        add_class("no-underline")
        self
      end

      # Text alignment
      def text_center
        add_class("text-center")
        self
      end

      def text_left
        add_class("text-left")
        self
      end

      def text_right(&block)
        add_class("text-right")
        @block = block if block_given?
        self
      end

      # Backgrounds
      def bg_gradient_to(direction)
        add_class("bg-gradient-to-#{direction}")
        self
      end

      def from(color)
        add_class("from-#{color}")
        self
      end

      def to(color)
        add_class("to-#{color}")
        self
      end

      def via(color)
        add_class("via-#{color}")
        self
      end

      # Widths
      def w_full
        add_class("w-full")
        self
      end

      def h_full
        add_class("h-full")
        self
      end

      # Aspect ratio
      def aspect(ratio)
        add_class("aspect-#{ratio}")
        self
      end

      # Object fit
      def object(fit)
        add_class("object-#{fit}")
        self
      end

      # Custom style attribute
      def style(styles)
        @attributes ||= {}
        @attributes[:style] = styles
        self
      end

      # ARIA attributes
      def aria_label(label)
        @attributes ||= {}
        @attributes[:"aria-label"] = label
        self
      end
      
      def aria_hidden(value)
        @attributes ||= {}
        @attributes[:"aria-hidden"] = value
        self
      end

      # Custom Tailwind classes
      def tw(classes)
        add_class(classes)
        self
      end

      private

      def add_class(class_name, &block)
        # For Element class compatibility
        if defined?(@css_classes)
          @css_classes.concat(class_name.split(' '))
        else
          # For other classes, use attributes
          @attributes ||= {}
          @attributes[:class] = [@attributes[:class], class_name].compact.join(" ")
        end
        # If a block is provided, treat it as the element's content block
        @block = block if block_given?
        self
      end
    end
  end
end