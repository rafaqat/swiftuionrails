# frozen_string_literal: true

# Copyright 2025

require_relative '../security/css_validator'
require_relative '../security/data_attribute_sanitizer'

module SwiftUIRails
  module DSL
    # Element wrapper that enables method chaining for DSL methods
    class Element
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::OutputSafetyHelper
      include SwiftUIRails::Tailwind::Modifiers

      attr_reader :tag_name, :content, :options
      attr_accessor :view_context

      ##
      # Initializes a new Element instance for building a chainable HTML element.
      # @param [String, Symbol] tag_name - The HTML tag name (e.g., 'div', 'span').
      # @param [String, nil] content - Optional static content for the element.
      # @param [Hash] options - Optional HTML attributes and options.
      # @param [Object, nil] dsl_context - Optional DSL context for nested rendering.
      # @yield Optional block for nested content or further configuration.
      def initialize(tag_name, content = nil, options = {}, dsl_context = nil, &block)
        @tag_name = tag_name
        @content = content
        @block = block
        @options = options.dup
        @css_classes = []
        @attributes = {}
        @dsl_context = dsl_context
      end

      ##
      # Adds one or more CSS classes to the element, supporting method chaining.
      # If a block is provided, sets it as the element's content block.
      # @param [Array<String>] classes - One or more CSS class names to add.
      # @return [Element] The element instance for chaining.
      def tw(*classes, &block)
        @css_classes.concat(classes.flatten.compact)
        # If a block is provided, treat it as the element's content block
        if block
          Rails.logger.debug { "Element.tw: Block provided for #{@tag_name}" }
          @block = block
        end
        self
      end

      ##
      # Adds a CSS class to the element unless it is already present.
      # If a block is provided, sets it as the element's content block.
      # @param [String] class_name - The CSS class to add.
      def add_class(class_name, &block)
        Rails.logger.debug { "Element.add_class: #{class_name}, block_given: #{block}" }
        # Avoid duplicate classes
        @css_classes << class_name unless @css_classes.include?(class_name)
        @block = block if block
        self
      end

      # Define spacing utilities using metaprogramming
      SPACING_UTILITIES = {
        # Margin utilities
        m: 'm', mt: 'mt', mr: 'mr', mb: 'mb', ml: 'ml', mx: 'mx', my: 'my',
        # Padding utilities
        p: 'p', pt: 'pt', pr: 'pr', pb: 'pb', pl: 'pl', px: 'px', py: 'py'
      }.freeze

      # Define size utilities using metaprogramming
      SIZE_UTILITIES = {
        # Width utilities
        w: 'w', min_w: 'min-w', max_w: 'max-w',
        # Height utilities
        h: 'h', min_h: 'min-h', max_h: 'max-h'
      }.freeze

      # Define text utilities using metaprogramming
      TEXT_UTILITIES = {
        text_size: 'text', font_size: 'text', text_color: 'text',
        font_weight: 'font', text_align: 'text', line_clamp: 'line-clamp'
      }.freeze

      # Define parameterless text utilities
      TEXT_STYLE_UTILITIES = %i[italic underline].freeze

      # Generate spacing utility methods
      SPACING_UTILITIES.each do |method_name, css_prefix|
        define_method(method_name) do |size, &block|
          tw("#{css_prefix}-#{size}", &block)
        end
      end

      # Generate size utility methods
      SIZE_UTILITIES.each do |method_name, css_prefix|
        define_method(method_name) do |size, &block|
          tw("#{css_prefix}-#{size}", &block)
        end
      end

      # Generate text utility methods with parameters
      TEXT_UTILITIES.each do |method_name, css_prefix|
        define_method(method_name) do |value, &block|
          tw("#{css_prefix}-#{value}", &block)
        end
      end

      # Generate parameterless text style methods
      TEXT_STYLE_UTILITIES.each do |method_name|
        define_method(method_name) do |&block|
          tw(method_name.to_s, &block)
        end
      end

      ##
      # Logs the provided padding size for debugging purposes.
      # @param [Object] size - The padding value to log.
      def padding(size, &block)
        Rails.logger.debug(size, &block)
      end

      ##
      # Adds a Tailwind CSS background color class to the element.
      # If a block is given, sets it as the element's content.
      # @param [String] color - The Tailwind color name or value to use for the background.
      def bg(color, &block)
        tw("bg-#{color}", &block)
      end

      ##
      # Sets the background color of the element using either an inline style for hex colors or a Tailwind CSS class for named colors.
      # If a block is provided, it is used as the element's content.
      # @param [String] color - The background color, either as a hex code (e.g., '#ff0000') or a Tailwind color name (e.g., 'red-500').
      # @return [Element] self for method chaining.
      def background(color, &block)
        if color.to_s.start_with?('#')
          # Hex color - use inline style
          @options[:style] = [@options[:style], "background-color: #{color}"].compact.join('; ')
        else
          # Tailwind class
          tw("bg-#{color}")
        end
        # If a block is provided, treat it as the element's content block
        @block = block if block
        self
      end

      ##
      # Adds a Tailwind CSS border class to the element.
      # If a width is provided, applies a specific border width class (e.g., 'border-2'); otherwise, applies the default 'border' class.
      # @param [String, Integer, nil] width - Optional border width to use in the Tailwind class.
      def border(width = nil)
        if width
          tw("border-#{width}")
        else
          tw('border')
        end
      end

      ##
      # Adds a Tailwind CSS rounded corner class to the element.
      # If a size is provided, uses "rounded-<size>"; otherwise, uses "rounded".
      # @param [String] size - The size of the rounded corners (e.g., "lg", "md"). If empty, applies the default "rounded" class.
      def rounded(size = '', &block)
        tw(size.empty? ? 'rounded' : "rounded-#{size}", &block)
      end

      ##
      # Adds a Tailwind CSS class for rounded corners with the specified size.
      # @param [String, Integer] size - The corner radius size to apply (e.g., 'md', 'lg', or a numeric value).
      def corner_radius(size, &block)
        tw("rounded-#{size}", &block)
      end

      ##
      # Adds the Tailwind CSS 'flex' class to enable flexbox layout on the element.
      # @return [self] The element instance for method chaining.
      def flex
        tw('flex')
      end

      ##
      # Adds the Tailwind CSS 'block' class to the element for block-level display.
      # @return [self] The element instance for chaining.
      def block
        tw('block')
      end

      ##
      # Adds the Tailwind CSS 'inline' class to the element for inline display.
      def inline
        tw('inline')
      end

      ##
      # Adds the Tailwind CSS 'hidden' class to hide the element from view.
      # @return [self] Returns self for method chaining.
      def hidden
        tw('hidden')
      end

      ##
      # Adds a bottom border Tailwind CSS class, optionally with a specified width.
      # @param [String, nil] width - The border width (e.g., '2' for 'border-b-2'). If omitted, applies the default bottom border.
      # @return [self] Returns self for method chaining.
      def border_b(width = nil)
        if width
          tw("border-b-#{width}")
        else
          tw('border-b')
        end
      end

      ##
      # Adds a Tailwind CSS top border class to the element.
      # If a width is provided, applies the corresponding `border-t-{width}` class; otherwise, applies the default `border-t` class.
      # @param [String, nil] width - Optional Tailwind width modifier for the top border.
      def border_t(width = nil)
        if width
          tw("border-t-#{width}")
        else
          tw('border-t')
        end
      end

      ##
      # Adds a left border to the element using Tailwind CSS classes.
      # Optionally sets the border width if provided.
      # @param [String, nil] width - The width of the left border (e.g., '2' for 'border-l-2').
      def border_l(width = nil)
        if width
          tw("border-l-#{width}")
        else
          tw('border-l')
        end
      end

      ##
      # Adds a right border to the element using Tailwind CSS classes.
      # Optionally specifies the border width.
      # @param [String, nil] width - The width of the right border (e.g., "2" for "border-r-2"). If omitted, applies the default right border.
      # @return [self] The element instance for chaining.
      def border_r(width = nil)
        if width
          tw("border-r-#{width}")
        else
          tw('border-r')
        end
      end

      ##
      # Adds a Tailwind CSS shadow utility class to the element.
      # If a size is provided, uses the corresponding `shadow-{size}` class; otherwise, applies the default `shadow` class.
      def shadow(size = '', &block)
        tw(size.empty? ? 'shadow' : "shadow-#{size}", &block)
      end

      # Button utilities - REMOVED CSS injection per user request
      ##
      # Sets the button style context without applying any CSS, allowing components to manage their own styling.
      # If a block is provided, it is stored for later rendering.
      # @return [Element] self for method chaining.
      def button_style(_style, &block)
        # No longer inject any CSS - let components handle their own styling
        @block = block if block
        self
      end

      ##
      # Sets the button size modifier without applying any CSS, allowing components to handle their own styling.
      # If a block is provided, it is stored for later rendering.
      # @return [Element] self for method chaining.
      def button_size(_size, &block)
        # No longer inject any CSS - let components handle their own styling
        @block = block if block
        self
      end

      # Hover effects are now defined in Tailwind module

      ##
      # Adds the Tailwind CSS class for full width to the element.
      # If a block is given, sets it as the content block for the element.
      def w_full(&block)
        tw('w-full', &block)
      end

      ##
      # Adds a Tailwind CSS break-inside utility class based on the given value.
      # @param [String] value - The break-inside value (e.g., 'avoid', 'auto', 'avoid-page', 'avoid-column').
      def break_inside(value = 'avoid', &block)
        case value
        when 'avoid'
          tw('break-inside-avoid', &block)
        when 'auto'
          tw('break-inside-auto', &block)
        when 'avoid-page'
          tw('break-inside-avoid-page', &block)
        when 'avoid-column'
          tw('break-inside-avoid-column', &block)
        else
          tw("break-inside-#{value}", &block)
        end
      end

      ##
      # Adds the Tailwind CSS 'items-center' class for flexbox alignment.
      # Yields to a block for nested content if provided.
      def items_center(&block)
        tw('items-center', &block)
      end

      ##
      # Adds the Tailwind CSS class for aligning flex items to the start of the cross axis.
      # Yields to a block for nested content if provided.
      def items_start(&block)
        tw('items-start', &block)
      end

      ##
      # Adds the Tailwind CSS class for aligning flex items to the end along the cross axis.
      # Yields to a block for nested content if provided.
      def items_end(&block)
        tw('items-end', &block)
      end

      ##
      # Adds the Tailwind CSS class for center horizontal justification to the element.
      # Yields to a block for nested content if provided.
      def justify_center(&block)
        tw('justify-center', &block)
      end

      ##
      # Applies the Tailwind CSS `justify-between` class to distribute flex items with space between them.
      # Yields to a block for nested content if provided.
      def justify_between(&block)
        tw('justify-between', &block)
      end

      ##
      # Adds the Tailwind CSS class for left-justified flex or grid container alignment.
      # Yields to a block for nested content if provided.
      def justify_start(&block)
        tw('justify-start', &block)
      end

      ##
      # Adds the Tailwind CSS class for end justification in flex or grid layouts.
      # If a block is given, sets it as the content block for the element.
      def justify_end(&block)
        tw('justify-end', &block)
      end

      ##
      # Applies center text alignment to the element using the Tailwind CSS `text-center` class.
      # Yields to a block for nested content if provided.
      def text_center(&block)
        tw('text-center', &block)
      end

      ##
      # Adds a Tailwind CSS margin-bottom utility class with the specified size.
      # @param [String, Integer] size - The margin-bottom size to apply (e.g., '4', '8').
      def margin_bottom(size, &block)
        tw("mb-#{size}", &block)
      end

      ##
      # Adds a Tailwind CSS top margin utility class with the specified size.
      # @param [String, Integer] size - The margin size to apply (e.g., '4', '8', etc.).
      def margin_top(size, &block)
        tw("mt-#{size}", &block)
      end

      ##
      # Adds horizontal padding using the Tailwind CSS `px-` utility.
      # @param [String, Integer] size - The padding size to apply on the x-axis.
      def padding_x(size, &block)
        tw("px-#{size}", &block)
      end

      ##
      # Adds a vertical padding Tailwind CSS class with the specified size.
      # @param [String, Integer] size - The padding size to apply on the y-axis.
      def padding_y(size, &block)
        tw("py-#{size}", &block)
      end

      ##
      # Adds a Tailwind CSS padding-bottom class with the specified size.
      # @param [String, Integer] size - The padding-bottom size to apply (e.g., '4', '8').
      def padding_bottom(size, &block)
        tw("pb-#{size}", &block)
      end

      ##
      # Sets the maximum width of the element using a Tailwind CSS max-width utility class.
      # @param [String] size - The Tailwind max-width size (e.g., 'sm', 'md', 'lg', 'xl', 'full').
      def max_width(size, &block)
        tw("max-w-#{size}", &block)
      end

      ##
      # Sets the width of the element using a Tailwind CSS width utility class.
      # @param [String, Integer] size - The width value to apply (e.g., 'full', '1/2', '64').
      def width(size, &block)
        tw("w-#{size}", &block)
      end

      ##
      # Sets the element's height using a Tailwind CSS height utility class.
      # @param [String, Integer] size - The height value to use in the Tailwind class (e.g., '4', 'full').
      def height(size, &block)
        tw("h-#{size}", &block)
      end

      ##
      # Adds the Tailwind CSS 'transition' class to enable transitions on the element.
      # Yields to a block for nested content if provided.
      def transition(&block)
        tw('transition', &block)
      end

      ##
      # Adds a spinning animation to the element to indicate a loading state.
      # If a block is given, sets the element's content using the block.
      # @return [Element] The modified element with loading animation.
      def loading(&block)
        tw('animate-spin', &block)
      end

      ##
      # Registers a tap (click) event handler using StimulusJS and associates it with the provided block.
      # @return [Element] self for method chaining.
      def on_tap(&block)
        add_stimulus_action('click', &block)
        self
      end

      ##
      # Registers a click event handler that triggers the provided block when the element is clicked.
      # This is an alias for the `on_tap` method.
      def on_click(&block)
        on_tap(&block)
      end

      ##
      # Registers a StimulusJS 'change' event handler for the element.
      # The provided block will be executed on the server when the change event is triggered.
      # @return [Element] self for method chaining.
      def on_change(&block)
        add_stimulus_action('change', &block)
        self
      end

      ##
      # Registers a StimulusJS action for the 'input' event, triggering the provided block when the event occurs.
      # @return [Element] self for method chaining.
      def on_input(&block)
        add_stimulus_action('input', &block)
        self
      end

      ##
      # Registers a StimulusJS action to handle the submit event for the element.
      # Yields the event to the provided block when the submit event is triggered.
      # @return [Element] self for method chaining.
      def on_submit(&block)
        add_stimulus_action('submit', &block)
        self
      end

      ##
      # Registers a StimulusJS action for the keyup event and associates it with the provided block.
      # @return [Element] self for method chaining.
      def on_keyup(&block)
        add_stimulus_action('keyup', &block)
        self
      end

      ##
      # Registers a StimulusJS action for the keydown event on the element.
      # Yields to the provided block to define the event handler.
      # @return [Element] self for method chaining.
      def on_keydown(&block)
        add_stimulus_action('keydown', &block)
        self
      end

      ##
      # Registers a StimulusJS action to handle the focus event for the element.
      # @yield Block to execute when the element receives focus.
      # @return [Element] Self for method chaining.
      def on_focus(&block)
        add_stimulus_action('focus', &block)
        self
      end

      ##
      # Registers a StimulusJS action to handle the blur event on the element.
      # @yield The block to execute when the blur event occurs.
      # @return [Element] Returns self for method chaining.
      def on_blur(&block)
        add_stimulus_action('blur', &block)
        self
      end

      ##
      # Registers a handler for the mouseover (hover) event using StimulusJS.
      # Yields to the provided block when the event is triggered.
      # @return [Element] self for method chaining.
      def on_hover(&block)
        add_stimulus_action('mouseover', &block)
        self
      end

      ##
      # Registers a StimulusJS action for the mouse enter event on the element.
      # @yield Executes the provided block when the mouse enters the element.
      def on_mouse_enter(&block)
        add_stimulus_action('mouseenter', &block)
        self
      end

      ##
      # Registers a StimulusJS action for the mouseleave event on the element.
      # @yield Executes the provided block when the mouseleave event is triggered.
      # @return [Element] Returns self for method chaining.
      def on_mouse_leave(&block)
        add_stimulus_action('mouseleave', &block)
        self
      end

      ##
      # Registers a StimulusJS action for a given event type and associates it with a Ruby block for server-side handling.
      #
      # Adds the necessary Stimulus controller and action attributes to the element, stores the action block for later execution, and attaches component metadata if available. If the view context supports action registration, the action is registered for server-side processing.
      # @param [String] event_type The DOM event type to listen for (e.g., 'click', 'change').
      # @yield The Ruby block to execute when the event is triggered.
      def add_stimulus_action(event_type, &block)
        # Generate a unique action identifier
        @action_counter ||= 0
        @action_counter += 1
        action_id = "action_#{@tag_name}_#{@action_counter}_#{event_type}"

        # Store the action block for later processing
        @action_blocks ||= {}
        @action_blocks[action_id] = block

        # Add Stimulus controller if not already present
        controller_name = 'swift-ui-component'
        existing_controller = @attributes['data-controller']
        unless existing_controller&.include?(controller_name)
          @attributes['data-controller'] = if existing_controller.present?
                                             "#{existing_controller} #{controller_name}"
                                           else
                                             controller_name
                                           end
        end

        # Add the action
        existing_actions = @attributes['data-action']
        new_action = "#{event_type}->#{controller_name}#handleAction"
        @attributes['data-action'] = if existing_actions.present?
                                       "#{existing_actions} #{new_action}"
                                     else
                                       new_action
                                     end

        # Store action data
        @attributes["data-#{controller_name}-action-#{action_id}"] = action_id

        # If we're in a component context, add component metadata to the element
        # Check for stored component first, then fall back to view_context
        component = @component || (@view_context if @view_context.respond_to?(:component_id))

        if component
          comp_id = component.component_id
          comp_class = component.class.name
          Rails.logger.debug { "Adding component metadata to element: component_id=#{comp_id}, class=#{comp_class}" }
          @attributes["data-#{controller_name}-component-id-value"] = comp_id
          @attributes["data-#{controller_name}-component-class-value"] = comp_class
        else
          Rails.logger.debug do
            "No component metadata available. view_context=#{@view_context&.class&.name}, component=#{@component&.class&.name}"
          end
        end

        # Store the Ruby code to execute (this will be processed server-side)
        return unless @view_context.respond_to?(:register_component_action)

        @view_context.register_component_action(action_id, block)
      end

      ##
      # Adds a Tailwind CSS border color class to the element.
      # @param [String] color - The Tailwind color name or value to use for the border.
      def border_color(color, &block)
        tw("border-#{color}", &block)
      end

      ##
      # Sets the cursor style for the element using a Tailwind CSS cursor utility.
      # @param [String] type - The cursor type (e.g., 'pointer', 'default', 'move').
      def cursor(type, &block)
        tw("cursor-#{type}", &block)
      end

      ##
      # Adds a Tailwind CSS hover background color utility to the element.
      # @param [String] color - The Tailwind color name or value to use for the hover background.
      def hover_background(color, &block)
        tw("hover:bg-#{color}", &block)
      end

      ##
      # Adds a Tailwind CSS ring effect on hover with optional width and color.
      # @param [Integer] width - The width of the ring (default: 2).
      # @param [String, nil] color - The color of the ring (optional).
      def ring_hover(width = 2, color = nil, &block)
        ring_classes = ["hover:ring-#{width}"]
        ring_classes << "hover:ring-#{color}" if color
        tw(ring_classes.join(' '), &block)
      end

      ##
      # Sets the opacity of the element when its parent group is hovered using the Tailwind `group-hover:opacity-{value}` utility.
      # @param [String, Integer] opacity - The opacity value to apply on group hover.
      def group_hover_opacity(opacity, &block)
        tw("group-hover:opacity-#{opacity}", &block)
      end

      ##
      # Sets the aspect ratio of the element using a validated Tailwind CSS class.
      # @param [String] ratio - The desired aspect ratio (e.g., '16/9', 'square').
      # @return [Element] Self for method chaining.
      def aspect_ratio(ratio, &block)
        safe_class = SwiftUIRails::Security::CSSValidator.safe_aspect_class(ratio)
        tw(safe_class, &block)
      end

      ##
      # Adds a Tailwind CSS object-fit utility class to the element.
      # @param [String] fit - The object-fit value (e.g., 'cover', 'contain', 'fill').
      def object_fit(fit, &block)
        tw("object-#{fit}", &block)
      end

      ##
      # Applies the Tailwind CSS grayscale filter to the element.
      # If a block is given, sets it as the element's content.
      def grayscale(&block)
        tw('grayscale', &block)
      end

      ##
      # Adds the Tailwind CSS 'blur' class to the element.
      # If a block is given, sets it as the element's content.
      def blur(&block)
        tw('blur', &block)
      end

      ##
      # Sets the column span for a grid item using Tailwind CSS.
      # @param [Integer] count - The number of columns the element should span.
      def col_span(count, &block)
        tw("col-span-#{count}", &block)
      end

      ##
      # Adds a Tailwind CSS row span class to the element.
      # @param [Integer] count - The number of grid rows the element should span.
      def row_span(count, &block)
        tw("row-span-#{count}", &block)
      end

      ##
      # Adds the Tailwind 'flex-grow' utility class to enable a flex item to grow and fill available space.
      # If a block is given, sets it as the element's content.
      def flex_grow(&block)
        tw('flex-grow', &block)
      end

      ##
      # Adds a Tailwind CSS flex-shrink utility class to the element.
      # If a value is provided, uses "flex-shrink-{value}"; otherwise, uses "flex-shrink".
      # @param [Integer, String, nil] value - The flex-shrink value to apply, or nil for the default utility.
      def flex_shrink(value = nil, &block)
        if value
          tw("flex-shrink-#{value}", &block)
        else
          tw('flex-shrink', &block)
        end
      end

      ##
      # Sets the disabled attribute on the element.
      # @param [Boolean] value - Whether the element should be disabled (default: true).
      # @return [Element] Returns self for method chaining.
      def disabled(value = true)
        @attributes[:disabled] = value if value
        self
      end

      ##
      # Sets a custom HTML attribute on the element.
      # @param [String, Symbol] name - The attribute name.
      # @param [Object] value - The attribute value.
      # @return [Element] Returns self for method chaining.
      def attr(name, value)
        @attributes[name] = value
        self
      end

      ##
      # Sets the HTML title attribute for the element.
      # @param [String] title_text - The value to assign to the title attribute.
      # @return [Element] self for method chaining.
      def title(title_text)
        @attributes[:title] = title_text
        self
      end

      ##
      # Sets an inline CSS style on the element after validating the style string for security risks.
      # Prevents application of styles containing potentially dangerous or XSS-related patterns.
      # @param [String] style_string The CSS style string to apply.
      def style(style_string)
        # SECURITY: Validate style string to prevent CSS injection
        if /javascript:|expression\(|@import|<script|behavior:|binding:|include-source:|moz-binding:|vbscript:/i.match?(style_string)
          Rails.logger.warn "[SECURITY] Potentially dangerous style blocked: #{style_string}"
          return self
        end

        # Additional validation for common XSS patterns
        if %r{data:(?!image/(?:png|jpg|jpeg|gif|webp|svg\+xml))|javascript:|vbscript:|on\w+\s*=}i.match?(style_string)
          Rails.logger.warn "[SECURITY] XSS pattern detected in style: #{style_string}"
          return self
        end

        existing_style = @options[:style] || ''
        @options[:style] = [existing_style, style_string].compact_blank.join('; ')
        self
      end

      ##
      # Merges the provided attributes into the element's existing attribute hash.
      # @param [Hash] attrs - The attributes to merge.
      def merge_attributes(attrs)
        @attributes.merge!(attrs)
        self
      end

      # ========================================
      # Hotwire and Morphing Capabilities
      # ========================================

      ##
      # Sets the Turbo Frame ID for the element by adding a `data-turbo-frame` attribute.
      # @param [String] id - The Turbo Frame identifier.
      # @return [Element] self for method chaining.
      def turbo_frame(id)
        @attributes['data-turbo-frame'] = id
        self
      end

      ##
      # Marks the element as permanent for Turbo, preserving it across page updates.
      # @return [Element] self for method chaining.
      def turbo_permanent
        @attributes['data-turbo-permanent'] = true
        self
      end

      ##
      # Adds a Stimulus controller to the element by updating the `data-controller` attribute.
      # If a controller is already present, appends the new controller name.
      # @param [String] controller_name The name of the Stimulus controller to add.
      # @return [Element] self for method chaining.
      def stimulus_controller(controller_name)
        existing = @attributes['data-controller']
        @attributes['data-controller'] = existing ? "#{existing} #{controller_name}" : controller_name
        self
      end

      ##
      # Sets a StimulusJS target data attribute for the element.
      # @param [String] target_name - The name of the Stimulus target.
      # @return [Element] Self, for method chaining.
      def stimulus_target(target_name)
        @attributes["data-#{target_name.tr('_', '-')}-target"]
        @attributes["data-#{target_name.tr('_', '-')}-target"] = target_name
        self
      end

      ##
      # Adds a StimulusJS action to the element's data-action attribute, appending to any existing actions.
      # @param [String] action - The Stimulus action to add (e.g., "click->controller#method").
      # @return [Element] self for method chaining.
      def stimulus_action(action)
        existing = @attributes['data-action']
        @attributes['data-action'] = existing ? "#{existing} #{action}" : action
        self
      end

      ##
      # Sets a StimulusJS parameter as a data attribute on the element.
      # @param [String] param_name - The name of the parameter (underscores will be converted to hyphens).
      # @param [Object] value - The value to assign to the parameter.
      # @return [Element] Returns self for method chaining.
      def stimulus_param(param_name, value)
        @attributes["data-#{param_name.tr('_', '-')}-param"] = value
        self
      end

      ##
      # Adds sanitized data attributes to the element.
      # Accepts a hash or a colon-separated string and ensures all data attributes are securely sanitized before applying them.
      # @param [Hash, String] attributes - Data attributes as a hash or a single 'key:value' string.
      # @return [self] The element instance for chaining.
      def data(attributes)
        # Handle different input formats
        if attributes.is_a?(Hash)
          # Sanitize all data attributes
          sanitized = SwiftUIRails::Security::DataAttributeSanitizer.sanitize_data_attributes(attributes)

          # Apply sanitized attributes
          sanitized.each do |key, value|
            # The sanitizer already adds 'data-' prefix
            @attributes[key] = value
          end
        elsif attributes.is_a?(String) && attributes.include?(':')
          # Handle single key:value format
          parts = attributes.split(':', 2)
          if parts.length == 2
            key, value = SwiftUIRails::Security::DataAttributeSanitizer.sanitize_data_attribute(parts[0], parts[1])
            @attributes[key] = value
          end
        end
        self
      end

      ##
      # Sets the HTML id attribute for the element.
      # @param [String] id_value The value to assign to the id attribute.
      # @return [Element] Returns self for method chaining.
      def id(id_value)
        @attributes['id'] = id_value
        self
      end

      ##
      # Sets both the HTML `id` and `data-morph-id` attributes for DOM morphing support.
      # @param [String] id - The identifier to assign to the element.
      # @return [Element] Returns self for method chaining.
      def morph_id(id)
        @attributes['id'] = id
        @attributes['data-morph-id'] = id
        self
      end

      ##
      # Sets a click event handler for the element.
      # If an action string is provided, it is assigned to the `onclick` attribute.
      # If no action is given and a block is present, registers a StimulusJS click action for advanced handling.
      # @param [String, nil] action - JavaScript code or function name to execute on click. If omitted, enables Stimulus integration when used with a block.
      # @return [self]
      def on_click(action = nil)
        if action
          @attributes[:onclick] = action
        elsif block_given?
          # For more complex interactions, use Stimulus
          stimulus_action("click->#{@tag_name}#handleClick")
        end
        self
      end

      ##
      # Sets the HTML `onsubmit` attribute to the specified action for the element.
      # @param [String] action - The JavaScript or handler to execute on form submission.
      # @return [Element] self for method chaining.
      def on_submit(action)
        @attributes[:onsubmit] = action
        self
      end

      ##
      # Sets the JavaScript `onchange` attribute for the element.
      # @param [String] action - The JavaScript code or function to execute when the element's value changes.
      # @return [Element] self for method chaining.
      def on_change(action)
        @attributes[:onchange] = action
        self
      end

      ##
      # Sets the ARIA label attribute for accessibility purposes.
      # @param [String] label - The descriptive label for assistive technologies.
      # @return [self] Returns self for method chaining.
      def aria_label(label)
        @attributes['aria-label'] = label
        self
      end

      ##
      # Sets the 'aria-hidden' attribute to control element visibility for assistive technologies.
      # @param [Boolean] hidden - Whether the element should be hidden from accessibility APIs. Defaults to true.
      # @return [Element] self for method chaining.
      def aria_hidden(hidden = true)
        @attributes['aria-hidden'] = hidden.to_s
        self
      end

      ##
      # Sets the ARIA role attribute for the element.
      # @param [String] role_name The ARIA role to assign.
      def role(role_name)
        @attributes['role'] = role_name
        self
      end

      ##
      # Sets the element's loading attribute to 'lazy' for deferred loading of resources.
      # @return [Element] Returns self for method chaining.
      def lazy_load
        @attributes['loading'] = 'lazy'
        self
      end

      ##
      # Sets the loading attribute to 'eager' for the element, indicating that resources should be loaded immediately.
      # @return [Element] self for method chaining.
      def eager_load
        @attributes['loading'] = 'eager'
        self
      end

      # ========================================
      # Advanced Layout and Animation
      # ========================================

      ##
      # Sets the CSS grid area for the element using a Tailwind utility class.
      # @param [String] area - The name of the grid area to assign.
      def grid_area(area)
        tw("grid-area-#{area}")
        self
      end

      ##
      # Sets the CSS grid-template-columns property for the element using inline styles.
      # @param [String] columns - The value to assign to grid-template-columns (e.g., '1fr 2fr').
      # @return [Element] self for method chaining.
      def grid_template_columns(columns)
        @options[:style] = [@options[:style], "grid-template-columns: #{columns}"].compact.join('; ')
        self
      end

      ##
      # Sets the CSS grid-template-rows property for the element using inline styles.
      # @param [String] rows - The value for the grid-template-rows CSS property.
      # @return [Element] Returns self for method chaining.
      def grid_template_rows(rows)
        @options[:style] = [@options[:style], "grid-template-rows: #{rows}"].compact.join('; ')
        self
      end

      ##
      # Adds a Tailwind CSS animation class for animating the element when it appears.
      # @param [String] animation The animation name to apply (default: 'fadeIn').
      # @return [Element] Self for method chaining.
      def animate_in(animation = 'fadeIn')
        tw("animate-#{animation}")
        self
      end

      ##
      # Adds a Tailwind CSS animation class for animating the element out.
      # @param [String] animation The animation name to use (default: 'fadeOut').
      # @return [Element] Returns self for method chaining.
      def animate_out(animation = 'fadeOut')
        tw("animate-#{animation}")
        self
      end

      ##
      # Adds a hover animation utility class to the element.
      # @param [String] animation The Tailwind CSS animation or transform class to apply on hover (default: 'scale-105').
      # @return [Element] Self for method chaining.
      def animate_on_hover(animation = 'scale-105')
        tw("hover:#{animation} transition-transform duration-200")
        self
      end

      ##
      # Adds Tailwind CSS classes to apply the specified animation or effect when the element receives focus.
      # @param [String] animation - The Tailwind utility classes to apply on focus (default: 'ring-2 ring-blue-500').
      # @return [Element] self for method chaining.
      def animate_on_focus(animation = 'ring-2 ring-blue-500')
        tw("focus:#{animation}")
        self
      end

      ##
      # Enables chaining of breakpoint-specific utility methods for responsive design.
      # Yields the element to a block for applying responsive styles, then returns self.
      # @return [Element] The element instance for further chaining.
      def responsive
        # Allow chaining different breakpoint styles
        yield(self) if block_given?
        self
      end

      ##
      # Adds a Tailwind CSS utility class scoped to the `sm` (small) breakpoint.
      # Optionally accepts a block for nested content.
      # @param [String] utility - The Tailwind utility to apply at the `sm` breakpoint.
      # @return [Element] self for method chaining.
      def sm(utility, &block)
        tw("sm:#{utility}", &block)
        self
      end

      ##
      # Adds a Tailwind CSS utility class scoped to the `md` (medium) breakpoint.
      # Optionally accepts a block to set as the element's content.
      # @param [String] utility - The Tailwind utility class to apply at the `md` breakpoint.
      # @return [Element] self for method chaining.
      def md(utility, &block)
        tw("md:#{utility}", &block)
        self
      end

      ##
      # Applies a Tailwind CSS utility class at the `lg` (large) breakpoint.
      # If a block is given, sets it as the content block for the element.
      # @param [String] utility - The Tailwind utility class to apply at the `lg` breakpoint.
      # @return [Element] self for method chaining.
      def lg(utility, &block)
        tw("lg:#{utility}", &block)
        self
      end

      ##
      # Applies a Tailwind CSS utility class at the `xl` (extra-large) breakpoint.
      # @param [String] utility - The Tailwind utility to apply at the `xl` breakpoint.
      # @return [Element] self for method chaining.
      def xl(utility, &block)
        tw("xl:#{utility}", &block)
        self
      end

      ##
      # Applies Tailwind CSS hover state utilities to the element.
      # @param [String] utilities - Space-separated Tailwind utility classes to apply on hover.
      # @return [Element] Self for method chaining.
      def hover(utilities)
        utilities.split.each { |util| tw("hover:#{util}") }
        self
      end

      ##
      # Adds Tailwind CSS classes for focus state utilities to the element.
      # @param [String] utilities - Space-separated Tailwind utility classes to apply on focus.
      # @return [Element] Self for method chaining.
      def focus(utilities)
        utilities.split.each { |util| tw("focus:#{util}") }
        self
      end

      ##
      # Adds Tailwind CSS classes for the active state using the provided utility classes.
      # @param [String] utilities - Space-separated Tailwind utility classes to apply when the element is active.
      # @return [Element] self for method chaining.
      def active(utilities)
        utilities.split.each { |util| tw("active:#{util}") }
        self
      end

      ##
      # Applies Tailwind CSS utilities to the element when it is in the disabled state.
      # @param [String] utilities - Space-separated Tailwind utility classes to apply when disabled.
      # @return [Element] self for method chaining.
      def disabled_state(utilities)
        utilities.split.each { |util| tw("disabled:#{util}") }
        self
      end

      ##
      # Adds Tailwind CSS classes for dark mode variants.
      # Each utility class provided will be prefixed with 'dark:' for dark mode styling.
      # @param [String] utilities - Space-separated Tailwind utility classes to apply in dark mode.
      # @return [Element] self for method chaining.
      def dark(utilities)
        utilities.split.each { |util| tw("dark:#{util}") }
        self
      end

      ##
      # Adds a Tailwind CSS scale transformation class to the element.
      # @param value [String, Numeric] The scale factor to apply (e.g., '105' for 'scale-105').
      # @return [Element] Self for method chaining.
      def scale(value)
        tw("scale-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS rotation utility class to the element.
      # @param [String, Integer] value - The rotation value (e.g., 45 for 'rotate-45').
      # @return [Element] self for method chaining.
      def rotate(value)
        tw("rotate-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class to translate the element along the X axis.
      # @param value [String, Integer] The translation value (e.g., '4', '1/2', 'full').
      def translate_x(value)
        tw("translate-x-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class to translate the element along the Y axis.
      # @param value [String, Integer] The translation amount (e.g., '4', '1/2', 'full').
      def translate_y(value)
        tw("translate-y-#{value}")
        self
      end

      ##
      # Adds the Tailwind CSS 'sticky' class to make the element use sticky positioning.
      # @return [Element] self for method chaining.
      def sticky
        tw('sticky')
        self
      end

      ##
      # Applies the Tailwind CSS 'fixed' class to set the element's position to fixed.
      # @return [Element] self for method chaining.
      def fixed
        tw('fixed')
        self
      end

      ##
      # Adds the Tailwind CSS 'absolute' class to set the element's position to absolute.
      # @return [Element] self for method chaining.
      def absolute
        tw('absolute')
        self
      end

      ##
      # Adds the Tailwind CSS 'relative' class to set the element's position to relative.
      # @return [Element] self for method chaining.
      def relative
        tw('relative')
        self
      end

      ##
      # Adds a Tailwind CSS class to set the top position of the element.
      # @param value [String, Integer] The value to use for the top position (e.g., '0', '4', '1/2').
      # @return [Element] Returns self for method chaining.
      def top(value)
        tw("top-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class to set the bottom position of the element.
      # @param value The value to use for the bottom position (e.g., '0', '4', '1/2').
      # @return [self] Returns self for method chaining.
      def bottom(value)
        tw("bottom-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class to set the left position of the element.
      # @param value [String, Integer] The value to use for the left position (e.g., '4', '1/2', 'full').
      # @return [Element] Returns self for method chaining.
      def left(value)
        tw("left-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS class to set the right position of the element.
      # @param value [String, Integer] The value to use for the Tailwind `right-*` class.
      # @return [Element] Returns self for method chaining.
      def right(value)
        tw("right-#{value}")
        self
      end

      ##
      # Adds a Tailwind CSS inset utility class with the specified value.
      # @param [String, Integer] value - The inset value to apply (e.g., '0', '4', '1/2').
      # @return [Element] self for method chaining.
      def inset(value)
        tw("inset-#{value}")
        self
      end

      ##
      # Sets the z-index of the element using a Tailwind CSS class.
      # @param value The z-index value to apply (e.g., 10, 20, 'auto').
      # @return [Element] Returns self for method chaining.
      def z_index(value)
        tw("z-#{value}")
        self
      end

      ##
      # Renders the element and its content as a sanitized HTML string.
      #
      # Merges CSS classes and attributes, registers any associated action blocks, and safely renders content or nested elements using the Rails view context. Handles both static content and block-based content, ensuring proper HTML escaping and sanitization to prevent XSS. Raises and logs errors if rendering fails.
      # @return [String] The rendered HTML string for the element.
      def to_s
        Rails.logger.debug do
          "Element.to_s: tag=#{@tag_name}, has_block=#{!@block.nil?}, content=#{@content.inspect[0..50]}"
        end

        # Merge CSS classes - deduplicate to avoid repetition
        if @css_classes.any?
          existing_classes = @options[:class] || ''
          # Split existing classes and combine with new ones, then deduplicate
          all_classes_array = existing_classes.split + @css_classes
          all_classes = all_classes_array.uniq.compact_blank.join(' ')
          @options[:class] = all_classes
        end

        # Merge other attributes
        @options.merge!(@attributes)

        # Register action blocks with the view context if they exist
        if @action_blocks && @view_context.respond_to?(:register_component_action)
          @action_blocks.each do |action_id, block|
            @view_context.register_component_action(action_id, block)
          end
        end

        # Handle the content/block
        if @block
          Rails.logger.debug { "Element.to_s: Processing block for #{@tag_name}" }

          # If we already have a DSL context, use it directly
          # This prevents creating nested contexts and duplicate rendering
          if @dsl_context
            # Create a new sub-context to isolate child elements
            # Pass current depth to track nesting level
            parent_depth = @dsl_context.respond_to?(:depth) ? @dsl_context.depth : 0
            sub_context = SwiftUIRails::DSLContext.new(@dsl_context.view_context, parent_depth)

            # Transfer component reference
            if (comp = @dsl_context.instance_variable_get(:@component))
              sub_context.instance_variable_set(:@component, comp)
            elsif @component
              sub_context.instance_variable_set(:@component, @component)
            end

            # Execute block in sub-context to collect child elements
            result = sub_context.instance_eval(&@block)

            # If the block returns an element that hasn't been registered, register it
            if result.is_a?(Element) && sub_context.instance_variable_get(:@pending_elements).exclude?(result)
              Rails.logger.debug do
                "Element.to_s: Block returned unregistered element #{result.tag_name}, registering it"
              end
              sub_context.register_element(result)
            end

            # Flush to get rendered content
            content = sub_context.flush_elements
          elsif @view_context.respond_to?(:capture)
            # No DSL context - render block directly
            # This happens for elements created outside the DSL
            # We need to capture the result properly
            content = @view_context.capture do
              # Execute the block and collect any returned elements
              result = @block.call
              # If the result is an array of elements, join them
              if result.is_a?(Array)
                result.map(&:to_s).join.html_safe
              elsif result.respond_to?(:to_s)
                result.to_s.html_safe
              else
                ''
              end
            end
          else
            # Fallback if capture is not available
            result = @block.call
            content = if result.is_a?(Array)
                        result.map(&:to_s).join.html_safe
                      elsif result.respond_to?(:to_s)
                        result.to_s.html_safe
                      else
                        ''
                      end
          end

          # Content from DSL context is already safe, don't re-sanitize
          # Otherwise we lose nested HTML elements like buttons inside hstacks
          if content.is_a?(ActiveSupport::SafeBuffer)
            # Already marked as safe by DSL context flush
            @view_context.content_tag(@tag_name, content, @options)
          else
            # Sanitize the content before marking as html_safe
            sanitized_content = if @view_context.respond_to?(:sanitize)
                                  @view_context.sanitize((content || '').to_s)
                                else
                                  ERB::Util.html_escape((content || '').to_s)
                                end
            @view_context.content_tag(@tag_name, sanitized_content.html_safe, @options)
          end
        elsif @content
          # Sanitize content to prevent XSS
          sanitized_content = if @view_context.respond_to?(:sanitize)
                                @view_context.sanitize(@content.to_s)
                              else
                                ERB::Util.html_escape(@content.to_s)
                              end
          @view_context.content_tag(@tag_name, sanitized_content, @options)
        elsif %i[span p h1 h2 h3 h4 h5 h6 div label button].include?(@tag_name)
          # For text-like elements, use content_tag with empty string
          @view_context.content_tag(@tag_name, '', @options)
        else
          @view_context.tag(@tag_name, @options)
        end
      rescue StandardError => e
        Rails.logger.error "Element.to_s failed: #{e.message} for tag #{@tag_name.inspect}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end

      ##
      # Returns the HTML string representation of the element for Rails rendering.
      # @return [String] The rendered HTML as a string.
      def to_str
        to_s
      end

      ##
      # Indicates that the element's string representation is HTML safe.
      # @return [Boolean] Always returns true.
      def html_safe?
        true
      end

      # ========================================
      # SwiftUI-Style Chainable Modifiers
      # ========================================

      # Background and Foreground Colors
      ##
      # Sets the foreground (text) color of the element using either an inline style for hex colors or a Tailwind CSS class for named colors.
      # @param [String] color - The color value, either as a hex code (e.g., '#ff0000') or a Tailwind color name (e.g., 'red-500').
      # @return [Element] self for method chaining.

      def foreground_color(color)
        if color.start_with?('#')
          # Hex color - use inline style
          @options[:style] = [@options[:style], "color: #{color}"].compact.join('; ')
        else
          # Tailwind class
          tw("text-#{color}")
        end
        self
      end

      ##
      # Sets the corner radius of the element using Tailwind classes for standard sizes or a custom pixel value.
      # @param [String, Numeric] radius - The desired corner radius (e.g., 'sm', 'md', 'lg', 'xl', 'full', or a numeric value for custom radius).
      # @return [Element] self for method chaining.
      def corner_radius(radius)
        case radius.to_s
        when 'none', '0'
          tw('rounded-none')
        when 'sm'
          tw('rounded-sm')
        when 'md'
          tw('rounded-md')
        when 'lg'
          tw('rounded-lg')
        when 'xl'
          tw('rounded-xl')
        when 'full'
          tw('rounded-full')
        else
          # Custom radius value
          @options[:style] = [@options[:style], "border-radius: #{radius}px"].compact.join('; ')
        end
        self
      end

      ##
      # Adds uniform padding to the element using a Tailwind CSS padding utility.
      # @param [Integer] amount - The padding size to apply (default: 4).
      # @return [Element] Returns self for method chaining.
      def padding(amount = 4)
        tw("p-#{amount}")
        self
      end

      ##
      # Adds horizontal padding to the element using the specified Tailwind CSS spacing value.
      # @param [String, Integer] amount - The amount of horizontal padding to apply (e.g., 4, '8', '2.5').
      # @return [Element] Returns self for method chaining.
      def padding_horizontal(amount)
        tw("px-#{amount}")
        self
      end

      ##
      # Adds vertical padding to the element using the specified Tailwind CSS spacing amount.
      # @param [String, Integer] amount - The amount of vertical padding to apply (e.g., 2, '4', '8').
      # @return [Element] self for method chaining.
      def padding_vertical(amount)
        tw("py-#{amount}")
        self
      end

      ##
      # Sets the font size using a Tailwind CSS text size utility.
      # @param [String] size - The Tailwind text size (e.g., 'lg', 'xl', '2xl').
      def font_size(size)
        tw("text-#{size}")
        self
      end

      ##
      # Applies the Tailwind CSS `font-bold` class to make text bold.
      # @return [Element] self for method chaining.
      def font_bold
        tw('font-bold')
        self
      end

      ##
      # Applies a semibold font weight to the element using the Tailwind CSS `font-semibold` class.
      # @return [Element] Returns self for method chaining.
      def font_semibold
        tw('font-semibold')
        self
      end

      ##
      # Applies the Tailwind CSS 'font-medium' class to set medium font weight.
      # @return [Element] self for method chaining.
      def font_medium
        tw('font-medium')
        self
      end

      ##
      # Applies the Tailwind CSS `font-light` class to set light font weight.
      # @return [Element] self for method chaining.
      def font_light
        tw('font-light')
        self
      end

      ##
      # Sets the button style modifier without applying any CSS, allowing components to handle their own styling.
      # @return [Element] Returns self for method chaining.
      def button_style(_style)
        # No longer inject any CSS - let components handle their own styling
        self
      end

      ##
      # Marks the element as disabled, adding opacity and cursor styles for visual indication.
      # @param [Boolean] is_disabled - Whether to disable the element (default: true).
      # @return [Element] Self, for method chaining.
      def disabled(is_disabled = true)
        if is_disabled
          tw('opacity-50 cursor-not-allowed')
          @options[:disabled] = true
        end
        self
      end

      ##
      # Sets the button size modifier without applying any CSS, allowing components to handle their own styling.
      # @return [Element] Returns self for method chaining.
      def button_size(_size)
        # No longer inject any CSS - let components handle their own styling
        self
      end

      ##
      # Adds animation and transition classes to the element for SwiftUI-like effects.
      # @param [String] type - The type of transition or animation (e.g., 'transition-all').
      # @param [String] duration - The duration of the animation in milliseconds (e.g., '200').
      # @return [Element] The element itself for method chaining.
      def animation(type = 'transition-all', duration = '200')
        tw("#{type} duration-#{duration}")
        self
      end

      ##
      # Adds a Tailwind CSS hover effect class to the element.
      # @param [String] effect The Tailwind utility to apply on hover (default: 'opacity-90').
      # @return [Element] Self for method chaining.
      def hover_effect(effect = 'opacity-90')
        tw("hover:#{effect}")
        self
      end

      ##
      # Adds Tailwind CSS classes for a focus ring with the specified color.
      # @param [String] color - The Tailwind color to use for the focus ring (default: 'blue-500').
      # @return [Element] self for method chaining.
      def focus_ring(color = 'blue-500')
        tw("focus:outline-none focus:ring-2 focus:ring-#{color} focus:ring-offset-2")
        self
      end

      # ========================================
      # Product List Specific Modifiers
      ##
      # Marks the element as sortable by setting the sortable option.
      # @param [Boolean] enabled - Whether sorting is enabled (default: true).
      # @return [Element] Returns self for method chaining.

      def sortable(enabled = true)
        @options[:sortable] = enabled
        self
      end

      ##
      # Sets whether the element should support filtering functionality.
      # @param [Boolean] enabled - If true, enables filtering; otherwise disables it.
      # @return [Element] Returns self for method chaining.
      def filterable(enabled = true)
        @options[:filterable] = enabled
        self
      end

      ##
      # Sets the number of columns for a grid layout.
      # @param [Integer] count - The number of columns to use in the grid.
      # @return [Element] self for method chaining.
      def grid_columns(count)
        @options[:columns] = count
        self
      end

      ##
      # Enables or disables the display of quick actions for the element.
      # @param [Boolean] enabled - Whether quick actions should be shown (default: true).
      # @return [Element] Returns self for method chaining.
      def quick_actions(enabled = true)
        @options[:show_quick_actions] = enabled
        self
      end

      ##
      # Enables or disables animation for the element and sets the animation delay.
      # @param [Boolean] enabled - Whether animations are enabled.
      # @param [String] delay - The delay before the animation starts, in milliseconds.
      # @return [Element] Returns self for method chaining.
      def animated(enabled = true, delay: '100')
        @options[:enable_animations] = enabled
        @options[:animation_delay] = delay
        self
      end

      ##
      # Sets the currency symbol option for the element, typically used for product list UI features.
      # @param [String] symbol - The currency symbol to associate with the element.
      # @return [Element] self for method chaining.
      def currency(symbol)
        @options[:currency_symbol] = symbol
        self
      end
    end
  end
end
# Copyright 2025
