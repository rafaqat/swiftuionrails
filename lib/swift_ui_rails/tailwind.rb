# frozen_string_literal: true
# Copyright 2025

require_relative 'security/css_validator'

module SwiftUIRails
  module Tailwind
    module Modifiers
      # Spacing utilities with SECURITY validation
      %i[p px py pt pr pb pl m mx my mt mr mb ml].each do |method|
        define_method method do |value, &block|
          safe_class = Security::CSSValidator.safe_spacing_class(method.to_s, value)
          add_class(safe_class, &block)
          self
        end
      end
      
      # Alias for padding with SECURITY validation
      def padding(value, &block)
        safe_class = Security::CSSValidator.safe_spacing_class('p', value)
        add_class(safe_class, &block)
        self
      end
      
      # Alias for margin with SECURITY validation
      def margin(value, &block)
        safe_class = Security::CSSValidator.safe_spacing_class('m', value)
        add_class(safe_class, &block)
        self
      end

      # Width and height
      %i[w h min_w min_h max_w max_h].each do |method|
        define_method method do |value, &block|
          css_method = method.to_s.gsub("_", "-")
          add_class("#{css_method}-#{value}", &block)
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
      def bg(color, &block)
        add_class("bg-#{color}", &block)
        self
      end
      
      # SECURITY: Validated color methods
      def background(color, shade = nil, &block)
        safe_class = Security::CSSValidator.safe_bg_class(color, shade)
        add_class(safe_class, &block)
        self
      end

      def text_color(color, shade = nil, &block)
        safe_class = Security::CSSValidator.safe_text_class(color, shade)
        add_class(safe_class, &block)
        self
      end

      # Typography with SECURITY validation
      def text_size(size, &block)
        safe_class = Security::CSSValidator.safe_text_size_class(size)
        add_class(safe_class, &block)
        self
      end

      def text_sm
        add_class("text-sm")
        self
      end

      def text_xs
        add_class("text-xs")
        self
      end

      def text_lg
        add_class("text-lg")
        self
      end

      def text_xl
        add_class("text-xl")
        self
      end

      def text_2xl
        add_class("text-2xl")
        self
      end

      def font_weight(weight, &block)
        safe_class = Security::CSSValidator.safe_font_weight_class(weight)
        add_class(safe_class, &block)
        self
      end

      # Borders
      def border(width = nil)
        add_class(width ? "border-#{width}" : "border")
        self
      end

      def border_t(width = nil)
        add_class(width ? "border-t-#{width}" : "border-t")
        self
      end

      def border_b(width = nil)
        add_class(width ? "border-b-#{width}" : "border-b")
        self
      end

      def border_l(width = nil)
        add_class(width ? "border-l-#{width}" : "border-l")
        self
      end

      def border_r(width = nil)
        add_class(width ? "border-r-#{width}" : "border-r")
        self
      end

      def border_color(color, shade = nil, &block)
        # Reuse text color validator for border colors
        safe_class = Security::CSSValidator.safe_text_class(color, shade).gsub('text-', 'border-')
        add_class(safe_class, &block)
        self
      end

      def rounded(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_rounded_class(size) : "rounded"
        add_class(safe_class, &block)
        self
      end

      def rounded_full(&block)
        add_class("rounded-full", &block)
        self
      end
      
      def corner_radius(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_rounded_class(size) : "rounded"
        add_class(safe_class, &block)
        self
      end

      # Effects with SECURITY validation
      def shadow(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_shadow_class(size) : "shadow"
        add_class(safe_class, &block)
        self
      end

      def hover_shadow(size)
        add_class("hover:shadow-#{size}")
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

      def inset(value, &block)
        add_class("inset-#{value}", &block)
        self
      end

      def inset_x(value)
        add_class("inset-x-#{value}")
        self
      end

      def inset_y(value, &block)
        add_class("inset-y-#{value}", &block)
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

      def left(value, &block)
        add_class("left-#{value}", &block)
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
      
      def inline_flex
        add_class("inline-flex")
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

      def flex_col(&block)
        add_class("flex-col", &block)
        self
      end

      def flex_row
        add_class("flex-row")
        self
      end

      def items_center(&block)
        add_class("items-center", &block)
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

      def justify_center(&block)
        add_class("justify-center", &block)
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

      def gap(value, &block)
        add_class("gap-#{value}", &block)
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

      def space_x(value)
        add_class("space-x-#{value}")
        self
      end

      def space_y(value, &block)
        add_class("space-y-#{value}", &block)
        self
      end

      # Grid utilities
      def grid(&block)
        add_class("grid", &block)
        self
      end
      
      def grid_class
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

      def transition_all
        add_class("transition-all")
        self
      end

      def transition_colors
        add_class("transition-colors")
        self
      end

      def duration(value)
        add_class("duration-#{value}")
        self
      end

      # Transform
      def transform
        add_class("transform")
        self
      end

      def scale(value)
        add_class("scale-#{value}")
        self
      end

      def hover_scale(value, &block)
        add_class("hover:scale-#{value} transition-transform", &block)
        self
      end

      def hover(classes)
        classes.split(' ').each do |cls|
          add_class("hover:#{cls}")
        end
        self
      end

      def hover_bg(color, &block)
        add_class("hover:bg-#{color}", &block)
        self
      end
      
      def hover_background(color, &block)
        add_class("hover:bg-#{color}", &block)
        self
      end

      def hover_text_color(color)
        add_class("hover:text-#{color}")
        self
      end
      
      def group_hover(classes)
        classes.split(' ').each do |cls|
          add_class("group-hover:#{cls}")
        end
        self
      end
      
      def group_hover_opacity(value)
        add_class("group-hover:opacity-#{value}")
        self
      end

      def focus(classes)
        classes.split(' ').each do |cls|
          add_class("focus:#{cls}")
        end
        self
      end

      # Placeholder
      def placeholder(color)
        add_class("placeholder-#{color}")
        self
      end
      
      # Focus utilities
      def focus_ring(width = nil)
        add_class(width ? "focus:ring-#{width}" : "focus:ring")
        self
      end

      def focus_ring_color(color)
        add_class("focus:ring-#{color}")
        self
      end

      def focus_ring_offset(width)
        add_class("focus:ring-offset-#{width}")
        self
      end

      def focus_ring_offset_color(color)
        add_class("focus:ring-offset-#{color}")
        self
      end

      def focus_border_color(color)
        add_class("focus:border-#{color}")
        self
      end

      def focus_outline_none
        add_class("focus:outline-none")
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

      # Cursor and pointer events
      def cursor(type)
        add_class("cursor-#{type}")
        self
      end

      def cursor_pointer
        add_class("cursor-pointer")
        self
      end
      
      def cursor_not_allowed
        add_class("cursor-not-allowed")
        self
      end

      def pointer_events_none(&block)
        add_class("pointer-events-none", &block)
        self
      end

      def pointer_events_auto
        add_class("pointer-events-auto")
        self
      end

      # Z-index
      def z(value)
        add_class("z-#{value}")
        self
      end

      # Line height
      def leading(value, &block)
        add_class("leading-#{value}", &block)
        self
      end

      # Letter spacing
      def tracking(value, &block)
        add_class("tracking-#{value}", &block)
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
      
      def line_clamp(lines = 1, &block)
        add_class("line-clamp-#{lines}", &block)
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
      
      def text_align(align)
        add_class("text-#{align}")
        self
      end

      # Backgrounds and gradients
      def bg_gradient_to(direction)
        add_class("bg-gradient-to-#{direction}")
        self
      end

      def bg_gradient_to_r
        add_class("bg-gradient-to-r")
        self
      end

      def bg_gradient_to_l
        add_class("bg-gradient-to-l")
        self
      end

      def bg_gradient_to_t
        add_class("bg-gradient-to-t")
        self
      end

      def bg_gradient_to_b
        add_class("bg-gradient-to-b")
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
      
      def full_width
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

      # Button styles (higher-level abstractions)
      def button_style(style)
        case style
        when :primary
          add_class("bg-blue-600 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2")
        when :secondary  
          add_class("bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2")
        when :danger
          add_class("bg-red-600 text-white hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2")
        when :ghost
          add_class("text-gray-700 hover:bg-gray-100 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2")
        end
        self
      end
      
      def button_size(size)
        case size
        when :sm
          add_class("px-3 py-1.5 text-sm")
        when :md
          add_class("px-4 py-2 text-base")
        when :lg
          add_class("px-6 py-3 text-lg")
        end
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
# Copyright 2025
