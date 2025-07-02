# frozen_string_literal: true

class ProductListComponent < SwiftUIRails::Component::Base
  prop :products, type: Array, required: true
  prop :title, type: String, default: "Products"
  prop :columns, type: Symbol, default: :auto
  prop :gap, type: String, default: "6"
  prop :background_color, type: String, default: "white"
  prop :title_size, type: String, default: "2xl"
  prop :title_color, type: String, default: "gray-900"
  prop :container_padding, type: String, default: "16"
  prop :max_width, type: String, default: "7xl"
  prop :image_aspect, type: String, default: "square"
  prop :show_colors, type: [TrueClass, FalseClass], default: true
  prop :currency_symbol, type: String, default: "$"
  
  # Grid column configurations
  COLUMN_CONFIGS = {
    auto: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4",
    one: "grid-cols-1",
    two: "grid-cols-1 sm:grid-cols-2", 
    three: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3",
    four: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4",
    five: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5",
    six: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"
  }.freeze
  
  # Image aspect ratio configurations
  ASPECT_CONFIGS = {
    square: "aspect-square",
    portrait: "aspect-[3/4]",
    landscape: "aspect-[4/3]",
    auto: "lg:aspect-auto lg:h-80"
  }.freeze
  
  def call
    content_tag(:div, class: container_classes) do
      content_tag(:div, class: inner_container_classes) do
        safe_join([
          title_section,
          products_grid
        ].compact)
      end
    end
  end
  
  private
  
  def title_section
    return nil unless title.present?
    content_tag(:h2, title, class: title_classes)
  end
  
  def products_grid
    content_tag(:div, class: grid_classes) do
      safe_join(products.map { |product| render_product_card(product) })
    end
  end
  
  def container_classes
    "bg-#{background_color}"
  end
  
  def inner_container_classes
    "mx-auto max-w-#{max_width} px-4 py-#{container_padding} sm:px-6 sm:py-#{container_padding.to_i + 8} lg:px-8"
  end
  
  def title_classes
    "text-#{title_size} font-bold tracking-tight text-#{title_color}"
  end
  
  def grid_classes
    base_classes = "mt-6 grid gap-x-#{gap} gap-y-10 xl:gap-x-8"
    column_classes = COLUMN_CONFIGS[columns] || COLUMN_CONFIGS[:auto]
    "#{base_classes} #{column_classes}"
  end
  
  def image_classes
    aspect_class = ASPECT_CONFIGS[image_aspect.to_sym] || ASPECT_CONFIGS[:square]
    "#{aspect_class} w-full rounded-md bg-gray-200 object-cover group-hover:opacity-75"
  end
  
  def render_product_card(product)
    content_tag(:div, class: "group relative") do
      safe_join([
        # Product image with link
        link_to(product_url(product), class: "block") do
          image_tag(product_image_url(product), 
            alt: product_alt_text(product),
            class: image_classes
          )
        end,
        
        # Product details
        content_tag(:div, class: "mt-4 flex justify-between") do
          safe_join([
            content_tag(:div) do
              safe_join([
                # Product name with link
                content_tag(:h3, class: "text-sm text-gray-700") do
                  link_to(product_url(product), class: "hover:text-gray-900 transition-colors") do
                    safe_join([
                      content_tag(:span, "", class: "absolute inset-0", "aria-hidden": true),
                      product_name(product)
                    ])
                  end
                end,
                
                # Product color/variant (if enabled and available)
                if show_colors && product_color(product).present?
                  content_tag(:p, product_color(product), class: "mt-1 text-sm text-gray-500")
                end
              ].compact)
            end,
            
            # Product price
            content_tag(:p, formatted_price(product), class: "text-sm font-medium text-gray-900")
          ])
        end
      ])
    end
  end
  
  # Product data extraction methods - override these for custom product structures
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
end