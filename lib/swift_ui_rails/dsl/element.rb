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
        
        # puts "🔧 Element.initialize: #{tag_name}, dsl_context=#{dsl_context.class.name if dsl_context}"
      end

      # Add CSS classes via chaining
      def tw(*classes, &block)
        @css_classes.concat(classes.flatten.compact)
        # If a block is provided, treat it as the element's content block
        if block
          safe_logger&.debug { "Element.tw: Block provided for #{@tag_name}" }
          @block = block
        end
        self
      end

      # Core method for adding classes - used by Tailwind module
      def add_class(class_name, &block)
        safe_logger&.debug { "Element.add_class: #{class_name}, block_given: #{block}" }
        # Avoid duplicate classes
        @css_classes << class_name unless @css_classes.include?(class_name)
        @block = block if block
        self
      end


      # Define size utilities using metaprogramming
      SIZE_UTILITIES = {
        # Width utilities
        w: 'w', min_w: 'min-w', max_w: 'max-w',
        # Height utilities
        h: 'h', min_h: 'min-h', max_h: 'h'
      }.freeze

      # Define text utilities using metaprogramming
      TEXT_UTILITIES = {
        text_size: 'text', font_size: 'text', text_color: 'text',
        font_weight: 'font', text_align: 'text', line_clamp: 'line-clamp'
      }.freeze

      # Define parameterless text utilities
      TEXT_STYLE_UTILITIES = %i[italic underline].freeze


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


      # Background utilities
      def bg(color, &block)
        color_class = resolve_color(color)
        tw("bg-#{color_class}", &block)
      end

      def background(color, &block)
        color_class = resolve_color(color)
        if color_class.start_with?('#')
          # Hex color - use inline style
          @options[:style] = [@options[:style], "background-color: #{color_class}"].compact.join('; ')
        else
          # Tailwind class
          tw("bg-#{color_class}")
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
      def flex(&block)
        tw('flex', &block)
      end

      def block(&block)
        tw('block', &block)
      end

      def inline(&block)
        tw('inline', &block)
      end

      def hidden(&block)
        tw('hidden', &block)
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

      def overflow(value = nil, &block)
        if value
          tw("overflow-#{value}", &block)
        else
          tw('overflow', &block)
        end
      end

      def relative(&block)
        tw('relative', &block)
      end

      def absolute(&block)
        tw('absolute', &block)
      end

      def fixed(&block)
        tw('fixed', &block)
      end

      def sticky(&block)
        tw('sticky', &block)
      end

      # Typography utilities
      def leading_tight(&block)
        tw('leading-tight', &block)
      end

      def leading_relaxed(&block)
        tw('leading-relaxed', &block)
      end

      def tracking(value = nil, &block)
        if value
          tw("tracking-#{value}", &block)
        else
          tw('tracking', &block)
        end
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
          safe_logger&.debug { "Adding component metadata to element: component_id=#{comp_id}, class=#{comp_class}" }
          @attributes["data-#{controller_name}-component-id-value"] = comp_id
          @attributes["data-#{controller_name}-component-class-value"] = comp_class
        else
          safe_logger&.debug do
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
          safe_logger&.warn "[SECURITY] Potentially dangerous style blocked: #{style_string}"
          return self
        end

        # Additional validation for common XSS patterns
        # Use simpler, non-backtracking patterns to avoid ReDoS
        if style_string.include?('javascript:') || style_string.include?('vbscript:')
          safe_logger&.warn "[SECURITY] Script URL detected in style: #{style_string}"
          return self
        end

        # Check for event handlers separately with a simpler pattern
        if style_string.match?(/on[a-z]+\s*=/i)
          safe_logger&.warn "[SECURITY] Event handler detected in style: #{style_string}"
          return self
        end

        # Check data: URLs separately with a simpler pattern
        if style_string.include?('data:') && style_string !~ %r{data:image/(?:png|jpg|jpeg|gif|webp|svg\+xml);}i
          safe_logger&.warn "[SECURITY] Potentially dangerous data URL in style: #{style_string}"
          return self
        end

        existing_style = @options[:style] || ''
        @options[:style] = [existing_style, style_string].compact.join('; ')
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
      def data(attributes, &block)
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
        
        # Handle block if provided - same as add_class method
        @block = block if block
        
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

      # Lifecycle
      def on_appear(&block)
        # Register the action with a unique ID
        add_stimulus_action("appear", &block)
        
        # Add the lifecycle controller to observe visibility
        stimulus_controller("lifecycle")
        self
      end

      # Server Actions (LiveView-like)
      def on_server_click(method_name)
        data(
          controller: "server-action",
          action: "click->server-action#trigger",
          server_action_name_value: method_name
        )
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

      # Advanced positioning methods removed - now handled by Tailwind::Modifiers

      # fixed method removed - now handled by Tailwind::Modifiers

      # Removed duplicate methods that override Tailwind::Modifiers
      # These methods are now handled by the included Tailwind::Modifiers module
      # which provides superior block handling for chaining syntax like div.relative do

      # Convert to HTML string
      def to_s
        safe_logger&.debug do
          "Element.to_s: tag=#{@tag_name}, has_block=#{!@block.nil?}, content=#{@content.inspect[0..50]}"
        end

        # X-Ray Debug Mode: Inject DSL node information
        if defined?(Rails) && Rails.env.development?
          # Try to infer a useful name from tag name or class
          debug_name = @tag_name
          debug_name = "vstack" if @css_classes.include?("flex-col")
          debug_name = "hstack" if @css_classes.include?("flex-row")
          debug_name = "text" if @tag_name == :span || @tag_name == :p
          
          @options["data-dsl-node"] = debug_name
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

        # Determine the inner HTML content to be rendered
        inner_html_content = ''

        if @block
          safe_logger&.debug { "Element.to_s: Processing block for #{@tag_name}" }
          safe_logger&.info { "Element.to_s: @dsl_context is #{@dsl_context.inspect}" }

          if @dsl_context
            if @dsl_context.is_a?(SwiftUIRails::Component::Base)
              safe_logger&.info { "Element.to_s: @dsl_context is #{@dsl_context.class.name}" }
              
              parent_elements = @dsl_context.instance_variable_get(:@pending_elements) || []
              @dsl_context.instance_variable_set(:@pending_elements, [])
              
              original_current_context = SwiftUIRails::DSL.current_context
              SwiftUIRails::DSL.current_context = @dsl_context # Set component as current context
              
              # Execute the block in the component context
              result = @dsl_context.instance_eval(&@block)
              
              # Restore current_context
              SwiftUIRails::DSL.current_context = original_current_context
              
              # If the block returns an element that hasn't been registered, register it
              if result.is_a?(Element) && @dsl_context.instance_variable_get(:@pending_elements).exclude?(result)
                safe_logger&.debug do
                  "Element.to_s: Block returned unregistered element #{result.tag_name}, registering it"
                end
                @dsl_context.register_element(result)
              end
              
              nested_elements = @dsl_context.instance_variable_get(:@pending_elements) || []
              
              # CRITICAL FIX: If we have nested elements, render them individually
              # instead of using flush_elements which may cause recursion
              if nested_elements.any?
                safe_logger&.debug { "Element.to_s: Rendering #{nested_elements.length} nested elements individually" }
                inner_html_content = nested_elements.map do |element|
                  element.view_context ||= @dsl_context
                  element.to_s
                end.join.html_safe
              else
                inner_html_content = if result.is_a?(String)
                                      result.html_safe
                                    elsif result.is_a?(Element)
                                      result.to_s
                                    else
                                      ''.html_safe
                                    end
              end
              
              safe_logger&.debug { "Element.to_s: content=#{inner_html_content.inspect}, result=#{result.inspect}" }
              
              # Restore parent elements WITHOUT losing nested elements
              # The nested elements were already rendered, so we don't need to merge them back
              @dsl_context.instance_variable_set(:@pending_elements, parent_elements)

            else # Traditional DSLContext handling
              parent_depth = @dsl_context.respond_to?(:depth) ? @dsl_context.depth : 0
              sub_context = SwiftUIRails::DSLContext.new(@dsl_context.view_context, parent_depth)

              if (comp = @dsl_context.instance_variable_get(:@component))
                sub_context.instance_variable_set(:@component, comp)
              elsif @component
                sub_context.instance_variable_set(:@component, @component)
              end

              result = sub_context.instance_eval(&@block)

              if result.is_a?(Element) && sub_context.instance_variable_get(:@pending_elements).exclude?(result)
                safe_logger&.debug do
                  "Element.to_s: Block returned unregistered element #{result.tag_name}, registering it"
                end
                sub_context.register_element(result)
              end

              inner_html_content = sub_context.flush_elements
              
              if inner_html_content.to_s.strip.empty? && result.is_a?(String)
                safe_logger&.debug { "Element.to_s: Using string result from DSLContext block: #{result.inspect}" }
                inner_html_content = result.html_safe
              end
            end
          elsif @view_context.respond_to?(:capture)
            inner_html_content = @view_context.capture do
              result = @block.call
              if result.is_a?(Array)
                result.map(&:to_s).join.html_safe
              elsif result.respond_to?(:to_s)
                result.to_s.html_safe
              else
                ''
              end
            end
          else
            result = @block.call
            inner_html_content = if result.is_a?(Array)
                                  result.map(&:to_s).join.html_safe
                                elsif result.respond_to?(:to_s)
                                  result.to_s.html_safe
                                else
                                  ''
                                end
          end
        end

        # If @content (direct content) exists and block did not produce content, prioritize it.
        # Otherwise, use the content generated by the block.
        final_content_to_render = if @content.present? && inner_html_content.blank?
                                    ERB::Util.html_escape(@content.to_s)
                                  else
                                    inner_html_content
                                  end

        # Final rendering using content_tag or tag
        if final_content_to_render.is_a?(ActiveSupport::SafeBuffer)
          @view_context.content_tag(@tag_name, final_content_to_render, @options)
        else
          # For self-closing tags, or elements that should be empty
          if final_content_to_render.blank? && %i[br img input hr svg path].include?(@tag_name)
            @view_context.tag(@tag_name, @options)
          else
            sanitized_content = if @view_context.respond_to?(:sanitize)
                                  @view_context.sanitize((final_content_to_render || '').to_s)
                                else
                                  ERB::Util.html_escape((final_content_to_render || '').to_s)
                                end
            @view_context.content_tag(@tag_name, sanitized_content.html_safe, @options)
          end
        end
      rescue StandardError => e
        safe_logger&.error "Element.to_s failed: #{e.message} for tag #{@tag_name.inspect}"
        safe_logger&.error e.backtrace.join("\n")
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

      # Custom Modifiers
      def modifier(name)
        block = SwiftUIRails::DSL.modifiers[name]
        if block
          block.call(self)
        else
          safe_logger&.warn "Modifier :#{name} not found"
        end
        self
      end
      alias_method :style, :modifier

      # Background and Foreground Colors
      # (background method is defined earlier with block support)

      def foreground_color(color)
        color_class = resolve_color(color)
        if color_class.start_with?('#')
          @options[:style] = [@options[:style], "color: #{color_class}"].compact.join('; ')
        else
          tw("text-#{color_class}")
        end
        self
      end
      alias_method :foreground, :foreground_color
      alias_method :fg, :foreground_color

      def resolve_color(color)
        return color.to_s if color.to_s.start_with?('#')
        
        # Intelligent symbol mapping
        if color.is_a?(Symbol)
          str = color.to_s
          # Handle :blue_500 -> blue-500
          str = str.gsub('_', '-')
          # Handle :blue -> blue-500 (default shade)
          unless str.match?(/\-\d+$/) || ['white', 'black', 'transparent', 'current'].include?(str)
            str = "#{str}-500"
          end
          str
        else
          color.to_s
        end
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

      # SwiftUI Modifiers
      
      # .fill(:blue) -> .bg(:blue)
      def fill(color)
        bg(color)
      end
      
      # .foregroundStyle(:white) -> .fg(:white)
      def foregroundStyle(style)
        foreground_color(style)
      end
      
      # .frame(width: 12, height: 12) -> w-12 h-12
      # .frame(12) -> w-12 h-12 (Square shorthand)
      def frame(*args, **kwargs)
        width = kwargs[:width]
        height = kwargs[:height]
        
        # Handle positional shorthand frame(12) -> width: 12, height: 12
        if args.first.is_a?(Integer)
          width ||= args.first
          height ||= args.first
        end
        
        tw("w-#{width}") if width
        tw("h-#{height}") if height
        
        # Handle alignment (e.g. alignment: :topLeading) if we were using flex
        # For now, simplistic size frame
        
        self
      end

      # Padding (SwiftUI-style with smart defaults)
      # .padding -> p-4
      # .padding(8) -> p-8
      # .padding(:x) -> px-4
      # .padding(:horizontal) -> px-4
      # .padding(:horizontal, 8) -> px-8
      def padding(*args)
        if args.empty?
          tw("p-4")
        else
          first = args.first
          second = args[1]
          
          if first.is_a?(Integer) || first.is_a?(String)
            tw("p-#{first}")
          elsif first.is_a?(Symbol)
            amount = second || 4
            case first
            when :x, :horizontal
              tw("px-#{amount}")
            when :y, :vertical
              tw("py-#{amount}")
            when :top, :t
              tw("pt-#{amount}")
            when :bottom, :b
              tw("pb-#{amount}")
            when :leading, :l, :left
              tw("pl-#{amount}")
            when :trailing, :r, :right
              tw("pr-#{amount}")
            else
              tw("p-#{amount}")
            end
          end
        end
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
      def font(style)
        case style
        when :large_title then tw("text-4xl font-bold")
        when :title then tw("text-2xl font-bold")
        when :title2 then tw("text-xl font-bold")
        when :title3 then tw("text-lg font-semibold")
        when :headline then tw("text-base font-semibold")
        when :body then tw("text-base")
        when :callout then tw("text-sm")
        when :subheadline then tw("text-sm text-gray-500")
        when :footnote then tw("text-xs text-gray-500")
        when :caption then tw("text-xs text-gray-400")
        else
          # Fallback to direct size
          tw("text-#{style}")
        end
        self
      end
      alias_method :font_size, :font

      def font_weight(weight)
        # Support :bold, :semibold symbols
        tw("font-#{weight}")
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

      private

      # Safe logger that handles nil Rails.logger in test environments
      def safe_logger
        return Rails.logger if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        return Logger.new(STDOUT) if defined?(Logger)
        nil
      end
    end
  end
end