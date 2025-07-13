# frozen_string_literal: true

# Copyright 2025

require_relative 'dsl/element'
require_relative 'dsl/safe_element'
require_relative 'dsl/context'
require_relative 'security/css_validator'
require_relative 'security/form_helpers'
require_relative 'security/url_validator'
require_relative 'orientation'

module SwiftUIRails
  module DSL
    extend ActiveSupport::Concern
    include Security::FormHelpers
    include Orientation::Helpers
    include Orientation::SizeClasses

    # Layout Components
    def vstack(alignment: :center, spacing: 8, **attrs, &block)
      attrs[:class] = class_names('flex flex-col', attrs[:class])
      attrs[:class] += " items-#{alignment_class(alignment)}"
      attrs[:class] += " space-y-#{spacing}" if spacing.positive?

      # Create element with special handling for collecting children
      create_element(:div, nil, **attrs) do
        if block
          # If we're in a DSL context, the block will be handled properly
          # If not, we need to collect all elements created in the block
          if is_a?(SwiftUIRails::DSLContext)
            # Execute the block and capture any returned element
            result = instance_eval(&block)
            # If the block returns an element, ensure it's registered
            register_element(result) if result.is_a?(Element) && @pending_elements.exclude?(result)
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
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
            elsif result.is_a?(Element) && elements.exclude?(result)
              elements << result
              elements
            else
              elements
            end
          end
        end
      end
    end

    def hstack(alignment: :center, spacing: 8, **attrs, &block)
      attrs[:class] = class_names('flex flex-row', attrs[:class])
      attrs[:class] += " items-#{alignment_class(alignment)}"
      attrs[:class] += " space-x-#{spacing}" if spacing.positive?

      # Create element with special handling for collecting children
      create_element(:div, nil, **attrs) do
        if block
          # If we're in a DSL context, the block will be handled properly
          # If not, we need to collect all elements created in the block
          if is_a?(SwiftUIRails::DSLContext)
            # Execute the block and capture any returned element
            result = instance_eval(&block)
            # If the block returns an element, ensure it's registered
            register_element(result) if result.is_a?(Element) && @pending_elements.exclude?(result)
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
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
    end

    def zstack(**attrs, &block)
      attrs[:class] = class_names('relative', attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def grid(columns: 2, spacing: 8, **attrs, &block)
      Rails.logger.debug { "DSL.grid called with columns: #{columns}, spacing: #{spacing}" }

      # Extract e-commerce specific properties
      row_gap = attrs.delete(:row_gap) || spacing
      column_gap = attrs.delete(:column_gap) || spacing
      responsive = attrs.delete(:responsive) { true }
      min_item_width = attrs.delete(:min_item_width)
      attrs.delete(:max_columns) || columns
      align = attrs.delete(:align) || :stretch
      justify = attrs.delete(:justify) || :start
      auto_rows = attrs.delete(:auto_rows)
      auto_flow = attrs.delete(:auto_flow)
      masonry = attrs.delete(:masonry) { false }

      Rails.logger.debug { "DSL.grid min_item_width: #{min_item_width.inspect}" }

      # Build base grid classes
      grid_classes = ['grid']

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
        grid_classes << case columns
                        when 1
                          'grid-cols-1'
                        when 2
                          'grid-cols-1 sm:grid-cols-2'
                        when 3
                          'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
                        when 4
                          'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                        when 5
                          'grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5'
                        when 6
                          'grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6'
                        else
                          Security::CSSValidator.safe_grid_cols_class(columns)
                        end
      else
        grid_classes << Security::CSSValidator.safe_grid_cols_class(columns)
      end

      # Handle gap/spacing
      if row_gap == column_gap
        grid_classes << "gap-#{spacing}"
      else
        grid_classes << "gap-x-#{column_gap}" if column_gap.positive?
        grid_classes << "gap-y-#{row_gap}" if row_gap.positive?
      end

      # Alignment and justification
      case align
      when :start
        grid_classes << 'items-start'
      when :center
        grid_classes << 'items-center'
      when :end
        grid_classes << 'items-end'
      when :stretch
        grid_classes << 'items-stretch'
      end

      case justify
      when :start
        grid_classes << 'justify-start'
      when :center
        grid_classes << 'justify-center'
      when :end
        grid_classes << 'justify-end'
      when :between
        grid_classes << 'justify-between'
      when :around
        grid_classes << 'justify-around'
      when :evenly
        grid_classes << 'justify-evenly'
      end

      # Auto rows for consistent heights
      if auto_rows
        case auto_rows
        when :min
          grid_classes << 'auto-rows-min'
        when :max
          grid_classes << 'auto-rows-max'
        when :fr
          grid_classes << 'auto-rows-fr'
        else
          grid_classes << "auto-rows-[#{auto_rows}]" if auto_rows.is_a?(String)
        end
      end

      # Auto flow for grid item placement
      if auto_flow
        case auto_flow
        when :row
          grid_classes << 'grid-flow-row'
        when :column
          grid_classes << 'grid-flow-col'
        when :dense
          grid_classes << 'grid-flow-dense'
        when :row_dense
          grid_classes << 'grid-flow-row-dense'
        when :column_dense
          grid_classes << 'grid-flow-col-dense'
        end
      end

      # Masonry layout hint (requires CSS/JS support)
      if masonry
        attrs[:data] ||= {}
        attrs[:data][:masonry] = 'true'
        grid_classes << 'masonry-grid'
      end

      attrs[:class] = class_names(grid_classes.join(' '), attrs[:class])
      Rails.logger.debug { "DSL.grid final class: #{attrs[:class]}" }
      create_element(:div, nil, **attrs, &block)
    end

    # SwiftUI-inspired grid components
    def grid_item(size_type = :flexible, **options)
      case size_type
      when :fixed
        { type: :fixed, size: options[:size] || 100 }
      when :flexible
        { type: :flexible, min: options[:min], max: options[:max] }
      when :adaptive
        { type: :adaptive, min: options[:min] || 80, max: options[:max] }
      else
        { type: :flexible }
      end
    end

    def lazy_vgrid(columns:, spacing: 20, **attrs, &block)
      # Calculate responsive grid classes based on GridItem specs
      grid_classes = calculate_grid_classes(columns)

      # Main grid container with isolation
      attrs[:class] = class_names('swift-ui-grid', attrs[:class])
      attrs[:data] ||= {}
      attrs[:data][:grid_type] = 'lazy-vgrid'

      div(**attrs) do
        # Grid implementation with proper isolation
        inner_attrs = { class: "grid gap-#{spacing} #{grid_classes}" }
        div(**inner_attrs, &block)
      end
    end

    # Grid item wrapper for CSS isolation
    def grid_item_wrapper(**attrs, &block)
      # 'contents' makes wrapper invisible to grid layout
      attrs[:class] = class_names('contents', attrs[:class])

      div(**attrs) do
        # Inner container for actual content
        div(class: 'swift-ui-grid-item', &block)
      end
    end

    # Text Components
    def text(content, **attrs)
      create_element(:span, content, **attrs)
    end

    def label(text_content = nil, for_input: nil, **attrs, &block)
      attrs[:for] = for_input if for_input
      if block
        create_element(:label, nil, **attrs, &block)
      elsif text_content
        create_element(:label, text_content, **attrs)
      else
        create_element(:label, nil, **attrs)
      end
    end

    # Control Components
    def button(title = nil, **attrs, &block)
      # Pure structure - no behavior. Behavior is handled by Stimulus
      if block
        create_element(:button, nil, **attrs, &block)
      else
        create_element(:button, title, **attrs)
      end
      # Ensure we always return an Element instance for powerful chaining
    end

    # Form elements
    def form(**attrs, &block)
      create_element(:form, nil, **attrs, &block)
    end

    # Secure form with CSRF protection
    def secure_form(action:, method: 'POST', **attrs)
      # Create the form element
      create_element(:form, nil, action: action, method: method.to_s.casecmp('GET').zero? ? 'GET' : 'POST', **attrs) do
        elements = []

        # Add CSRF token for non-GET requests if we can
        if !method.to_s.casecmp('GET').zero? && respond_to?(:protect_against_forgery?) && protect_against_forgery? && respond_to?(:get_form_authenticity_token)
          token = get_form_authenticity_token
          param = respond_to?(:request_forgery_protection_token) ? request_forgery_protection_token : :authenticity_token
          elements << create_element(:input, nil,
                                     type: 'hidden',
                                     name: param.to_s,
                                     value: token,
                                     autocomplete: 'off')
        end

        # Add method override for non-POST/GET methods
        if %w[PUT PATCH DELETE].include?(method.to_s.upcase)
          elements << create_element(:input, nil,
                                     type: 'hidden',
                                     name: '_method',
                                     value: method.to_s.downcase,
                                     autocomplete: 'off')
        end

        # Add UTF-8 enforcer
        elements << create_element(:input, nil,
                                   type: 'hidden',
                                   name: 'utf8',
                                   value: '✓',
                                   autocomplete: 'off')

        # Add block content
        if block_given?
          block_result = yield
          if block_result.is_a?(Array)
            elements.concat(block_result)
          elsif block_result
            elements << block_result
          end
        end

        elements
      end
    end

    def input(**attrs, &block)
      create_element(:input, nil, **attrs, &block)
    end

    def link(title = nil, destination: '#', **attrs, &block)
      attrs[:href] = destination
      if block
        create_element(:a, nil, **attrs, &block)
      else
        create_element(:a, title, **attrs)
      end
    end

    def textfield(placeholder: '', value: '', **attrs)
      attrs[:type] ||= 'text'
      attrs[:placeholder] = placeholder
      attrs[:value] = value
      create_element(:input, nil, **attrs)
    end

    def toggle(label_text, is_on: false, **attrs)
      create_element(:label, nil, **attrs) do
        concat(tag.input(type: 'checkbox', checked: is_on))
        concat(content_tag(:span, label_text))
      end
    end

    def slider(value: 50, min: 0, max: 100, step: 1, **attrs)
      attrs[:type] = 'range'
      attrs[:value] = value
      attrs[:min] = min
      attrs[:max] = max
      attrs[:step] = step
      create_element(:input, nil, **attrs)
    end

    def select(name: nil, selected: nil, **attrs, &block)
      attrs[:name] = name if name
      attrs[:value] = selected if selected
      create_element(:select, nil, **attrs, &block)
    end

    def option(value, text_content = nil, selected: false, **attrs)
      attrs[:value] = value
      attrs[:selected] = selected if selected
      content = text_content || value
      create_element(:option, content, **attrs)
    end

    # DSL Product Card - Reusable product card following DSL-first pattern
    def dsl_product_card(name:, price:, image_url: nil, variant: nil, currency: '$',
                         show_cta: true, cta_text: 'Add to Cart', cta_style: 'primary',
                         elevation: 2, **attrs)
      # Build product card using pure DSL chaining
      # Main container with group and relative for hover effects
      div(class: 'group relative') do
        card(elevation: elevation) do
          # Product image container
          if image_url
            div.aspect('square').overflow('hidden').rounded('md').bg('gray-200') do
              image(src: image_url, alt: "#{name}#{variant ? " in #{variant}" : ''}")
                .w('full').h('full').object('cover')
                .hover_scale(105).transition.duration(300)
            end
          end

          # Product details
          vstack(spacing: 2, alignment: :start) do
            # Product name
            text(name)
              .font_weight('semibold')
              .text_color('gray-900')
              .text_size('lg')
              .line_clamp(1)

            # Variant/color
            if variant
              text(variant)
                .text_color('gray-600')
                .text_size('sm')
            end

            # Price with flex layout for better alignment
            div(class: 'flex justify-between items-baseline') do
              text("#{currency}#{price}")
                .font_weight('bold')
                .text_color('gray-900')
                .text_size('xl')
            end.mt(2)
          end.mt(4)

          # CTA Button
          if show_cta
            button_classes = case cta_style
                             when 'primary'
                               'w-full mt-4 px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 transition-colors'
                             when 'outline'
                               'w-full mt-4 px-4 py-2 border-2 border-gray-900 text-gray-900 rounded-md hover:bg-gray-900 hover:text-white transition-colors'
                             else # secondary
                               'w-full mt-4 px-4 py-2 bg-gray-200 text-gray-900 rounded-md hover:bg-gray-300 transition-colors'
                             end

            button(cta_text, class: button_classes).font_weight('medium')
          end

          # Allow custom content via block
          yield if block_given?
        end
        .p(6)
        .bg('white')
        .hover_shadow('lg')
        .transition
      end
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
        if defined?(::ProductListComponent) && view_context.respond_to?(:render)
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
              div.p(4).bg('white').rounded('lg').shadow('md') do
                text(product[:name] || product['name'] || 'Product').font_weight('semibold')
                text("#{component_props[:currency_symbol] || '$'}#{product[:price] || product['price'] || 0}").font_weight('bold')
              end
            end
          end
        end
      end
    end

    # E-commerce Components with ViewComponent 2.0 Collection Optimization
    # Generic list method - composition-based approach
    def list(items:, **attrs, &block)
      # Pure structure for listing items - behavior comes from the block
      attrs[:class] = class_names('space-y-4', attrs[:class])

      create_element(:div, nil, **attrs) do
        items.each_with_index do |item, index|
          # Pass both item and index to the block for maximum flexibility
          if block
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
      attrs[:class] = class_names('grid gap-4', attrs[:class])
      attrs[:class] += " grid-cols-#{columns}"

      create_element(:div, nil, **attrs) do
        items.each_with_index do |item, index|
          if block
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
        if block
          items.each_with_index(&block)
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end

    def hstack_collection(items:, spacing: 8, **attrs, &block)
      # Render collection in horizontal stack with ViewComponent 2.0 performance
      hstack(spacing: spacing, **attrs) do
        if block
          items.each_with_index(&block)
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end

    def grid_collection(items:, columns: 3, spacing: 8, **attrs, &block)
      # Render collection in grid with ViewComponent 2.0 performance
      grid(columns: columns, spacing: spacing, **attrs) do
        if block
          items.each_with_index(&block)
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
                     when 0 then ''
                     when 1 then 'shadow'
                     when 2 then 'shadow-md'
                     when 3 then 'shadow-lg'
                     when 4 then 'shadow-xl'
                     else 'shadow-2xl'
                     end

      # Simple card container - just structure and styling
      attrs[:class] = class_names('rounded-lg bg-white', shadow_class, attrs[:class])

      # For slots, we need to ensure they render properly
      if header_slot || content_slot || actions_slot
        # Build content array first
        content_parts = []

        if header_slot
          header_content = if header_slot.is_a?(Proc)
                             result = instance_eval(&header_slot)
                             result.respond_to?(:to_s) ? result.to_s : ''
                           else
                             header_slot.to_s
                           end
          content_parts << create_element(:div, header_content.html_safe, class: 'p-4 border-b')
        end

        if content_slot
          content_content = if content_slot.is_a?(Proc)
                              result = instance_eval(&content_slot)
                              result.respond_to?(:to_s) ? result.to_s : ''
                            else
                              content_slot.to_s
                            end
          content_parts << create_element(:div, content_content.html_safe, class: 'p-4')
        end

        if actions_slot
          actions_content = if actions_slot.is_a?(Array)
                              create_element(:div, nil, class: 'flex flex-row items-center space-x-2') do
                                actions_slot.map do |action|
                                  if action.is_a?(Proc)
                                    result = instance_eval(&action)
                                    result.respond_to?(:to_s) ? result : ''
                                  else
                                    action
                                  end
                                end
                              end.to_s
                            elsif actions_slot.is_a?(Proc)
                              result = instance_eval(&actions_slot)
                              result.respond_to?(:to_s) ? result.to_s : ''
                            else
                              actions_slot.to_s
                            end
          content_parts << create_element(:div, actions_content.html_safe, class: 'p-4 border-t')
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
      attrs[:class] = class_names('p-4 border-b', attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def card_content(**attrs, &block)
      # A helper for the main content area
      attrs[:class] = class_names('p-4', attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def card_footer(**attrs, &block)
      # A helper for a styled footer region
      attrs[:class] = class_names('p-4 border-t', attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def card_section(**attrs, &block)
      # A helper for additional card sections
      attrs[:class] = class_names('p-4', attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def list(**attrs, &block)
      create_element(:ul, nil, **attrs, &block)
    end

    def list_item(**attrs, &block)
      create_element(:li, nil, **attrs, &block)
    end

    def scroll_view(**attrs, &block)
      attrs[:class] = class_names('overflow-auto', attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    # Media Components with SECURITY validation
    def image(src: nil, alt: '', **attrs)
      raise ArgumentError, 'image requires src attribute' unless src

      # SECURITY: Validate image source URL
      safe_src = Security::URLValidator.validate_image_src(src)
      unless safe_src
        Rails.logger.warn "Invalid image source blocked: #{src}"
        safe_src = '/images/placeholder.png'
      end

      attrs[:src] = safe_src
      attrs[:alt] = alt
      attrs[:loading] ||= 'lazy' # Default to lazy loading
      create_element(:img, nil, **attrs)
    end

    def icon(_name, size: 16, **attrs)
      # For now, just return a placeholder span
      # In a real implementation, this would render an SVG icon
      attrs[:class] = class_names('inline-block', attrs[:class])
      attrs[:style] = "width: #{size}px; height: #{size}px;"
      create_element(:span, '', **attrs)
    end

    # Layout Helpers
    def spacer(min_length: nil)
      attrs = { class: 'flex-1' }
      attrs[:style] = "min-height: #{min_length}px" if min_length
      create_element(:div, '', **attrs)
    end

    def divider(**attrs)
      attrs[:class] = class_names('border-t border-gray-300', attrs[:class])
      create_element(:hr, nil, **attrs)
    end

    def div(**attrs, &block)
      Rails.logger.debug { "DSL.div called with block: #{block}" }
      create_element(:div, nil, **attrs, &block)
    end

    def span(**attrs, &block)
      create_element(:span, nil, **attrs, &block)
    end

    def section(**attrs, &block)
      Rails.logger.debug { "DSL.section called with block: #{block}, attrs: #{attrs.inspect}" }
      create_element(:section, nil, **attrs, &block)
    end

    def article(**attrs, &block)
      create_element(:article, nil, **attrs, &block)
    end

    def header(**attrs, &block)
      create_element(:header, nil, **attrs, &block)
    end

    def footer(**attrs, &block)
      create_element(:footer, nil, **attrs, &block)
    end

    def nav(**attrs, &block)
      create_element(:nav, nil, **attrs, &block)
    end

    def a(**attrs, &block)
      create_element(:a, nil, **attrs, &block)
    end

    def h1(**attrs, &block)
      create_element(:h1, nil, **attrs, &block)
    end

    def h2(**attrs, &block)
      create_element(:h2, nil, **attrs, &block)
    end

    def h3(**attrs, &block)
      create_element(:h3, nil, **attrs, &block)
    end

    def h4(**attrs, &block)
      create_element(:h4, nil, **attrs, &block)
    end

    def h5(**attrs, &block)
      create_element(:h5, nil, **attrs, &block)
    end

    def h6(**attrs, &block)
      create_element(:h6, nil, **attrs, &block)
    end

    def p(**attrs, &block)
      create_element(:p, nil, **attrs, &block)
    end

    # Loading Components
    def spinner(size: :md, border_color: nil, spinner_color: nil)
      size_classes = {
        xs: 'h-3 w-3',
        sm: 'h-4 w-4',
        md: 'h-5 w-5',
        lg: 'h-6 w-6',
        xl: 'h-8 w-8'
      }

      border_class = border_color ? "border-#{border_color}" : ''
      spinner_class = spinner_color ? "border-t-#{spinner_color}" : ''

      create_element(:div, nil, class: 'inline-flex items-center') do
        content_tag(:div, '',
                    class: "animate-spin rounded-full border-2 #{border_class} #{spinner_class} #{size_classes[size]}")
      end
    end

    private

    def calculate_grid_classes(grid_items)
      return '' unless grid_items.is_a?(Array)

      if grid_items.all? { |item| item[:type] == :flexible }
        # Fixed number of columns
        count = grid_items.size
        case count
        when 1 then 'grid-cols-1'
        when 2 then 'grid-cols-1 sm:grid-cols-2'
        when 3 then 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
        when 4 then 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4'
        when 6 then 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-6'
        else 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4'
        end
      elsif grid_items.any? { |item| item[:type] == :adaptive }
        # Adaptive grid based on minimum size
        min_size = grid_items.find { |i| i[:type] == :adaptive }[:min]
        case min_size
        when 0..150 then 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6'
        when 151..250 then 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
        else 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
        end
      else
        # Mixed or fixed - default responsive
        'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4'
      end
    end

    def alignment_class(alignment)
      case alignment
      when :top, :start then 'start'
      when :center then 'center'
      when :bottom, :end then 'end'
      else 'center'
      end
    end

    # Override concat to handle Element instances
    def concat(content)
      if defined?(Element) && content.is_a?(Element)
        super(content.to_s.html_safe)
      else
        super
      end
    end

    # Component slot helpers - these are used in stories for composition
    def with_form(**attrs, &block)
      # Helper for form-based content in components
      create_element(:div, nil, **attrs, &block)
    end

    def with_sidebar(**attrs, &block)
      # Helper for sidebar content in components
      create_element(:div, nil, **attrs, &block)
    end

    def with_header(**attrs, &block)
      # Helper for header content in components
      create_element(:div, nil, **attrs, &block)
    end

    def with_footer(**attrs, &block)
      # Helper for footer content in components
      create_element(:div, nil, **attrs, &block)
    end

    # Ruby enumerable helpers used in stories
    def each_with_index(**attrs, &block)
      # This is typically called on collections, not as a DSL method
      # But stories may use it, so we provide a no-op version
      create_element(:div, nil, **attrs, &block)
    end

    def times(count = 1, **_attrs)
      # Helper to repeat content multiple times
      results = []
      count.times do |i|
        results << capture { yield(i) } if block_given?
      end
      safe_join(results)
    end

    # Create a chainable element
    def create_element(tag_name, content = nil, options = {}, &block)
      # Always use the current DSL context if we're in one
      dsl_context = is_a?(SwiftUIRails::DSLContext) ? self : nil
      element = Element.new(tag_name, content, options, dsl_context, &block)

      # Set the view context for Rails helper access
      element.view_context = if is_a?(SwiftUIRails::DSLContext)
                               @view_context
                             else
                               self
                             end

      # Store component reference for event handling
      if respond_to?(:component_id)
        Rails.logger.debug { "Storing component on element: #{self.class.name}, component_id=#{component_id}" }
        element.instance_variable_set(:@component, self)
      elsif is_a?(DSLContext) && @component
        Rails.logger.debug do
          "Storing component from context: #{@component.class.name}, component_id=#{@component&.component_id}"
        end
        element.instance_variable_set(:@component, @component)
      end

      # Register the element only if we're in a DSL context
      # This prevents double registration when blocks return elements
      if is_a?(SwiftUIRails::DSLContext)
        Rails.logger.debug { "[DSL] Registering element #{tag_name} to context #{object_id}" }
        register_element(element)
      else
        Rails.logger.debug { "[DSL] Created element #{tag_name} outside DSL context - not registering" }
      end

      element
    end
  end
end
# Copyright 2025
