# Enhanced Product List Component Usage Guide

## Overview

The `EnhancedProductListComponent` provides a flexible, animated, and interactive product grid with powerful sorting, filtering, and customization capabilities. It supports slots for maximum flexibility.

## Basic Usage

### 1. Simple Product List

```ruby
# In your view or component
render EnhancedProductListComponent.new(
  products: @products,
  title: "Featured Products",
  columns: :four,
  sortable: true,
  filterable: true
)
```

### 2. With SwiftUI-style DSL

```erb
<%= swift_ui do
  enhanced_product_list(
    products: @products,
    title: "Featured Products"
  ).grid_columns(:three)
   .sortable(true)
   .filterable(true)
   .animated(true)
   .hover_scale("110")
   .currency("€")
end %>
```

## Product Data Structure

The component accepts flexible product data structures:

### Hash-based Products

```ruby
products = [
  {
    id: 1,
    name: "Product Name",
    image_url: "https://example.com/image.jpg",
    color: "Blue",
    price: 99.99
  },
  # ... more products
]
```

### ActiveRecord Objects

```ruby
# Your Product model should have these attributes/methods:
# - id, name (or title), image_url (or image), color (or variant), price

products = Product.includes(:images).limit(12)
```

### Custom Objects

```ruby
ProductStruct = Struct.new(:id, :name, :image_url, :color, :price)
products = [
  ProductStruct.new(1, "Product Name", "image_url", "Color", 99.99)
]
```

## Slot Usage

### 1. Custom Header Slot

```ruby
render EnhancedProductListComponent.new(products: @products) do |component|
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
```

### 2. Custom Product Card Slot

```ruby
render EnhancedProductListComponent.new(products: @products) do |component|
  component.with_product_card do |product:, index:|
    content_tag(:div, class: "bg-white rounded-xl shadow-lg overflow-hidden") do
      safe_join([
        # Custom image section
        content_tag(:div, class: "relative h-64") do
          safe_join([
            image_tag(product[:image_url], class: "w-full h-full object-cover"),
            content_tag(:div, class: "absolute top-4 left-4") do
              content_tag(:span, "NEW", class: "px-2 py-1 bg-red-500 text-white text-xs font-bold rounded-full")
            end
          ])
        end,
        
        # Custom content section
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
```

### 3. Custom Actions Slot

```ruby
render EnhancedProductListComponent.new(products: @products) do |component|
  component.with_actions do
    content_tag(:div, class: "flex gap-2") do
      safe_join([
        content_tag(:button, "Grid View", class: "p-2 bg-gray-100 rounded-md"),
        content_tag(:button, "List View", class: "p-2 bg-gray-100 rounded-md"),
        content_tag(:button, "Export", class: "p-2 bg-blue-600 text-white rounded-md")
      ])
    end
  end
end
```

### 4. Custom Filters Slot

```ruby
render EnhancedProductListComponent.new(products: @products) do |component|
  component.with_filters do
    content_tag(:div, class: "bg-gray-50 rounded-lg p-4 space-y-4") do
      safe_join([
        # Price range filter
        content_tag(:div) do
          safe_join([
            content_tag(:label, "Price Range", class: "block text-sm font-medium text-gray-700 mb-2"),
            content_tag(:input, "", type: "range", min: "0", max: "500", class: "w-full")
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
                    content_tag(:span, category, class: "text-sm")
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
```

### 5. Custom Empty State Slot

```ruby
render EnhancedProductListComponent.new(products: []) do |component|
  component.with_empty_state do
    content_tag(:div, class: "text-center py-16") do
      safe_join([
        content_tag(:div, "🛍️", class: "text-6xl mb-4"),
        content_tag(:h3, "Your shopping adventure starts here!", class: "text-xl font-semibold mb-2"),
        content_tag(:p, "Discover amazing products tailored just for you.", class: "text-gray-600 mb-6"),
        content_tag(:button, "Browse Categories", class: "px-6 py-3 bg-blue-600 text-white rounded-lg")
      ])
    end
  end
end
```

## Available Props

### Core Props
- `products` (Array, required): Array of product objects
- `title` (String): Section title
- `columns` (Symbol): Grid columns (:auto, :one, :two, :three, :four, :five, :six)
- `gap` (String): Grid gap spacing ("2", "4", "6", "8", "10", "12")
- `background_color` (String): Background color
- `container_padding` (String): Container padding
- `max_width` (String): Maximum container width

### Animation Props
- `enable_animations` (Boolean): Enable/disable animations
- `animation_delay` (String): Stagger delay between cards ("50", "100", "150", "200")
- `hover_scale` (String): Hover scale effect ("105", "110", "125")

### Feature Props
- `sortable` (Boolean): Enable sorting controls
- `filterable` (Boolean): Enable filtering controls
- `show_quick_actions` (Boolean): Show hover action buttons
- `currency_symbol` (String): Currency symbol for prices

### Sorting Props
- `sort_options` (Array): Available sort fields
- `default_sort` (String): Default sort field
- `sort_direction` (String): Default sort direction

## JavaScript Events

The component dispatches custom events you can listen to:

```javascript
// Listen for quick view events
document.addEventListener('enhanced-product-list:quickView', (event) => {
  const { productId } = event.detail
  // Handle quick view
})

// Listen for add to cart events
document.addEventListener('enhanced-product-list:addToCart', (event) => {
  const { productId } = event.detail
  // Handle add to cart
})
```

## Chainable DSL Methods

When using the SwiftUI-style DSL, you can chain these methods:

- `.sortable(true/false)`: Enable/disable sorting
- `.filterable(true/false)`: Enable/disable filtering
- `.grid_columns(:count)`: Set grid columns
- `.quick_actions(true/false)`: Enable/disable quick actions
- `.animated(true/false, delay: "100")`: Configure animations
- `.hover_scale("105")`: Set hover scale effect
- `.currency("$")`: Set currency symbol

## Example: Complete Implementation

```ruby
# In your controller
def index
  @products = Product.featured.includes(:images)
end

# In your view
<div class="container mx-auto px-4 py-8">
  <%= render EnhancedProductListComponent.new(
    products: @products,
    title: "Featured Products",
    columns: :four,
    sortable: true,
    filterable: true,
    enable_animations: true,
    show_quick_actions: true,
    currency_symbol: "$"
  ) do |component|
    
    # Custom header with branding
    component.with_header do
      content_tag(:div, class: "text-center mb-12") do
        safe_join([
          content_tag(:h1, "Premium Collection", class: "text-4xl font-bold text-gray-900 mb-4"),
          content_tag(:p, "Discover our handpicked selection of premium products", class: "text-lg text-gray-600")
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
    
  end %>
</div>
```

## Styling Customization

The component includes CSS classes for customization:

```css
/* Custom animations */
.product-card-hover:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

/* Custom loading states */
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  animation: skeleton-loading 1.5s infinite;
}
```

This enhanced component provides maximum flexibility while maintaining ease of use. The slot system allows you to completely customize any part of the component while still benefiting from the built-in sorting, filtering, and animation features.