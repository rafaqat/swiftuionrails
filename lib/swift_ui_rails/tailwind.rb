# frozen_string_literal: true

# Copyright 2025

require_relative 'security/css_validator'
require_relative 'tailwind/spacing_converter'

module SwiftUIRails
  module Tailwind
    module Modifiers
      # Spacing utilities with SECURITY validation
      %i[px py pt pr pb pl m mx my mt mr mb ml].each do |method|
        define_method method do |value, &block|
          # Convert pixel values to Tailwind spacing scale if needed
          converted_value = if SpacingConverter.pixel_value?(value)
                              SpacingConverter.convert(value)
                            else
                              value
                            end
          safe_class = Security::CSSValidator.safe_spacing_class(method.to_s, converted_value)
          add_class(safe_class, &block)
          self
        end
      end

      # Padding modifier - clean separation from HTML <p> element
      def p(value, &block)
        # Convert pixel values to Tailwind spacing scale if needed
        converted_value = if SpacingConverter.pixel_value?(value)
                            SpacingConverter.convert(value)
                          else
                            value
                          end
        safe_class = Security::CSSValidator.safe_spacing_class('p', converted_value)
        add_class(safe_class, &block)
        self
      end

      # Alias for padding with SECURITY validation
      def padding(value, &block)
        # Convert pixel values to Tailwind spacing scale if needed
        converted_value = if SpacingConverter.pixel_value?(value)
                            SpacingConverter.convert(value)
                          else
                            value
                          end
        safe_class = Security::CSSValidator.safe_spacing_class('p', converted_value)
        add_class(safe_class, &block)
        self
      end

      # Alias for margin with SECURITY validation
      def margin(value, &block)
        # Convert pixel values to Tailwind spacing scale if needed
        converted_value = if SpacingConverter.pixel_value?(value)
                            SpacingConverter.convert(value)
                          else
                            value
                          end
        safe_class = Security::CSSValidator.safe_spacing_class('m', converted_value)
        add_class(safe_class, &block)
        self
      end

      # Width and height
      %i[w h min_w min_h max_w max_h].each do |method|
        define_method method do |value, &block|
          css_method = method.to_s.tr('_', '-')
          add_class("#{css_method}-#{value}", &block)
          self
        end
      end

      # Flexbox
      def flex(value = nil, &block)
        add_class(value ? "flex-#{value}" : 'flex')
        @block = block if block
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

      def text_sm(&block)
        add_class('text-sm', &block)
        self
      end

      def text_xs(&block)
        add_class('text-xs', &block)
        self
      end

      def text_lg(&block)
        add_class('text-lg', &block)
        self
      end

      def text_xl(&block)
        add_class('text-xl', &block)
        self
      end

      def text_2xl(&block)
        add_class('text-2xl', &block)
        self
      end

      def text_3xl(&block)
        add_class('text-3xl', &block)
        self
      end

      def text_4xl(&block)
        add_class('text-4xl', &block)
        self
      end

      def text_5xl(&block)
        add_class('text-5xl', &block)
        self
      end

      def text_6xl(&block)
        add_class('text-6xl', &block)
        self
      end

      def text_7xl(&block)
        add_class('text-7xl', &block)
        self
      end

      def text_8xl(&block)
        add_class('text-8xl', &block)
        self
      end

      def text_9xl(&block)
        add_class('text-9xl', &block)
        self
      end

      def font_weight(weight, &block)
        safe_class = Security::CSSValidator.safe_font_weight_class(weight)
        add_class(safe_class, &block)
        self
      end

      def font_bold(&block)
        add_class('font-bold', &block)
        self
      end

      def font_semibold(&block)
        add_class('font-semibold', &block)
        self
      end

      def font_medium(&block)
        add_class('font-medium', &block)
        self
      end

      def font_normal(&block)
        add_class('font-normal', &block)
        self
      end

      def font_light(&block)
        add_class('font-light', &block)
        self
      end

      def leading_tight(&block)
        add_class('leading-tight', &block)
        self
      end

      def leading_relaxed(&block)
        add_class('leading-relaxed', &block)
        self
      end

      def leading_normal(&block)
        add_class('leading-normal', &block)
        self
      end

      def font_size(size, &block)
        safe_class = Security::CSSValidator.safe_text_size_class(size)
        add_class(safe_class, &block)
        self
      end

      # Convenience methods for common margin utilities
      def mb(value, &block)
        safe_class = Security::CSSValidator.safe_spacing_class('mb', value)
        add_class(safe_class, &block)
        self
      end

      def mt(value, &block)
        safe_class = Security::CSSValidator.safe_spacing_class('mt', value)
        add_class(safe_class, &block)
        self
      end

      # Borders
      def border(width = nil, &block)
        add_class(width ? "border-#{width}" : 'border', &block)
        self
      end

      def border_t(width = nil, &block)
        add_class(width ? "border-t-#{width}" : 'border-t', &block)
        self
      end

      def border_b(width = nil, &block)
        add_class(width ? "border-b-#{width}" : 'border-b', &block)
        self
      end

      def border_l(width = nil, &block)
        add_class(width ? "border-l-#{width}" : 'border-l', &block)
        self
      end

      def border_r(width = nil, &block)
        add_class(width ? "border-r-#{width}" : 'border-r', &block)
        self
      end

      def border_color(color, shade = nil, &block)
        # Reuse text color validator for border colors
        safe_class = Security::CSSValidator.safe_text_class(color, shade).gsub('text-', 'border-')
        add_class(safe_class, &block)
        self
      end

      def rounded(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_rounded_class(size) : 'rounded'
        add_class(safe_class, &block)
        self
      end

      def rounded_full(&block)
        add_class('rounded-full', &block)
        self
      end

      def rounded_t(size = nil, &block)
        safe_class = size ? "rounded-t-#{size}" : 'rounded-t'
        add_class(safe_class, &block)
        self
      end

      def rounded_b(size = nil, &block)
        safe_class = size ? "rounded-b-#{size}" : 'rounded-b'
        add_class(safe_class, &block)
        self
      end

      def rounded_l(size = nil, &block)
        safe_class = size ? "rounded-l-#{size}" : 'rounded-l'
        add_class(safe_class, &block)
        self
      end

      def rounded_r(size = nil, &block)
        safe_class = size ? "rounded-r-#{size}" : 'rounded-r'
        add_class(safe_class, &block)
        self
      end

      def corner_radius(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_rounded_class(size) : 'rounded'
        add_class(safe_class, &block)
        self
      end

      # Effects with SECURITY validation
      def shadow(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_shadow_class(size) : 'shadow'
        add_class(safe_class, &block)
        self
      end

      def hover_shadow(size)
        add_class("hover:shadow-#{size}")
        self
      end

      def opacity(value, &block)
        add_class("opacity-#{value}", &block)
        self
      end

      def bg_opacity(value, &block)
        add_class("bg-opacity-#{value}", &block)
        self
      end

      def text_opacity(value, &block)
        add_class("text-opacity-#{value}", &block)
        self
      end

      # Overflow
      def overflow(value, &block)
        add_class("overflow-#{value}", &block)
        self
      end

      def overflow_x(value, &block)
        add_class("overflow-x-#{value}", &block)
        self
      end

      def overflow_y(value, &block)
        add_class("overflow-y-#{value}", &block)
        self
      end

      # Position
      def relative(&block)
        add_class('relative')
        @block = block if block
        self
      end

      def absolute(&block)
        add_class('absolute')
        @block = block if block
        self
      end

      def fixed(&block)
        add_class('fixed')
        @block = block if block
        self
      end

      def sticky(&block)
        add_class('sticky')
        @block = block if block
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

      def top(value, &block)
        add_class("top-#{value}", &block)
        self
      end

      def right(value, &block)
        add_class("right-#{value}", &block)
        self
      end

      def bottom(value, &block)
        add_class("bottom-#{value}", &block)
        self
      end

      def left(value, &block)
        add_class("left-#{value}", &block)
        self
      end

      # Display
      def hidden(&block)
        add_class('hidden', &block)
        self
      end

      def group(&block)
        add_class('group')
        @block = block if block
        self
      end

      def block(&block)
        add_class('block')
        @block = block if block
        self
      end

      def inline(&block)
        add_class('inline')
        @block = block if block
        self
      end

      def inline_block(&block)
        add_class('inline-block', &block)
        self
      end

      def inline_flex(&block)
        add_class('inline-flex', &block)
        self
      end

      def flex_1(&block)
        add_class('flex-1', &block)
        self
      end

      def flex_wrap(&block)
        add_class('flex-wrap', &block)
        self
      end

      def flex_col(&block)
        add_class('flex-col', &block)
        self
      end

      def flex_row(&block)
        add_class('flex-row', &block)
        self
      end

      def items_center(&block)
        add_class('items-center', &block)
        self
      end

      def items_start(&block)
        add_class('items-start', &block)
        self
      end

      def items_end(&block)
        add_class('items-end', &block)
        self
      end

      def justify_center(&block)
        add_class('justify-center', &block)
        self
      end

      def justify_between(&block)
        add_class('justify-between')
        @block = block if block
        self
      end

      def justify_start(&block)
        add_class('justify-start', &block)
        self
      end

      def justify_end(&block)
        add_class('justify-end', &block)
        self
      end

      def gap(value, &block)
        add_class("gap-#{value}", &block)
        self
      end

      def gap_x(value, &block)
        add_class("gap-x-#{value}", &block)
        self
      end

      def gap_y(value, &block)
        add_class("gap-y-#{value}", &block)
        self
      end


      # Grid utilities
      def grid(&block)
        add_class('grid', &block)
        self
      end

      def cols(value, &block)
        add_class("grid-cols-#{value}", &block)
        self
      end

      def md_cols(value, &block)
        add_class("md:grid-cols-#{value}", &block)
        self
      end

      def lg_cols(value, &block)
        add_class("lg:grid-cols-#{value}", &block)
        self
      end

      def xl_cols(value, &block)
        add_class("xl:grid-cols-#{value}", &block)
        self
      end

      def flex_shrink(value = nil, &block)
        add_class(value ? "shrink-#{value}" : 'shrink', &block)
        self
      end

      def grid_class(&block)
        add_class('grid', &block)
        self
      end

      def grid_cols(value, &block)
        add_class("grid-cols-#{value}", &block)
        self
      end

      # Transitions
      def transition(property = nil, &block)
        add_class(property ? "transition-#{property}" : 'transition', &block)
        self
      end

      def transition_all(&block)
        add_class('transition-all', &block)
        self
      end

      def transition_colors(&block)
        add_class('transition-colors', &block)
        self
      end

      def duration(value, &block)
        add_class("duration-#{value}", &block)
        self
      end

      # Transform
      def transform(value = nil, &block)
        if value
          add_class(value, &block)
        else
          add_class('transform', &block)
        end
        self
      end

      def scale(value, &block)
        add_class("scale-#{value}", &block)
        self
      end

      def hover_scale(value, &block)
        add_class("hover:scale-#{value} transition-transform", &block)
        self
      end

      def hover(classes)
        classes.split.each do |cls|
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
        classes.split.each do |cls|
          add_class("group-hover:#{cls}")
        end
        self
      end

      def group_hover_opacity(value)
        add_class("group-hover:opacity-#{value}")
        self
      end

      def focus(classes)
        classes.split.each do |cls|
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
        add_class(width ? "focus:ring-#{width}" : 'focus:ring')
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
        add_class('focus:outline-none')
        self
      end

      # Responsive
      def sm(classes)
        classes.split.each do |cls|
          add_class("sm:#{cls}")
        end
        self
      end

      def md(classes)
        classes.split.each do |cls|
          add_class("md:#{cls}")
        end
        self
      end

      def lg(classes)
        classes.split.each do |cls|
          add_class("lg:#{cls}")
        end
        self
      end

      def xl(classes)
        classes.split.each do |cls|
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
        add_class('cursor-pointer')
        self
      end

      def cursor_not_allowed
        add_class('cursor-not-allowed')
        self
      end

      def pointer_events_none(&block)
        add_class('pointer-events-none', &block)
        self
      end

      def pointer_events_auto
        add_class('pointer-events-auto')
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
        add_class('line-through')
        self
      end

      def underline
        add_class('underline')
        self
      end

      def line_clamp(lines = 1, &block)
        add_class("line-clamp-#{lines}", &block)
        self
      end

      def no_underline
        add_class('no-underline')
        self
      end

      # Text alignment
      def text_center(&block)
        add_class('text-center', &block)
        self
      end

      def text_left(&block)
        add_class('text-left', &block)
        self
      end

      def text_right(&block)
        add_class('text-right', &block)
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
        add_class('bg-gradient-to-r')
        self
      end

      def bg_gradient_to_l
        add_class('bg-gradient-to-l')
        self
      end

      def bg_gradient_to_t
        add_class('bg-gradient-to-t')
        self
      end

      def bg_gradient_to_b
        add_class('bg-gradient-to-b')
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
        add_class('w-full')
        self
      end

      def full_width
        add_class('w-full')
        self
      end

      def h_full
        add_class('h-full')
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
        @attributes[:'aria-label'] = label
        self
      end

      def aria_hidden(value)
        @attributes ||= {}
        @attributes[:'aria-hidden'] = value
        self
      end

      # Button styles (higher-level abstractions)
      def button_style(style)
        case style
        when :primary
          add_class('bg-blue-600 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2')
        when :secondary
          add_class('bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2')
        when :danger
          add_class('bg-red-600 text-white hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2')
        when :ghost
          add_class('text-gray-700 hover:bg-gray-100 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2')
        end
        self
      end

      def button_size(size)
        case size
        when :sm
          add_class('px-3 py-1.5 text-sm')
        when :md
          add_class('px-4 py-2 text-base')
        when :lg
          add_class('px-6 py-3 text-lg')
        end
        self
      end

      # Custom Tailwind classes
      def tw(classes)
        add_class(classes)
        self
      end


      # Size methods
      def w(value = nil)
        add_class(value ? "w-#{value}" : 'w')
        self
      end

      def width(value = nil)
        add_class(value ? "w-#{value}" : 'w')
        self
      end

      # Temporarily disable h method to avoid Rails conflict
      # def h(value = nil)
      #   add_class(value ? "h-#{value}" : 'h')
      #   self
      # end

      def height(value = nil)
        add_class(value ? "h-#{value}" : 'h')
        self
      end

      def min_h(value = nil)
        add_class(value ? "min-h-#{value}" : 'min-h')
        self
      end

      def max_w(value = nil)
        add_class(value ? "max-w-#{value}" : 'max-w')
        self
      end

      def h_full
        add_class('h-full')
        self
      end

      # NOTE: Typography methods removed to avoid conflicts with security-validated methods above

      def leading(value = nil)
        add_class(value ? "leading-#{value}" : 'leading')
        self
      end

      def tracking(value = nil)
        add_class(value ? "tracking-#{value}" : 'tracking')
        self
      end

      def text_align(align = nil)
        add_class(align ? "text-#{align}" : 'text-align')
        self
      end

      # Layout methods
      def space_x(value = nil, &block)
        add_class(value ? "space-x-#{value}" : 'space-x', &block)
        self
      end

      def space_y(value = nil, &block)
        add_class(value ? "space-y-#{value}" : 'space-y', &block)
        self
      end

      def gap(value = nil)
        add_class(value ? "gap-#{value}" : 'gap')
        self
      end

      def grid_cols(value = nil)
        add_class(value ? "grid-cols-#{value}" : 'grid-cols')
        self
      end

      def aspect(ratio = nil)
        add_class(ratio ? "aspect-#{ratio}" : 'aspect')
        self
      end

      def overflow(value = nil)
        add_class(value ? "overflow-#{value}" : 'overflow')
        self
      end

      def object(value = nil)
        add_class(value ? "object-#{value}" : 'object')
        self
      end

      # Interactive states
      def pointer_events_none
        add_class('pointer-events-none')
        self
      end

      def hover_bg(color = nil)
        add_class(color ? "hover:bg-#{color}" : 'hover:bg')
        self
      end

      def hover_shadow(value = nil)
        add_class(value ? "hover:shadow-#{value}" : 'hover:shadow')
        self
      end

      def hover_scale(value = nil)
        add_class(value ? "hover:scale-#{value}" : 'hover:scale')
        self
      end

      def focus_outline_none
        add_class('focus:outline-none')
        self
      end

      def focus_border_color(color)
        add_class("focus:border-#{color}")
        self
      end

      # Utility methods
      def opacity(value = nil)
        add_class(value ? "opacity-#{value}" : 'opacity')
        self
      end

      def duration(value = nil)
        add_class(value ? "duration-#{value}" : 'duration')
        self
      end

      def inset_y(value = nil)
        add_class(value ? "inset-y-#{value}" : 'inset-y')
        self
      end

      def from(color = nil)
        add_class(color ? "from-#{color}" : 'from')
        self
      end

      def to(color = nil)
        add_class(color ? "to-#{color}" : 'to')
        self
      end

      # Object fit utilities
      def object_cover
        add_class('object-cover')
        self
      end

      def object_contain
        add_class('object-contain')
        self
      end

      def object_fill
        add_class('object-fill')
        self
      end

      def object_none
        add_class('object-none')
        self
      end

      def object_scale_down
        add_class('object-scale-down')
        self
      end

      # Container utility
      def container(&block)
        add_class('container', &block)
        self
      end

      private

      def add_class(class_name, &block)
        # For Element class compatibility
        if defined?(@css_classes)
          @css_classes.concat(class_name.split)
        else
          # For other classes, use attributes
          @attributes ||= {}
          @attributes[:class] = [@attributes[:class], class_name].compact.join(' ')
        end
        # If a block is provided, treat it as the element's content block
        @block = block if block
        self
      end
    end
  end
end
# Copyright 2025
