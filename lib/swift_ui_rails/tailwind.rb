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

      ##
      # Adds a validated Tailwind CSS padding class to the element.
      # @param value The padding value to apply (e.g., 4, 'md', etc.).
      def padding(value, &block)
        safe_class = Security::CSSValidator.safe_spacing_class('p', value)
        add_class(safe_class, &block)
        self
      end

      ##
      # Adds a validated Tailwind CSS margin class to the element.
      # @param value The margin value to apply, validated for security.
      # @return [self] Returns self for method chaining.
      def margin(value, &block)
        safe_class = Security::CSSValidator.safe_spacing_class('m', value)
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

      ##
      # Adds a Tailwind CSS flexbox class, optionally specifying a flex value.
      # If a block is given, it is stored for later use as content or nested elements.
      # @param [String, nil] value - The flex value to use (e.g., 'row', 'col', '1'), or nil for the default 'flex' class.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds a Tailwind background color class to the element.
      # @param [String] color - The Tailwind color name or value to use for the background.
      def bg(color, &block)
        add_class("bg-#{color}", &block)
        self
      end

      ##
      # Adds a validated Tailwind background color class to the element.
      # Uses security validation to ensure the color and shade are safe.
      # @param [String] color The base color name.
      # @param [String, nil] shade The optional color shade.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds a validated Tailwind CSS text size class to the element.
      # @param [String] size - The desired text size (e.g., 'sm', 'lg', '2xl'). The value is validated for security.
      # @return [self] Returns self for method chaining.
      def text_size(size, &block)
        safe_class = Security::CSSValidator.safe_text_size_class(size)
        add_class(safe_class, &block)
        self
      end

      ##
      # Applies the Tailwind CSS class for small text size.
      # @return [self] Returns self for method chaining.
      def text_sm
        add_class('text-sm')
        self
      end

      ##
      # Applies the Tailwind CSS class for extra small text size.
      # @return [self] Returns self for method chaining.
      def text_xs
        add_class('text-xs')
        self
      end

      ##
      # Applies the Tailwind CSS class for large text size.
      # @return [self] Returns self for method chaining.
      def text_lg
        add_class('text-lg')
        self
      end

      ##
      # Applies the Tailwind CSS class for extra-large text size.
      # @return [self] Returns self for method chaining.
      def text_xl
        add_class('text-xl')
        self
      end

      ##
      # Adds the Tailwind CSS class for extra-extra-large text size.
      # @return [self] Returns self for method chaining.
      def text_2xl
        add_class('text-2xl')
        self
      end

      def font_weight(weight, &block)
        safe_class = Security::CSSValidator.safe_font_weight_class(weight)
        add_class(safe_class, &block)
        self
      end

      ##
      # Adds a Tailwind CSS border class, optionally specifying the border width.
      # @param [String, nil] width - The border width to apply (e.g., '2', '4'). If omitted, applies the default border.
      # @return [self] Returns self for method chaining.
      def border(width = nil)
        add_class(width ? "border-#{width}" : 'border')
        self
      end

      ##
      # Adds a top border class with an optional width to the element.
      # @param [String, nil] width - The width of the top border (e.g., '2', '4'). If omitted, applies the default top border.
      # @return [self] Returns self for method chaining.
      def border_t(width = nil)
        add_class(width ? "border-t-#{width}" : 'border-t')
        self
      end

      ##
      # Adds a bottom border class, optionally specifying the border width.
      # @param [String, nil] width - The width of the bottom border (e.g., '2', '4'). If omitted, applies the default bottom border.
      # @return [self] Returns self for method chaining.
      def border_b(width = nil)
        add_class(width ? "border-b-#{width}" : 'border-b')
        self
      end

      ##
      # Adds a left border class, optionally specifying the border width.
      # @param [String, nil] width - The width of the left border (e.g., '2', '4'). If omitted, applies the default left border.
      # @return [self] Returns self for method chaining.
      def border_l(width = nil)
        add_class(width ? "border-l-#{width}" : 'border-l')
        self
      end

      ##
      # Adds a Tailwind CSS right border class, optionally specifying the border width.
      # @param [String, nil] width - The width of the right border (e.g., '2', '4'). If omitted, applies the default right border.
      # @return [self] Returns self for method chaining.
      def border_r(width = nil)
        add_class(width ? "border-r-#{width}" : 'border-r')
        self
      end

      ##
      # Adds a validated Tailwind border color class based on the given color and optional shade.
      # @param [String] color The base color name.
      # @param [String, nil] shade The optional color shade (e.g., '500').
      # @return [self] Returns self for method chaining.
      def border_color(color, shade = nil, &block)
        # Reuse text color validator for border colors
        safe_class = Security::CSSValidator.safe_text_class(color, shade).gsub('text-', 'border-')
        add_class(safe_class, &block)
        self
      end

      ##
      # Adds a Tailwind CSS rounded corner class, optionally with a specific size.
      # If a size is provided, it is validated for safety before being added.
      # @param [String, nil] size - The size of the rounded corners (e.g., 'lg', 'full'). If nil, applies the default 'rounded' class.
      # @return [self] Returns self for method chaining.
      def rounded(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_rounded_class(size) : 'rounded'
        add_class(safe_class, &block)
        self
      end

      ##
      # Applies the Tailwind `rounded-full` class for fully rounded corners.
      # @return [self] Returns self for method chaining.
      def rounded_full(&block)
        add_class('rounded-full', &block)
        self
      end

      ##
      # Adds a Tailwind CSS rounded corner class with optional size validation.
      # If a size is provided, it is validated for safety; otherwise, a default 'rounded' class is used.
      # @param [String, nil] size - The size of the corner radius (e.g., 'md', 'lg'). If nil, uses the default rounded class.
      # @return [self] Returns self for method chaining.
      def corner_radius(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_rounded_class(size) : 'rounded'
        add_class(safe_class, &block)
        self
      end

      ##
      # Adds a Tailwind CSS shadow utility class, validating the shadow size for security.
      # @param [String, nil] size - The shadow size (e.g., 'sm', 'md', 'lg'). If nil, applies the default 'shadow' class.
      # @return [self] Returns self for method chaining.
      def shadow(size = nil, &block)
        safe_class = size ? Security::CSSValidator.safe_shadow_class(size) : 'shadow'
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

      ##
      # Adds the Tailwind `relative` class to set the element's position to relative.
      # Stores the given block for later use as content or nested elements if provided.
      # @return [self] Returns self for method chaining.
      def relative(&block)
        add_class('relative')
        @block = block if block
        self
      end

      ##
      # Adds the Tailwind 'absolute' class to set absolute positioning.
      # Stores the given block for later use if provided.
      # @return [self] Returns self for method chaining.
      def absolute(&block)
        add_class('absolute')
        @block = block if block
        self
      end

      ##
      # Applies the Tailwind 'fixed' class to set the element's position to fixed.
      # Stores the given block for use as content or nested elements.
      # @return [self]
      def fixed(&block)
        add_class('fixed')
        @block = block if block
        self
      end

      ##
      # Adds the Tailwind CSS 'sticky' class to make the element use sticky positioning.
      # If a block is given, it is stored for later use as the element's content or nested elements.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds the Tailwind 'hidden' class to hide the element.
      # @return [self] Returns self for method chaining.
      def hidden
        add_class('hidden')
        self
      end

      ##
      # Adds the 'group' Tailwind CSS class to the element, enabling group-hover and group-focus state styling for child elements.
      # If a block is provided, it is stored for later use as the element's content or nested elements.
      # @return [self] Returns self for method chaining.
      def group(&block)
        add_class('group')
        @block = block if block
        self
      end

      ##
      # Adds the Tailwind 'block' display class to the element.
      # Stores the given block for use as content or nested elements.
      # @return [self] Returns self for method chaining.
      def block(&block)
        add_class('block')
        @block = block if block
        self
      end

      ##
      # Adds the Tailwind CSS 'inline' class to the element.
      # Stores the given block for later use as content or nested elements.
      # @return [self] Returns self for method chaining.
      def inline(&block)
        add_class('inline')
        @block = block if block
        self
      end

      ##
      # Adds the Tailwind CSS 'inline-block' class to the element.
      # @return [self] Returns self for method chaining.
      def inline_block
        add_class('inline-block')
        self
      end

      ##
      # Adds the Tailwind CSS class for inline flex container layout.
      # @return [self] Returns self for method chaining.
      def inline_flex
        add_class('inline-flex')
        self
      end

      ##
      # Adds the Tailwind CSS class for a flex item that grows to fill available space.
      # @return [self] Returns self for method chaining.
      def flex_1
        add_class('flex-1')
        self
      end

      ##
      # Adds the Tailwind CSS class for wrapping flex items within a flex container.
      # @return [self] Returns self for method chaining.
      def flex_wrap
        add_class('flex-wrap')
        self
      end

      ##
      # Applies the Tailwind CSS `flex-col` class to set flex direction to column.
      # @return [self] Returns self for method chaining.
      def flex_col(&block)
        add_class('flex-col', &block)
        self
      end

      ##
      # Adds the Tailwind CSS class for horizontal flex direction to the element.
      # @return [self] Returns self for method chaining.
      def flex_row
        add_class('flex-row')
        self
      end

      ##
      # Adds the Tailwind CSS class for centering flex items along the cross axis.
      # @return [self] Returns self for method chaining.
      def items_center(&block)
        add_class('items-center', &block)
        self
      end

      ##
      # Adds the Tailwind CSS class for aligning flex or grid items to the start of the cross axis.
      # @return [self]
      def items_start
        add_class('items-start')
        self
      end

      ##
      # Adds the Tailwind CSS class for aligning flex items to the end of the cross axis.
      # @return [self]
      def items_end
        add_class('items-end')
        self
      end

      ##
      # Adds the Tailwind CSS class for center justification of flex or grid items.
      # Returns self for method chaining.
      def justify_center(&block)
        add_class('justify-center', &block)
        self
      end

      ##
      # Adds the Tailwind CSS class for distributing flex items with space between them.
      # Stores the given block for nested content if provided.
      # @return [self]
      def justify_between(&block)
        add_class('justify-between')
        @block = block if block
        self
      end

      ##
      # Adds the Tailwind CSS class for start-aligned flex or grid justification.
      # @return [self] Returns self for method chaining.
      def justify_start
        add_class('justify-start')
        self
      end

      ##
      # Adds the Tailwind CSS class for end-aligned flex or grid content.
      # @return [self] Returns self for method chaining.
      def justify_end
        add_class('justify-end')
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

      ##
      # Adds the Tailwind CSS `grid` class to enable grid layout on the element.
      # If a block is given, it is stored for use as nested content.
      # @return [self]
      def grid(&block)
        add_class('grid', &block)
        self
      end

      ##
      # Adds the Tailwind CSS 'grid' class to the element for grid layout.
      # @return [self] Returns self for method chaining.
      def grid_class
        add_class('grid')
        self
      end

      ##
      # Adds a Tailwind CSS class to set the number of grid columns.
      # @param value The number of columns for the grid.
      # @return self
      def grid_cols(value)
        add_class("grid-cols-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS transition class, optionally specifying a transition property.
      # @param [String, nil] property - The transition property to apply (e.g., 'colors', 'opacity'). If nil, applies the generic 'transition' class.
      # @return [self] Returns self for method chaining.
      def transition(property = nil)
        add_class(property ? "transition-#{property}" : 'transition')
        self
      end

      ##
      # Adds the Tailwind CSS class for transitioning all properties.
      # @return [self] Returns self for method chaining.
      def transition_all
        add_class('transition-all')
        self
      end

      ##
      # Adds the Tailwind CSS class for transitioning color properties.
      # @return [self] Returns self for method chaining.
      def transition_colors
        add_class('transition-colors')
        self
      end

      def duration(value)
        add_class("duration-#{value}")
        self
      end

      ##
      # Adds the Tailwind CSS `transform` class to enable CSS transforms on the element.
      # @return [self] Returns self for method chaining.
      def transform
        add_class('transform')
        self
      end

      def scale(value)
        add_class("scale-#{value}")
        self
      end

      ##
      # Adds a Tailwind class for scaling the element on hover with a transition.
      # @param [String, Numeric] value - The scale value to apply on hover.
      # @return [self] Returns self for method chaining.
      def hover_scale(value, &block)
        add_class("hover:scale-#{value} transition-transform", &block)
        self
      end

      ##
      # Adds one or more Tailwind CSS classes that apply on hover state.
      # Each class in the input string is prefixed with 'hover:' and added to the element.
      # @param [String] classes - Space-separated Tailwind class names to apply on hover.
      # @return [self] Returns self for method chaining.
      def hover(classes)
        classes.split.each do |cls|
          add_class("hover:#{cls}")
        end
        self
      end

      ##
      # Adds a Tailwind CSS class for a hover background color.
      # @param [String] color - The background color to apply on hover.
      def hover_bg(color, &block)
        add_class("hover:bg-#{color}", &block)
        self
      end

      ##
      # Adds a Tailwind CSS hover background color class for the specified color.
      # @param [String] color - The background color to apply on hover.
      def hover_background(color, &block)
        add_class("hover:bg-#{color}", &block)
        self
      end

      ##
      # Adds a Tailwind CSS class to set the text color on hover.
      # @param [String] color - The color to apply to the text when hovered.
      def hover_text_color(color)
        add_class("hover:text-#{color}")
        self
      end

      ##
      # Adds one or more classes that apply on group hover state.
      # Each class is prefixed with 'group-hover:' for Tailwind CSS group hover styling.
      # @param [String] classes - Space-separated list of class names to apply on group hover.
      # @return [self] Returns self for method chaining.
      def group_hover(classes)
        classes.split.each do |cls|
          add_class("group-hover:#{cls}")
        end
        self
      end

      ##
      # Adds a Tailwind CSS class to set the opacity on group hover.
      # @param [String, Integer] value - The opacity value to apply when the parent group is hovered.
      def group_hover_opacity(value)
        add_class("group-hover:opacity-#{value}")
        self
      end

      ##
      # Adds one or more Tailwind CSS classes to be applied when the element is in the focus state.
      # @param [String] classes - Space-separated Tailwind class names to apply on focus.
      # @return [self] Returns self for method chaining.
      def focus(classes)
        classes.split.each do |cls|
          add_class("focus:#{cls}")
        end
        self
      end

      ##
      # Adds a Tailwind CSS placeholder color class to the element.
      # @param [String] color - The color name or value for the placeholder text.
      # @return [self] Returns self for method chaining.
      def placeholder(color)
        add_class("placeholder-#{color}")
        self
      end

      ##
      # Adds a Tailwind CSS focus ring class, optionally specifying the ring width.
      # @param [String, nil] width - The width of the focus ring, or nil for the default.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds a Tailwind CSS class to set the border color on focus.
      # @param [String] color - The color to apply to the border when the element is focused.
      # @return [self] Returns self for method chaining.
      def focus_border_color(color)
        add_class("focus:border-#{color}")
        self
      end

      ##
      # Adds the Tailwind class to remove the focus outline from the element.
      # @return [self] Returns self for method chaining.
      def focus_outline_none
        add_class('focus:outline-none')
        self
      end

      ##
      # Adds Tailwind CSS classes with the `sm:` responsive prefix.
      # @param [String] classes - One or more class names to be prefixed for small screens.
      # @return [self] Returns self for method chaining.
      def sm(classes)
        classes.split.each do |cls|
          add_class("sm:#{cls}")
        end
        self
      end

      ##
      # Adds the given Tailwind CSS classes with the `md:` responsive prefix.
      # @param [String] classes - One or more class names separated by whitespace.
      # @return [self] Returns self for method chaining.
      def md(classes)
        classes.split.each do |cls|
          add_class("md:#{cls}")
        end
        self
      end

      ##
      # Adds Tailwind CSS classes with the `lg:` responsive prefix for large screens.
      # @param [String] classes - One or more Tailwind class names to apply at the large breakpoint.
      # @return [self] Returns self for method chaining.
      def lg(classes)
        classes.split.each do |cls|
          add_class("lg:#{cls}")
        end
        self
      end

      ##
      # Adds Tailwind CSS classes with the `xl:` responsive prefix for extra-large screens.
      # @param [String] classes - One or more Tailwind class names to apply at the `xl` breakpoint.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds a Tailwind CSS cursor utility class for the specified cursor type.
      # @param [String] type - The cursor style to apply (e.g., 'pointer', 'not-allowed').
      def cursor(type)
        add_class("cursor-#{type}")
        self
      end

      ##
      # Adds the Tailwind CSS class for a pointer cursor to the element.
      # @return [self] Returns self for method chaining.
      def cursor_pointer
        add_class('cursor-pointer')
        self
      end

      ##
      # Adds the Tailwind CSS class for a "not-allowed" cursor, indicating an unavailable or disabled action.
      # @return [self] Returns self for method chaining.
      def cursor_not_allowed
        add_class('cursor-not-allowed')
        self
      end

      ##
      # Disables pointer events for the element by adding the Tailwind `pointer-events-none` class.
      # @return [self] Returns self for method chaining.
      def pointer_events_none(&block)
        add_class('pointer-events-none', &block)
        self
      end

      ##
      # Enables automatic pointer events on the element by adding the Tailwind `pointer-events-auto` class.
      # @return [self] Returns self for method chaining.
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

      ##
      # Applies the Tailwind CSS `line-through` class to add a line-through text decoration.
      # @return [self] Returns self for method chaining.
      def line_through
        add_class('line-through')
        self
      end

      ##
      # Adds the Tailwind CSS class for underlining text.
      # @return [self] Returns self for method chaining.
      def underline
        add_class('underline')
        self
      end

      ##
      # Limits the number of visible text lines using the Tailwind `line-clamp` utility.
      # @param [Integer] lines The maximum number of lines to display before truncating. Defaults to 1.
      # @return [self] Returns self for method chaining.
      def line_clamp(lines = 1, &block)
        add_class("line-clamp-#{lines}", &block)
        self
      end

      ##
      # Removes underline styling from text by adding the 'no-underline' Tailwind CSS class.
      # @return [self] Returns self for method chaining.
      def no_underline
        add_class('no-underline')
        self
      end

      ##
      # Applies the Tailwind CSS class for center text alignment.
      # @return [self] Returns self for method chaining.
      def text_center
        add_class('text-center')
        self
      end

      ##
      # Applies the Tailwind CSS class for left-aligned text.
      # @return [self] Returns self for method chaining.
      def text_left
        add_class('text-left')
        self
      end

      ##
      # Applies the Tailwind CSS class for right-aligned text.
      # Stores an optional content block for later use.
      # @return [self] Returns self for method chaining.
      def text_right(&block)
        add_class('text-right')
        @block = block if block
        self
      end

      ##
      # Adds a Tailwind CSS text alignment class based on the given alignment value.
      # @param [String] align - The desired text alignment (e.g., 'left', 'center', 'right', 'justify').
      # @return [self] Returns self for method chaining.
      def text_align(align)
        add_class("text-#{align}")
        self
      end

      ##
      # Adds a Tailwind CSS background gradient class for the specified direction.
      # @param [String] direction - The direction of the gradient (e.g., 'r', 'l', 't', 'b').
      # @return [self] Returns self for method chaining.
      def bg_gradient_to(direction)
        add_class("bg-gradient-to-#{direction}")
        self
      end

      ##
      # Adds the Tailwind CSS class for a rightward background gradient.
      # @return [self] Returns self for method chaining.
      def bg_gradient_to_r
        add_class('bg-gradient-to-r')
        self
      end

      ##
      # Applies the Tailwind CSS class for a leftward background gradient direction.
      # @return [self] Returns self for method chaining.
      def bg_gradient_to_l
        add_class('bg-gradient-to-l')
        self
      end

      ##
      # Adds the Tailwind CSS class for a background gradient that transitions to the top.
      # @return [self] Returns self for method chaining.
      def bg_gradient_to_t
        add_class('bg-gradient-to-t')
        self
      end

      ##
      # Adds the Tailwind CSS class for a background gradient transitioning to the bottom.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds the Tailwind CSS class for full width to the element.
      # @return [self] Returns self for method chaining.
      def w_full
        add_class('w-full')
        self
      end

      ##
      # Adds the Tailwind CSS class for full width to the element.
      # @return [self] Returns self for method chaining.
      def full_width
        add_class('w-full')
        self
      end

      ##
      # Adds the Tailwind CSS class for full height to the element.
      # @return [self]
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

      ##
      # Sets the ARIA label attribute for accessibility.
      # @param [String] label - The text to use as the ARIA label.
      # @return [self] Returns self for method chaining.
      def aria_label(label)
        @attributes ||= {}
        @attributes[:'aria-label'] = label
        self
      end

      ##
      # Sets the 'aria-hidden' attribute to control the element's visibility to assistive technologies.
      # @param value The value to assign to the 'aria-hidden' attribute.
      def aria_hidden(value)
        @attributes ||= {}
        @attributes[:'aria-hidden'] = value
        self
      end

      ##
      # Applies a predefined set of Tailwind CSS classes for common button styles.
      # @param [Symbol] style - The button style to apply (:primary, :secondary, :danger, or :ghost).
      # @return [self] Returns self for method chaining.
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

      ##
      # Applies predefined Tailwind CSS classes for button padding and text size based on the specified size symbol.
      # @param [Symbol] size - The button size, accepted values are :sm, :md, or :lg.
      # @return [self] Returns self for method chaining.
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

      ##
      # Adds a Tailwind CSS padding class with the specified value, or the base 'p' class if no value is given.
      # @param [String, nil] value - The padding size to apply (e.g., '4', '8'). If omitted, applies the default 'p' class.
      # @return [self] Returns self for method chaining.
      def p(value = nil)
        add_class(value ? "p-#{value}" : 'p')
        self
      end

      ##
      # Adds a Tailwind CSS horizontal padding class to the element.
      # If a value is provided, uses `px-{value}`; otherwise, uses `px`.
      # @param [String, Integer, nil] value - The horizontal padding value to apply.
      def px(value = nil)
        add_class(value ? "px-#{value}" : 'px')
        self
      end

      ##
      # Adds a Tailwind CSS class for vertical padding to the element.
      # If a value is provided, uses `py-{value}`; otherwise, uses `py`.
      # @param [String, nil] value The padding size to apply vertically.
      def py(value = nil)
        add_class(value ? "py-#{value}" : 'py')
        self
      end

      ##
      # Adds a Tailwind CSS margin-top class to the element.
      # If a value is provided, uses `mt-{value}`; otherwise, uses `mt`. Returns self for chaining.
      def mt(value = nil)
        add_class(value ? "mt-#{value}" : 'mt')
        self
      end

      ##
      # Adds a Tailwind CSS margin-bottom class to the element.
      # If a value is provided, uses `mb-{value}`; otherwise, uses `mb`.
      # @param [String, nil] value - The margin-bottom value to apply (e.g., '4', '8').
      def mb(value = nil)
        add_class(value ? "mb-#{value}" : 'mb')
        self
      end

      ##
      # Adds a Tailwind CSS left margin class to the element.
      # If a value is provided, uses `ml-{value}`; otherwise, uses `ml`.
      # @param [String, nil] value The margin size (e.g., '4', 'auto').
      def ml(value = nil)
        add_class(value ? "ml-#{value}" : 'ml')
        self
      end

      ##
      # Adds a Tailwind CSS right margin class to the element.
      # If a value is provided, uses `mr-{value}`; otherwise, uses `mr`.
      # @param [String, nil] value - The margin size to apply, or nil for default.
      # @return [self]
      def mr(value = nil)
        add_class(value ? "mr-#{value}" : 'mr')
        self
      end

      ##
      # Adds a Tailwind CSS horizontal margin class to the element.
      # If a value is provided, uses `mx-{value}`; otherwise, uses `mx`.
      # @param [String, nil] value The margin size to apply horizontally.
      def mx(value = nil)
        add_class(value ? "mx-#{value}" : 'mx')
        self
      end

      ##
      # Adds a Tailwind CSS class for vertical margin (`my-{value}`) or `my` if no value is given.
      # @param [String, nil] value - The margin size to apply vertically.
      def my(value = nil)
        add_class(value ? "my-#{value}" : 'my')
        self
      end

      ##
      # Adds a Tailwind CSS left padding class to the element.
      # If a value is provided, uses `pl-{value}`; otherwise, uses `pl`.
      def pl(value = nil)
        add_class(value ? "pl-#{value}" : 'pl')
        self
      end

      ##
      # Adds a Tailwind CSS class for right padding to the element.
      # If a value is provided, uses `pr-{value}`; otherwise, uses `pr`.
      # @param [String, nil] value The padding size (e.g., '4', '8'). If nil, applies the base 'pr' class.
      # @return [self] Returns self for method chaining.
      def pr(value = nil)
        add_class(value ? "pr-#{value}" : 'pr')
        self
      end

      ##
      # Adds a Tailwind CSS width class to the element.
      # If a value is provided, uses the format `w-{value}`; otherwise, adds the `w` class for default width.
      # @param [String, nil] value - The width value to apply (e.g., 'full', '1/2', '64').
      def w(value = nil)
        add_class(value ? "w-#{value}" : 'w')
        self
      end

      ##
      # Adds a Tailwind CSS height utility class to the element.
      # If a value is provided, uses the format `h-{value}`; otherwise, adds the base `h` class.
      # @param [String, nil] value - The height value to use in the class, or nil for the base class.
      # @return [self]
      def h(value = nil)
        add_class(value ? "h-#{value}" : 'h')
        self
      end

      ##
      # Adds a Tailwind CSS minimum height utility class to the element.
      # If a value is provided, uses `min-h-{value}`; otherwise, uses `min-h`.
      # @param [String, nil] value The minimum height value to apply (e.g., 'full', 'screen', '0', etc.).
      def min_h(value = nil)
        add_class(value ? "min-h-#{value}" : 'min-h')
        self
      end

      ##
      # Adds a Tailwind CSS maximum width class to the element.
      # If a value is provided, uses `max-w-{value}`; otherwise, uses `max-w`.
      # @param [String, nil] value - The maximum width value (e.g., 'sm', 'md', 'lg'), or nil for the base class.
      # @return [self]
      def max_w(value = nil)
        add_class(value ? "max-w-#{value}" : 'max-w')
        self
      end

      ##
      # Adds the Tailwind CSS class for full height to the element.
      # @return [self]
      def h_full
        add_class('h-full')
        self
      end

      # Typography methods
      def text_size(size)
        add_class("text-#{size}")
        self
      end

      def text_color(color)
        add_class("text-#{color}")
        self
      end

      ##
      # Adds a Tailwind CSS font weight class based on the given weight.
      # @param [String, Symbol] weight - The font weight value (e.g., 'bold', 'medium', 'light').
      def font_weight(weight)
        add_class("font-#{weight}")
        self
      end

      ##
      # Adds a Tailwind CSS line-height utility class to the element.
      # If a value is provided, uses `leading-{value}`; otherwise, uses `leading`.
      # @param [String, nil] value - The line-height value to apply (e.g., 'tight', 'loose', 'none').
      def leading(value = nil)
        add_class(value ? "leading-#{value}" : 'leading')
        self
      end

      ##
      # Adds a Tailwind CSS letter-spacing class to the element.
      # If a value is provided, uses `tracking-{value}`; otherwise, uses `tracking`.
      # @param [String, nil] value The letter-spacing value to apply (e.g., 'wide', 'tight').
      def tracking(value = nil)
        add_class(value ? "tracking-#{value}" : 'tracking')
        self
      end

      ##
      # Adds a text alignment class based on the given alignment value.
      # @param [String, nil] align - The alignment value (e.g., 'left', 'center', 'right'). If nil, adds the 'text-align' class.
      # @return [self] Returns self for method chaining.
      def text_align(align = nil)
        add_class(align ? "text-#{align}" : 'text-align')
        self
      end

      ##
      # Adds a horizontal spacing utility class for child elements.
      # @param [String, nil] value - The spacing value to apply (e.g., '4' for 'space-x-4'). If nil, applies the base 'space-x' class.
      # @return [self] Returns self for method chaining.
      def space_x(value = nil)
        add_class(value ? "space-x-#{value}" : 'space-x')
        self
      end

      ##
      # Adds a vertical spacing utility class to the element.
      # If a value is provided, uses `space-y-{value}`; otherwise, uses `space-y`.
      # @param [String, nil] value - The spacing value to apply vertically.
      def space_y(value = nil)
        add_class(value ? "space-y-#{value}" : 'space-y')
        self
      end

      ##
      # Adds a Tailwind CSS gap utility class to set the spacing between grid or flex items.
      # @param [String, nil] value - The gap size (e.g., '4', 'px'). If omitted, applies the default 'gap' class.
      # @return [self] Returns self for method chaining.
      def gap(value = nil)
        add_class(value ? "gap-#{value}" : 'gap')
        self
      end

      ##
      # Adds a Tailwind CSS grid column class to the element.
      # If a value is provided, uses `grid-cols-{value}`; otherwise, uses `grid-cols`.
      # @param [String, Integer, nil] value - The number of grid columns or a custom grid column value.
      def grid_cols(value = nil)
        add_class(value ? "grid-cols-#{value}" : 'grid-cols')
        self
      end

      ##
      # Adds an aspect ratio utility class.
      # @param [String, nil] ratio - The aspect ratio value to apply. If omitted, applies the base 'aspect' class.
      # @return [self] Returns self for method chaining.
      def aspect(ratio = nil)
        add_class(ratio ? "aspect-#{ratio}" : 'aspect')
        self
      end

      ##
      # Adds an overflow utility class to the element.
      # If a value is provided, adds an `overflow-{value}` class; otherwise, adds `overflow`.
      # @param [String, nil] value The overflow value (e.g., 'auto', 'hidden', 'scroll').
      def overflow(value = nil)
        add_class(value ? "overflow-#{value}" : 'overflow')
        self
      end

      ##
      # Adds a Tailwind CSS object-fit class to the element.
      # If a value is provided, uses "object-{value}"; otherwise, uses "object".
      # @param [String, nil] value - The object-fit value (e.g., 'cover', 'contain').
      def object(value = nil)
        add_class(value ? "object-#{value}" : 'object')
        self
      end

      ##
      # Disables pointer events for the element by adding the Tailwind `pointer-events-none` class.
      # @return [self] Returns self for method chaining.
      def pointer_events_none
        add_class('pointer-events-none')
        self
      end

      ##
      # Adds a Tailwind CSS hover background color class to the element.
      # If a color is provided, applies `hover:bg-{color}`; otherwise, applies `hover:bg`.
      # @param [String, nil] color The background color to apply on hover.
      def hover_bg(color = nil)
        add_class(color ? "hover:bg-#{color}" : 'hover:bg')
        self
      end

      ##
      # Adds a Tailwind CSS hover shadow utility class, optionally specifying the shadow size.
      # @param [String, nil] value - The shadow size to apply on hover (e.g., 'md', 'lg'). If omitted, applies the default hover shadow.
      # @return [self] Returns self for method chaining.
      def hover_shadow(value = nil)
        add_class(value ? "hover:shadow-#{value}" : 'hover:shadow')
        self
      end

      ##
      # Adds a Tailwind CSS class for scaling the element on hover.
      # @param [String, nil] value - The scale value to apply on hover. If omitted, applies the default hover scale class.
      # @return [self] Returns self for method chaining.
      def hover_scale(value = nil)
        add_class(value ? "hover:scale-#{value}" : 'hover:scale')
        self
      end

      ##
      # Adds the Tailwind class to remove the focus outline from the element.
      # @return [self] Returns self for method chaining.
      def focus_outline_none
        add_class('focus:outline-none')
        self
      end

      def focus_border_color(color)
        add_class("focus:border-#{color}")
        self
      end

      ##
      # Adds an opacity utility class to the element.
      # If a value is provided, applies the corresponding Tailwind `opacity-{value}` class; otherwise, applies the default `opacity` class.
      def opacity(value = nil)
        add_class(value ? "opacity-#{value}" : 'opacity')
        self
      end

      ##
      # Adds a Tailwind CSS duration utility class to set transition duration.
      # @param [String, Integer, nil] value - The duration value to use (e.g., 200, '500'), or nil for the default duration.
      # @return [self] Returns self for method chaining.
      def duration(value = nil)
        add_class(value ? "duration-#{value}" : 'duration')
        self
      end

      ##
      # Adds a Tailwind CSS vertical inset class to the element.
      # If a value is provided, uses `inset-y-{value}`; otherwise, uses `inset-y`.
      # @param [String, nil] value - The vertical inset value to apply.
      def inset_y(value = nil)
        add_class(value ? "inset-y-#{value}" : 'inset-y')
        self
      end

      ##
      # Adds a Tailwind CSS gradient color stop class with the specified color.
      # If no color is provided, adds the base 'from' class.
      # @param [String, nil] color - The gradient color stop to use, or nil for the base class.
      # @return [self] Returns self for method chaining.
      def from(color = nil)
        add_class(color ? "from-#{color}" : 'from')
        self
      end

      ##
      # Adds a Tailwind CSS gradient color stop class with the specified color.
      # If no color is provided, adds the base 'to' class.
      # @param [String, nil] color The color to use for the gradient stop, or nil for the default.
      # @return [self] Returns self for method chaining.
      def to(color = nil)
        add_class(color ? "to-#{color}" : 'to')
        self
      end

      private

      ##
      # Adds one or more CSS classes to the element.
      # If a block is provided, it is stored as the element's content block.
      # @param [String] class_name - One or more CSS class names, separated by whitespace.
      # @return [self] Returns self to allow method chaining.
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
