# frozen_string_literal: true
# Copyright 2025

class EnhancedProductListComponent < SwiftUIRails::Component::Base
  # Core props
  prop :products, type: Array, required: true
  prop :title, type: String, default: "Products"
  prop :columns, type: Symbol, default: :auto
  prop :gap, type: String, default: "6"
  prop :background_color, type: String, default: "white"
  prop :container_padding, type: String, default: "16"
  prop :max_width, type: String, default: "7xl"
  
  # Animation props
  prop :enable_animations, type: [TrueClass, FalseClass], default: true
  prop :animation_delay, type: String, default: "100"
  prop :hover_scale, type: String, default: "105"
  
  # Sorting props
  prop :sortable, type: [TrueClass, FalseClass], default: true
  prop :sort_options, type: Array, default: -> { ["name", "price", "color"] }
  prop :default_sort, type: String, default: "name"
  prop :sort_direction, type: String, default: "asc"
  
  # Filtering props
  prop :filterable, type: [TrueClass, FalseClass], default: true
  prop :filter_by_color, type: [TrueClass, FalseClass], default: true
  
  # Display props
  prop :show_quick_actions, type: [TrueClass, FalseClass], default: true
  prop :currency_symbol, type: String, default: "$"
  
  # Slots for maximum flexibility (temporarily disabled for testing)
  # slot :header, required: false
  # slot :product_card, required: false  # Custom product card template
  # slot :empty_state, required: false
  # slot :actions, required: false      # Custom action buttons
  # slot :filters, required: false      # Custom filter controls
  
  # Grid configurations
  COLUMN_CONFIGS = {
    auto: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4",
    one: "grid-cols-1",
    two: "grid-cols-1 sm:grid-cols-2", 
    three: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3",
    four: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4",
    five: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5",
    six: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"
  }.freeze
  
  # Animation configurations
  ANIMATION_CONFIGS = {
    fade_in: "animate-fade-in",
    slide_up: "animate-slide-up",
    scale_in: "animate-scale-in",
    stagger: "animate-stagger"
  }.freeze
  
  def call
    content_tag(:div, 
      class: container_classes,
      data: {
        controller: "enhanced-product-list",
        "enhanced-product-list-sortable-value": sortable,
        "enhanced-product-list-filterable-value": filterable,
        "enhanced-product-list-products-value": products_json
      }
    ) do
      content_tag(:div, class: inner_container_classes) do
        safe_join([
          render_header,
          render_controls,
          render_products_grid,
          render_empty_state
        ].compact)
      end
    end
  end
  
  private
  
  def render_header
    # if header.present?
    #   header
    # elsif title.present?
    if title.present?
      content_tag(:div, class: "flex items-center justify-between mb-6") do
        safe_join([
          content_tag(:h2, title, class: title_classes),
          # actions.presence
        ].compact)
      end
    end
  end
  
  def render_controls
    return unless sortable || filterable
    
    content_tag(:div, class: "mb-6 flex flex-wrap items-center gap-4") do
      safe_join([
        render_sort_controls,
        render_filter_controls,
        # filters.presence
      ].compact)
    end
  end
  
  def render_sort_controls
    return unless sortable
    
    content_tag(:div, class: "flex items-center gap-2") do
      safe_join([
        content_tag(:label, "Sort by:", class: "text-sm font-medium text-gray-700"),
        content_tag(:select, 
          class: "rounded-md border-gray-300 text-sm focus:border-blue-500 focus:ring-blue-500",
          data: { action: "change->enhanced-product-list#sort".html_safe }
        ) do
          safe_join(
            sort_options.map do |option|
              content_tag(:option, option.humanize, value: option, selected: option == default_sort)
            end
          )
        end,
        content_tag(:button,
          class: "p-2 rounded-md border border-gray-300 hover:bg-gray-50 transition-colors",
          data: { action: "click->enhanced-product-list#toggleDirection".html_safe }
        ) do
          content_tag(:svg, class: "w-4 h-4", viewBox: "0 0 20 20", fill: "currentColor") do
            content_tag(:path, "", 
              fill_rule: "evenodd",
              d: "M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z",
              clip_rule: "evenodd"
            )
          end
        end
      ])
    end
  end
  
  def render_filter_controls
    return unless filterable && filter_by_color
    
    colors = products.map { |p| product_color(p) }.compact.uniq.sort
    return if colors.empty?
    
    content_tag(:div, class: "flex items-center gap-2") do
      safe_join([
        content_tag(:label, "Filter:", class: "text-sm font-medium text-gray-700"),
        content_tag(:div, class: "flex gap-1") do
          safe_join([
            content_tag(:button, "All", 
              class: "px-3 py-1 text-xs rounded-full border border-gray-300 hover:bg-gray-50 transition-colors",
              data: { action: "click->enhanced-product-list#filterByColor".html_safe, color: "all" }
            )
          ] + colors.map do |color|
            content_tag(:button, color,
              class: "px-3 py-1 text-xs rounded-full border border-gray-300 hover:bg-gray-50 transition-colors",
              data: { action: "click->enhanced-product-list#filterByColor".html_safe, color: color }
            )
          end)
        end
      ])
    end
  end
  
  def render_products_grid
    content_tag(:div, 
      class: grid_classes,
      data: { "enhanced-product-list-target": "grid" }
    ) do
      if products.any?
        safe_join(
          products.each_with_index.map { |product, index| 
            render_product_card(product, index) 
          }
        )
      else
        ""
      end
    end
  end
  
  def render_empty_state
    content_tag(:div, 
      class: "text-center py-12 hidden",
      data: { "enhanced-product-list-target": "emptyState" }
    ) do
      # if empty_state.present?
      #   empty_state
      if false  # Temporarily disabled
      else
        safe_join([
          content_tag(:div, class: "text-gray-400 mb-4") do
            content_tag(:svg, class: "mx-auto h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
              content_tag(:path, "", 
                stroke_linecap: "round", 
                stroke_linejoin: "round", 
                stroke_width: "2", 
                d: "M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2 2v-5m16 0h-2M4 13h2"
              )
            end
          end,
          content_tag(:h3, "No products found", class: "text-lg font-medium text-gray-900 mb-2"),
          content_tag(:p, "Try adjusting your filters or search criteria.", class: "text-gray-500")
        ])
      end
    end
  end
  
  def render_product_card(product, index)
    # card_content = if product_card.present?
    #   # Use custom product card slot
    #   product_card.call(product: product, index: index)
    # else
    #   # Default product card implementation
    #   render_default_product_card(product, index)
    # end
    
    card_content = render_default_product_card(product, index)
    
    # Wrap in animation container
    content_tag(:div, 
      class: product_card_classes(index),
      data: {
        "enhanced-product-list-target": "productCard",
        "product-id": product_id(product),
        "product-name": product_name(product),
        "product-price": product_price(product),
        "product-color": product_color(product)
      }
    ) do
      card_content
    end
  end
  
  def render_default_product_card(product, index)
    content_tag(:div, class: "group relative") do
      safe_join([
        # Product image with flash-resistant animations
        content_tag(:div, class: "product-image-container relative overflow-hidden rounded-lg") do
          safe_join([
            link_to(product_url(product), class: "block h-full") do
              image_tag(product_image_url(product), 
                alt: product_alt_text(product),
                class: image_classes,
                loading: "lazy" # Improve loading performance
              )
            end,
            (render_quick_actions(product) if show_quick_actions)
          ].compact)
        end,
        
        # Product details with stable layout
        content_tag(:div, class: "mt-4 space-y-2 min-h-[60px]") do # Fixed min-height to prevent layout shift
          safe_join([
            # Product name and price with consistent layout
            content_tag(:div, class: "flex justify-between items-start gap-2") do
              safe_join([
                content_tag(:div, class: "flex-1 min-w-0") do
                  safe_join([
                    content_tag(:h3, class: "text-sm font-medium text-gray-900 truncate leading-tight") do
                      link_to(product_url(product), 
                        class: "hover:text-blue-600 transition-colors duration-200"
                      ) do
                        product_name(product)
                      end
                    end,
                    if product_color(product).present?
                      content_tag(:p, product_color(product), 
                        class: "text-xs text-gray-500 mt-1 leading-tight"
                      )
                    end
                  ].compact)
                end,
                content_tag(:p, formatted_price(product), 
                  class: "text-sm font-semibold text-gray-900 whitespace-nowrap"
                )
              ])
            end
          ])
        end
      ])
    end
  end
  
  def render_quick_actions(product)
    content_tag(:div, 
      class: "absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-opacity duration-300 flex items-center justify-center opacity-0 group-hover:opacity-100"
    ) do
      content_tag(:div, class: "flex gap-2") do
        safe_join([
          content_tag(:button, 
            class: "p-2 bg-white rounded-full shadow-lg hover:bg-gray-50 transition-transform duration-200 transform hover:scale-110",
            data: { action: "click->enhanced-product-list#quickView".html_safe, product_id: product_id(product) }
          ) do
            content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
              content_tag(:path, "", 
                stroke_linecap: "round", 
                stroke_linejoin: "round", 
                stroke_width: "2", 
                d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
              )
            end
          end,
          content_tag(:button, 
            class: "p-2 bg-white rounded-full shadow-lg hover:bg-gray-50 transition-transform duration-200 transform hover:scale-110",
            data: { action: "click->enhanced-product-list#addToCart".html_safe, product_id: product_id(product) }
          ) do
            content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
              content_tag(:path, "", 
                stroke_linecap: "round", 
                stroke_linejoin: "round", 
                stroke_width: "2", 
                d: "M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m8 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
              )
            end
          end
        ])
      end
    end
  end
  
  # CSS Classes
  def container_classes
    "bg-#{background_color} transition-colors duration-500 ease-in-out"
  end
  
  def inner_container_classes
    "mx-auto max-w-#{max_width} px-4 py-#{container_padding} sm:px-6 lg:px-8"
  end
  
  def title_classes
    "text-2xl font-bold tracking-tight text-gray-900"
  end
  
  def grid_classes
    base_classes = "grid gap-#{gap} transition-[grid-template-columns,gap] duration-700 ease-in-out"
    column_classes = COLUMN_CONFIGS[columns] || COLUMN_CONFIGS[:auto]
    "#{base_classes} #{column_classes}"
  end
  
  def product_card_classes(index)
    classes = ["relative"]
    
    # Add stable base classes to prevent flash during re-renders
    classes << "product-card-stable" # CSS containment and stability
    classes << "flash-resistant" # Optimized transitions
    classes << "transform-gpu" # Force GPU acceleration
    
    if enable_animations
      classes << "hover:scale-#{hover_scale} hover:z-10"
      # Completely remove any initial state animations that cause flash
    else
      classes << "hover:scale-102 hover:z-10"
    end
    
    classes.join(" ")
  end
  
  def image_classes
    "aspect-square w-full rounded-md bg-gray-200 object-cover transition-transform duration-300 ease-out group-hover:scale-105"
  end
  
  # Data extraction methods (same as before)
  def product_name(product)
    product.try(:name) || product.try(:title) || product[:name] || product[:title] || "Product"
  end
  
  def product_image_url(product)
    product.try(:image_url) || product.try(:image) || product[:image_url] || product[:image] || "https://via.placeholder.com/400x400?text=No+Image"
  end
  
  def product_url(product)
    if product.respond_to?(:id)
      "/products/#{product.id}"
    elsif product[:id]
      "/products/#{product[:id]}"
    else
      "#"
    end
  end
  
  def product_color(product)
    product.try(:color) || product.try(:variant) || product[:color] || product[:variant]
  end
  
  def product_price(product)
    product.try(:price) || product[:price] || 0
  end
  
  def product_id(product)
    product.try(:id) || product[:id] || SecureRandom.hex(4)
  end
  
  def product_alt_text(product)
    name = product_name(product)
    color = product_color(product)
    if color.present?
      "#{name} in #{color}"
    else
      name
    end
  end
  
  def formatted_price(product)
    price = product_price(product)
    if price.is_a?(Numeric)
      "#{currency_symbol}#{price}"
    else
      price.to_s
    end
  end
  
  def products_json
    products.to_json
  end
end
# Copyright 2025
