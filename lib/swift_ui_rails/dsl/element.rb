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

      def initialize(tag_name, content = nil, options = {}, dsl_context = nil, &block)
        @tag_name = tag_name
        @content = content
        @block = block
        @options = options.dup
        @css_classes = []
        @attributes = {}
        @dsl_context = dsl_context
      end

      # Add CSS classes via chaining
      def tw(*classes, &block)
        @css_classes.concat(classes.flatten.compact)
        # If a block is provided, treat it as the element's content block
        if block
          Rails.logger.debug { "Element.tw: Block provided for #{@tag_name}" }
          @block = block
        end
        self
      end

      # Core method for adding classes - used by Tailwind module
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

      # Special case: padding alias
      def padding(size, &block)
        Rails.logger.debug(size, &block)
      end

      # Background utilities
      def bg(color, &block)
        tw("bg-#{color}", &block)
      end

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

      # Border utilities
      def border(width = nil)
        if width
          tw("border-#{width}")
        else
          tw('border')
        end
      end

      def rounded(size = '', &block)
        tw(size.empty? ? 'rounded' : "rounded-#{size}", &block)
      end

      def corner_radius(size, &block)
        tw("rounded-#{size}", &block)
      end

      # Display utilities
      def flex
        tw('flex')
      end

      def block
        tw('block')
      end

      def inline
        tw('inline')
      end

      def hidden
        tw('hidden')
      end

      # Border utilities
      def border_b(width = nil)
        if width
          tw("border-b-#{width}")
        else
          tw('border-b')
        end
      end

      def border_t(width = nil)
        if width
          tw("border-t-#{width}")
        else
          tw('border-t')
        end
      end

      def border_l(width = nil)
        if width
          tw("border-l-#{width}")
        else
          tw('border-l')
        end
      end

      def border_r(width = nil)
        if width
          tw("border-r-#{width}")
        else
          tw('border-r')
        end
      end

      def border_transparent(&block)
        tw('border-transparent', &block)
      end

      def overflow_hidden(&block)
        tw('overflow-hidden', &block)
      end

      def pt(value = nil, &block)
        tw(value ? "pt-#{value}" : 'pt', &block)
      end

      def pb(value = nil, &block)
        tw(value ? "pb-#{value}" : 'pb', &block)
      end

      # Shadow utilities
      def shadow(size = '', &block)
        tw(size.empty? ? 'shadow' : "shadow-#{size}", &block)
      end

      # Button utilities - REMOVED CSS injection per user request
      # Storybook should passively render components without injecting its own CSS
      def button_style(_style, &block)
        # No longer inject any CSS - let components handle their own styling
        @block = block if block
        self
      end

      # Button size utilities - REMOVED CSS injection per user request
      def button_size(_size, &block)
        # No longer inject any CSS - let components handle their own styling
        @block = block if block
        self
      end

      # Hover effects are now defined in Tailwind module

      # Layout utilities
      def w_full(&block)
        tw('w-full', &block)
      end

      # Break utilities
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

      # Flexbox utilities
      def items_center(&block)
        tw('items-center', &block)
      end

      def items_start(&block)
        tw('items-start', &block)
      end

      def items_end(&block)
        tw('items-end', &block)
      end

      def justify_center(&block)
        tw('justify-center', &block)
      end

      def justify_between(&block)
        tw('justify-between', &block)
      end

      def justify_start(&block)
        tw('justify-start', &block)
      end

      def justify_end(&block)
        tw('justify-end', &block)
      end

      # Additional layout utilities
      def text_center(&block)
        tw('text-center', &block)
      end

      # Margin utilities
      def margin_bottom(size, &block)
        tw("mb-#{size}", &block)
      end

      def margin_top(size, &block)
        tw("mt-#{size}", &block)
      end

      # Additional padding utilities
      def padding_x(size, &block)
        tw("px-#{size}", &block)
      end

      def padding_y(size, &block)
        tw("py-#{size}", &block)
      end

      def padding_bottom(size, &block)
        tw("pb-#{size}", &block)
      end

      # Width and height utilities
      def max_width(size, &block)
        tw("max-w-#{size}", &block)
      end

      def width(size, &block)
        tw("w-#{size}", &block)
      end

      def height(size, &block)
        tw("h-#{size}", &block)
      end

      # Animation and transition utilities
      def transition(&block)
        tw('transition', &block)
      end

      def loading(&block)
        tw('animate-spin', &block)
      end

      # Event handlers
      def on_tap(&block)
        add_stimulus_action('click', &block)
        self
      end

      def on_click(&block)
        on_tap(&block)
      end

      def on_change(&block)
        add_stimulus_action('change', &block)
        self
      end

      def on_input(&block)
        add_stimulus_action('input', &block)
        self
      end

      def on_submit(&block)
        add_stimulus_action('submit', &block)
        self
      end

      def on_keyup(&block)
        add_stimulus_action('keyup', &block)
        self
      end

      def on_keydown(&block)
        add_stimulus_action('keydown', &block)
        self
      end

      def on_focus(&block)
        add_stimulus_action('focus', &block)
        self
      end

      def on_blur(&block)
        add_stimulus_action('blur', &block)
        self
      end

      def on_hover(&block)
        add_stimulus_action('mouseover', &block)
        self
      end

      def on_mouse_enter(&block)
        add_stimulus_action('mouseenter', &block)
        self
      end

      def on_mouse_leave(&block)
        add_stimulus_action('mouseleave', &block)
        self
      end

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

      # Border utilities
      def border_color(color, &block)
        tw("border-#{color}", &block)
      end

      # Interactive utilities
      def cursor(type, &block)
        tw("cursor-#{type}", &block)
      end

      def hover_background(color, &block)
        tw("hover:bg-#{color}", &block)
      end

      # Ring hover effect
      def ring_hover(width = 2, color = nil, &block)
        ring_classes = ["hover:ring-#{width}"]
        ring_classes << "hover:ring-#{color}" if color
        tw(ring_classes.join(' '), &block)
      end

      # Group hover opacity
      def group_hover_opacity(opacity, &block)
        tw("group-hover:opacity-#{opacity}", &block)
      end

      # Image utilities
      def aspect_ratio(ratio, &block)
        safe_class = SwiftUIRails::Security::CSSValidator.safe_aspect_class(ratio)
        tw(safe_class, &block)
      end

      def object_fit(fit, &block)
        tw("object-#{fit}", &block)
      end

      def grayscale(&block)
        tw('grayscale', &block)
      end

      def blur(&block)
        tw('blur', &block)
      end

      # Grid utilities
      def col_span(count, &block)
        tw("col-span-#{count}", &block)
      end

      def row_span(count, &block)
        tw("row-span-#{count}", &block)
      end

      # Flexbox utilities
      def flex_grow(&block)
        tw('flex-grow', &block)
      end

      def flex_shrink(value = nil, &block)
        if value
          tw("flex-shrink-#{value}", &block)
        else
          tw('flex-shrink', &block)
        end
      end

      # Set disabled attribute
      def disabled(value = true)
        @attributes[:disabled] = value if value
        self
      end

      # Set any attribute
      def attr(name, value)
        @attributes[name] = value
        self
      end

      # Set title attribute
      def title(title_text)
        @attributes[:title] = title_text
        self
      end

      # Set inline style with SECURITY validation
      def style(style_string)
        # SECURITY: Validate style string to prevent CSS injection
        if /javascript:|expression\(|@import|<script|behavior:|binding:|include-source:|moz-binding:|vbscript:/i.match?(style_string)
          Rails.logger.warn "[SECURITY] Potentially dangerous style blocked: #{style_string}"
          return self
        end

        # Additional validation for common XSS patterns
        # Use simpler, non-backtracking patterns to avoid ReDoS
        if style_string.include?('javascript:') || style_string.include?('vbscript:')
          Rails.logger.warn "[SECURITY] Script URL detected in style: #{style_string}"
          return self
        end

        # Check for event handlers separately with a simpler pattern
        if style_string.match?(/\bon[a-z]+\s*=/i)
          Rails.logger.warn "[SECURITY] Event handler detected in style: #{style_string}"
          return self
        end

        # Check data: URLs separately with a simpler pattern
        if style_string.include?('data:') && style_string !~ %r{data:image/(?:png|jpg|jpeg|gif|webp|svg\+xml);}i
          Rails.logger.warn "[SECURITY] Potentially dangerous data URL in style: #{style_string}"
          return self
        end

        existing_style = @options[:style] || ''
        @options[:style] = [existing_style, style_string].compact_blank.join('; ')
        self
      end

      # Merge additional attributes
      def merge_attributes(attrs)
        @attributes.merge!(attrs)
        self
      end

      # ========================================
      # Hotwire and Morphing Capabilities
      # ========================================

      # Turbo Frame support
      def turbo_frame(id)
        @attributes['data-turbo-frame'] = id
        self
      end

      def turbo_permanent
        @attributes['data-turbo-permanent'] = true
        self
      end

      # Stimulus controller support
      def stimulus_controller(controller_name)
        existing = @attributes['data-controller']
        @attributes['data-controller'] = existing ? "#{existing} #{controller_name}" : controller_name
        self
      end

      def stimulus_target(target_name)
        @attributes["data-#{target_name.tr('_', '-')}-target"]
        @attributes["data-#{target_name.tr('_', '-')}-target"] = target_name
        self
      end

      def stimulus_action(action)
        existing = @attributes['data-action']
        @attributes['data-action'] = existing ? "#{existing} #{action}" : action
        self
      end

      def stimulus_param(param_name, value)
        @attributes["data-#{param_name.tr('_', '-')}-param"] = value
        self
      end

      # Data attributes with SECURITY sanitization
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

      # ID attribute
      def id(id_value)
        @attributes['id'] = id_value
        self
      end

      # DOM morphing support
      def morph_id(id)
        @attributes['id'] = id
        @attributes['data-morph-id'] = id
        self
      end

      # Event handling for powerful interactions
      def on_click(action = nil)
        if action
          @attributes[:onclick] = action
        elsif block_given?
          # For more complex interactions, use Stimulus
          stimulus_action("click->#{@tag_name}#handleClick")
        end
        self
      end

      def on_submit(action)
        @attributes[:onsubmit] = action
        self
      end

      def on_change(action)
        @attributes[:onchange] = action
        self
      end

      # Accessibility enhancements
      def aria_label(label)
        @attributes['aria-label'] = label
        self
      end

      def aria_hidden(hidden = true)
        @attributes['aria-hidden'] = hidden.to_s
        self
      end

      def role(role_name)
        @attributes['role'] = role_name
        self
      end

      # Performance and loading states
      def lazy_load
        @attributes['loading'] = 'lazy'
        self
      end

      def eager_load
        @attributes['loading'] = 'eager'
        self
      end

      # ========================================
      # Advanced Layout and Animation
      # ========================================

      # CSS Grid enhancements
      def grid_area(area)
        tw("grid-area-#{area}")
        self
      end

      def grid_template_columns(columns)
        @options[:style] = [@options[:style], "grid-template-columns: #{columns}"].compact.join('; ')
        self
      end

      def grid_template_rows(rows)
        @options[:style] = [@options[:style], "grid-template-rows: #{rows}"].compact.join('; ')
        self
      end

      # Advanced animations
      def animate_in(animation = 'fadeIn')
        tw("animate-#{animation}")
        self
      end

      def animate_out(animation = 'fadeOut')
        tw("animate-#{animation}")
        self
      end

      def animate_on_hover(animation = 'scale-105')
        tw("hover:#{animation} transition-transform duration-200")
        self
      end

      def animate_on_focus(animation = 'ring-2 ring-blue-500')
        tw("focus:#{animation}")
        self
      end

      # Responsive design helpers
      def responsive
        # Allow chaining different breakpoint styles
        yield(self) if block_given?
        self
      end

      def sm(utility, &block)
        tw("sm:#{utility}", &block)
        self
      end

      def md(utility, &block)
        tw("md:#{utility}", &block)
        self
      end

      def lg(utility, &block)
        tw("lg:#{utility}", &block)
        self
      end

      def xl(utility, &block)
        tw("xl:#{utility}", &block)
        self
      end

      # State-based styling
      def hover(utilities)
        utilities.split.each { |util| tw("hover:#{util}") }
        self
      end

      def focus(utilities)
        utilities.split.each { |util| tw("focus:#{util}") }
        self
      end

      def active(utilities)
        utilities.split.each { |util| tw("active:#{util}") }
        self
      end

      def disabled_state(utilities)
        utilities.split.each { |util| tw("disabled:#{util}") }
        self
      end

      # Dark mode support
      def dark(utilities)
        utilities.split.each { |util| tw("dark:#{util}") }
        self
      end

      # Transform utilities
      def scale(value)
        tw("scale-#{value}")
        self
      end

      def rotate(value)
        tw("rotate-#{value}")
        self
      end

      def translate_x(value)
        tw("translate-x-#{value}")
        self
      end

      def translate_y(value)
        tw("translate-y-#{value}")
        self
      end

      # Advanced positioning
      def sticky
        tw('sticky')
        self
      end

      def fixed
        tw('fixed')
        self
      end

      def absolute
        tw('absolute')
        self
      end

      def relative
        tw('relative')
        self
      end

      def top(value)
        tw("top-#{value}")
        self
      end

      def bottom(value)
        tw("bottom-#{value}")
        self
      end

      def left(value)
        tw("left-#{value}")
        self
      end

      def right(value)
        tw("right-#{value}")
        self
      end

      def inset(value)
        tw("inset-#{value}")
        self
      end

      def z_index(value)
        tw("z-#{value}")
        self
      end

      # Convert to HTML string
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
          # Escape HTML content to prevent XSS
          # For text elements, we should escape HTML rather than sanitize it
          # This preserves the content while making it safe
          escaped_content = ERB::Util.html_escape(@content.to_s)
          @view_context.content_tag(@tag_name, escaped_content, @options)
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

      # Make it work with Rails rendering
      def to_str
        to_s
      end

      # Make it HTML safe
      def html_safe?
        true
      end

      # ========================================
      # SwiftUI-Style Chainable Modifiers
      # ========================================

      # Background and Foreground Colors
      # (background method is defined earlier with block support)

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

      # Corner Radius (SwiftUI-style)
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

      # Padding (SwiftUI-style)
      def padding(amount = 4)
        tw("p-#{amount}")
        self
      end

      def padding_horizontal(amount)
        tw("px-#{amount}")
        self
      end

      def padding_vertical(amount)
        tw("py-#{amount}")
        self
      end

      # Font Styling (SwiftUI-style)
      def font_size(size)
        tw("text-#{size}")
        self
      end

      def font_bold
        tw('font-bold')
        self
      end

      def font_semibold
        tw('font-semibold')
        self
      end

      def font_medium
        tw('font-medium')
        self
      end

      def font_light
        tw('font-light')
        self
      end

      # Button-specific modifiers - REMOVED CSS injection per user request
      def button_style(_style)
        # No longer inject any CSS - let components handle their own styling
        self
      end

      def disabled(is_disabled = true)
        if is_disabled
          tw('opacity-50 cursor-not-allowed')
          @options[:disabled] = true
        end
        self
      end

      # Size modifiers for buttons - REMOVED CSS injection per user request
      def button_size(_size)
        # No longer inject any CSS - let components handle their own styling
        self
      end

      # SwiftUI-like animation and interaction
      def animation(type = 'transition-all', duration = '200')
        tw("#{type} duration-#{duration}")
        self
      end

      def hover_effect(effect = 'opacity-90')
        tw("hover:#{effect}")
        self
      end

      def focus_ring(color = 'blue-500')
        tw("focus:outline-none focus:ring-2 focus:ring-#{color} focus:ring-offset-2")
        self
      end

      # ========================================
      # Product List Specific Modifiers
      # ========================================

      def sortable(enabled = true)
        @options[:sortable] = enabled
        self
      end

      def filterable(enabled = true)
        @options[:filterable] = enabled
        self
      end

      def grid_columns(count)
        @options[:columns] = count
        self
      end

      def quick_actions(enabled = true)
        @options[:show_quick_actions] = enabled
        self
      end

      def animated(enabled = true, delay: '100')
        @options[:enable_animations] = enabled
        @options[:animation_delay] = delay
        self
      end

      def currency(symbol)
        @options[:currency_symbol] = symbol
        self
      end

      # Ruby's tap method for chaining
      def tap(&block)
        yield(self) if block
        self
      end

      # Convert to symbol (used in some DSL patterns)
      def to_sym(&block)
        # This is a DSL modifier, not actually converting to symbol
        # It's used for symbolic references in the DSL
        tw('to-sym', &block)
      end
    end
  end
end
# Copyright 2025
