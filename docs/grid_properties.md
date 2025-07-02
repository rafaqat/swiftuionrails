# SwiftUI Rails Grid Properties Documentation

## Enhanced Grid Method for E-commerce Layouts

The `grid` method now supports a comprehensive set of properties typical for e-commerce product grids:

### Basic Properties

#### `columns` (Integer, Hash, or with `min_item_width`)
- **Integer**: Number of columns (1-6 with automatic responsive breakpoints)
- **Hash**: Responsive columns e.g., `{ base: 1, sm: 2, lg: 3, xl: 4 }`
- **With `min_item_width`**: Auto-fit columns based on minimum item width

```ruby
# Fixed columns with automatic responsive behavior
grid(columns: 4) # 1 col mobile → 2 sm → 3 lg → 4 xl

# Custom responsive columns
grid(columns: { base: 1, sm: 2, md: 3, lg: 4, xl: 5 })

# Auto-fit based on minimum width
grid(min_item_width: 280) # As many columns as fit with 280px min
```

### Spacing Properties

#### `spacing` (Integer)
- Uniform gap between all grid items (default: 8)

#### `row_gap` (Integer)
- Vertical spacing between rows

#### `column_gap` (Integer)
- Horizontal spacing between columns

```ruby
# Uniform spacing
grid(columns: 3, spacing: 6)

# Different row/column gaps
grid(columns: 4, row_gap: 8, column_gap: 4)
```

### Layout Properties

#### `responsive` (Boolean)
- Enable/disable automatic responsive breakpoints (default: true)

```ruby
# Disable responsive behavior
grid(columns: 4, responsive: false) # Always 4 columns
```

#### `align` (Symbol)
- Vertical alignment of items: `:start`, `:center`, `:end`, `:stretch` (default)

```ruby
# Center items vertically
grid(columns: 3, align: :center)
```

#### `justify` (Symbol)
- Horizontal distribution: `:start` (default), `:center`, `:end`, `:between`, `:around`, `:evenly`

```ruby
# Space items evenly
grid(columns: 3, justify: :evenly)
```

#### `auto_rows` (Symbol or String)
- Control row heights:
  - `:min` - Minimum content height
  - `:max` - Maximum content height
  - `:fr` - Equal height rows
  - String value like "300px" or "minmax(200px, 1fr)"

```ruby
# Equal height rows
grid(columns: 3, auto_rows: :fr)

# Fixed height rows
grid(columns: 4, auto_rows: "300px")

# Flexible with minimum
grid(columns: 3, auto_rows: "minmax(250px, auto)")
```

#### `auto_flow` (Symbol)
- Control item placement algorithm:
  - `:row` - Fill by rows (default)
  - `:column` - Fill by columns
  - `:dense` - Pack items to fill holes
  - `:row_dense` - Row-wise dense packing
  - `:column_dense` - Column-wise dense packing

```ruby
# Dense packing for varied item sizes
grid(columns: 4, auto_flow: :dense)
```

#### `masonry` (Boolean)
- Enable masonry/Pinterest-style layout (requires additional CSS/JS)

```ruby
# Masonry layout
grid(columns: 4, masonry: true)
```

## Complete Examples

### Basic E-commerce Product Grid
```ruby
grid(columns: 4, spacing: 6) do
  products.each do |product|
    dsl_product_card(
      name: product[:name],
      price: product[:price],
      image_url: product[:image]
    )
  end
end
```

### Responsive Grid with Custom Breakpoints
```ruby
grid(
  columns: { base: 1, sm: 2, md: 3, lg: 4, xl: 5 },
  row_gap: 8,
  column_gap: 6,
  align: :start
) do
  products.each { |p| dsl_product_card(...) }
end
```

### Auto-fit Grid with Minimum Width
```ruby
grid(
  min_item_width: 250,
  spacing: 4,
  auto_rows: "minmax(300px, auto)"
) do
  products.each { |p| dsl_product_card(...) }
end
```

### Category Grid with Different Gaps
```ruby
grid(
  columns: 3,
  row_gap: 12,      # More vertical space
  column_gap: 6,    # Less horizontal space
  align: :stretch,  # Equal heights
  auto_rows: :fr    # Force equal row heights
) do
  categories.each do |category|
    category_card(category)
  end
end
```

### Featured Products Grid
```ruby
grid(
  columns: 2,
  spacing: 8,
  responsive: true,
  align: :center,
  justify: :center,
  auto_rows: "400px"  # Fixed height for featured items
) do
  featured_products.each do |product|
    featured_product_card(product)
  end
end
```

### Mixed Size Grid with Dense Packing
```ruby
grid(
  columns: 4,
  spacing: 4,
  auto_flow: :dense,  # Fill gaps efficiently
  align: :start
) do
  products.each_with_index do |product, i|
    # Some items span 2 columns
    if product[:featured]
      div.col_span(2) do
        featured_product_card(product)
      end
    else
      dsl_product_card(product)
    end
  end
end
```

## Integration with Existing DSL

All grid properties work seamlessly with the DSL chaining pattern:

```ruby
swift_ui do
  section.bg("gray-50").py(12) do
    div.container.mx("auto") do
      # Header
      text("Our Products").text_4xl.font_bold.mb(8)
      
      # Product grid with all features
      grid(
        columns: { base: 1, sm: 2, lg: 3, xl: 4 },
        row_gap: 8,
        column_gap: 6,
        align: :stretch,
        auto_rows: :fr,
        responsive: true
      ) do
        @products.each do |product|
          dsl_product_card(
            name: product.name,
            price: product.price,
            image_url: product.image_url,
            variant: product.variant,
            show_cta: true,
            cta_text: "Add to Cart"
          )
        end
      end
    end
  end
end
```