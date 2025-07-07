# frozen_string_literal: true

# Copyright 2025
module SwiftUIDSL
  module Tailwind
    # Tailwind-specific modifiers for SwiftUI DSL
    module Modifiers
      ##
      # Adds a Tailwind padding utility class with the specified value.
      # @param value The padding size to apply (e.g., 4, 'md', etc.).
      # @return [self] Returns self for method chaining.
      def p(value)
        add_class("p-#{value}")
        self
      end

      ##
      # Adds a horizontal padding class with the specified value to the component.
      # @param value The Tailwind padding value to apply on the x-axis (left and right).
      # @return [self] Returns self for method chaining.
      def px(value)
        add_class("px-#{value}")
        self
      end

      ##
      # Adds a vertical padding utility class with the specified value.
      # @param [String, Integer] value - The Tailwind padding value to apply for top and bottom (e.g., 4, '2.5').
      # @return [self] Returns self for method chaining.
      def py(value)
        add_class("py-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS padding-top class with the specified value to the component.
      # @param value The padding-top value to use in the Tailwind class (e.g., 4 for "pt-4").
      # @return [self] Returns self to allow method chaining.
      def pt(value)
        add_class("pt-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class for right padding with the specified value.
      # @param [String, Integer] value - The padding value to apply on the right side.
      # @return [self] Returns self to allow method chaining.
      def pr(value)
        add_class("pr-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS padding-bottom class with the specified value to the component.
      # @param [String, Integer] value - The padding-bottom value to use (e.g., 4, '8', 'px').
      # @return [self] Returns self for method chaining.
      def pb(value)
        add_class("pb-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS left padding class with the specified value to the component.
      # @param value The padding value to apply (e.g., 4, '2.5', 'px').
      def pl(value)
        add_class("pl-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS margin utility class with the specified value to the component.
      # @param [String, Integer] value - The margin value to use in the class (e.g., 4, 'auto').
      def m(value)
        add_class("m-#{value}")
        self
      end

      ##
      # Adds a horizontal margin utility class with the specified value.
      # @param value The margin value to use in the Tailwind `mx-{value}` class.
      # @return [self] Returns self to allow method chaining.
      def mx(value)
        add_class("mx-#{value}")
        self
      end

      ##
      # Adds a vertical margin utility class with the specified value.
      # @param value The Tailwind CSS margin value to apply for top and bottom (e.g., 4, 'auto').
      # @return [self] Returns self for method chaining.
      def my(value)
        add_class("my-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS top margin class with the specified value to the component.
      # @param value The margin size to apply (e.g., 2, 4, 'auto').
      # @return [self] Returns self to allow method chaining.
      def mt(value)
        add_class("mt-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS right margin class with the specified value to the component.
      # @param value The margin value to apply (e.g., 2, 4, 'auto').
      # @return [self] Returns self to allow method chaining.
      def mr(value)
        add_class("mr-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS margin-bottom class with the specified value to the component.
      # @param value The margin-bottom value to use in the Tailwind class (e.g., 4 for "mb-4").
      # @return [self] Returns self to allow method chaining.
      def mb(value)
        add_class("mb-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS left margin class with the specified value to the component.
      # @param value The margin value to apply (e.g., 4, 'auto').
      def ml(value)
        add_class("ml-#{value}")
        self
      end

      ##
      # Adds a Tailwind width utility class with the specified value to the component.
      # @param value The width value to use in the Tailwind class (e.g., 'full', '1/2', '64').
      def w(value)
        add_class("w-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS height utility class with the specified value to the component.
      # @param [String, Integer] value - The height value to use in the Tailwind class (e.g., 4, 'full', 'screen').
      # @return [self] Returns self to allow method chaining.
      def h(value)
        add_class("h-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS minimum width class with the specified value to the component.
      # @param value The minimum width value to use in the Tailwind class (e.g., 'full', '0', 'screen').
      def min_w(value)
        add_class("min-w-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS minimum height class with the specified value to the component.
      # @param value The minimum height value to use in the Tailwind class (e.g., 'full', 'screen', '0', '16').
      # @return [self] Returns self to allow method chaining.
      def min_h(value)
        add_class("min-h-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS maximum width class with the specified value to the component.
      # @param [String, Integer] value - The maximum width value to use in the Tailwind class (e.g., 'sm', 'md', 'lg', 'full', or a numeric value).
      # @return [self] Returns self to allow method chaining.
      def max_w(value)
        add_class("max-w-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class to set the maximum height of the component.
      # @param value [String, Numeric] The maximum height value to use in the Tailwind class (e.g., 'full', '64', etc.).
      # @return [self] Returns self for method chaining.
      def max_h(value)
        add_class("max-h-#{value}")
        self
      end

      ##
      # Adds a Tailwind flexbox utility class to the component.
      # If a value is provided, adds a specific flex utility (e.g., "flex-row"); otherwise, adds the base "flex" class.
      # @param [String, nil] value - Optional flex utility value to append to "flex-".
      # @return [self] Returns self for method chaining.
      def flex(value = nil)
        add_class(value ? "flex-#{value}" : 'flex')
        self
      end

      ##
      # Adds the Tailwind CSS 'flex-col' class to set flex direction to column.
      # @return [self] Returns self for method chaining.
      def flex_col
        add_class('flex-col')
        self
      end

      ##
      # Adds the Tailwind CSS 'flex-row' class to the component, setting flex direction to row.
      # @return [self] Returns self to allow method chaining.
      def flex_row
        add_class('flex-row')
        self
      end

      ##
      # Adds a Tailwind CSS flexbox alignment class for aligning items along the cross axis.
      # @param value [String, Symbol, Integer] The alignment value (e.g., 'center', 'start', 'end', 'baseline', etc.).
      # @return [self] Returns self to allow method chaining.
      def items(value)
        add_class("items-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS justify-content class with the specified value to the component.
      # @param [String] value - The justify-content value (e.g., 'center', 'between', 'end').
      # @return [self] Returns self to allow method chaining.
      def justify(value)
        add_class("justify-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS gap utility class with the specified value to the component.
      # @param [String, Integer] value - The gap size to apply between flex or grid items.
      # @return [self] Returns self for method chaining.
      def gap(value)
        add_class("gap-#{value}")
        self
      end

      ##
      # Adds a Tailwind horizontal gap utility class with the specified value to the component.
      # @param [String, Integer] value - The gap size to apply between columns.
      def gap_x(value)
        add_class("gap-x-#{value}")
        self
      end

      ##
      # Adds a vertical gap utility class with the specified value to the component.
      # @param [String, Integer] value - The vertical gap size to apply (e.g., 4, '2', 'px').
      # @return [self] Returns self for method chaining.
      def gap_y(value)
        add_class("gap-y-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS grid column count class to the component.
      # @param value [String, Integer] The number of columns for the grid (e.g., 3 for "grid-cols-3").
      # @return [self] Returns self to allow method chaining.
      def grid_cols(value)
        add_class("grid-cols-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS column span class with the specified value to the component.
      # @param [Integer, String] value - The number of columns the element should span.
      def col_span(value)
        add_class("col-span-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS text size class to the component.
      # @param [String, Symbol, Integer] size - The text size to apply (e.g., 'lg', '2xl', 4).
      # @return [self] Returns self for method chaining.
      def text(size)
        add_class("text-#{size}")
        self
      end

      ##
      # Adds a Tailwind CSS font size class with the specified value to the component.
      # @param [String, Symbol, Integer] value - The font size value to use (e.g., "lg", "2xl", 24).
      # @return [self] Returns self to allow method chaining.
      def font_size(value)
        add_class("text-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS font weight class with the specified value to the component.
      # @param [String, Symbol] value - The font weight value (e.g., "bold", "medium", "light").
      # @return [self] Returns self for method chaining.
      def font_weight(value)
        add_class("font-#{value}")
        self
      end

      ##
      # Adds a Tailwind text color class with the specified value to the component.
      # @param value [String] The Tailwind color value (e.g., "red-500").
      # @return [self] Returns self to allow method chaining.
      def text_color(value)
        add_class("text-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS line-height utility class with the specified value to the component.
      # @param value The line-height value to use (e.g., 'tight', 'normal', 'loose', or a numeric value).
      # @return [self] Returns self to allow method chaining.
      def leading(value)
        add_class("leading-#{value}")
        self
      end

      ##
      # Adds a Tailwind tracking (letter-spacing) class with the specified value to the component.
      # @param value The tracking value to use (e.g., 'tight', 'wide', or a numeric value).
      # @return [self] Returns self for method chaining.
      def tracking(value)
        add_class("tracking-#{value}")
        self
      end

      ##
      # Adds a Tailwind background color utility class with the specified color.
      # @param [String] color - The Tailwind color name or value to use for the background.
      def bg(color)
        add_class("bg-#{color}")
        self
      end

      ##
      # Adds a Tailwind background opacity utility class with the specified value.
      # @param [String, Integer] value - The opacity value to apply (e.g., 50 for 'bg-opacity-50').
      # @return [self] Returns self to allow method chaining.
      def bg_opacity(value)
        add_class("bg-opacity-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS border class, optionally specifying the border width.
      # @param [String, nil] width - The border width to apply (e.g., "2" for "border-2"). If omitted, applies the default "border" class.
      # @return [self] Returns self to allow method chaining.
      def border(width = nil)
        add_class(width ? "border-#{width}" : 'border')
        self
      end

      ##
      # Adds a Tailwind CSS border color class with the specified color.
      # @param [String] color - The Tailwind color name or value to use for the border color.
      # @return [self] Returns self to allow method chaining.
      def border_color(color)
        add_class("border-#{color}")
        self
      end

      ##
      # Adds a Tailwind CSS border-radius class to the component.
      # If a size is provided, uses "rounded-{size}"; otherwise, uses "rounded".
      # @param [String, nil] size - Optional size for the border-radius class (e.g., "lg", "md").
      # @return [self] Returns self for method chaining.
      def rounded(size = nil)
        add_class(size ? "rounded-#{size}" : 'rounded')
        self
      end

      ##
      # Adds a Tailwind CSS class for top border radius to the component.
      # If a size is provided, uses "rounded-t-{size}"; otherwise, uses "rounded-t".
      # @param [String, nil] size - Optional size for the top border radius.
      def rounded_t(size = nil)
        add_class(size ? "rounded-t-#{size}" : 'rounded-t')
        self
      end

      ##
      # Adds a Tailwind CSS class for right-side border radius, optionally with a specified size.
      # @param [String, nil] size - The size of the right border radius (e.g., "lg", "md"). If omitted, applies the default right border radius.
      # @return [self] Returns self to allow method chaining.
      def rounded_r(size = nil)
        add_class(size ? "rounded-r-#{size}" : 'rounded-r')
        self
      end

      ##
      # Adds a Tailwind CSS class for rounded bottom corners, optionally specifying the size.
      # @param [String, nil] size - The size of the bottom border radius (e.g., 'lg', 'md'). If nil, applies the default rounded bottom class.
      # @return [self] Returns self to allow method chaining.
      def rounded_b(size = nil)
        add_class(size ? "rounded-b-#{size}" : 'rounded-b')
        self
      end

      ##
      # Adds a Tailwind CSS class for left border radius to the component.
      # @param [String, nil] size - Optional size for the left border radius (e.g., "md", "lg"). If omitted, applies the default left border radius.
      # @return [self] Returns self to allow method chaining.
      def rounded_l(size = nil)
        add_class(size ? "rounded-l-#{size}" : 'rounded-l')
        self
      end

      ##
      # Adds a Tailwind CSS shadow utility class to the component.
      # If a size is provided, uses the corresponding shadow size class (e.g., "shadow-lg"); otherwise, applies the default "shadow" class.
      # @param [String, nil] size - Optional shadow size (e.g., "sm", "md", "lg").
      def shadow(size = nil)
        add_class(size ? "shadow-#{size}" : 'shadow')
        self
      end

      ##
      # Adds an opacity utility class with the specified value to the component.
      # @param [String, Integer] value - The opacity value to apply (e.g., 50 for 'opacity-50').
      # @return [self] Returns self to allow method chaining.
      def opacity(value)
        add_class("opacity-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS blur utility class to the component.
      # @param [String, nil] size - The optional blur size (e.g., "sm", "md", "lg"). If omitted, applies the default blur.
      # @return [self] Returns self for method chaining.
      def blur(size = nil)
        add_class(size ? "blur-#{size}" : 'blur')
        self
      end

      ##
      # Adds a Tailwind CSS scale transform class with the specified value.
      # @param [String, Integer] value - The scale value to apply (e.g., 50, 100, 150).
      # @return [self] Returns self to allow method chaining.
      def scale(value)
        add_class("scale-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS rotation class with the specified value to the component.
      # @param [String, Integer] value - The rotation value to apply (e.g., 45 for 'rotate-45').
      # @return [self] Returns self to allow method chaining.
      def rotate(value)
        add_class("rotate-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS translate-x utility class with the specified value to the component.
      # @param [String, Integer] value - The translation value for the x-axis (e.g., 4, '1/2', 'full').
      # @return [self] Returns self for method chaining.
      def translate_x(value)
        add_class("translate-x-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS translate-y utility class with the specified value to the component.
      # @param [String, Integer] value - The amount to translate along the Y axis.
      def translate_y(value)
        add_class("translate-y-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS transition utility class, optionally specifying a transition property.
      # @param [String, nil] property - The transition property to apply (e.g., "colors", "opacity"). If omitted, applies the generic "transition" class.
      # @return [self] Returns self to allow method chaining.
      def transition(property = nil)
        add_class(property ? "transition-#{property}" : 'transition')
        self
      end

      ##
      # Adds a Tailwind CSS duration class with the specified value to the component.
      # @param [String, Integer] value - The duration value to use in the class (e.g., 300 for "duration-300").
      # @return [self] Returns self to allow method chaining.
      def duration(value)
        add_class("duration-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS easing class for transitions.
      # @param [String] type - The easing type (e.g., 'in', 'out', 'in-out').
      def ease(type)
        add_class("ease-#{type}")
        self
      end

      ##
      # Adds a Tailwind CSS hover state class to the component.
      # If a string is provided as a block, it is prefixed with "hover:" and added to the class attribute.
      # @return [self] Returns self to allow method chaining.
      def hover(&block)
        add_hover_classes(block)
        self
      end

      ##
      # Adds a Tailwind CSS `focus:`-prefixed class to the component.
      # If a string is provided as a block, it is prefixed with `focus:` and added to the class list.
      # @return [self] Returns self to allow method chaining.
      def focus(&block)
        add_focus_classes(block)
        self
      end

      ##
      # Adds Tailwind CSS classes with the `active:` state prefix to the component.
      # If a string is provided as a block, it is prefixed with `active:` and added as a class.
      # @return [self] Returns self to allow method chaining.
      def active(&block)
        add_active_classes(block)
        self
      end

      ##
      # Adds Tailwind CSS classes with the `dark:` prefix for dark mode styling.
      # Accepts a block containing class names to be prefixed and added.
      # @return [self] Returns self to allow method chaining.
      def dark(&block)
        add_dark_classes(block)
        self
      end

      ##
      # Adds Tailwind CSS classes with the `sm:` breakpoint prefix to the component.
      # Accepts a block or string representing the class to be prefixed.
      # @return [self] Returns self for method chaining.
      def sm(&block)
        add_responsive_classes('sm', block)
        self
      end

      ##
      # Adds a Tailwind CSS class with the `md:` (medium breakpoint) prefix to the component.
      # The class is determined by the provided block if it is a string.
      # @return [self] Returns self to allow method chaining.
      def md(&block)
        add_responsive_classes('md', block)
        self
      end

      ##
      # Adds a Tailwind CSS `lg:` (large breakpoint) prefix to the provided class or classes.
      # If a string is given as a block, it is prefixed with `lg:` and added to the component's class attribute.
      # @return [self] Returns self for method chaining.
      def lg(&block)
        add_responsive_classes('lg', block)
        self
      end

      ##
      # Adds Tailwind CSS classes with the `xl:` breakpoint prefix to the component.
      # Accepts a block containing the class or classes to be prefixed.
      # @return [self] Returns self to allow method chaining.
      def xl(&block)
        add_responsive_classes('xl', block)
        self
      end

      ##
      # Adds a Tailwind CSS `2xl:` (extra-extra-large) breakpoint prefix to the provided utility class or classes.
      # Accepts a block containing the class string to be prefixed.
      # @return [self] Returns self for method chaining.
      def xxl(&block)
        add_responsive_classes('2xl', block)
        self
      end

      ##
      # Adds arbitrary Tailwind CSS utility classes to the component.
      # @param [String] classes - One or more Tailwind class names to add.
      def tw(classes)
        add_class(classes)
        self
      end

      private

      ##
      # Appends the given class name to the component's class attribute.
      # If a class attribute already exists, the new class is appended with a space separator.
      # @param [String] class_name - The Tailwind CSS class to add.
      def add_class(class_name)
        @attributes[:class] = [@attributes[:class], class_name].compact.join(' ')
      end

      ##
      # Adds a Tailwind CSS class with a `hover:` prefix if the provided block is a string.
      # @param [String] block - The class name to be prefixed with `hover:` and added.
      def add_hover_classes(block)
        # This would need to parse the block and prefix with hover:
        # For now, just accept a string
        add_class("hover:#{block}") if block.is_a?(String)
      end

      ##
      # Adds a responsive-prefixed Tailwind class to the component if the provided block is a string.
      # @param [String] breakpoint The responsive breakpoint prefix (e.g., "sm", "md").
      # @param [String] block The Tailwind class to be prefixed and added.
      def add_responsive_classes(breakpoint, block)
        # Similar to hover, prefix with breakpoint
        add_class("#{breakpoint}:#{block}") if block.is_a?(String)
      end
    end

    # Include Tailwind modifiers in Component class
    Component.include(Modifiers)
  end
end
# Copyright 2025
