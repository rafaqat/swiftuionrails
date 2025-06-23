# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Element wrapper that enables method chaining for DSL methods
    class Element
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::OutputSafetyHelper
      
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
        @block = block if block_given?
        self
      end
      
      # Add margin-right utility
      def mr(size, &block)
        tw("mr-#{size}", &block)
      end
      
      # Add margin-left utility  
      def ml(size, &block)
        tw("ml-#{size}", &block)
      end
      
      # Add margin utilities
      def m(size, &block)
        tw("m-#{size}", &block)
      end
      
      def mt(size, &block)
        tw("mt-#{size}", &block)
      end
      
      def mb(size, &block)
        tw("mb-#{size}", &block)
      end
      
      # Add padding utilities
      def p(size, &block)
        tw("p-#{size}", &block)
      end
      
      def padding(size, &block)
        tw("p-#{size}", &block)
      end
      
      def pt(size, &block)
        tw("pt-#{size}", &block)
      end
      
      def pb(size, &block)
        tw("pb-#{size}", &block)
      end
      
      def pl(size, &block)
        tw("pl-#{size}", &block)
      end
      
      def pr(size, &block)
        tw("pr-#{size}", &block)
      end
      
      def px(size, &block)
        tw("px-#{size}", &block)
      end
      
      def py(size, &block)
        tw("py-#{size}", &block)
      end
      
      # Add margin-x and margin-y utilities
      def mx(size, &block)
        tw("mx-#{size}", &block)
      end
      
      def my(size, &block)
        tw("my-#{size}", &block)
      end
      
      # Width utilities
      def max_w(size, &block)
        tw("max-w-#{size}", &block)
      end
      
      def w(size, &block)
        tw("w-#{size}", &block)
      end
      
      def min_w(size, &block)
        tw("min-w-#{size}", &block)
      end
      
      # Height utilities
      def h(size)
        tw("h-#{size}")
      end
      
      def max_h(size)
        tw("max-h-#{size}")
      end
      
      def min_h(size)
        tw("min-h-#{size}")
      end
      
      # Text utilities
      def text_size(size, &block)
        tw("text-#{size}", &block)
      end
      
      def font_size(size, &block)
        tw("text-#{size}", &block)
      end
      
      def text_color(color, &block)
        tw("text-#{color}", &block)
      end
      
      def font_weight(weight, &block)
        tw("font-#{weight}", &block)
      end
      
      def text_align(alignment, &block)
        tw("text-#{alignment}", &block)
      end
      
      def line_clamp(lines, &block)
        tw("line-clamp-#{lines}", &block)
      end
      
      def italic(&block)
        tw("italic", &block)
      end
      
      def underline(&block)
        tw("underline", &block)
      end
      
      # Background utilities
      def bg(color, &block)
        tw("bg-#{color}", &block)
      end
      
      def background(color, &block)
        tw("bg-#{color}", &block)
      end
      
      # Border utilities
      def border(width = nil)
        if width
          tw("border-#{width}")
        else
          tw("border")
        end
      end
      
      def rounded(size = "", &block)
        tw(size.empty? ? "rounded" : "rounded-#{size}", &block)
      end
      
      def corner_radius(size, &block)
        tw("rounded-#{size}", &block)
      end
      
      # Display utilities
      def flex
        tw("flex")
      end
      
      def block
        tw("block")
      end
      
      def inline
        tw("inline")
      end
      
      def hidden
        tw("hidden")
      end
      
      # Shadow utilities
      def shadow(size = "")
        tw(size.empty? ? "shadow" : "shadow-#{size}")
      end
      
      # Button utilities
      def button_style(style, &block)
        case style
        when :primary
          tw("bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded", &block)
        when :secondary
          tw("bg-gray-200 hover:bg-gray-300 text-gray-900 font-medium py-2 px-4 rounded", &block)
        when :success
          tw("bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded", &block)
        when :danger
          tw("bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded", &block)
        when :outline
          tw("border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 px-4 rounded", &block)
        else
          self
        end
      end
      
      def button_size(size, &block)
        case size
        when :xs
          tw("px-2 py-1 text-xs", &block)
        when :sm
          tw("px-3 py-1.5 text-sm", &block)
        when :md
          tw("px-4 py-2 text-sm", &block)
        when :lg
          tw("px-6 py-3 text-base", &block)
        when :xl
          tw("px-8 py-4 text-lg", &block)
        else
          self
        end
      end
      
      # Hover effects
      def hover_scale(scale, &block)
        tw("hover:scale-#{scale} transition-transform", &block)
      end
      
      # Layout utilities
      def w_full(&block)
        tw("w-full", &block)
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
      
      # Image utilities
      def aspect_ratio(ratio, &block)
        tw("aspect-#{ratio}", &block)
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
      
      # Flexbox utilities
      def flex_grow(&block)
        tw("flex-grow", &block)
      end
      
      def flex_shrink(&block)
        tw("flex-shrink", &block)
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
      
      # Convert to HTML string
      def to_s
        # Merge CSS classes
        if @css_classes.any?
          existing_classes = @options[:class] || ""
          all_classes = [existing_classes, @css_classes.join(" ")].reject(&:blank?).join(" ")
          @options[:class] = all_classes
        end
        
        # Merge other attributes
        @options.merge!(@attributes)
        
        # Handle the content/block
        if @block
          # Execute the block and capture all content
          if @dsl_context
            # Save current pending elements
            old_pending = @dsl_context.instance_variable_get(:@pending_elements)
            @dsl_context.instance_variable_set(:@pending_elements, [])
            
            # Execute the block to collect child elements
            @dsl_context.instance_eval(&@block)
            
            # Get the rendered content from collected elements
            content = @dsl_context.flush_elements
            
            # Restore previous pending elements
            @dsl_context.instance_variable_set(:@pending_elements, old_pending)
          else
            # Fallback to standard capture
            content = @view_context.capture(&@block)
          end
          
          @view_context.content_tag(@tag_name, (content || "").html_safe, @options)
        elsif @content
          @view_context.content_tag(@tag_name, @content, @options)
        else
          # For text-like elements, use content_tag with empty string to get <span></span> instead of <span />
          if [:span, :p, :h1, :h2, :h3, :h4, :h5, :h6, :div, :label, :button].include?(@tag_name)
            @view_context.content_tag(@tag_name, "", @options)
          else
            @view_context.tag(@tag_name, @options)
          end
        end
      rescue => e
        Rails.logger.error "Element.to_s failed: #{e.message} for tag #{@tag_name.inspect}"
        ""
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
      def background(color)
        if color.start_with?('#')
          # Hex color - use inline style
          @options[:style] = [@options[:style], "background-color: #{color}"].compact.join('; ')
        else
          # Tailwind class
          tw("bg-#{color}")
        end
        self
      end
      
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
        case style.to_sym
        when :primary
          tw("bg-blue-600 hover:bg-blue-700 text-white")
        when :secondary  
          tw("bg-gray-200 hover:bg-gray-300 text-gray-900")
        when :danger
          tw("bg-red-600 hover:bg-red-700 text-white")
        when :success
          tw("bg-green-600 hover:bg-green-700 text-white")
        when :warning
          tw("bg-yellow-500 hover:bg-yellow-600 text-white")
        end
        self
      end
      
      def disabled(is_disabled = true)
        if is_disabled
          tw("opacity-50 cursor-not-allowed")
          @options[:disabled] = true
        end
        self
      end
      
      # Size modifiers for buttons
      def button_size(size)
        case size.to_sym
        when :sm
          tw("px-3 py-2 text-sm")
        when :md
          tw("px-4 py-2 text-sm") 
        when :lg
          tw("px-6 py-3 text-base")
        when :xl
          tw("px-8 py-4 text-lg")
        end
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
      
      def hover_scale(scale)
        @options[:hover_scale] = scale
        self
      end
      
      def currency(symbol)
        @options[:currency_symbol] = symbol
        self
      end
      
    end
  end
end