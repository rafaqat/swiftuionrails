# SwiftUI Rails Migration Guide

This guide helps you migrate between different versions of SwiftUI Rails, covering breaking changes, new features, and upgrade paths.

## Table of Contents
- [Migrating to 1.0.0](#migrating-to-100)
- [From 0.x to 1.0](#from-0x-to-10)
- [Component Migration](#component-migration)
- [DSL Changes](#dsl-changes)
- [Security Updates](#security-updates)
- [Performance Improvements](#performance-improvements)

## Migrating to 1.0.0

### Overview
Version 1.0.0 brings significant improvements in security, performance, and API consistency. This is a major release with some breaking changes.

### Breaking Changes

#### 1. Component Base Class Change
```ruby
# Old (0.x)
class MyComponent < ViewComponent::Base
  include SwiftUIRails::DSL
end

# New (1.0)
class MyComponent < SwiftUIRails::Component::Base
  # DSL is automatically included
end
```

#### 2. Prop Definition Syntax
```ruby
# Old (0.x)
class MyComponent < ViewComponent::Base
  attr_reader :title, :color
  
  def initialize(title:, color: "blue")
    @title = title
    @color = color
  end
end

# New (1.0)
class MyComponent < SwiftUIRails::Component::Base
  prop :title, type: String, required: true
  prop :color, type: String, default: "blue"
end
```

#### 3. DSL Method Changes
```ruby
# Old (0.x)
def call
  content_tag :div, class: "p-4" do
    content_tag :span, title
  end
end

# New (1.0)
swift_ui do
  div do
    text(title)
  end.p(4)
end
```

#### 4. Removed Components
The following components have been removed in favor of DSL-based composition:

- `ProductListComponent` → Use DSL `product_card` with collection rendering
- `SimpleCardComponent` → Use DSL `card` method
- `EnhancedProductListComponent` → Use DSL composition patterns

```ruby
# Old
<%= render ProductListComponent.new(products: @products) %>

# New
<%= swift_ui do
  vstack(spacing: 4) do
    @products.each do |product|
      product_card(product)
    end
  end
end %>

# New (optimized with ViewComponent 2.0)
<%= render ProductCardComponent.with_collection(@products) %>
```

### Security Enhancements

#### URL Validation
All URLs passed to components are now validated:

```ruby
# This will raise an error in 1.0 if URL is invalid
link("Click", destination: user_input_url)  # Validated automatically

# To allow specific protocols
link("Download", destination: custom_url, allowed_protocols: ["ftp", "ftps"])
```

#### CSS Injection Prevention
CSS classes are now sanitized:

```ruby
# Old (potentially unsafe)
div(class: user_input)  

# New (automatically sanitized)
div.class(user_input)  # Dangerous characters removed
```

#### Content Security Policy
CSP headers are automatically applied. To customize:

```ruby
# config/initializers/swift_ui_rails.rb
SwiftUIRails.configure do |config|
  config.content_security_policy = {
    default_src: ["'self'"],
    script_src: ["'self'", "'unsafe-inline'"],
    style_src: ["'self'", "'unsafe-inline'"],
    img_src: ["'self'", "data:", "https:"]
  }
end
```

### Performance Improvements

#### Collection Rendering (10x faster)
```ruby
# Old (slow)
@products.each do |product|
  render ProductComponent.new(product: product)
end

# New (10x faster)
render ProductComponent.with_collection(@products)
```

#### Slots API
```ruby
# Old
class CardComponent < ViewComponent::Base
  def initialize(header:, body:, footer: nil)
    @header = header
    @body = body
    @footer = footer
  end
end

# New (more efficient)
class CardComponent < SwiftUIRails::Component::Base
  renders_one :header
  renders_one :body
  renders_one :footer
end
```

### Step-by-Step Migration

#### Step 1: Update Gemfile
```ruby
# Gemfile
gem 'swift_ui_rails', '~> 1.0'
```

#### Step 2: Run Bundle Update
```bash
bundle update swift_ui_rails
```

#### Step 3: Update Base Classes
Find all components inheriting from `ViewComponent::Base`:

```bash
# Find components to update
grep -r "< ViewComponent::Base" app/components/

# Update each file to inherit from SwiftUIRails::Component::Base
```

#### Step 4: Convert Props
Update component initialization to use the prop DSL:

```ruby
# Before
def initialize(title:, subtitle: nil, color: "blue")
  @title = title
  @subtitle = subtitle
  @color = color
end

# After
prop :title, type: String, required: true
prop :subtitle, type: String
prop :color, type: String, default: "blue"
```

#### Step 5: Convert Render Methods
Convert `call` methods to `swift_ui` blocks:

```ruby
# Before
def call
  content_tag :div, class: "card p-4" do
    concat content_tag(:h2, title, class: "text-xl")
    concat content_tag(:p, subtitle) if subtitle
  end
end

# After
swift_ui do
  div.card.p(4) do
    h2(title).text_xl
    p(subtitle) if subtitle
  end
end
```

#### Step 6: Update Component Usage
Update component instantiation in views:

```ruby
# Before (if using removed components)
<%= render ProductListComponent.new(products: @products) %>

# After (using DSL)
<%= swift_ui do
  product_list(@products)
end %>

# Or with custom component
<%= render ProductCardComponent.with_collection(@products) %>
```

#### Step 7: Test Security Features
Ensure your components handle untrusted input safely:

```ruby
# Test with potentially dangerous input
component = MyComponent.new(
  url: "javascript:alert('xss')",  # Will be sanitized
  css_class: "valid-class <script>",  # Script tags removed
  content: "<script>alert('xss')</script>"  # Use html_safe carefully
)
```

#### Step 8: Run Tests
```bash
# Run your test suite
bundle exec rspec
bundle exec rails test
bundle exec rails test:system
```

### Deprecation Warnings

To help with migration, deprecation warnings are shown for removed components:

```ruby
# This will show a deprecation warning
ProductListComponent.new(products: @products)
# => DEPRECATION WARNING: ProductListComponent has been removed in version 1.0.0. 
#    Use DSL-based product cards with swift_ui blocks instead.
```

To silence deprecation warnings temporarily:

```ruby
# config/initializers/swift_ui_rails.rb
SwiftUIRails.configure do |config|
  config.silence_deprecations = true  # Not recommended for production
end
```

### Common Migration Issues

#### Issue 1: NoMethodError for `call`
**Problem**: Component uses `call` method instead of `swift_ui` block.

**Solution**:
```ruby
# Add swift_ui block
swift_ui do
  # Move your call method content here
end
```

#### Issue 2: Missing Props
**Problem**: Props not defined with prop DSL.

**Solution**:
```ruby
# Define all props explicitly
prop :name, type: String, required: true
prop :age, type: Integer, default: 0
```

#### Issue 3: HTML Safety
**Problem**: Content not rendering due to HTML escaping.

**Solution**:
```ruby
# Only use html_safe for trusted content
text(sanitize(user_content))  # Sanitize first
text(trusted_content).html_safe  # Only for trusted content
```

#### Issue 4: Collection Performance
**Problem**: Slow rendering of multiple components.

**Solution**:
```ruby
# Use ViewComponent collection rendering
render MyComponent.with_collection(@items)
```

## From 0.x to 1.0

### Feature Comparison

| Feature | 0.x | 1.0 |
|---------|-----|-----|
| Base Class | ViewComponent::Base | SwiftUIRails::Component::Base |
| Props | Manual attr_reader | prop DSL |
| Rendering | call method | swift_ui block |
| Chainable Modifiers | Limited | Full Tailwind support |
| Security | Basic | Enhanced validation |
| Performance | Standard | 10x with collections |
| Slots | Basic | ViewComponent 2.0 slots |

### New Features in 1.0

1. **Comprehensive DSL Methods**
   - 100+ chainable modifiers
   - Layout helpers (vstack, hstack, grid)
   - Form helpers with validation
   - Animation support

2. **Security Validators**
   - URL validation with protocol checking
   - CSS class sanitization
   - Content Security Policy
   - Rate limiting

3. **Performance Optimizations**
   - Collection rendering
   - Compiled templates
   - Optimized prop handling

4. **Developer Experience**
   - Better error messages
   - Comprehensive documentation
   - Interactive Storybook
   - Generator improvements

## Component Migration

### Basic Component
```ruby
# Old (0.x)
class ButtonComponent < ViewComponent::Base
  def initialize(text:, type: :primary)
    @text = text
    @type = type
  end
  
  def call
    content_tag :button, @text, 
      class: "btn btn-#{@type}",
      data: { action: "click->button#click" }
  end
end

# New (1.0)
class ButtonComponent < SwiftUIRails::Component::Base
  prop :text, type: String, required: true
  prop :type, type: Symbol, default: :primary
  
  swift_ui do
    button(text)
      .button_style(type)
      .data(action: "click->button#click")
  end
end
```

### Component with Slots
```ruby
# Old (0.x)
class CardComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
  
  def call
    content_tag :div, class: "card" do
      concat content_tag(:h3, @title)
      concat content
    end
  end
end

# New (1.0)
class CardComponent < SwiftUIRails::Component::Base
  prop :title, type: String, required: true
  
  renders_one :header
  renders_one :footer
  
  swift_ui do
    card do
      header || h3(title)
      div { content }
      footer if footer?
    end
  end
end
```

## DSL Changes

### New Chainable Modifiers

Version 1.0 adds many new modifiers:

```ruby
# Spacing
.p(4)           # padding
.m(2)           # margin  
.px(4).py(2)    # padding x/y

# Layout
.flex           # display: flex
.grid           # display: grid
.hidden         # display: none

# Typography
.text_xl        # font-size
.font_bold      # font-weight
.italic         # font-style

# Effects  
.shadow_lg      # box-shadow
.rounded_lg     # border-radius
.opacity(50)    # opacity

# States
.hover("bg-blue-600")
.focus("ring-2")
.disabled("opacity-50")

# Animations
.transition
.duration(300)
.ease_in_out
```

### Form Helpers

New form-specific DSL methods:

```ruby
swift_ui do
  form(action: "/submit", method: :post) do
    field_group do
      label("Email", for: :email)
      textfield(:email, type: :email, required: true)
      error_text(@errors[:email])
    end
    
    button("Submit", type: :submit)
      .button_style(:primary)
  end
end
```

## Security Updates

### Input Validation

All user inputs are validated:

```ruby
# URLs are validated
link("Click", destination: params[:url])  # Automatically validated

# CSS classes are sanitized
div.class(params[:class])  # Dangerous characters removed

# HTML content requires explicit trust
text(params[:content])  # Escaped by default
text(params[:content]).html_safe  # Only for trusted content
```

### Rate Limiting

Components can implement rate limiting:

```ruby
class SearchComponent < SwiftUIRails::Component::Base
  include SwiftUIRails::Security::RateLimiter
  
  rate_limit :render, max: 10, per: :minute
  
  swift_ui do
    # Component content
  end
end
```

## Performance Improvements

### Benchmark Results

| Operation | 0.x | 1.0 | Improvement |
|-----------|-----|-----|-------------|
| Render 100 components | 250ms | 25ms | 10x |
| Component with slots | 5ms | 0.5ms | 10x |
| Prop validation | 2ms | 0.2ms | 10x |

### Collection Rendering

Always use collection rendering for multiple components:

```ruby
# Slow (avoid)
@items.map { |item| render ItemComponent.new(item: item) }

# Fast (recommended)
render ItemComponent.with_collection(@items)

# With counter
render ItemComponent.with_collection(@items) do |item, counter|
  # counter.index gives you the position
end
```

### Caching

Leverage Rails caching with components:

```ruby
class ExpensiveComponent < SwiftUIRails::Component::Base
  prop :data, type: Hash, required: true
  
  def cache_key
    [self.class.name, data.hash, I18n.locale]
  end
  
  swift_ui do
    cache(cache_key, expires_in: 1.hour) do
      # Expensive rendering
    end
  end
end
```

## Troubleshooting

### Common Errors

1. **"undefined method 'swift_ui'"**
   - Ensure component inherits from `SwiftUIRails::Component::Base`

2. **"invalid URL"**
   - Check URL validation, add allowed protocols if needed

3. **"uninitialized constant Component"**
   - Run `bundle install` and restart server

4. **Deprecation warnings**
   - Follow migration steps for removed components

### Getting Help

- Check the [API Reference](API_REFERENCE.md)
- See [examples in test app](../test_app/app/components)
- Report issues on GitHub

## Version History

### 1.0.0 (2024-01)
- Complete DSL overhaul
- Security enhancements
- 10x performance improvements
- ViewComponent 2.0 integration

### 0.x (2023)
- Initial release
- Basic component system
- Limited DSL support