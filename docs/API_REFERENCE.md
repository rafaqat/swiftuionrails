# SwiftUI Rails API Reference

This document provides comprehensive API documentation for all DSL methods available in SwiftUI Rails.

## Table of Contents

1. [Layout Components](#layout-components)
2. [Basic Elements](#basic-elements)
3. [Form Elements](#form-elements)
4. [Chainable Modifiers](#chainable-modifiers)
5. [Data Attributes](#data-attributes)
6. [Component Props](#component-props)
7. [Slots API](#slots-api)
8. [Security Helpers](#security-helpers)

## Layout Components

### vstack

Creates a vertical stack layout with consistent spacing between children.

```ruby
vstack(spacing: 4, align: :start, **attrs, &block)
```

**Parameters:**
- `spacing` (Integer, optional): Space between children in Tailwind units. Default: 4
- `align` (Symbol, optional): Alignment of children. Options: `:start`, `:center`, `:end`, `:stretch`. Default: `:stretch`
- `**attrs`: Additional HTML attributes
- `&block`: Content block containing child elements

**Examples:**
```ruby
# Basic vertical stack
vstack do
  text("Item 1")
  text("Item 2")
end

# Custom spacing and alignment
vstack(spacing: 8, align: :center) do
  image(src: "/logo.png", alt: "Logo")
  text("Welcome").font_size("xl")
end

# With additional attributes
vstack(id: "main-content", data: { controller: "stack" }) do
  # content
end
```

### hstack

Creates a horizontal stack layout with consistent spacing between children.

```ruby
hstack(spacing: 4, align: :center, justify: :start, **attrs, &block)
```

**Parameters:**
- `spacing` (Integer, optional): Space between children in Tailwind units. Default: 4
- `align` (Symbol, optional): Vertical alignment. Options: `:start`, `:center`, `:end`, `:baseline`. Default: `:center`
- `justify` (Symbol, optional): Horizontal alignment. Options: `:start`, `:center`, `:end`, `:between`, `:around`, `:evenly`. Default: `:start`
- `**attrs`: Additional HTML attributes
- `&block`: Content block

**Examples:**
```ruby
# Basic horizontal stack
hstack do
  button("Cancel")
  button("Save")
end

# Space between items
hstack(justify: :between) do
  text("Total")
  text("$99.99").font_weight("bold")
end

# Custom alignment
hstack(align: :baseline, spacing: 2) do
  text("Name:").text_sm
  text("John Doe").text_lg
end
```

### zstack

Creates a layered stack where children are positioned on top of each other.

```ruby
zstack(**attrs, &block)
```

**Parameters:**
- `**attrs`: Additional HTML attributes
- `&block`: Content block. First child is the base layer, subsequent children are overlaid.

**Examples:**
```ruby
# Image with overlay text
zstack do
  image(src: "/hero.jpg", alt: "Hero").w("full").h(64)
  div.absolute.inset(0).bg("black").opacity(50)
  text("Overlay Text").absolute.center.text_color("white")
end
```

### grid

Creates a CSS grid layout with configurable columns and gaps.

```ruby
grid(cols: 1, gap: 4, **attrs, &block)
```

**Parameters:**
- `cols` (Integer/String): Number of columns or responsive config. Default: 1
- `gap` (Integer): Gap between grid items in Tailwind units. Default: 4
- `**attrs`: Additional HTML attributes
- `&block`: Content block

**Examples:**
```ruby
# 3-column grid
grid(cols: 3, gap: 6) do
  6.times { |i| card { text("Item #{i + 1}") } }
end

# Responsive grid
grid(cols: { sm: 1, md: 2, lg: 3 }) do
  # items
end
```

### spacer

Creates flexible space that expands to fill available space.

```ruby
spacer(size: nil)
```

**Parameters:**
- `size` (Integer, optional): Fixed size in Tailwind units. If nil, expands to fill.

**Examples:**
```ruby
hstack do
  text("Left")
  spacer
  text("Right")
end
```

### divider

Creates a visual separator line.

```ruby
divider(orientation: :horizontal, **attrs)
```

**Parameters:**
- `orientation` (Symbol): `:horizontal` or `:vertical`. Default: `:horizontal`
- `**attrs`: Additional HTML attributes

**Examples:**
```ruby
vstack do
  text("Section 1")
  divider
  text("Section 2")
end
```

## Basic Elements

### text

Renders text content with automatic HTML escaping.

```ruby
text(content = nil, **attrs, &block)
```

**Parameters:**
- `content` (String, optional): Text content to display
- `**attrs`: Additional HTML attributes
- `&block`: Alternative content block

**Examples:**
```ruby
# Simple text
text("Hello World")

# With styling
text("Important").font_weight("bold").text_color("red-600")

# Block form
text { "Dynamic: #{Time.now}" }
```

### button

Creates an interactive button element.

```ruby
button(label = nil, type: "button", **attrs, &block)
```

**Parameters:**
- `label` (String, optional): Button text
- `type` (String): Button type. Options: "button", "submit", "reset". Default: "button"
- `**attrs`: Additional HTML attributes including data attributes for Stimulus
- `&block`: Alternative content block

**Examples:**
```ruby
# Simple button
button("Click Me")

# Submit button
button("Save", type: "submit").variant(:primary)

# With Stimulus action
button("Increment").data(action: "click->counter#increment")

# Block form with icon
button do
  icon(:save).mr(2)
  text("Save Changes")
end
```

### link

Creates a hyperlink with URL validation.

```ruby
link(text = nil, destination: "#", **attrs, &block)
```

**Parameters:**
- `text` (String, optional): Link text
- `destination` (String): URL or path. Validated for security. Default: "#"
- `**attrs`: Additional HTML attributes
- `&block`: Alternative content block

**Examples:**
```ruby
# Basic link
link("Home", destination: "/")

# External link with attributes
link("Documentation", destination: "https://docs.example.com", target: "_blank")

# Block form
link(destination: user_path(@user)) do
  avatar(@user.image)
  text(@user.name)
end
```

### image

Renders an image with automatic URL validation.

```ruby
image(src: nil, alt: "", **attrs)
```

**Parameters:**
- `src` (String): Image URL or path. Validated for security.
- `alt` (String): Alternative text for accessibility
- `**attrs`: Additional HTML attributes

**Examples:**
```ruby
# Basic image
image(src: "/logo.png", alt: "Company Logo")

# With sizing and styling
image(src: @product.image_url, alt: @product.name)
  .w(64)
  .h(64)
  .object_cover
  .rounded("lg")
```

### icon

Renders an icon (requires icon library integration).

```ruby
icon(name, size: 24, **attrs)
```

**Parameters:**
- `name` (String/Symbol): Icon identifier
- `size` (Integer): Icon size in pixels. Default: 24
- `**attrs`: Additional HTML attributes

**Examples:**
```ruby
# Basic icon
icon(:check)

# Colored and sized
icon(:warning, size: 32).text_color("yellow-500")
```

### card

Creates a card container with elevation.

```ruby
card(elevation: 1, **attrs, &block)
```

**Parameters:**
- `elevation` (Integer): Shadow depth (0-5). Default: 1
- `**attrs`: Additional HTML attributes
- `&block`: Card content

**Examples:**
```ruby
card(elevation: 2) do
  vstack(spacing: 4) do
    text("Card Title").font_size("lg").font_weight("semibold")
    text("Card content goes here")
  end
end
```

## Form Elements

### textfield

Creates a text input field.

```ruby
textfield(name: nil, value: nil, placeholder: nil, type: "text", **attrs)
```

**Parameters:**
- `name` (String): Input name attribute
- `value` (String): Initial value
- `placeholder` (String): Placeholder text
- `type` (String): Input type (text, email, password, etc.). Default: "text"
- `**attrs`: Additional HTML attributes

**Examples:**
```ruby
# Basic text input
textfield(name: "user[email]", placeholder: "Enter email")

# Password field
textfield(name: "password", type: "password").w("full")

# With validation attributes
textfield(
  name: "age",
  type: "number",
  min: 18,
  max: 100,
  required: true
)
```

### textarea

Creates a multi-line text input.

```ruby
textarea(name: nil, value: nil, rows: 4, **attrs)
```

**Parameters:**
- `name` (String): Input name attribute
- `value` (String): Initial value
- `rows` (Integer): Number of visible rows. Default: 4
- `**attrs`: Additional HTML attributes

**Examples:**
```ruby
textarea(name: "comment", rows: 6, placeholder: "Enter your comment...")
  .w("full")
  .resize_none
```

### select

Creates a dropdown select element.

```ruby
select(name: nil, selected: nil, **attrs, &block)
```

**Parameters:**
- `name` (String): Select name attribute
- `selected` (String): Value of selected option
- `**attrs`: Additional HTML attributes
- `&block`: Block containing option elements

**Examples:**
```ruby
select(name: "country", selected: "us") do
  option("", "Choose a country", disabled: true)
  option("us", "United States")
  option("uk", "United Kingdom")
  option("ca", "Canada")
end
```

### option

Creates an option for select elements.

```ruby
option(value, text_content = nil, selected: false, **attrs)
```

**Parameters:**
- `value` (String): Option value
- `text_content` (String): Display text. Uses value if nil.
- `selected` (Boolean): Whether option is selected. Default: false
- `**attrs`: Additional HTML attributes

### checkbox

Creates a checkbox input.

```ruby
checkbox(name: nil, checked: false, **attrs)
```

**Parameters:**
- `name` (String): Input name attribute
- `checked` (Boolean): Whether checked. Default: false
- `**attrs`: Additional HTML attributes

**Examples:**
```ruby
checkbox(name: "terms", checked: @user.accepted_terms?)
  .mr(2)
```

### radio

Creates a radio button input.

```ruby
radio(name: nil, value: nil, checked: false, **attrs)
```

**Parameters:**
- `name` (String): Input name attribute (shared across radio group)
- `value` (String): This radio button's value
- `checked` (Boolean): Whether selected. Default: false
- `**attrs`: Additional HTML attributes

### label

Creates a form label.

```ruby
label(text_content = nil, for_input: nil, **attrs, &block)
```

**Parameters:**
- `text_content` (String): Label text
- `for_input` (String): ID of associated input
- `**attrs`: Additional HTML attributes
- `&block`: Alternative content block

**Examples:**
```ruby
label("Email Address", for_input: "email_field")

# Block form with nested input
label do
  checkbox(name: "remember")
  text("Remember me").ml(2)
end
```

## Chainable Modifiers

All DSL elements return self, allowing method chaining for applying styles and attributes.

### Spacing Modifiers

```ruby
# Padding
.p(size)          # All sides
.px(size)         # Horizontal
.py(size)         # Vertical
.pt(size)         # Top
.pr(size)         # Right
.pb(size)         # Bottom
.pl(size)         # Left

# Margin
.m(size)          # All sides
.mx(size)         # Horizontal
.my(size)         # Vertical
.mt(size)         # Top
.mr(size)         # Right
.mb(size)         # Bottom
.ml(size)         # Left

# Space between children (for flex/grid containers)
.space_x(size)    # Horizontal spacing
.space_y(size)    # Vertical spacing
```

### Color Modifiers

```ruby
.bg(color)              # Background color
.text_color(color)      # Text color
.border_color(color)    # Border color
.ring_color(color)      # Focus ring color
.placeholder_color(color) # Placeholder text color
```

### Typography Modifiers

```ruby
.font_size(size)        # Text size (xs, sm, base, lg, xl, 2xl, etc.)
.font_weight(weight)    # Font weight (thin, light, normal, medium, semibold, bold, extrabold, black)
.font_style(style)      # italic or normal
.text_align(align)      # left, center, right, justify
.line_height(height)    # Leading (none, tight, snug, normal, relaxed, loose)
.letter_spacing(spacing) # Tracking (tighter, tight, normal, wide, wider, widest)
.text_transform(transform) # uppercase, lowercase, capitalize, normal-case
.text_decoration(decoration) # underline, line-through, no-underline
.line_clamp(lines)      # Truncate to N lines
```

### Layout Modifiers

```ruby
# Display
.block
.inline_block
.inline
.flex
.inline_flex
.grid
.hidden

# Width & Height
.w(size)          # Width (full, screen, min, max, fit, or number)
.h(size)          # Height
.min_w(size)      # Min width
.min_h(size)      # Min height
.max_w(size)      # Max width
.max_h(size)      # Max height

# Flexbox
.flex_direction(dir)  # row, row-reverse, col, col-reverse
.flex_wrap(wrap)      # wrap, wrap-reverse, nowrap
.flex_grow(value)     # 0 or 1
.flex_shrink(value)   # 0 or 1
.items(align)         # Align items (start, center, end, baseline, stretch)
.justify(justify)     # Justify content (start, center, end, between, around, evenly)
.gap(size)            # Gap between flex/grid items

# Position
.relative
.absolute
.fixed
.sticky
.static

# Position values
.top(value)
.right(value)
.bottom(value)
.left(value)
.inset(value)     # All sides
.inset_x(value)   # Left and right
.inset_y(value)   # Top and bottom

# Z-index
.z(index)
```

### Border & Shape Modifiers

```ruby
# Border width
.border(width = 1)    # All sides
.border_t(width)      # Top
.border_r(width)      # Right
.border_b(width)      # Bottom
.border_l(width)      # Left

# Border style
.border_style(style)  # solid, dashed, dotted, double, none

# Border radius
.rounded(size = "DEFAULT")     # All corners
.rounded_t(size)              # Top corners
.rounded_r(size)              # Right corners
.rounded_b(size)              # Bottom corners
.rounded_l(size)              # Left corners
.rounded_tl(size)             # Top left
.rounded_tr(size)             # Top right
.rounded_bl(size)             # Bottom left
.rounded_br(size)             # Bottom right
.rounded_full                 # Full circle

# Common shortcuts
.circle           # Alias for rounded_full
.corner_radius(size) # Alias for rounded
```

### Effect Modifiers

```ruby
# Shadow
.shadow(size = "DEFAULT")  # Box shadow (sm, DEFAULT, md, lg, xl, 2xl, none)
.shadow_color(color)       # Shadow color

# Opacity
.opacity(value)           # 0-100

# Transform
.scale(value)             # Scale transform
.rotate(degrees)          # Rotation
.translate_x(value)       # X translation
.translate_y(value)       # Y translation
.transform(value)         # Custom transform

# Transition
.transition(properties = "DEFAULT")  # Enable transitions
.duration(ms)             # Transition duration
.ease(timing)             # Transition timing function

# Overflow
.overflow(value)          # visible, hidden, auto, scroll
.overflow_x(value)        # Horizontal overflow
.overflow_y(value)        # Vertical overflow

# Other effects
.cursor(type)             # Cursor type
.select(value)            # User selection (none, text, all, auto)
.resize(value)            # Resize behavior (none, both, horizontal, vertical)
```

### State Modifiers

```ruby
# Pseudo-class modifiers
.hover(classes)           # Hover state
.focus(classes)           # Focus state
.active(classes)          # Active state
.disabled(classes)        # Disabled state
.visited(classes)         # Visited state (links)

# Responsive modifiers
.sm(classes)              # Small screens and up
.md(classes)              # Medium screens and up
.lg(classes)              # Large screens and up
.xl(classes)              # Extra large screens and up
.xxl(classes)             # 2X large screens and up

# Dark mode
.dark(classes)            # Dark mode styles
```

### Additional Modifiers

```ruby
# Accessibility
.sr_only                  # Screen reader only
.not_sr_only              # Not screen reader only

# Utilities
.truncate                 # Truncate text with ellipsis
.break_words              # Break long words
.whitespace(value)        # Whitespace handling
.list_style(type)         # List style type
.list_position(position)  # List marker position

# Custom attributes
.attr(name, value)        # Set any HTML attribute
.data(hash)               # Set data attributes
.aria(hash)               # Set ARIA attributes
.style(css_string)        # Inline styles (validated)
.title(text)              # Title attribute (tooltip)
```

## Data Attributes

### Stimulus Integration

```ruby
# Set Stimulus controller
.data(controller: "my-controller")

# Set Stimulus action
.data(action: "click->my-controller#handleClick")

# Set Stimulus values
.data("my-controller-url-value": "/api/endpoint")
.data("my-controller-count-value": 42)

# Set Stimulus targets
.data("my-controller-target": "button")

# Multiple controllers
.data(controller: "controller1 controller2")

# Multiple actions
.data(action: "click->controller1#action1 change->controller2#action2")
```

### Custom Data Attributes

```ruby
# Single attribute
.data(id: "123")

# Multiple attributes
.data(
  user_id: current_user.id,
  role: current_user.role,
  timestamp: Time.current.to_i
)

# Nested data
.data(
  config: { theme: "dark", language: "en" }.to_json
)
```

## Component Props

### Defining Props

```ruby
class MyComponent < SwiftUIRails::Component::Base
  # Required string prop
  prop :title, type: String, required: true
  
  # Optional prop with default
  prop :count, type: Integer, default: 0
  
  # Boolean prop (accepts TrueClass or FalseClass)
  prop :active, type: [TrueClass, FalseClass], default: false
  
  # Array prop
  prop :items, type: Array, default: []
  
  # Hash prop
  prop :options, type: Hash, default: {}
  
  # Custom type
  prop :user, type: User, required: true
  
  # Multiple allowed types
  prop :content, type: [String, Proc], required: true
  
  # Nil-able prop
  prop :description, type: [String, NilClass], default: nil
end
```

### Prop Validation

Props are validated at initialization:
- Type checking ensures correct data types
- Required props must be provided
- Default values are used for optional props
- Type mismatches raise `ArgumentError`

## Slots API

### Single Slots

```ruby
class CardComponent < SwiftUIRails::Component::Base
  renders_one :header
  renders_one :footer
  
  swift_ui do
    div do
      div { header } if header?
      div { content }
      div { footer } if footer?
    end
  end
end

# Usage
render CardComponent.new do |card|
  card.with_header do
    text("Card Title")
  end
  card.with_footer do
    button("Save")
  end
  text("Card content")
end
```

### Multiple Slots

```ruby
class ListComponent < SwiftUIRails::Component::Base
  renders_many :items
  
  swift_ui do
    ul do
      items.each do |item|
        li { item }
      end
    end
  end
end

# Usage
render ListComponent.new do |list|
  list.with_item { text("Item 1") }
  list.with_item { text("Item 2") }
  list.with_item { text("Item 3") }
end
```

### Slot with Arguments

```ruby
class TabsComponent < SwiftUIRails::Component::Base
  renders_many :tabs, TabComponent
  
  class TabComponent < SwiftUIRails::Component::Base
    prop :label, type: String, required: true
    prop :active, type: [TrueClass, FalseClass], default: false
  end
end

# Usage
render TabsComponent.new do |tabs|
  tabs.with_tab(label: "Home", active: true) do
    text("Home content")
  end
  tabs.with_tab(label: "Profile") do
    text("Profile content")
  end
end
```

## Security Helpers

### URL Validation

```ruby
# Automatically validates URLs in links and images
link("Click", destination: user_input)  # Validates user_input
image(src: user_input)                   # Validates user_input

# Manual validation
validator = SwiftUIRails::Security::UrlValidator.new
safe_url = validator.safe_url(user_input, fallback: "#")
```

### CSS Validation

```ruby
# Automatically validates CSS in style attributes
div.style("color: #{user_input}")  # Validates user_input

# Manual validation
validator = SwiftUIRails::Security::CssValidator.new
safe_css = validator.safe_css_value(user_input, fallback: "inherit")
```

### Form Security

```ruby
# Secure form with CSRF token
secure_form(action: "/submit", method: "post") do
  textfield(name: "email")
  button("Submit", type: "submit")
end

# Generates:
# <form action="/submit" method="post">
#   <input type="hidden" name="authenticity_token" value="...">
#   ...
# </form>
```

### Content Escaping

```ruby
# Text content is automatically escaped
text(user_input)  # HTML entities are escaped

# Raw HTML (use with caution)
raw(trusted_html)  # Only use with content you trust
```

## Component Collections

### Rendering Collections

```ruby
# Define collection-compatible component
class ProductCardComponent < SwiftUIRails::Component::Base
  prop :product, type: Product, required: true
  prop :featured, type: [TrueClass, FalseClass], default: false
  
  swift_ui do
    card(elevation: featured ? 3 : 1) do
      text(product.name)
      text(product.price)
    end
  end
end

# Render collection efficiently
products = Product.all
ProductCardComponent.with_collection(
  products,
  featured: ->(product) { product.bestseller? }
)
```

### Collection with Counter

```ruby
# Access index in collection rendering
class ListItemComponent < SwiftUIRails::Component::Base
  prop :item, type: String, required: true
  prop :item_counter, type: Integer  # Automatic counter
  
  swift_ui do
    div do
      text("#{item_counter}. #{item}")
    end
  end
end

# Usage
items = ["Apple", "Banana", "Cherry"]
ListItemComponent.with_collection(items.map { |i| { item: i } })
# Renders: "1. Apple", "2. Banana", "3. Cherry"
```

## Error Handling

### Development Mode

In development, components show detailed error messages:
```ruby
# Missing required prop shows helpful error
CardComponent.new  # => ArgumentError: Missing required prop: title

# Type mismatch shows expected type
CardComponent.new(title: 123)  # => ArgumentError: Invalid type for prop title. Expected String, got Integer
```

### Production Mode

In production, components gracefully handle errors:
- Invalid props log warnings but don't crash
- Missing content returns empty elements
- XSS attempts are sanitized silently

## Performance Optimization

### Memoization

Components support view caching:
```ruby
class ExpensiveComponent < SwiftUIRails::Component::Base
  prop :data, type: Array, required: true
  
  # Enable/disable memoization
  self.swift_ui_memoization_enabled = true
  
  swift_ui do
    # Expensive rendering logic
  end
  
  # Custom cache key
  def cache_key_with_version
    [self.class.name, data.cache_key_with_version].join("/")
  end
end
```

### Collection Rendering

Use ViewComponent's optimized collection rendering:
```ruby
# 10x faster than manual iteration
components = MyComponent.with_collection(items)

# Instead of:
items.map { |item| render MyComponent.new(item: item) }
```

## Testing Components

### Unit Testing

```ruby
RSpec.describe MyComponent do
  it "renders title" do
    component = MyComponent.new(title: "Test")
    rendered = component.call
    
    expect(rendered).to include("Test")
  end
  
  it "validates props" do
    expect {
      MyComponent.new(title: 123)
    }.to raise_error(ArgumentError)
  end
end
```

### System Testing

```ruby
class ComponentSystemTest < ApplicationSystemTestCase
  test "interactive component" do
    visit root_path
    
    # Find component by data attributes
    within("[data-controller='counter']") do
      assert_text "0"
      click_button "+"
      assert_text "1"
    end
  end
end
```

## Best Practices

1. **Prop Design**: Use specific types and required flags
2. **Security**: Never trust user input - all methods validate automatically
3. **Performance**: Use collections for multiple components
4. **Composition**: Build complex UIs from simple components
5. **Testing**: Test props, rendering, and interactions separately
6. **Accessibility**: Always include alt text, labels, and ARIA attributes
7. **Responsive**: Use responsive modifiers for mobile-first design
8. **State**: Keep components stateless, use Stimulus for interactivity