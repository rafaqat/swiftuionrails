# frozen_string_literal: true

require_relative '../security/css_validator'
require_relative '../security/strict_css'
require_relative '../security/data_attribute_sanitizer'
require_relative 'semantic_styles'
require 'json'

module SwiftUIRails
  module DSL
    # Element wrapper that enables method chaining for DSL methods
    class Element
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::OutputSafetyHelper
      include SwiftUIRails::Tailwind::Modifiers
      include SwiftUIRails::DSL::SemanticStyleModifiers
      
      attr_reader :tag_name, :content, :options
      attr_accessor :view_context, :child_layout_axis
      
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
        if block_given?
          Rails.logger.debug "Element.tw: Block provided for #{@tag_name}"
          @block = block
        end
        self
      end
      
      # Core method for adding classes - used by Tailwind module
      def add_class(class_name, &block)
        Rails.logger.debug "Element.add_class: #{class_name}, block_given: #{block_given?}"
        # Avoid duplicate classes
        @css_classes << class_name unless @css_classes.include?(class_name)
        @block = block if block_given?
        self
      end
      
      # Define spacing utilities using metaprogramming
      SPACING_UTILITIES = {
        # Margin utilities
        m: "m", mt: "mt", mr: "mr", mb: "mb", ml: "ml", mx: "mx", my: "my",
        # Padding utilities  
        p: "p", pt: "pt", pr: "pr", pb: "pb", pl: "pl", px: "px", py: "py"
      }.freeze
      
      # Define size utilities using metaprogramming
      SIZE_UTILITIES = {
        # Width utilities
        w: "w", min_w: "min-w", max_w: "max-w",
        # Height utilities
        h: "h", min_h: "min-h", max_h: "max-h"
      }.freeze
      
      # Define text utilities using metaprogramming
      TEXT_UTILITIES = {
        text_size: "text", font_size: "text",
        font_weight: "font", text_align: "text", line_clamp: "line-clamp"
      }.freeze
      
      # Define parameterless text utilities
      TEXT_STYLE_UTILITIES = %i[italic underline].freeze
      
      # Strict-mode allowlists for the metaprogrammed text utilities.
      STRICT_TEXT_ALLOWLISTS = {
        text_size: SwiftUIRails::Security::CSSValidator::VALID_TEXT_SIZES,
        font_size: SwiftUIRails::Security::CSSValidator::VALID_TEXT_SIZES,
        font_weight: SwiftUIRails::Security::CSSValidator::VALID_FONT_WEIGHTS,
        text_align: %w[left center right justify start end],
        line_clamp: %w[1 2 3 4 5 6 none]
      }.freeze

      # Generate spacing utility methods
      SPACING_UTILITIES.each do |method_name, css_prefix|
        define_method(method_name) do |size, &block|
          SwiftUIRails::Security::StrictCSS.check_allowlist!(
            "spacing value for .#{method_name}", size,
            SwiftUIRails::Security::CSSValidator::VALID_SPACING
          )
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
          if (allowlist = STRICT_TEXT_ALLOWLISTS[method_name])
            SwiftUIRails::Security::StrictCSS.check_allowlist!("value for .#{method_name}", value, allowlist)
          end
          tw("#{css_prefix}-#{value}", &block)
        end
      end
      
      # Generate parameterless text style methods
      TEXT_STYLE_UTILITIES.each do |method_name|
        define_method(method_name) do |&block|
          tw(method_name.to_s, &block)
        end
      end

      # Palette colors remain available as a low-level escape hatch. Share the
      # same modifier slot as foreground_style so the last call in a chain has
      # deterministic precedence without relying on CSS source order.
      def text_color(color, shade = nil, &block)
        value = shade.nil? ? color : "#{color}-#{shade}"
        SwiftUIRails::Security::StrictCSS.check_color!("text color", value)
        replace_modifier_classes(:foreground_style, ["text-#{value}"])
        @block = block if block_given?
        self
      end
      
      # Special case: padding alias
      def padding(size, &block)
        p(size, &block)
      end
      
      # Background utilities
      def bg(color, &block)
        SwiftUIRails::Security::StrictCSS.check_color!("background color", color)
        replace_modifier_classes(:background_style, ["bg-#{color}"])
        @block = block if block_given?
        self
      end

      def background(color, &block)
        if color.to_s.start_with?('#')
          # Hex color - use inline style
          @options[:style] = [@options[:style], "background-color: #{color}"].compact.join('; ')
        else
          # Tailwind class
          SwiftUIRails::Security::StrictCSS.check_color!("background color", color)
          tw("bg-#{color}")
        end
        # If a block is provided, treat it as the element's content block
        @block = block if block_given?
        self
      end
      
      # Border utilities
      def border(width = nil, &block)
        if width
          tw("border-#{width}", &block)
        else
          tw("border", &block)
        end
      end
      
      def rounded(size = "", &block)
        SwiftUIRails::Security::StrictCSS.check_allowlist!(
          "rounded size", size, SwiftUIRails::Security::CSSValidator::VALID_ROUNDED_WITH_EDGES, allow_blank: true
        )
        tw(size.empty? ? "rounded" : "rounded-#{size}", &block)
      end
      
      def corner_radius(size, &block)
        tw("rounded-#{size}", &block)
      end
      
      # Display utilities
      def flex(&block)
        tw("flex", &block)
      end
      
      def block(&block)
        tw("block", &block)
      end
      
      def inline(&block)
        tw("inline", &block)
      end
      
      # SwiftUI's hidden modifier preserves the view's layout allocation. Use
      # visibility rather than display:none, and allow a conditional modifier
      # to be reversed in the same chain with hidden(false).
      def hidden(is_hidden = true, &block)
        replace_modifier_classes(:visibility, is_hidden ? %w[invisible] : [])

        if is_hidden
          @attributes["aria-hidden"] = true
        else
          @attributes.delete("aria-hidden")
          @attributes.delete(:"aria-hidden")
          @options.delete("aria-hidden")
          @options.delete(:"aria-hidden")
        end

        @block = block if block_given?
        self
      end

      # Web layouts sometimes need display:none rather than SwiftUI's
      # space-preserving hidden behavior. Keep that intent explicit.
      def gone(is_gone = true, &block)
        replace_modifier_classes(:display_visibility, is_gone ? %w[hidden] : [])
        @block = block if block_given?
        self
      end
      
      # Border utilities
      def border_b(width = nil, &block)
        if width
          tw("border-b-#{width}", &block)
        else
          tw("border-b", &block)
        end
      end
      
      def border_t(width = nil, &block)
        if width
          tw("border-t-#{width}", &block)
        else
          tw("border-t", &block)
        end
      end
      
      def border_l(width = nil, &block)
        if width
          tw("border-l-#{width}", &block)
        else
          tw("border-l", &block)
        end
      end
      
      def border_r(width = nil, &block)
        if width
          tw("border-r-#{width}", &block)
        else
          tw("border-r", &block)
        end
      end
      
      # Shadow utilities
      def shadow(size = "", &block)
        tw(size.empty? ? "shadow" : "shadow-#{size}", &block)
      end
      
      # Semantic button styles. These are intentionally usable on the base DSL
      # button without requiring an application component to inject its CSS.
      def button_style(style, &block)
        apply_button_style(style)
        @block = block if block_given?
        self
      end
      
      def button_size(size, &block)
        apply_button_size(size)
        @block = block if block_given?
        self
      end
      
      # Hover effects are now defined in Tailwind module
      
      # Layout utilities
      def w_full(&block)
        tw("w-full", &block)
      end
      
      # Break utilities
      def break_inside(value = "avoid", &block)
        case value
        when "avoid"
          tw("break-inside-avoid", &block)
        when "auto"
          tw("break-inside-auto", &block)
        when "avoid-page"
          tw("break-inside-avoid-page", &block)
        when "avoid-column"
          tw("break-inside-avoid-column", &block)
        else
          tw("break-inside-#{value}", &block)
        end
      end
      
      # Flexbox utilities
      def items_center(&block)
        tw("items-center", &block)
      end
      
      def items_start(&block)
        tw("items-start", &block)
      end
      
      def items_end(&block)
        tw("items-end", &block)
      end
      
      def justify_center(&block)
        tw("justify-center", &block)
      end
      
      def justify_between(&block)
        tw("justify-between", &block)
      end
      
      def justify_start(&block)
        tw("justify-start", &block)
      end
      
      def justify_end(&block)
        tw("justify-end", &block)
      end
      
      # Additional layout utilities
      def text_center(&block)
        tw("text-center", &block)
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
        tw("transition", &block)
      end
      
      def loading(&block)
        tw("animate-spin", &block)
      end
      
      # Event handlers
      def on_tap(&block)
        add_server_action("click", &block)
        self
      end
      
      def on_click(&block)
        on_tap(&block)
      end
      
      def on_change(&block)
        add_server_action("change", &block)
        self
      end
      
      def on_input(&block)
        add_server_action("input", &block)
        self
      end
      
      def on_submit(&block)
        add_server_action("submit", &block)
        self
      end
      
      def on_keyup(&block)
        add_server_action("keyup", &block)
        self
      end
      
      def on_keydown(&block)
        add_server_action("keydown", &block)
        self
      end
      
      def on_focus(&block)
        add_server_action("focusin", &block)
        self
      end
      
      def on_blur(&block)
        add_server_action("focusout", &block)
        self
      end
      
      def on_hover(&block)
        add_server_action("mouseover", &block)
        self
      end
      
      def on_mouse_enter(&_block)
        raise ArgumentError,
          "on_mouse_enter cannot be transported reliably; use on_hover or a pointer semantic"
      end
      
      def on_mouse_leave(&_block)
        raise ArgumentError,
          "on_mouse_leave cannot be transported reliably; use a pointer semantic"
      end
      
      def add_server_action(event_type, &block)
        raise ArgumentError, "server actions require a Ruby block" unless block

        # Element-local counters collide for sibling buttons. Allocate from the
        # render context so every handler has a stable, render-wide identity.
        action_id = if @dsl_context&.respond_to?(:next_action_id)
          @dsl_context.next_action_id(@tag_name, event_type, block)
        else
          fallback_action_id(event_type, block)
        end
        
        # Store the action block for later processing
        @action_blocks ||= {}
        @action_blocks[action_id] = block
        
        @swift_ui_action_map ||= {}
        @swift_ui_action_map[event_type.to_s] = action_id
        @attributes["data-sui-actions"] = JSON.generate(@swift_ui_action_map)
        
        # Store the Ruby code to execute (this will be processed server-side)
        if @view_context && @view_context.respond_to?(:register_component_action)
          @view_context.register_component_action(action_id, block)
        end

        self
      end
      
      # Border utilities
      def border_color(color, &block)
        tw("border-#{color}", &block)
      end
      
      # Interactive utilities
      def cursor(type, &block)
        tw("cursor-#{type}", &block)
      end
      
      # Ring hover effect
      def ring_hover(width = 2, color = nil, &block)
        ring_classes = ["hover:ring-#{width}"]
        ring_classes << "hover:ring-#{color}" if color
        tw(ring_classes.join(" "), &block)
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
        tw("grayscale", &block)
      end
      
      def blur(&block)
        tw("blur", &block)
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
        tw("grow", &block)
      end
      
      def flex_shrink(value = nil, &block)
        if value
          tw("flex-shrink-#{value}", &block)
        else
          tw("flex-shrink", &block)
        end
      end
      
      # Set any attribute
      def attr(name, value)
        @attributes[name] = value
        self
      end

      # Internal protocol used by DSLContext#with_render_identity_scope. An
      # author-provided DOM or morph identity remains authoritative.
      def apply_scoped_render_identity(identity)
        return self if explicit_render_identity?

        @attributes['id'] = identity
        @attributes['data-morph-id'] = identity
        self
      end
      private :apply_scoped_render_identity

      # SwiftUI-style insertion/removal transitions, mirroring
      # View.transition(.asymmetric(insertion:removal:)). Insertion plays as a
      # pure CSS animation when the element enters the DOM (including Turbo
      # Stream appends); removal is declared as data so the Turbo Stream hook
      # can play it before remove/replace. Called with no keywords this stays
      # the Tailwind transition utility: transition -> "transition",
      # transition("colors") -> "transition-colors".
      TRANSITION_NAMES = %i[opacity move_up move_down scale blur].freeze

      def transition(property = nil, insertion: nil, removal: nil, &block)
        if insertion.nil? && removal.nil?
          add_class(property ? "transition-#{property}" : "transition")
          @block = block if block_given?
          return self
        end

        if property
          raise ArgumentError, "transition takes either a CSS property or insertion:/removal:, not both"
        end

        add_class("motion-enter-#{validate_transition_name!(insertion)}") if insertion
        if removal
          @attributes["data-motion-exit"] = "motion-exit-#{validate_transition_name!(removal)}"
        end
        @block = block if block_given?
        self
      end

      def validate_transition_name!(name)
        unless TRANSITION_NAMES.include?(name.to_s.to_sym)
          raise ArgumentError,
                "unknown transition: #{name.inspect} (expected one of #{TRANSITION_NAMES.join(', ')})"
        end

        name.to_s.tr("_", "-")
      end
      private :validate_transition_name!
      
      # Set title attribute
      def title(title_text)
        @attributes[:title] = title_text
        self
      end
      
      # Set inline style
      def style(style_string)
        existing_style = @options[:style] || ""
        @options[:style] = [existing_style, style_string].reject(&:blank?).join("; ")
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
        @attributes["data-turbo-frame"] = id
        self
      end
      
      def turbo_permanent
        @attributes["data-turbo-permanent"] = true
        self
      end
      
      # Application-specific browser controllers split behavior across Ruby and
      # JavaScript. SwiftUI Rails deliberately supports only Ruby server actions
      # and the finite semantic browser behaviors emitted by the DSL.
      def stimulus_controller(controller_name, &block)
        reject_application_javascript!(:stimulus_controller, controller_name, block)
      end
      
      def stimulus_target(target_name, &block)
        reject_application_javascript!(:stimulus_target, target_name, block)
      end
      
      def stimulus_action(action, &block)
        reject_application_javascript!(:stimulus_action, action, block)
      end
      
      def stimulus_param(param_name, value, &block)
        reject_application_javascript!(:stimulus_param, "#{param_name}=#{value}", block)
      end

      def reject_application_javascript!(method_name, value, _block)
        raise SwiftUIRails::Error,
              ".#{method_name}(#{value.inspect}) is unsupported: declare a Ruby action with " \
              ".on_tap/.on_change or use a finite SwiftUI Rails semantic behavior"
      end
      private :reject_application_javascript!
      
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
        @block = block if block_given?
        self
      end
      
      # ID attribute
      def id(id_value)
        @attributes["id"] = id_value
        self
      end
      
      # DOM morphing support
      def morph_id(id)
        @attributes["id"] = id
        @attributes["data-morph-id"] = id
        self
      end

      def explicit_render_identity?
        explicit_render_identity_in?(@options) || explicit_render_identity_in?(@attributes)
      end
      private :explicit_render_identity?

      def explicit_render_identity_in?(attributes)
        values = attributes.values_at('id', :id, 'data-morph-id', :'data-morph-id')
        values.any? { |value| !value.nil? }
      end
      private :explicit_render_identity_in?

      # Accessibility enhancements
      def aria_label(label)
        @attributes["aria-label"] = label
        self
      end
      
      def aria_hidden(hidden = true)
        @attributes["aria-hidden"] = hidden.to_s
        self
      end
      
      def role(role_name)
        @attributes["role"] = role_name
        self
      end
      
      # Performance and loading states
      def lazy_load
        @attributes["loading"] = "lazy"
        self
      end
      
      def eager_load
        @attributes["loading"] = "eager"
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
      def animate_in(animation = "fadeIn")
        tw("animate-#{animation}")
        self
      end
      
      def animate_out(animation = "fadeOut")
        tw("animate-#{animation}")
        self
      end
      
      def animate_on_hover(animation = "scale-105")
        tw("hover:#{animation} transition-transform duration-200")
        self
      end
      
      def animate_on_focus(animation = "ring-2 ring-blue-500")
        tw("focus:#{animation}")
        self
      end
      
      # Responsive design helpers
      def responsive(&block)
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
        utilities.split(' ').each { |util| tw("hover:#{util}") }
        self
      end
      
      def focus(utilities)
        utilities.split(' ').each { |util| tw("focus:#{util}") }
        self
      end
      
      def active(utilities)
        utilities.split(' ').each { |util| tw("active:#{util}") }
        self
      end
      
      def disabled_state(utilities)
        utilities.split(' ').each { |util| tw("disabled:#{util}") }
        self
      end
      
      # Dark mode support
      def dark(utilities)
        utilities.split(' ').each { |util| tw("dark:#{util}") }
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
      def sticky(&block)
        tw("sticky", &block)
        self
      end
      
      def fixed(&block)
        tw("fixed", &block)
        self
      end
      
      def absolute(&block)
        tw("absolute", &block)
        self
      end
      
      def relative(&block)
        tw("relative", &block)
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
        Rails.logger.debug "Element.to_s: tag=#{@tag_name}, has_block=#{!!@block}, content_present=#{!@content.nil?}"
        
        # Merge CSS classes - deduplicate to avoid repetition
        if @css_classes.any?
          existing_classes = @options[:class] || ""
          # Split existing classes and combine with new ones, then deduplicate
          all_classes_array = existing_classes.split(' ') + @css_classes
          all_classes = all_classes_array.uniq.reject(&:blank?).join(" ")
          @options[:class] = all_classes
        end
        
        # Merge other attributes
        @options.merge!(@attributes)
        
        # Register action blocks with the view context if they exist
        if @action_blocks && @view_context && @view_context.respond_to?(:register_component_action)
          @action_blocks.each do |action_id, block|
            @view_context.register_component_action(action_id, block)
          end
        end
        
        # Handle the content/block
        if @block
          Rails.logger.debug "Element.to_s: Processing block for #{@tag_name}"
          
          # If we already have a DSL context, use it directly
          # This prevents creating nested contexts and duplicate rendering
          if @dsl_context
            # Create a new sub-context to isolate child elements
            sub_context = SwiftUIRails::DSLContext.new(
              @dsl_context,
              layout_axis: @child_layout_axis
            )
            
            # Transfer component reference
            if comp = @dsl_context.instance_variable_get(:@component)
              sub_context.instance_variable_set(:@component, comp)
            elsif @component
              sub_context.instance_variable_set(:@component, @component)
            end
            
            # Execute block in sub-context to collect child elements
            result = sub_context.instance_eval(&@block)
            
            # If the block returns an element that hasn't been registered, register it
            if result.is_a?(Element) && !sub_context.instance_variable_get(:@pending_elements).include?(result)
              Rails.logger.debug "Element.to_s: Block returned unregistered element #{result.tag_name}, registering it"
              sub_context.register_element(result)
            elsif result.is_a?(Array)
              pending_elements = sub_context.instance_variable_get(:@pending_elements)
              result.grep(Element).each do |returned_element|
                sub_context.register_element(returned_element) unless pending_elements.include?(returned_element)
              end
            end
            
            # Flush to get rendered content
            content = sub_context.flush_elements

            # Rails helpers and component slots may return a SafeBuffer instead of
            # DSL elements. Preserve explicitly safe HTML, but escape ordinary
            # strings before appending them to the generated child elements.
            if result.respond_to?(:to_str) && !result.is_a?(Element)
              # DSLContext#render already registered its result as a child
              # element; appending the returned string again would duplicate
              # the rendered component.
              unless sub_context.rendered_child?(result)
                returned_content = if result.respond_to?(:html_safe?) && result.html_safe?
                  result
                else
                  ERB::Util.html_escape(result.to_str)
                end
                content = @view_context.safe_join([content, returned_content])
              end
            elsif result.is_a?(Array)
              # DSL children have already been registered and flushed above.
              # Never stringify their Element objects: each Element retains its
              # DSLContext, so Array#to_s would traverse a large cyclic graph and
              # then duplicate the rendered children. Arrays also commonly come
              # from Enumerable#each (returning domain hashes/structs), so their
              # return value is control-flow data and never rendered implicitly.
            elsif !result.is_a?(Element)
              rendered_result = result.to_s
              if rendered_result.respond_to?(:html_safe?) && rendered_result.html_safe?
                content = @view_context.safe_join([content, rendered_result])
              end
            end
          else
            # No DSL context - render block directly
            # This happens for elements created outside the DSL
            # We need to capture the result properly
            if @view_context.respond_to?(:capture)
              content = @view_context.capture do
                safe_block_result(@block.call)
              end
            else
              # Fallback if capture is not available
              content = safe_block_result(@block.call)
            end
          end
          
          # Child elements already escape their text and attributes. Sanitizing
          # the completed fragment here would remove valid structural elements
          # such as buttons, selects, and options.
          @view_context.content_tag(@tag_name, content || "", @options)
        elsif @content
          # Let Rails escape ordinary strings while preserving SafeBuffer values
          # that callers have explicitly marked as trusted.
          @view_context.content_tag(@tag_name, @content, @options)
        else
          # For text-like elements, use content_tag with empty string
          if [:span, :p, :h1, :h2, :h3, :h4, :h5, :h6, :div, :label, :button].include?(@tag_name)
            @view_context.content_tag(@tag_name, "", @options)
          else
            @view_context.tag(@tag_name, @options)
          end
        end
      rescue => e
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

      # A misspelled modifier is the most common authoring mistake (human or
      # LLM). Phrase the failure at the domain level with a repair suggestion
      # instead of a bare NoMethodError — the error message IS the repair
      # signal in a generate→validate→repair loop.
      def method_missing(method_name, *args, &block)
        suggestion = self.class.modifier_spell_checker.correct(method_name.to_s).first
        hint = suggestion ? " — did you mean `.#{suggestion}`?" : ""
        raise NoMethodError,
              "unknown modifier `.#{method_name}` on DSL element `#{@tag_name}`#{hint} " \
              "(the modifier vocabulary is SwiftUIRails::DSL::Element's public methods)"
      end

      def respond_to_missing?(method_name, include_private = false)
        super
      end

      def self.modifier_spell_checker
        @modifier_spell_checker ||= DidYouMean::SpellChecker.new(
          dictionary: (public_instance_methods - Object.public_instance_methods).map(&:to_s)
        )
      end

      def safe_block_result(result)
        values = result.is_a?(Array) ? result : [result]

        safe_join(values.compact.map do |value|
          if value.is_a?(Element) || (value.respond_to?(:html_safe?) && value.html_safe?)
            value.to_s
          else
            ERB::Util.html_escape(value.to_s)
          end
        end)
      end
      private :safe_block_result
      
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
      def corner_radius(radius, &block)
        case radius.to_s
        when "none", "0"
          tw("rounded-none")
        when "sm"
          tw("rounded-sm")
        when "md" 
          tw("rounded-md")
        when "lg"
          tw("rounded-lg")
        when "xl"
          tw("rounded-xl")
        when "full"
          tw("rounded-full")
        else
          # Custom radius value
          @options[:style] = [@options[:style], "border-radius: #{radius}px"].compact.join('; ')
        end
        @block = block if block_given?
        self
      end
      
      # Padding (SwiftUI-style)
      def padding(amount = 4, &block)
        tw("p-#{amount}", &block)
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
      # (font_size is defined by TEXT_UTILITIES with strict validation.)
      def font_bold
        tw("font-bold")
        self
      end
      
      def font_semibold
        tw("font-semibold")
        self
      end
      
      def font_medium
        tw("font-medium")
        self
      end
      
      def font_light
        tw("font-light")
        self
      end
      
      # Button-specific modifiers
      def button_style(style)
        apply_button_style(style)
        self
      end
      
      def disabled(is_disabled = true)
        if is_disabled
          replace_modifier_classes(:disabled, %w[opacity-50 cursor-not-allowed])
          @attributes[:disabled] = true
          @options[:disabled] = true
          @attributes["aria-disabled"] = true
        else
          replace_modifier_classes(:disabled, [])
          @attributes.delete(:disabled)
          @attributes.delete("disabled")
          @options.delete(:disabled)
          @options.delete("disabled")
          @attributes.delete("aria-disabled")
          @attributes.delete(:"aria-disabled")
          @options.delete("aria-disabled")
          @options.delete(:"aria-disabled")
        end
        self
      end
      
      # Size modifiers for buttons
      def button_size(size)
        apply_button_size(size)
        self
      end
      
      # SwiftUI-like animation and interaction
      def animation(type = "transition-all", duration = "200")
        tw("#{type} duration-#{duration}")
        self
      end
      
      def hover_effect(effect = "opacity-90")
        tw("hover:#{effect}")
        self
      end
      
      def focus_ring(color = "blue-500")
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
      
      def animated(enabled = true, delay: "100")
        @options[:enable_animations] = enabled
        @options[:animation_delay] = delay
        self
      end
      
      
      def currency(symbol)
        @options[:currency_symbol] = symbol
        self
      end
      
      private

      BUTTON_STYLE_CLASSES = {
        automatic: "inline-flex items-center justify-center rounded-md bg-blue-600 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        bordered_prominent: "inline-flex items-center justify-center rounded-md bg-blue-600 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        primary: "inline-flex items-center justify-center rounded-md bg-blue-600 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        bordered: "inline-flex items-center justify-center rounded-md border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        secondary: "inline-flex items-center justify-center rounded-md border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        borderless: "inline-flex items-center justify-center rounded-md bg-transparent text-blue-600 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500",
        ghost: "inline-flex items-center justify-center rounded-md bg-transparent text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-500",
        plain: "inline-flex items-center justify-center bg-transparent text-inherit",
        danger: "inline-flex items-center justify-center rounded-md bg-red-600 text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2",
        # SwiftUI puts pressed feedback in ButtonStyle, not per-element gesture
        # maps. btn-springy carries the bounce-eased hover/active transform
        # (defined in the application's Tailwind layer).
        springy: "inline-flex items-center justify-center rounded-full bg-slate-950 text-white btn-springy focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2"
      }.freeze

      BUTTON_SIZE_CLASSES = {
        mini: "px-2 py-1 text-xs",
        xs: "px-2 py-1 text-xs",
        small: "px-3 py-1.5 text-sm",
        sm: "px-3 py-1.5 text-sm",
        regular: "px-4 py-2 text-base",
        md: "px-4 py-2 text-base",
        large: "px-5 py-2.5 text-base",
        lg: "px-5 py-2.5 text-base",
        extra_large: "px-6 py-3 text-lg",
        xl: "px-6 py-3 text-lg"
      }.freeze

      def apply_button_style(style)
        classes = BUTTON_STYLE_CLASSES[style.to_s.tr("-", "_").to_sym]
        raise ArgumentError, "unknown button style: #{style.inspect}" unless classes

        replace_modifier_classes(:button_style, classes.split)
      end

      def apply_button_size(size)
        classes = BUTTON_SIZE_CLASSES[size.to_s.tr("-", "_").to_sym]
        raise ArgumentError, "unknown button size: #{size.inspect}" unless classes

        replace_modifier_classes(:button_size, classes.split)
      end

      def replace_modifier_classes(modifier, classes)
        @modifier_classes ||= {}
        Array(@modifier_classes[modifier]).each do |class_name|
          index = @css_classes.index(class_name)
          @css_classes.delete_at(index) if index

          if @options[:class]
            @options[:class] = @options[:class].to_s.split.reject { |name| name == class_name }.join(" ")
          end
        end

        new_classes = Array(classes)
        @css_classes.concat(new_classes)
        @modifier_classes[modifier] = new_classes
        self
      end

      def fallback_action_id(event_type, block)
        @fallback_action_sequence ||= 0
        @fallback_action_sequence += 1
        source = block&.source_location&.join("-") || "anonymous"
        fingerprint = Digest::SHA256.hexdigest(
          [source, @fallback_action_sequence, @tag_name, event_type].join("\0")
        ).first(32)

        "a_#{fingerprint}"
      end
      
    end
  end
end
