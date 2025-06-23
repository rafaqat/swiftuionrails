# frozen_string_literal: true

class EnhancedProductListComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  
  # Basic properties
  control :title, as: :text, default: "Enhanced Product Collection"
  control :columns, as: :select, options: [:auto, :one, :two, :three, :four, :five, :six], default: :auto
  control :gap, as: :select, options: ["2", "4", "6", "8", "10", "12"], default: "6"
  control :background_color, as: :select, options: ["white", "gray-50", "gray-100", "blue-50"], default: "white"
  control :container_padding, as: :select, options: ["8", "12", "16", "20", "24"], default: "16"
  control :max_width, as: :select, options: ["2xl", "4xl", "6xl", "7xl", "full"], default: "7xl"
  
  # Animation controls
  control :enable_animations, as: :boolean, default: true
  control :animation_delay, as: :select, options: ["50", "100", "150", "200"], default: "100"
  control :hover_scale, as: :select, options: ["105", "110", "125"], default: "105"
  
  # Feature controls
  control :sortable, as: :boolean, default: true
  control :filterable, as: :boolean, default: true
  control :show_quick_actions, as: :boolean, default: true
  control :currency_symbol, as: :select, options: ["$", "€", "£", "¥"], default: "$"
  
  def default(
    title: "Enhanced Product Collection",
    columns: :auto,
    gap: "6",
    background_color: "white",
    container_padding: "16",
    max_width: "7xl",
    enable_animations: true,
    animation_delay: "100",
    hover_scale: "105",
    sortable: true,
    filterable: true,
    show_quick_actions: true,
    currency_symbol: "$"
  )
    render EnhancedProductListComponent.new(
      products: sample_products,
      title: title,
      columns: columns,
      gap: gap,
      background_color: background_color,
      container_padding: container_padding,
      max_width: max_width,
      enable_animations: enable_animations,
      animation_delay: animation_delay,
      hover_scale: hover_scale,
      sortable: sortable,
      filterable: filterable,
      show_quick_actions: show_quick_actions,
      currency_symbol: currency_symbol
    )
  end
  
  def with_custom_header_slot
    render EnhancedProductListComponent.new(
      products: sample_products,
      columns: :three,
      enable_animations: true,
      sortable: true
    ) do |component|
      # Custom header slot
      component.with_header do
        content_tag(:div, class: "bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg p-6 mb-8 text-white") do
          safe_join([
            content_tag(:h1, "Premium Collection", class: "text-3xl font-bold mb-2"),
            content_tag(:p, "Handpicked items with exceptional quality and style", class: "text-blue-100"),
            content_tag(:div, class: "mt-4 flex gap-3") do
              safe_join([
                content_tag(:button, "View All", class: "px-4 py-2 bg-white bg-opacity-20 rounded-lg hover:bg-opacity-30 transition-all"),
                content_tag(:button, "Filter", class: "px-4 py-2 bg-white bg-opacity-20 rounded-lg hover:bg-opacity-30 transition-all")
              ])
            end
          ])
        end
      end
      
      # Custom actions slot
      component.with_actions do
        content_tag(:div, class: "flex gap-2") do
          safe_join([
            content_tag(:button, "Grid View", class: "p-2 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors"),
            content_tag(:button, "List View", class: "p-2 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors")
          ])
        end
      end
    end
  end
  
  def with_custom_product_card_slot
    render EnhancedProductListComponent.new(
      products: sample_products,
      title: "Custom Card Design",
      columns: :three,
      enable_animations: true,
      show_quick_actions: false
    ) do |component|
      # Custom product card slot
      component.with_product_card do |product:, index:|
        content_tag(:div, class: "bg-white rounded-xl shadow-lg overflow-hidden transform transition-all duration-300 hover:scale-105 hover:shadow-xl") do
          safe_join([
            # Large image with overlay
            content_tag(:div, class: "relative h-64") do
              safe_join([
                image_tag(product_image_url(product), 
                  class: "w-full h-full object-cover",
                  alt: product_alt_text(product)
                ),
                content_tag(:div, class: "absolute top-4 left-4") do
                  content_tag(:span, "NEW", class: "px-2 py-1 bg-red-500 text-white text-xs font-bold rounded-full")
                end,
                content_tag(:div, class: "absolute bottom-4 right-4") do
                  content_tag(:span, formatted_price(product), 
                    class: "px-3 py-1 bg-black bg-opacity-70 text-white text-sm font-semibold rounded-full"
                  )
                end
              ])
            end,
            
            # Content area
            content_tag(:div, class: "p-6") do
              safe_join([
                content_tag(:h3, product_name(product), class: "text-lg font-semibold text-gray-900 mb-2"),
                content_tag(:p, product_color(product), class: "text-sm text-gray-600 mb-4"),
                content_tag(:div, class: "flex gap-2") do
                  safe_join([
                    content_tag(:button, "Quick View", 
                      class: "flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
                    ),
                    content_tag(:button, "♡", 
                      class: "px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                    )
                  ])
                end
              ])
            end
          ])
        end
      end
    end
  end
  
  def with_custom_filters_slot
    render EnhancedProductListComponent.new(
      products: diverse_products,
      title: "Advanced Filtering",
      columns: :auto,
      sortable: true,
      filterable: true
    ) do |component|
      # Custom filters slot
      component.with_filters do
        content_tag(:div, class: "bg-gray-50 rounded-lg p-4 space-y-4") do
          safe_join([
            # Price range filter
            content_tag(:div) do
              safe_join([
                content_tag(:label, "Price Range", class: "block text-sm font-medium text-gray-700 mb-2"),
                content_tag(:div, class: "flex items-center gap-2") do
                  safe_join([
                    content_tag(:input, "", 
                      type: "range", 
                      min: "0", 
                      max: "500", 
                      value: "250",
                      class: "flex-1"
                    ),
                    content_tag(:span, "$0 - $500", class: "text-sm text-gray-600")
                  ])
                end
              ])
            end,
            
            # Category filter
            content_tag(:div) do
              safe_join([
                content_tag(:label, "Category", class: "block text-sm font-medium text-gray-700 mb-2"),
                content_tag(:div, class: "flex flex-wrap gap-2") do
                  %w[Clothing Accessories Electronics].map do |category|
                    content_tag(:label, class: "flex items-center") do
                      safe_join([
                        content_tag(:input, "", type: "checkbox", class: "mr-2"),
                        content_tag(:span, category, class: "text-sm text-gray-700")
                      ])
                    end
                  end.join.html_safe
                end
              ])
            end
          ])
        end
      end
    end
  end
  
  def with_empty_state_slot
    render EnhancedProductListComponent.new(
      products: [],
      title: "Custom Empty State",
      sortable: true,
      filterable: true
    ) do |component|
      # Custom empty state slot
      component.with_empty_state do
        content_tag(:div, class: "text-center py-16") do
          safe_join([
            content_tag(:div, class: "mb-6") do
              content_tag(:div, "🛍️", class: "text-6xl mb-4")
            end,
            content_tag(:h3, "Your shopping adventure starts here!", class: "text-xl font-semibold text-gray-900 mb-2"),
            content_tag(:p, "Discover amazing products tailored just for you.", class: "text-gray-600 mb-6 max-w-md mx-auto"),
            content_tag(:div, class: "flex gap-3 justify-center") do
              safe_join([
                content_tag(:button, "Browse Categories", 
                  class: "px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
                ),
                content_tag(:button, "View Trending", 
                  class: "px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
                )
              ])
            end
          ])
        end
      end
    end
  end
  
  def slot_usage_examples
    content_tag(:div, class: "space-y-12") do
      safe_join([
        # Example 1: Basic usage without slots
        content_tag(:div) do
          safe_join([
            content_tag(:h3, "1. Basic Usage (No Slots)", class: "text-lg font-semibold mb-4"),
            content_tag(:pre, class: "bg-gray-100 p-4 rounded-lg text-sm overflow-x-auto mb-4") do
              <<~CODE.strip
                render EnhancedProductListComponent.new(
                  products: @products,
                  title: "Products",
                  columns: :four,
                  sortable: true,
                  filterable: true,
                  enable_animations: true,
                  show_quick_actions: true,
                  currency_symbol: "$"
                )
              CODE
            end,
            render(EnhancedProductListComponent.new(
              products: sample_products.first(2),
              title: "Basic Products",
              columns: :two,
              sortable: true,
              enable_animations: true
            ))
          ])
        end,
        
        # Example 2: With header slot - EXACT CODE
        content_tag(:div) do
          safe_join([
            content_tag(:h3, "2. With Custom Header Slot", class: "text-lg font-semibold mb-4"),
            content_tag(:pre, class: "bg-gray-100 p-4 rounded-lg text-sm overflow-x-auto mb-4") do
              <<~CODE.strip
                render EnhancedProductListComponent.new(
                  products: @products,
                  columns: :three,
                  sortable: true,
                  filterable: true
                ) do |component|
                  component.with_header do
                    content_tag(:div, class: "bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg p-6 text-white") do
                      safe_join([
                        content_tag(:h1, "Premium Collection", class: "text-3xl font-bold mb-2"),
                        content_tag(:p, "Handpicked items with exceptional quality", class: "text-blue-100"),
                        content_tag(:div, class: "mt-4 flex gap-3") do
                          safe_join([
                            content_tag(:button, "View All", class: "px-4 py-2 bg-white bg-opacity-20 rounded-lg"),
                            content_tag(:button, "Filter", class: "px-4 py-2 bg-white bg-opacity-20 rounded-lg")
                          ])
                        end
                      ])
                    end
                  end
                end
              CODE
            end
          ])
        end,
        
        # Example 3: Custom Product Card Slot - EXACT CODE
        content_tag(:div) do
          safe_join([
            content_tag(:h3, "3. With Custom Product Card Slot", class: "text-lg font-semibold mb-4"),
            content_tag(:pre, class: "bg-gray-100 p-4 rounded-lg text-sm overflow-x-auto mb-4") do
              <<~CODE.strip
                render EnhancedProductListComponent.new(
                  products: @products,
                  title: "Custom Card Design",
                  columns: :three
                ) do |component|
                  component.with_product_card do |product:, index:|
                    content_tag(:div, class: "bg-white rounded-xl shadow-lg overflow-hidden") do
                      safe_join([
                        # Custom image with overlay
                        content_tag(:div, class: "relative h-64") do
                          safe_join([
                            image_tag(product[:image_url], class: "w-full h-full object-cover"),
                            content_tag(:div, class: "absolute top-4 left-4") do
                              content_tag(:span, "NEW", class: "px-2 py-1 bg-red-500 text-white text-xs font-bold rounded-full")
                            end,
                            content_tag(:div, class: "absolute bottom-4 right-4") do
                              content_tag(:span, "$#{product[:price]}", class: "px-3 py-1 bg-black bg-opacity-70 text-white text-sm font-semibold rounded-full")
                            end
                          ])
                        end,
                        # Custom content
                        content_tag(:div, class: "p-6") do
                          safe_join([
                            content_tag(:h3, product[:name], class: "text-lg font-semibold mb-2"),
                            content_tag(:p, product[:color], class: "text-sm text-gray-600 mb-4"),
                            content_tag(:div, class: "flex gap-2") do
                              safe_join([
                                content_tag(:button, "Quick View", class: "flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg"),
                                content_tag(:button, "♡", class: "px-4 py-2 border border-gray-300 rounded-lg")
                              ])
                            end
                          ])
                        end
                      ])
                    end
                  end
                end
              CODE
            end
          ])
        end,
        
        # Example 4: SwiftUI Style DSL - EXACT CODE
        content_tag(:div) do
          safe_join([
            content_tag(:h3, "4. SwiftUI-Style Chainable DSL", class: "text-lg font-semibold mb-4"),
            content_tag(:pre, class: "bg-gray-100 p-4 rounded-lg text-sm overflow-x-auto mb-4") do
              <<~CODE.strip
                <%= swift_ui do
                  enhanced_product_list(products: @products, title: "Featured Products")
                    .grid_columns(:four)
                    .sortable(true)
                    .filterable(true)
                    .animated(true, delay: "100")
                    .hover_scale("110")
                    .currency("€")
                    .quick_actions(true)
                end %>
              CODE
            end
          ])
        end,
        
        # Example 5: Data structure documentation
        content_tag(:div) do
          safe_join([
            content_tag(:h3, "5. Supported Product Data Structures", class: "text-lg font-semibold mb-4"),
            content_tag(:pre, class: "bg-gray-100 p-4 rounded-lg text-sm overflow-x-auto") do
              <<~CODE.strip
                # 1. Hash-based products (most flexible)
                products = [
                  {
                    id: 1,
                    name: "Basic Tee",
                    image_url: "https://example.com/image.jpg",
                    color: "Black",
                    price: 35
                  },
                  {
                    id: 2,
                    name: "Premium Hoodie",
                    image_url: "https://example.com/hoodie.jpg", 
                    color: "Navy",
                    price: 89
                  }
                ]
                
                # 2. ActiveRecord objects
                products = Product.includes(:images).featured
                
                # 3. Custom objects (must respond to: id, name, image_url, color, price)
                ProductStruct = Struct.new(:id, :name, :image_url, :color, :price)
                products = [
                  ProductStruct.new(1, "Product Name", "image_url", "Blue", 99.99)
                ]
                
                # Usage with any structure:
                render EnhancedProductListComponent.new(products: products)
              CODE
            end
          ])
        end,
        
        # Example 6: Complete implementation with all slots
        content_tag(:div) do
          safe_join([
            content_tag(:h3, "6. Complete Implementation (All Slots)", class: "text-lg font-semibold mb-4"),
            content_tag(:pre, class: "bg-gray-100 p-4 rounded-lg text-sm overflow-x-auto") do
              <<~CODE.strip
                render EnhancedProductListComponent.new(
                  products: @products,
                  columns: :auto,
                  sortable: true,
                  filterable: true,
                  enable_animations: true
                ) do |component|
                  
                  # Custom header
                  component.with_header do
                    content_tag(:div, class: "text-center mb-8") do
                      safe_join([
                        content_tag(:h1, "Premium Collection", class: "text-3xl font-bold"),
                        content_tag(:p, "Discover our handpicked selection", class: "text-gray-600")
                      ])
                    end
                  end
                  
                  # Custom actions
                  component.with_actions do
                    content_tag(:div, class: "flex gap-2") do
                      safe_join([
                        link_to("View All", products_path, class: "px-4 py-2 bg-blue-600 text-white rounded-lg"),
                        content_tag(:button, "Export", class: "px-4 py-2 border border-gray-300 rounded-lg")
                      ])
                    end
                  end
                  
                  # Custom filters
                  component.with_filters do
                    content_tag(:div, class: "bg-gray-50 rounded-lg p-4") do
                      content_tag(:label, "Price Range", class: "block text-sm font-medium mb-2")
                      # ... custom filter controls
                    end
                  end
                  
                  # Custom empty state
                  component.with_empty_state do
                    content_tag(:div, class: "text-center py-16") do
                      safe_join([
                        content_tag(:div, "🛍️", class: "text-6xl mb-4"),
                        content_tag(:h3, "No products found", class: "text-xl font-semibold"),
                        content_tag(:button, "Browse All", class: "px-6 py-3 bg-blue-600 text-white rounded-lg")
                      ])
                    end
                  end
                  
                end
              CODE
            end
          ])
        end
      ])
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
  
  def diverse_products
    sample_products + [
      {
        id: 5,
        name: "Wireless Headphones",
        image_url: "https://via.placeholder.com/400x400/3B82F6/FFFFFF?text=Headphones",
        color: "Black",
        price: 199,
        category: "Electronics"
      },
      {
        id: 6,
        name: "Leather Wallet",
        image_url: "https://via.placeholder.com/400x400/8B5CF6/FFFFFF?text=Wallet",
        color: "Brown",
        price: 45,
        category: "Accessories"
      }
    ]
  end
  
  # Helper methods for product data extraction
  def product_name(product)
    product.try(:name) || product.try(:title) || product[:name] || product[:title] || "Product"
  end
  
  def product_image_url(product)
    product.try(:image_url) || product.try(:image) || product[:image_url] || product[:image] || "https://via.placeholder.com/400x400?text=No+Image"
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
      "$#{price}"
    else
      price.to_s
    end
  end
end