# frozen_string_literal: true

class ProductListComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  # Basic properties
  control :title, as: :text, default: "Customers also purchased"
  control :columns, as: :select, options: [:auto, :one, :two, :three, :four, :five, :six], default: :auto
  control :gap, as: :select, options: ["2", "4", "6", "8", "10", "12"], default: "6"
  control :background_color, as: :select, options: [
    "white", "gray-50", "gray-100", "blue-50", "green-50", "purple-50"
  ], default: "white"
  control :title_size, as: :select, options: ["xl", "2xl", "3xl", "4xl"], default: "2xl"
  control :title_color, as: :select, options: [
    "gray-900", "gray-800", "black", "blue-900", "green-900"
  ], default: "gray-900"
  control :container_padding, as: :select, options: ["8", "12", "16", "20", "24"], default: "16"
  control :max_width, as: :select, options: ["2xl", "4xl", "6xl", "7xl", "full"], default: "7xl"
  control :image_aspect, as: :select, options: ["square", "portrait", "landscape", "auto"], default: "square"
  control :show_colors, as: :boolean, default: true
  control :currency_symbol, as: :select, options: ["$", "€", "£", "¥"], default: "$"
  
  def default(
    title: "Customers also purchased",
    columns: :auto,
    gap: "6",
    background_color: "white",
    title_size: "2xl",
    title_color: "gray-900",
    container_padding: "16",
    max_width: "7xl",
    image_aspect: "square",
    show_colors: true,
    currency_symbol: "$"
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        # Create rich DSL-based product list with chained properties
        product_list_element = vstack(spacing: 20) do
          # Title with dynamic styling
          text(title)
            .font_size(title_size)
            .font_weight("bold")
            .text_color(title_color)
            .margin_bottom(8)
          
          # Product grid with dynamic layout and styling
          grid(columns: columns, spacing: gap.to_i) do
            sample_products.each do |product|
              # Individual product card with rich DSL
              card(elevation: 1) do
                vstack(spacing: 12) do
                  # Product image with dynamic aspect ratio
                  image(product[:image_url])
                    .aspect_ratio(image_aspect)
                    .object_fit("cover")
                    .corner_radius("lg")
                  
                  # Product details
                  vstack(spacing: 4) do
                    text(product[:name])
                      .font_size("sm")
                      .font_weight("medium")
                      .text_color("gray-900")
                    
                    if show_colors
                      text(product[:color])
                        .font_size("xs")
                        .text_color("gray-500")
                    end
                    
                    text("#{currency_symbol}#{product[:price]}")
                      .font_size("sm")
                      .font_weight("semibold")
                      .text_color("gray-900")
                  end
                  .text_align("left")
                end
              end
              .padding(12)
              .corner_radius("lg")
              .background("white")
              .border
              .hover_scale("102")
              .transition
            end
          end
        end
        
        # Apply container-level chained modifiers
        product_list_element = product_list_element.padding(container_padding.to_i)
        product_list_element = product_list_element.max_width(max_width)
        product_list_element = product_list_element.background(background_color) if background_color != "white"
        product_list_element = product_list_element.corner_radius("xl")
        
        product_list_element
      end
    end
  end
  
  def with_hash_products
    # Example: Using hash-based product data
    hash_products = [
      {
        id: 1,
        name: "Basic Tee",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-01.jpg",
        color: "Black",
        price: 35
      },
      {
        id: 2,
        name: "Premium Hoodie",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-02.jpg",
        color: "Navy",
        price: 89
      },
      {
        id: 3,
        name: "Classic Jeans",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-03.jpg",
        color: "Indigo",
        price: 125
      },
      {
        id: 4,
        name: "Summer Dress",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg",
        color: "Floral",
        price: 78
      }
    ]
    
    render ProductListComponent.new(
      products: hash_products,
      title: "Hash-based Products",
      columns: :four
    )
  end
  
  def with_active_record_products
    # Example: Using ActiveRecord-like objects
    product_struct = Struct.new(:id, :name, :image_url, :color, :price, :category) do
      def to_param
        id.to_s
      end
    end
    
    ar_products = [
      product_struct.new(1, "Wireless Headphones", "https://via.placeholder.com/400x400/3B82F6/FFFFFF?text=Headphones", "Space Gray", 199.99, "Electronics"),
      product_struct.new(2, "Smart Watch", "https://via.placeholder.com/400x400/10B981/FFFFFF?text=Watch", "Silver", 299.99, "Electronics"),
      product_struct.new(3, "Laptop Stand", "https://via.placeholder.com/400x400/F59E0B/FFFFFF?text=Stand", "Aluminum", 89.99, "Accessories"),
      product_struct.new(4, "Bluetooth Speaker", "https://via.placeholder.com/400x400/EF4444/FFFFFF?text=Speaker", "Midnight", 149.99, "Electronics")
    ]
    
    render ProductListComponent.new(
      products: ar_products,
      title: "Tech Products",
      columns: :four,
      currency_symbol: "$"
    )
  end
  
  def grid_variations
    content_tag(:div, class: "space-y-12") do
      variations = [
        { columns: :two, title: "2 Columns Grid" },
        { columns: :three, title: "3 Columns Grid" },
        { columns: :four, title: "4 Columns Grid" },
        { columns: :six, title: "6 Columns Grid" }
      ]
      
      variations.map do |config|
        render ProductListComponent.new(
          products: sample_products.first(4),
          title: config[:title],
          columns: config[:columns],
          container_padding: "8"
        )
      end.join.html_safe
    end
  end
  
  def different_currencies
    content_tag(:div, class: "space-y-12") do
      currencies = [
        { symbol: "$", title: "US Dollars", price_multiplier: 1 },
        { symbol: "€", title: "Euros", price_multiplier: 0.85 },
        { symbol: "£", title: "British Pounds", price_multiplier: 0.75 },
        { symbol: "¥", title: "Japanese Yen", price_multiplier: 110 }
      ]
      
      currencies.map do |config|
        products = sample_products.first(3).map do |p|
          p.merge(price: (p[:price] * config[:price_multiplier]).round(2))
        end
        
        render ProductListComponent.new(
          products: products,
          title: config[:title],
          currency_symbol: config[:symbol],
          columns: :three,
          container_padding: "8"
        )
      end.join.html_safe
    end
  end
  
  def chainable_dsl_demo
    include SwiftUIRails::DSL
    
    content_tag(:div, class: "space-y-8") do
      demos = [
        {
          title: "Default Product List",
          code: 'product_list(products: sample_products).padding(4)',
          component: product_list(products: sample_products.first(2)).padding(4)
        },
        {
          title: "Customized Grid",
          code: 'product_list(products: sample_products).background("gray-50").corner_radius("lg").columns(:three)',
          component: product_list(products: sample_products.first(3)).background("gray-50").corner_radius("lg")
        }
      ]
      
      demos.map do |demo|
        content_tag(:div, class: "bg-gray-50 p-6 rounded-lg border") do
          safe_join([
            content_tag(:h4, demo[:title], class: "text-sm font-semibold text-gray-900 mb-3"),
            content_tag(:div, class: "space-y-4") do
              safe_join([
                demo[:component],
                content_tag(:pre, demo[:code], class: "text-xs text-gray-700 bg-white p-3 rounded border overflow-x-auto")
              ])
            end
          ])
        end
      end.join.html_safe
    end
  end
  
  private
  
  def sample_products
    [
      {
        id: 1,
        name: "Basic Tee",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-01.jpg",
        color: "Black",
        price: 35
      },
      {
        id: 2,
        name: "Premium Hoodie", 
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-02.jpg",
        color: "Navy",
        price: 89
      },
      {
        id: 3,
        name: "Classic Jeans",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-03.jpg",
        color: "Indigo", 
        price: 125
      },
      {
        id: 4,
        name: "Summer Dress",
        image_url: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg",
        color: "Floral",
        price: 78
      }
    ]
  end
end