# SwiftUI Rails DSL Reference

This reference provides a comprehensive guide to the SwiftUI Rails DSL (Domain Specific Language) for building declarative UI components in Rails applications.

## DSL Quick Reference

### Core Elements

#### Text Elements
```ruby
text("Hello World")                    # Basic text
text("Bold").font_weight("bold")      # Bold text
label("Name", for_input: "name_field") # Form label
span("inline text")                    # Inline text
```

#### Layout Components
```ruby
# Vertical Stack
vstack(spacing: 4) do
  text("Item 1")
  text("Item 2")
end

# Horizontal Stack
hstack(spacing: 2, align: :center) do
  text("Left")
  spacer
  text("Right")
end

# Z-Stack (Layered)
zstack do
  image(src: "bg.jpg")
  text("Overlay").text_color("white")
end

# Grid Layout
grid(columns: 3, gap: 4) do
  products.each { |p| product_card(p) }
end
```

#### Form Elements
```ruby
# Text Input
textfield(name: "user[name]", placeholder: "Enter name")
  .required
  .data(controller: "validation")

# Select Dropdown
select(name: "category", selected: "books") do
  option("electronics", "Electronics")
  option("books", "Books", selected: true)
  option("clothing", "Clothing")
end

# Label
label("Email", for_input: "email_field")
  .font_weight("medium")
```

#### Interactive Elements
```ruby
# Button
button("Click Me")
  .bg("blue-500")
  .text_color("white")
  .px(4).py(2)
  .rounded("lg")
  .data(action: "click->controller#method")

# Link
link("View More", destination: "/products")
  .text_color("blue-600")
  .hover_underline
```

### Modifier Chains

#### Spacing Modifiers
```ruby
.p(4)              # padding: 1rem
.px(4).py(2)       # padding x/y
.m(2)              # margin: 0.5rem
.mx("auto")        # margin x auto
.space_y(4)        # vertical spacing between children
```

#### Color Modifiers
```ruby
.bg("blue-500")              # background color
.text_color("white")         # text color
.border_color("gray-300")    # border color
.hover_bg("blue-600")        # hover background
.hover_text_color("gray-900") # hover text color
```

#### Typography Modifiers
```ruby
.font_size("xl")       # text-xl
.font_weight("bold")   # font-bold
.text_align("center")  # text-center
.line_height("tight")  # leading-tight
.text_transform("uppercase") # uppercase
```

#### Layout Modifiers
```ruby
.w("full")           # width: 100%
.h(64)               # height: 16rem
.max_w("lg")         # max-width
.min_h("screen")     # min-height: 100vh
.flex                # display: flex
.flex_col            # flex-direction: column
.items_center        # align-items: center
.justify_between     # justify-content: space-between
.gap(4)              # gap: 1rem
```

#### Border & Effects Modifiers
```ruby
.border              # border
.border_width(2)     # border-width: 2px
.rounded("lg")       # border-radius
.shadow("md")        # box-shadow
.opacity(90)         # opacity: 0.9
.blur("sm")          # blur effect
.ring(2, "blue-500") # focus ring
```

#### State & Interaction Modifiers
```ruby
.hover("bg-blue-600 text-white")  # hover state
.focus("ring-2 ring-blue-500")     # focus state
.active("bg-blue-700")             # active state
.disabled("opacity-50 cursor-not-allowed") # disabled state
.transition                        # smooth transitions
.duration(300)                     # transition duration
.cursor("pointer")                 # cursor style
```

#### Advanced Modifiers
```ruby
.transform("scale-105")     # CSS transform
.translate_x(4)             # translateX
.rotate(45)                 # rotate degrees
.z(10)                      # z-index
.overflow("hidden")         # overflow
.position("relative")       # position
.display("inline-block")    # display
.break_inside("avoid")      # break-inside for print
.truncate                   # text truncation
.line_clamp(3)             # multi-line truncation
```

#### Data & Accessibility Modifiers
```ruby
.data(controller: "search", action: "input->search#query")
.data("search-target": "input", "search-delay-value": 300)
.aria(label: "Search products", expanded: false)
.role("navigation")
.title("Tooltip text")
.id("unique-id")
.attr("data-custom", "value")
```

### Common Patterns

#### Card Component
```ruby
swift_ui do
  div do
    yield  # Card content
  end
  .bg("white")
  .rounded("lg")
  .shadow("md")
  .p(6)
  .hover_shadow("lg")
  .transition
end
```

#### Form Field Group
```ruby
swift_ui do
  vstack(spacing: 1) do
    label(label_text, for_input: input_id)
      .font_weight("medium")
      .text_sm
    
    textfield(name: field_name, id: input_id)
      .w("full")
      .border
      .rounded("md")
      .px(3).py(2)
      .focus("ring-2 ring-blue-500")
    
    if error_message
      text(error_message)
        .text_color("red-600")
        .text_sm
        .mt(1)
    end
  end
end
```

#### Responsive Grid
```ruby
swift_ui do
  grid(columns: { base: 1, md: 2, lg: 3 }, gap: 6) do
    items.each do |item|
      card { yield item }
    end
  end
end
```