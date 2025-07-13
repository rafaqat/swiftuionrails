# Troubleshooting Guide

This guide provides solutions to common issues you may encounter while working with SwiftUI Rails.

## Common Issues and Solutions

### 1. Stimulus Actions Not Working
**Problem**: Click handlers or other Stimulus actions don't fire

**Solution**: Ensure HTML escaping is correct
```ruby
# Wrong - HTML escaped
button("Click").data(action: "click->controller#method")

# Correct - with .html_safe
button("Click")
  .attr("data-action", "click->controller#method".html_safe)
```

### 2. Turbo Morphing Flickering
**Problem**: Page flashes during updates

**Solution**: Use proper Turbo permanent attributes
```ruby
div(data: { turbo_permanent: true }) do
  # Content that shouldn't morph
end
```

### 3. Component Props Not Updating
**Problem**: Component doesn't reflect new prop values

**Solution**: Components are stateless - ensure parent re-renders
```ruby
# In controller
def update
  @product = Product.find(params[:id])
  @product.update!(product_params)
  
  # Trigger re-render with Turbo
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @product }
  end
end
```

### 4. ViewComponent Slot Content Missing
**Problem**: Slot content doesn't appear

**Solution**: Check slot rendering syntax
```ruby
# Component definition
renders_one :header
renders_many :items

# Usage - note the 'with_' prefix
render CardComponent.new do |card|
  card.with_header { "Title" }  # NOT card.header
  card.with_item { "Item 1" }   # NOT card.items
end
```

### 5. Tailwind Classes Not Applied
**Problem**: Custom Tailwind classes don't work

**Solution**: Ensure classes are in content paths
```javascript
// tailwind.config.js
module.exports = {
  content: [
    './app/components/**/*.rb',
    './lib/swift_ui_rails/**/*.rb',
    // Add all paths with Tailwind classes
  ]
}
```

### 6. Importmap Controller Warnings
**Problem**: "Importmap skipped missing path" warnings

**Solution**: These are harmless - controllers still work. The warnings occur because Rails looks for files during asset resolution at multiple stages.

### 7. Storybook Not Loading
**Problem**: Stories don't appear in Storybook

**Solution**: Check story class naming
```ruby
# Must end with 'Stories'
class ButtonComponentStories < ViewComponent::Storybook::Stories
  # Must include DSL
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
end
```

### 8. Form Submission Not Working
**Problem**: Forms don't submit with Turbo

**Solution**: Check CSRF token and form method
```ruby
form(action: products_path, method: :post) do
  # Rails automatically includes CSRF token
  # Make sure not to disable it accidentally
end
```

### 9. Collections Rendering Slowly
**Problem**: Lists of components render slowly

**Solution**: Use ViewComponent 2.0 collection rendering
```ruby
# Slow - manual iteration
products.each do |product|
  render ProductCardComponent.new(product: product)
end

# Fast - collection rendering
render ProductCardComponent.with_collection(products)
```

### 10. State Not Persisting
**Problem**: UI state lost on navigation

**Solution**: Choose appropriate state storage
```ruby
# URL state - survives navigation
link_to "Filter", products_path(category: "electronics")

# Session state - survives across requests
session[:user_preferences] = { theme: "dark" }

# Stimulus values - client-side only
data: { "controller-value-name": value }
```

## Performance Tips

1. **Use Turbo Frames for Partial Updates**
   ```erb
   <%= turbo_frame_tag "product_list" do %>
     <%= render ProductListComponent.new(products: @products) %>
   <% end %>
   ```

2. **Lazy Load with Turbo Frames**
   ```erb
   <%= turbo_frame_tag "comments", src: product_comments_path(@product), loading: :lazy do %>
     <div class="animate-pulse">Loading comments...</div>
   <% end %>
   ```

3. **Optimize Asset Loading**
   ```ruby
   # Preload critical components
   <%= preload_link_tag "application.css" %>
   <%= preload_link_tag "application.js" %>
   ```