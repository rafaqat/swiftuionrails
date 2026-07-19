# frozen_string_literal: true

require_relative "dsl/element"
require_relative "dsl/raw_element"
require_relative "dsl/safe_element"
require_relative "dsl/context"
require_relative "dsl/advanced_content"
require_relative "security/css_validator"
require_relative "security/form_helpers"
require_relative "security/url_validator"

module SwiftUIRails
  module DSL
    extend ActiveSupport::Concern
    include Security::FormHelpers

    # Curated single-codepoint glyphs rendered as text inside a fixed-size
    # span. Names outside this allowlist raise; custom artwork should use
    # image() with an SVG asset instead of extending this table ad hoc.
    ICON_GLYPHS = {
      "search" => "⌕",
      "star" => "★",
      "x" => "×",
      "check" => "✓",
      "plus" => "+",
      "minus" => "−",
      "chevron_left" => "‹",
      "chevron_right" => "›",
      "chevron_up" => "⌃",
      "chevron_down" => "⌄",
      "arrow_left" => "←",
      "arrow_right" => "→",
      "arrow_up" => "↑",
      "arrow_down" => "↓",
      "heart" => "♥",
      "circle" => "●",
      "square" => "■",
      "warning" => "⚠",
      "info" => "ℹ",
      "gear" => "⚙",
      "menu" => "☰",
      "sun" => "☀",
      "moon" => "☾",
      "play" => "▶",
      "pause" => "⏸",
      "refresh" => "↻",
      "mail" => "✉",
      "pencil" => "✎",
      "trash" => "⌫",
      "clock" => "◷",
      "bolt" => "⚡",
      "dot" => "•",
      "ellipsis" => "…"
    }.freeze

    # Layout Components
    def vstack(alignment: :center, spacing: 8, **attrs, &block)
      attrs[:class] = class_names("flex flex-col", attrs[:class])
      attrs[:class] += " items-#{alignment_class(alignment)}"
      attrs[:style] = merge_inline_styles(attrs[:style], stack_gap_style(spacing))
      attrs[:data] = merge_data_attributes(attrs[:data], swift_ui_layout_axis: "vertical")
      
      # Create element with special handling for collecting children
      element = create_element(:div, nil, **attrs) do
        if block_given?
          # If we're in a DSL context, the block will be handled properly
          # If not, we need to collect all elements created in the block
          if self.is_a?(SwiftUIRails::DSLContext)
            instance_eval(&block)
          else
            # Outside DSL context - collect all elements
            elements = []
            # Temporarily override create_element to collect elements
            original_create = method(:create_element)
            define_singleton_method(:create_element) do |*args, &inner_block|
              elem = original_create.call(*args, &inner_block)
              elements << elem
              elem
            end
            
            # Execute the block
            instance_eval(&block)
            
            # Restore original method
            define_singleton_method(:create_element, original_create)
            
            # Return all collected elements
            elements
          end
        end
      end
      
      element.child_layout_axis = :vertical
      element
    end

    def hstack(alignment: :center, spacing: 8, **attrs, &block)
      attrs[:class] = class_names("flex flex-row", attrs[:class])
      attrs[:class] += " items-#{alignment_class(alignment)}"
      attrs[:style] = merge_inline_styles(attrs[:style], stack_gap_style(spacing))
      attrs[:data] = merge_data_attributes(attrs[:data], swift_ui_layout_axis: "horizontal")
      
      # Create element with special handling for collecting children
      element = create_element(:div, nil, **attrs) do
        if block_given?
          # If we're in a DSL context, the block will be handled properly
          # If not, we need to collect all elements created in the block
          if self.is_a?(SwiftUIRails::DSLContext)
            instance_eval(&block)
          else
            # Outside DSL context - collect all elements
            elements = []
            # Temporarily override create_element to collect elements
            original_create = method(:create_element)
            define_singleton_method(:create_element) do |*args, &inner_block|
              elem = original_create.call(*args, &inner_block)
              elements << elem
              elem
            end
            
            # Execute the block
            result = instance_eval(&block)
            
            # Restore original method
            define_singleton_method(:create_element, original_create)
            
            # Return all collected elements or the block result if it's an array
            if result.is_a?(Array)
              result
            else
              elements
            end
          end
        end
      end
      
      element.child_layout_axis = :horizontal
      element
    end

    def zstack(alignment: :center, **attrs, &block)
      attrs[:class] = class_names("relative grid", zstack_alignment_classes(alignment), attrs[:class])
      attrs[:data] = merge_data_attributes(attrs[:data], swift_ui_layout_axis: "overlay")
      element = create_element(:div, nil, **attrs, &block)
      element.child_layout_axis = :overlay
      element
    end

    def grid(columns: 2, spacing: 8, **attrs, &block)
      Rails.logger.debug "DSL.grid called with columns: #{columns}, spacing: #{spacing}"
      
      # Extract e-commerce specific properties
      row_gap = attrs.delete(:row_gap) || spacing
      column_gap = attrs.delete(:column_gap) || spacing
      responsive = attrs.delete(:responsive) { true }
      min_item_width = attrs.delete(:min_item_width)
      max_columns = attrs.delete(:max_columns) || columns
      align = attrs.delete(:align) || :stretch
      justify = attrs.delete(:justify) || :start
      auto_rows = attrs.delete(:auto_rows)
      auto_flow = attrs.delete(:auto_flow)
      masonry = attrs.delete(:masonry) { false }

      # cols:/gap: are the docs' historic misspellings of this signature and
      # would otherwise pass through silently as HTML attributes. Name the
      # correct keyword in the error so the fix needs no second lookup.
      if attrs.key?(:cols) || attrs.key?(:gap)
        raise ArgumentError,
              "grid takes columns:/spacing: (not cols:/gap:) — e.g. grid(columns: 3, spacing: 12)"
      end
      
      Rails.logger.debug "DSL.grid min_item_width: #{min_item_width.inspect}"
      
      # Build base grid classes
      grid_classes = ["grid"]
      
      # Handle responsive columns
      if min_item_width
        # Auto-fit grid with minimum item width takes precedence
        grid_classes << "grid-cols-[repeat(auto-fit,minmax(#{min_item_width}px,1fr))]"
      elsif columns.is_a?(Hash)
        # Support responsive object like { base: 1, sm: 2, lg: 3 }
        columns.each do |breakpoint, cols|
          if breakpoint == :base
            grid_classes << Security::CSSValidator.safe_grid_cols_class(cols)
          else
            safe_cols = Security::CSSValidator.safe_grid_cols_class(cols)
            grid_classes << "#{breakpoint}:#{safe_cols}"
          end
        end
      elsif responsive && columns.is_a?(Integer)
        case columns
        when 1
          grid_classes << "grid-cols-1"
        when 2
          grid_classes << "grid-cols-1 sm:grid-cols-2"
        when 3
          grid_classes << "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
        when 4
          grid_classes << "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
        when 5
          grid_classes << "grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5"
        when 6
          grid_classes << "grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6"
        else
          grid_classes << Security::CSSValidator.safe_grid_cols_class(columns)
        end
      else
        grid_classes << Security::CSSValidator.safe_grid_cols_class(columns)
      end
      
      # Handle gap/spacing
      if row_gap == column_gap
        grid_classes << "gap-#{spacing}"
      else
        grid_classes << "gap-x-#{column_gap}" if column_gap > 0
        grid_classes << "gap-y-#{row_gap}" if row_gap > 0
      end
      
      # Alignment and justification
      case align
      when :start
        grid_classes << "items-start"
      when :center
        grid_classes << "items-center"
      when :end
        grid_classes << "items-end"
      when :stretch
        grid_classes << "items-stretch"
      end
      
      case justify
      when :start
        grid_classes << "justify-start"
      when :center
        grid_classes << "justify-center"
      when :end
        grid_classes << "justify-end"
      when :between
        grid_classes << "justify-between"
      when :around
        grid_classes << "justify-around"
      when :evenly
        grid_classes << "justify-evenly"
      end
      
      # Auto rows for consistent heights
      if auto_rows
        case auto_rows
        when :min
          grid_classes << "auto-rows-min"
        when :max
          grid_classes << "auto-rows-max"
        when :fr
          grid_classes << "auto-rows-fr"
        else
          grid_classes << "auto-rows-[#{normalize_grid_auto_rows(auto_rows)}]" if auto_rows.is_a?(String)
        end
      end
      
      # Auto flow for grid item placement
      if auto_flow
        case auto_flow
        when :row
          grid_classes << "grid-flow-row"
        when :column
          grid_classes << "grid-flow-col"
        when :dense
          grid_classes << "grid-flow-dense"
        when :row_dense
          grid_classes << "grid-flow-row-dense"
        when :column_dense
          grid_classes << "grid-flow-col-dense"
        end
      end
      
      # Masonry layout hint (requires CSS/JS support)
      if masonry
        attrs[:data] ||= {}
        attrs[:data][:masonry] = "true"
      end
      
      attrs[:class] = class_names(grid_classes.join(" "), attrs[:class])
      Rails.logger.debug "DSL.grid final class: #{attrs[:class]}"
      create_element(:div, nil, **attrs, &block)
    end
    
    # SwiftUI-inspired grid components
    def grid_item(size_type = :flexible, **options)
      type = size_type.to_sym
      minimum = options.key?(:minimum) ? options[:minimum] : options[:min]
      maximum = options.key?(:maximum) ? options[:maximum] : options[:max]
      alignment = options[:alignment]
      item_spacing = options[:spacing]

      case type
      when :fixed
        {
          type: :fixed,
          size: grid_length(options.fetch(:size, 100), name: "fixed grid item size"),
          alignment: alignment,
          spacing: item_spacing
        }.compact
      when :flexible
        min = grid_length(minimum || 0, name: "flexible grid item minimum")
        max = maximum.nil? ? nil : grid_length(maximum, name: "flexible grid item maximum")
        validate_grid_bounds!(min, max)
        { type: :flexible, min: min, max: max, alignment: alignment, spacing: item_spacing }.compact
      when :adaptive
        min = grid_length(minimum || 80, name: "adaptive grid item minimum")
        max = maximum.nil? ? nil : grid_length(maximum, name: "adaptive grid item maximum")
        validate_grid_bounds!(min, max)
        { type: :adaptive, min: min, max: max, alignment: alignment, spacing: item_spacing }.compact
      else
        raise ArgumentError, "unknown grid item type: #{type.inspect}"
      end
    end
    
    def lazy_vgrid(columns:, spacing: 20, **attrs, &block)
      build_vertical_grid(columns: columns, spacing: spacing, lazy: true, attrs: attrs, &block)
    end

    # Explicit eager counterpart for callers that do not want browser-level
    # rendering deferral.
    def vgrid(columns:, spacing: 20, **attrs, &block)
      build_vertical_grid(columns: columns, spacing: spacing, lazy: false, attrs: attrs, &block)
    end

    def build_vertical_grid(columns:, spacing:, lazy:, attrs:, &block)
      template = grid_template_columns(columns)

      attrs[:class] = class_names("swift-ui-grid", attrs[:class])
      attrs[:data] = merge_data_attributes(
        attrs[:data],
        grid_type: lazy ? "lazy-vgrid" : "vgrid",
        lazy_strategy: lazy ? "content-visibility" : "none"
      )
      if lazy
        # Rails still creates the HTML on the server. content-visibility gives
        # lazy_vgrid honest browser-rendering laziness without pretending that
        # it virtualizes or defers Ruby block evaluation.
        attrs[:style] = merge_inline_styles(
          attrs[:style],
          "content-visibility: auto; contain-intrinsic-size: auto 500px"
        )
      end
      
      div(**attrs) do
        inner_attrs = {
          class: "grid",
          style: merge_inline_styles(
            "grid-template-columns: #{template}",
            stack_gap_style(spacing)
          )
        }
        div(**inner_attrs, &block)
      end
    end
    
    # Grid item wrapper for CSS isolation
    def grid_item_wrapper(**attrs, &block)
      # 'contents' makes wrapper invisible to grid layout
      attrs[:class] = class_names("contents", attrs[:class])
      
      div(**attrs) do
        # Inner container for actual content
        div(class: "swift-ui-grid-item", &block)
      end
    end
    

    # Text Components
    def text(content, **attrs)
      create_element(:span, content, **attrs)
    end

    def label(text_content = nil, for_input: nil, **attrs, &block)
      attrs[:for] = for_input if for_input
      if block_given?
        create_element(:label, nil, **attrs, &block)
      elsif text_content
        create_element(:label, text_content, **attrs)
      else
        create_element(:label, nil, **attrs)
      end
    end

    # Control Components
    def button(title = nil, **attrs, &block)
      # A button nested in a form submits by default in HTML. DSL actions are
      # ordinarily independent controls, so make that safe behavior explicit
      # unless the caller deliberately opts into form submission or reset.
      requested_type = if attrs.key?(:type)
        attrs.delete(:type)
      elsif attrs.key?("type")
        attrs.delete("type")
      end
      normalized_type = requested_type.to_s.downcase
      attrs[:type] = %w[submit reset].include?(normalized_type) ? normalized_type : "button"

      # Pure structure. Ruby action modifiers add semantic event descriptors.
      element = if block_given?
        create_element(:button, nil, **attrs, &block)
      else
        create_element(:button, title, **attrs)
      end
      # Ensure we always return an Element instance for powerful chaining
      element
    end
    
    # Form elements
    def form(**attrs, &block)
      create_element(:form, nil, **attrs, &block)
    end
    
    def input(**attrs, &block)
      create_element(:input, nil, **attrs, &block)
    end

    def textarea(content = nil, **attrs, &block)
      if block
        create_element(:textarea, nil, **attrs, &block)
      else
        create_element(:textarea, content, **attrs)
      end
    end

    def link(title = nil, destination: "#", **attrs, &block)
      attrs[:href] = Security::URLValidator.validate_link_href(destination.to_s) || "#"
      if block_given?
        create_element(:a, nil, **attrs, &block)
      else
        create_element(:a, title, **attrs)
      end
    end

    def textfield(placeholder: "", value: "", **attrs)
      attrs[:type] ||= "text"
      attrs[:placeholder] = placeholder
      attrs[:value] = value
      create_element(:input, nil, **attrs)
    end

    def toggle(label_text, is_on: false, **attrs)
      create_element(:label, nil, **attrs) do
        concat(tag(:input, type: "checkbox", checked: is_on))
        concat(content_tag(:span, label_text))
      end
    end

    def slider(value: 50, min: 0, max: 100, step: 1, **attrs)
      attrs[:type] = "range"
      attrs[:value] = value
      attrs[:min] = min
      attrs[:max] = max
      attrs[:step] = step
      create_element(:input, nil, **attrs)
    end

    def select(name: nil, selected: nil, **attrs, &block)
      attrs[:name] = name if name
      attrs[:value] = selected if selected

      select_block = if block
        proc do
          previous_selection = @swift_ui_selected_option
          @swift_ui_selected_option = selected
          instance_exec(&block)
        ensure
          @swift_ui_selected_option = previous_selection
        end
      end

      create_element(:select, nil, **attrs, &select_block)
    end

    def option(value, text_content = nil, selected: nil, **attrs)
      attrs[:value] = value
      option_selected = if selected.nil?
        !@swift_ui_selected_option.nil? && value.to_s == @swift_ui_selected_option.to_s
      else
        selected
      end
      attrs[:selected] = true if option_selected
      content = text_content || value
      create_element(:option, content, **attrs)
    end

    # DSL Product Card - Reusable product card following DSL-first pattern
    def dsl_product_card(name:, price:, image_url: nil, variant: nil, currency: "$", 
                         show_cta: true, cta_text: "Add to Cart", cta_style: "primary", 
                         **attrs, &block)
      # Build product card using pure DSL chaining
      card do
        # Product image container
        if image_url
          div.aspect("square").overflow("hidden").rounded("md").bg("gray-200") do
            image(src: image_url, alt: name)
              .w("full").h("full").object_fit("cover")
              .hover_scale(105).transition.duration(300)
          end
        end
        
        # Product details
        vstack(spacing: 2, alignment: :start) do
          # Product name
          text(name)
            .font_weight("semibold")
            .text_color("gray-900")
            .text_size("lg")
            .line_clamp(1)
          
          # Variant/color
          if variant
            text(variant)
              .text_color("gray-600")
              .text_size("sm")
          end
          
          # Price
          text("#{currency}#{price}")
            .font_weight("bold")
            .text_color("gray-900")
            .text_size("xl")
            .mt(2)
        end.mt(4)
        
        # CTA Button
        if show_cta
          button_classes = case cta_style
          when "primary"
            "w-full mt-4 px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 transition-colors"
          when "outline"
            "w-full mt-4 px-4 py-2 border-2 border-gray-900 text-gray-900 rounded-md hover:bg-gray-900 hover:text-white transition-colors"
          else # secondary
            "w-full mt-4 px-4 py-2 bg-gray-200 text-gray-900 rounded-md hover:bg-gray-300 transition-colors"
          end
          
          button(cta_text, class: button_classes).font_weight("medium")
        end
        
        # Allow custom content via block
        yield if block_given?
      end
      .p(6)
      .bg("white")
      .rounded("lg")
      .shadow("md")
      .overflow("hidden")
      .merge_attributes(attrs)
    end
    
    # Product list DSL method - renders ProductListComponent with DSL chaining
    def product_list(products:, **attrs)
      # Extract component props from attrs
      columns = attrs.delete(:columns)
      
      # Convert integer columns to symbol
      if columns.is_a?(Integer)
        columns = case columns
        when 1 then :one
        when 2 then :two
        when 3 then :three
        when 4 then :four
        when 5 then :five
        when 6 then :six
        else :auto
        end
      end
      
      component_props = {
        products: products,
        title: attrs.delete(:title),
        columns: columns,
        gap: attrs.delete(:gap),
        background_color: attrs.delete(:background_color),
        title_size: attrs.delete(:title_size),
        title_color: attrs.delete(:title_color),
        container_padding: attrs.delete(:container_padding),
        max_width: attrs.delete(:max_width),
        image_aspect: attrs.delete(:image_aspect),
        show_colors: attrs.delete(:show_colors),
        currency_symbol: attrs.delete(:currency_symbol)
      }.compact
      
      # Create a wrapper element that can be chained
      create_element(:div, nil, **attrs) do
        rendering_available = if view_context.respond_to?(:render_available?)
          view_context.render_available?
        else
          view_context.respond_to?(:render, true)
        end

        if defined?(::ProductListComponent) && rendering_available
          view_context.render(::ProductListComponent.new(**component_props))
        else
          # Fallback for testing or when component not available
          # Render a simple product grid using pure DSL
          # Convert symbol columns back to integer for grid
          grid_columns = case columns
          when :one then 1
          when :two then 2
          when :three then 3
          when :four then 4
          when :five then 5
          when :six then 6
          else 4
          end
          
          grid(columns: grid_columns, spacing: component_props[:gap]&.to_i || 6) do
            products.each do |product|
              # Simplified product card for performance testing
              div.p(4).bg("white").rounded("lg").shadow("md") do
                text(product[:name] || product["name"] || "Product").font_weight("semibold")
                text("#{component_props[:currency_symbol] || "$"}#{product[:price] || product["price"] || 0}").font_weight("bold")
              end
            end
          end
        end
      end
    end
    
    # E-commerce Components with ViewComponent 2.0 Collection Optimization
    # Generic list method - composition-based approach
    def item_list(items:, **attrs, &block)
      # Pure structure for listing items - behavior comes from the block
      attrs[:class] = class_names("space-y-4", attrs[:class])
      
      create_element(:div, nil, **attrs) do
        items.each_with_index do |item, index|
          # Pass both item and index to the block for maximum flexibility
          if block_given?
            instance_exec(item, index, &block)
          else
            # Default rendering if no block provided
            text(item.to_s)
          end
        end
      end
    end
    
    # Grid variant of list for grid layouts
    def grid_list(items:, columns: 3, **attrs, &block)
      attrs[:class] = class_names("grid gap-4", attrs[:class])
      attrs[:class] += " grid-cols-#{columns}"
      
      create_element(:div, nil, **attrs) do
        items.each_with_index do |item, index|
          if block_given?
            instance_exec(item, index, &block)
          else
            text(item.to_s)
          end
        end
      end
    end
    
    # ViewComponent 2.0 Collection-optimized rendering methods
    def card_collection(items:, **attrs, &block)
      # Use ViewComponent 2.0 collection rendering for 10x performance
      CardComponent.card_collection(cards: items, **attrs, &block)
    end
    
    def button_collection(items:, **attrs, &block)
      # Use ViewComponent 2.0 collection rendering for 10x performance  
      SimpleButtonComponent.button_collection(buttons: items, **attrs, &block)
    end
    
    # Layout collection optimizations
    def vstack_collection(items:, spacing: 8, **attrs, &block)
      # Render collection in vertical stack with ViewComponent 2.0 performance
      vstack(spacing: spacing, **attrs) do
        if block_given?
          items.each_with_index do |item, index|
            block.call(item, index)
          end
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end
    
    def hstack_collection(items:, spacing: 8, **attrs, &block)
      # Render collection in horizontal stack with ViewComponent 2.0 performance
      hstack(spacing: spacing, **attrs) do
        if block_given?
          items.each_with_index do |item, index|
            block.call(item, index)
          end
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end
    
    def grid_collection(items:, columns: 3, spacing: 8, **attrs, &block)
      # Render collection in grid with ViewComponent 2.0 performance
      grid(columns: columns, spacing: spacing, **attrs) do
        if block_given?
          items.each_with_index do |item, index|
            block.call(item, index)
          end
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end

    # Container Components - Simplified for composition
    def card(**attrs, &block)
      # Extract slot attributes
      header_slot = attrs.delete(:header)
      content_slot = attrs.delete(:content)
      actions_slot = attrs.delete(:actions)
      elevation = attrs.delete(:elevation) || 1
      
      # Apply elevation shadow
      shadow_class = case elevation
      when 0 then ""
      when 1 then "shadow"
      when 2 then "shadow-md"
      when 3 then "shadow-lg"
      when 4 then "shadow-xl"
      else "shadow-2xl"
      end
      
      # Simple card container - just structure and styling
      attrs[:class] = class_names("bg-white rounded-lg", shadow_class, attrs[:class])
      
      # For slots, we need to ensure they render properly
      if header_slot || content_slot || actions_slot
        # Build content array first
        content_parts = []
        
        if header_slot
          header_content = if header_slot.is_a?(Proc)
            result = instance_eval(&header_slot)
            result.respond_to?(:to_s) ? result.to_s : ""
          else
            header_slot.to_s
          end
          content_parts << create_element(:div, header_content.html_safe, class: "p-4 border-b")
        end
        
        if content_slot
          content_content = if content_slot.is_a?(Proc)
            result = instance_eval(&content_slot)
            result.respond_to?(:to_s) ? result.to_s : ""
          else
            content_slot.to_s
          end
          content_parts << create_element(:div, content_content.html_safe, class: "p-4")
        end
        
        if actions_slot
          actions_content = if actions_slot.is_a?(Array)
            create_element(:div, nil, class: "flex flex-row items-center space-x-2") do
              actions_slot.map do |action|
                if action.is_a?(Proc)
                  result = instance_eval(&action)
                  result.respond_to?(:to_s) ? result : ""
                else
                  action
                end
              end
            end.to_s
          else
            if actions_slot.is_a?(Proc)
              result = instance_eval(&actions_slot)
              result.respond_to?(:to_s) ? result.to_s : ""
            else
              actions_slot.to_s
            end
          end
          content_parts << create_element(:div, actions_content.html_safe, class: "p-4 border-t")
        end
        
        # Return the element with all content parts
        create_element(:div, nil, **attrs) do
          content_parts
        end
      else
        # No slots - use normal block handling
        create_element(:div, nil, **attrs, &block)
      end
    end
    
    def card_header(**attrs, &block)
      # A helper for a styled header region
      attrs[:class] = class_names("p-4 border-b", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_content(**attrs, &block)
      # A helper for the main content area
      attrs[:class] = class_names("p-4", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_footer(**attrs, &block)
      # A helper for a styled footer region
      attrs[:class] = class_names("p-4 border-t", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_section(**attrs, &block)
      # A helper for additional card sections
      attrs[:class] = class_names("p-4", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def list(items: nil, **attrs, &block)
      return item_list(items: items, **attrs, &block) if items

      create_element(:ul, nil, **attrs, &block)
    end

    def list_item(**attrs, &block)
      create_element(:li, nil, **attrs, &block)
    end

    def scroll_view(**attrs, &block)
      attrs[:class] = class_names("overflow-auto", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    # Media Components with SECURITY validation
    def image(source = nil, src: nil, alt: "", **attrs)
      source = src || source
      raise ArgumentError, "image requires src attribute" unless source
      
      # SECURITY: Validate image source URL
      safe_src = Security::URLValidator.validate_image_src(source)
      unless safe_src
        Rails.logger.warn "Invalid image source blocked: #{source}"
        safe_src = '/images/placeholder.png'
      end
      
      attrs[:src] = safe_src
      attrs[:alt] = alt
      attrs[:loading] ||= "lazy" # Default to lazy loading
      create_element(:img, nil, **attrs)
    end

    def icon(name, size: 16, **attrs)
      pixel_size = Integer(size)
      unless pixel_size.between?(1, 256)
        raise ArgumentError, "icon size must be between 1 and 256 pixels"
      end

      glyph = ICON_GLYPHS.fetch(name.to_s) do
        raise ArgumentError, "unknown icon: #{name}; expected one of: #{ICON_GLYPHS.keys.join(', ')}"
      end

      attrs[:class] = class_names("inline-block", attrs[:class])
      attrs[:style] = [attrs[:style], "width: #{pixel_size}px; height: #{pixel_size}px; line-height: 1;"].compact.join(" ")
      attrs[:aria] = { hidden: true }.merge(attrs.fetch(:aria, {}))
      create_element(:span, glyph, **attrs)
    end

    # Layout Helpers
    def spacer(min_length: nil, **attrs)
      axis = current_layout_axis
      axis_class = axis == :horizontal ? "min-w-0" : "min-h-0"
      attrs[:class] = class_names("flex-1 #{axis_class}", attrs[:class])
      attrs[:aria] = { hidden: true }.merge(attrs.fetch(:aria, {}))
      attrs[:data] = merge_data_attributes(attrs[:data], spacer_axis: axis || "unspecified")

      if min_length
        property = axis == :horizontal ? "min-width" : "min-height"
        attrs[:style] = merge_inline_styles(
          attrs[:style],
          "#{property}: #{css_point_length(min_length, name: "spacer min_length")}"
        )
      end

      create_element(:div, "", **attrs)
    end

    def divider(**attrs)
      if current_layout_axis == :horizontal
        attrs[:class] = class_names("self-stretch w-0 border-0 border-l border-gray-300", attrs[:class])
        attrs[:role] ||= "separator"
        attrs[:aria] = { orientation: "vertical" }.merge(attrs.fetch(:aria, {}))
        create_element(:div, nil, **attrs)
      else
        attrs[:class] = class_names("self-stretch h-0 border-0 border-t border-gray-300", attrs[:class])
        attrs[:aria] = { orientation: "horizontal" }.merge(attrs.fetch(:aria, {}))
        create_element(:hr, nil, **attrs)
      end
    end

    def div(content = nil, **attrs, &block)
      Rails.logger.debug "DSL.div called with block: #{block_given?}"
      create_element(:div, content, **attrs, &block)
    end
    
    def span(content = nil, **attrs, &block)
      create_element(:span, content, **attrs, &block)
    end
    
    def section(content = nil, **attrs, &block)
      Rails.logger.debug "DSL.section called with block: #{block_given?}, attrs: #{attrs.inspect}"
      create_element(:section, content, **attrs, &block)
    end
    
    def article(content = nil, **attrs, &block)
      create_element(:article, content, **attrs, &block)
    end
    
    def header(content = nil, **attrs, &block)
      create_element(:header, content, **attrs, &block)
    end
    
    def footer(content = nil, **attrs, &block)
      create_element(:footer, content, **attrs, &block)
    end
    
    def nav(content = nil, **attrs, &block)
      create_element(:nav, content, **attrs, &block)
    end

    def main(content = nil, **attrs, &block)
      create_element(:main, content, **attrs, &block)
    end

    def aside(content = nil, **attrs, &block)
      create_element(:aside, content, **attrs, &block)
    end
    
    def a(content = nil, **attrs, &block)
      create_element(:a, content, **attrs, &block)
    end
    
    def h1(content = nil, **attrs, &block)
      create_element(:h1, content, **attrs, &block)
    end
    
    def h2(content = nil, **attrs, &block)
      create_element(:h2, content, **attrs, &block)
    end
    
    def h3(content = nil, **attrs, &block)
      create_element(:h3, content, **attrs, &block)
    end
    
    def h4(content = nil, **attrs, &block)
      create_element(:h4, content, **attrs, &block)
    end
    
    def h5(content = nil, **attrs, &block)
      create_element(:h5, content, **attrs, &block)
    end
    
    def h6(content = nil, **attrs, &block)
      create_element(:h6, content, **attrs, &block)
    end
    
    def p(content = nil, **attrs, &block)
      create_element(:p, content, **attrs, &block)
    end

    # Tabular data elements. Semantic passthroughs like div/section — table
    # structure stays native HTML so screen readers get real row/column
    # semantics instead of a div grid.
    def table(content = nil, **attrs, &block)
      create_element(:table, content, **attrs, &block)
    end

    def thead(content = nil, **attrs, &block)
      create_element(:thead, content, **attrs, &block)
    end

    def tbody(content = nil, **attrs, &block)
      create_element(:tbody, content, **attrs, &block)
    end

    def tr(content = nil, **attrs, &block)
      create_element(:tr, content, **attrs, &block)
    end

    def th(content = nil, **attrs, &block)
      attrs[:scope] ||= "col"
      create_element(:th, content, **attrs, &block)
    end

    def td(content = nil, **attrs, &block)
      create_element(:td, content, **attrs, &block)
    end

    def caption(content = nil, **attrs, &block)
      create_element(:caption, content, **attrs, &block)
    end

    # Native <dialog> passthrough for custom modal surfaces. Prefer sheet()
    # for standard presentations — this exists for cases like command
    # palettes where the presentation chrome is bespoke.
    def dialog(content = nil, **attrs, &block)
      create_element(:dialog, content, **attrs, &block)
    end

    # Loading Components
    def spinner(size: :md, border_color: nil, spinner_color: nil)
      size_classes = {
        xs: "h-3 w-3",
        sm: "h-4 w-4",
        md: "h-5 w-5",
        lg: "h-6 w-6",
        xl: "h-8 w-8"
      }
      
      border_class = border_color ? "border-#{border_color}" : ""
      spinner_class = spinner_color ? "border-t-#{spinner_color}" : ""
      
      create_element(:div, nil, class: "inline-flex items-center") do
        content_tag(:div, "", class: "animate-spin rounded-full border-2 #{border_class} #{spinner_class} #{size_classes[size]}")
      end
    end

    private
    
    def grid_template_columns(grid_items)
      unless grid_items.is_a?(Array) && grid_items.any?
        raise ArgumentError, "columns must be a non-empty array of grid_item values"
      end

      adaptive_count = grid_items.count { |item| item.is_a?(Hash) && item[:type] == :adaptive }
      if adaptive_count > 1
        raise ArgumentError, "only one adaptive grid_item can be represented by a CSS auto-repeat track"
      end

      grid_items.map do |item|
        unless item.is_a?(Hash) && %i[fixed flexible adaptive].include?(item[:type])
          raise ArgumentError, "columns must contain values returned by grid_item"
        end

        case item[:type]
        when :fixed
          css_grid_length(item.fetch(:size))
        when :flexible
          minimum = css_grid_length(item.fetch(:min, 0))
          maximum = item[:max] ? css_grid_length(item[:max]) : "1fr"
          "minmax(#{minimum}, #{maximum})"
        when :adaptive
          minimum = css_grid_length(item.fetch(:min))
          maximum = item[:max] ? css_grid_length(item[:max]) : "1fr"
          "repeat(auto-fit, minmax(min(100%, #{minimum}), #{maximum}))"
        end
      end.join(" ")
    end

    def normalize_grid_auto_rows(value)
      normalized = value.strip.gsub(/\s+/, "_")
      length = /(?:0|\d+(?:\.\d+)?(?:px|rem|em|%|fr))/
      endpoint = /(?:auto|min-content|max-content|#{length})/
      return normalized if normalized.match?(/\Aminmax\(#{length},_#{endpoint}\)\z/)

      raise ArgumentError, "auto_rows must be :min, :max, :fr, or a safe minmax CSS track"
    end

    def alignment_class(alignment)
      case alignment
      when :top, :start, :leading then "start"
      when :center then "center"
      when :bottom, :end, :trailing then "end"
      else "center"
      end
    end

    def zstack_alignment_classes(alignment)
      normalized = alignment.to_s
        .gsub(/([a-z])([A-Z])/, '\\1_\\2')
        .tr("-", "_")
        .downcase

      {
        "center" => "items-center justify-items-center",
        "leading" => "items-center justify-items-start",
        "trailing" => "items-center justify-items-end",
        "top" => "items-start justify-items-center",
        "bottom" => "items-end justify-items-center",
        "top_leading" => "items-start justify-items-start",
        "top_trailing" => "items-start justify-items-end",
        "bottom_leading" => "items-end justify-items-start",
        "bottom_trailing" => "items-end justify-items-end"
      }.fetch(normalized) do
        raise ArgumentError, "unknown ZStack alignment: #{alignment.inspect}"
      end
    end

    def stack_gap_style(spacing)
      "gap: #{css_point_length(spacing, name: "stack spacing")}"
    end

    def css_point_length(value, name: "length")
      number = Float(value)
      unless number.finite? && number >= 0
        raise ArgumentError, "#{name} must be a finite, non-negative number"
      end

      formatted = number == number.to_i ? number.to_i.to_s : number.to_s
      "#{formatted}px"
    rescue ArgumentError, TypeError
      raise ArgumentError, "#{name} must be a finite, non-negative number"
    end

    def grid_length(value, name:)
      Float(css_point_length(value, name: name).delete_suffix("px"))
    end

    def css_grid_length(value)
      css_point_length(value, name: "grid track size")
    end

    def validate_grid_bounds!(minimum, maximum)
      return unless maximum && maximum < minimum

      raise ArgumentError, "grid item maximum must be greater than or equal to its minimum"
    end

    def merge_inline_styles(*styles)
      styles.compact.map(&:to_s).map { |style| style.strip.sub(/;\z/, "") }.reject(&:empty?).join("; ")
    end

    def merge_data_attributes(existing, additions)
      (existing || {}).merge(additions) { |_key, original, _new_value| original }
    end

    def current_layout_axis
      if is_a?(SwiftUIRails::DSLContext)
        layout_axis
      elsif instance_variable_defined?(:@_swift_ui_dsl_context)
        instance_variable_get(:@_swift_ui_dsl_context)&.layout_axis
      end
    end

    # Override concat to handle Element instances
    def concat(content)
      if defined?(Element) && content.is_a?(Element)
        super(content.to_s.html_safe)
      else
        super(content)
      end
    end
    
    private
    
    # Create a chainable element
    def create_element(tag_name, content = nil, options = {}, &block)
      # Component helper methods execute on the component rather than on the
      # DSLContext. DSLContext temporarily exposes the active nested context so
      # elements created by those helpers remain children of the right parent.
      dsl_context = if is_a?(SwiftUIRails::DSLContext)
        self
      elsif instance_variable_defined?(:@_swift_ui_dsl_context)
        instance_variable_get(:@_swift_ui_dsl_context)
      end
      element = Element.new(tag_name, content, options, dsl_context, &block)

      # CSS Grid does not overlap auto-placed children by default. Direct
      # ZStack children explicitly share the first grid cell, so the largest
      # child establishes the container's size and the rest genuinely overlay.
      if dsl_context&.layout_axis == :overlay
        element.add_class("col-start-1 row-start-1")
      end
      
      # Set the view context for Rails helper access
      if dsl_context
        element.view_context = dsl_context.view_context
      else
        element.view_context = self
      end
      
      # Store component reference for event handling
      if !is_a?(SwiftUIRails::DSLContext) && respond_to?(:component_id)
        Rails.logger.debug "Storing component on element: #{self.class.name}, component_id=#{self.component_id}"
        element.instance_variable_set(:@component, self)
      elsif dsl_context&.component
        Rails.logger.debug "Storing component from context: #{dsl_context.component.class.name}, component_id=#{dsl_context.component.component_id}"
        element.instance_variable_set(:@component, dsl_context.component)
      end
      
      # Register the element only if we're in a DSL context
      # This prevents double registration when blocks return elements
      if dsl_context
        Rails.logger.debug "[DSL] Registering element #{tag_name} to context #{self.object_id}"
        dsl_context.register_element(element)
      else
        Rails.logger.debug "[DSL] Created element #{tag_name} outside DSL context - not registering"
      end
      
      element
    end
  end
end
