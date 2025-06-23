# SwiftUI Rails

A declarative, component-based view system for Rails that combines SwiftUI's intuitive API with Tailwind CSS utilities and ViewComponent architecture.

## Features

- 🚀 **SwiftUI-inspired DSL** - Write views with a familiar, declarative syntax
- 🎨 **Tailwind CSS Integration** - Style components with utility classes
- 📦 **ViewComponent Based** - Organized, testable, reusable components
- ⚡ **Stimulus Powered** - Reactive state management and interactions
- 🔄 **Turbo Ready** - Seamless SPA-like experiences
- 🎯 **Type Safe** - Runtime prop validation and type checking
- 📚 **Storybook Integration** - Visual component development and testing

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swift_ui_rails'
```

Then execute:

```bash
$ bundle install
$ rails generate swift_ui_rails:install
```

## Quick Start

### Basic Usage

```ruby
<%= swift_ui do
  vstack(spacing: 16) do
    text("Welcome to SwiftUI Rails!").text_size("3xl").font_weight("bold")
    
    hstack(spacing: 12) do
      button("Get Started").bg("blue-600").text_color("white").rounded("lg")
      button("Learn More").border.text_color("gray-700")
    end
  end
end %>
```

### Creating Components

Generate a new component:

```bash
$ rails generate swift_ui_rails:component Button title:string variant:symbol
```

This creates:

```ruby
# app/components/button_component.rb
class ButtonComponent < ApplicationComponent
  prop :title, type: String, required: true
  prop :variant, type: Symbol, default: :primary
  
  state :loading, false
  
  swift_ui do
    button(title).tap do |btn|
      case variant
      when :primary
        btn.bg("blue-600").text_color("white")
      when :secondary
        btn.border.text_color("gray-700")
      end
      
      btn.rounded("md").px(4).py(2)
      btn.opacity(50) if loading
    end
  end
end
```

Use it in your views:

```erb
<%= render ButtonComponent.new(title: "Save", variant: :primary) %>
```

### State Management

Components can have reactive state:

```ruby
class CounterComponent < ApplicationComponent
  state :count, 0
  
  swift_ui do
    card.p(6) do
      vstack(spacing: 12) do
        text("Count: #{count}").text_size("2xl")
        
        hstack(spacing: 8) do
          button("−").on_tap { self.count -= 1 }
          button("Reset").on_tap { self.count = 0 }
          button("+").on_tap { self.count += 1 }
        end
      end
    end
  end
end
```

### Props with Validation

```ruby
class UserCardComponent < ApplicationComponent
  prop :user, type: User, required: true
  prop :show_actions, type: [TrueClass, FalseClass], default: true
  prop :variant, type: Symbol, default: :default
  
  computed :initials do
    user.name.split.map(&:first).join.upcase
  end
  
  swift_ui do
    card(elevation: 2).p(6) do
      hstack(spacing: 16) do
        # Avatar
        div.w(16).h(16).rounded("full").bg("gray-300").flex.items("center").justify("center") do
          text(initials).font_weight("semibold")
        end
        
        # User info
        vstack(alignment: :leading).flex(1) do
          text(user.name).font_weight("semibold")
          text(user.email).text_size("sm").text_color("gray-600")
        end
        
        # Actions
        if show_actions
          hstack(spacing: 8) do
            button("Edit").text_size("sm")
            button("Delete").text_size("sm").text_color("red-600")
          end
        end
      end
    end
  end
end
```

### Slots for Composition

```ruby
class ModalComponent < ApplicationComponent
  prop :title, type: String
  
  slot :trigger
  slot :content
  slot :footer
  
  state :open, false
  
  swift_ui do
    div do
      # Trigger slot
      div.on_tap { self.open = true } do
        trigger
      end
      
      # Modal
      if open
        div.fixed.inset(0).z(50).flex.items("center").justify("center") do
          # Backdrop
          div.absolute.inset(0).bg("black").opacity(25)
            .on_tap { self.open = false }
          
          # Modal content
          card.relative.max_w("lg").w("full").m(4) do
            # Header
            hstack.p(6).border_b do
              text(title).text_size("xl").font_weight("semibold") if title
              spacer
              button("×").text_size("2xl").on_tap { self.open = false }
            end
            
            # Content slot
            div.p(6) { content }
            
            # Footer slot
            if footer?
              div.p(6).border_t.bg("gray-50") { footer }
            end
          end
        end
      end
    end
  end
end
```

Use with slots:

```erb
<%= render ModalComponent.new(title: "Edit Profile") do |modal| %>
  <% modal.with_trigger do %>
    <%= render ButtonComponent.new(title: "Open Modal") %>
  <% end %>
  
  <% modal.with_content do %>
    <form>
      <!-- Form fields -->
    </form>
  <% end %>
  
  <% modal.with_footer do %>
    <%= render ButtonComponent.new(title: "Cancel", variant: :secondary) %>
    <%= render ButtonComponent.new(title: "Save") %>
  <% end %>
<% end %>
```

### Available Components

#### Layout
- `vstack` - Vertical stack
- `hstack` - Horizontal stack  
- `zstack` - Z-index stack
- `grid` - CSS Grid container
- `spacer` - Flexible space
- `divider` - Horizontal line

#### Text & Input
- `text` - Text content
- `label` - Label with optional icon
- `textfield` - Text input
- `textarea` - Multiline text
- `button` - Button element
- `link` - Anchor link

#### Containers
- `card` - Card container
- `list` - List container
- `scroll_view` - Scrollable area
- `section` - Section with header/footer

#### Form Controls
- `toggle` - Toggle switch
- `slider` - Range slider
- `picker` - Select dropdown
- `checkbox` - Checkbox input
- `radio` - Radio button

#### Feedback
- `progress_view` - Progress bar
- `spinner` - Loading spinner
- `alert` - Alert message
- `sheet` - Bottom sheet
- `toast` - Toast notification

### Tailwind Modifiers

Chain Tailwind utilities for styling:

```ruby
text("Hello World")
  .text_size("2xl")        # text-2xl
  .font_weight("bold")     # font-bold
  .text_color("blue-600")  # text-blue-600
  .p(4)                    # p-4
  .mt(8)                   # mt-8
  .bg("gray-100")         # bg-gray-100
  .rounded("lg")          # rounded-lg
  .shadow("md")           # shadow-md
  .hover("shadow-lg")     # hover:shadow-lg
```

Or use the `tw` method for any Tailwind classes:

```ruby
div.tw("container mx-auto px-4 sm:px-6 lg:px-8")
```

### Responsive Design

```ruby
card
  .p(4)                    # Default padding
  .md("p-6")              # Medium screens and up
  .lg("p-8")              # Large screens and up
  .tw("sm:grid sm:grid-cols-2 sm:gap-6")
```

### Animations

```ruby
# Built-in animations
card.animation(:fade, duration: 0.5)
text("Sliding in").animation(:slide, delay: 0.2)
button("Click me").animation(:scale)

# Spring animations
div.animation(:spring, damping: 0.8, stiffness: 300)

# Custom animations
image("photo.jpg").animation(:custom, name: "bounce", duration: 1)
```

### Data Binding

Bind form inputs to other elements:

```ruby
class PricingComponent < ApplicationComponent
  swift_ui do
    vstack(spacing: 16) do
      slider(value: 50, min: 0, max: 100)
        .bind(target: "#price-display", property: "textContent", format: "currency")
      
      div(id: "price-display").text_size("3xl").font_weight("bold")
    end
  end
end
```

### Turbo Integration

```ruby
# Turbo Frames
button("Load Content").turbo_frame("modal")

# Turbo Streams
form.turbo_stream("append") do
  # Form content
end

# Live updates
div(data: { turbo_permanent: true }) do
  # Content that persists across page changes
end
```

## Advanced Features

### Effects and Computed Properties

```ruby
class SearchComponent < ApplicationComponent
  prop :items, type: Array, required: true
  
  state :query, ""
  state :sort_by, "name"
  
  computed :filtered_items do
    items.select { |item| item.name.include?(query) }
  end
  
  computed :sorted_items do
    filtered_items.sort_by { |item| item.send(sort_by) }
  end
  
  effect :query do |new_query|
    # Triggered when query changes
    track_search_analytics(new_query) if new_query.present?
  end
  
  swift_ui do
    vstack(spacing: 16) do
      textfield(placeholder: "Search...", value: query)
        .bind(target: "@state.query", property: "value")
      
      picker(selection: sort_by, options: [
        ["name", "Name"],
        ["created_at", "Date"],
        ["priority", "Priority"]
      ])
      
      list do
        sorted_items.each do |item|
          list_item { render ItemComponent.new(item: item) }
        end
      end
    end
  end
end
```

### Custom Modifiers

Create your own modifier methods:

```ruby
# config/initializers/swift_ui_rails.rb
module SwiftUIRails
  module CustomModifiers
    def gradient(from:, to:, direction: "r")
      tw("bg-gradient-to-#{direction} from-#{from} to-#{to}")
    end
    
    def glass_morphism
      tw("backdrop-blur-md bg-white/30 border border-white/20")
    end
    
    def neon_glow(color)
      style("box-shadow: 0 0 20px #{color}")
    end
  end
  
  Component::Element.include(CustomModifiers)
end

# Use in components
card.gradient(from: "purple-400", to: "pink-600").p(8)
div.glass_morphism.rounded("xl")
button("Glow").neon_glow("#00ff00")
```

## Component Storybook

SwiftUI Rails includes ViewComponent Storybook integration for visual component development and testing.

### Getting Started with Storybook

After installation, visit `http://localhost:3000/swift_ui/storybook` to see your component stories.

### Creating Stories

Generate stories for your components:

```bash
$ rails generate swift_ui_rails:stories Button default variants sizes states
```

This creates:

```ruby
# test/components/stories/button_component_stories.rb
class ButtonComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Storybook::Layouts
  include SwiftUIRails::Storybook::Previews
  
  story :default do
    component ButtonComponent
    
    controls do
      swift_text :title, default: "Click Me"
      swift_select :variant, 
        options: [:primary, :secondary, :danger],
        default: :primary
      swift_boolean :disabled, default: false
    end
  end
  
  story :variants do
    component ButtonComponent
    
    controls do
      swift_text :title, default: "Button"
    end
    
    layout :variants_grid
  end
end
```

### Story Layouts

SwiftUI Rails provides helpful layouts for showcasing components:

```erb
<!-- test/components/stories/button_component_preview.html.erb -->
<% if layout == :variants_grid %>
  <%= swift_story_layout(title: "Button Variants") do %>
    <%= swift_story_grid(columns: 4) do %>
      <% [:primary, :secondary, :danger, :ghost].each do |variant| %>
        <div>
          <%= render component, **args.merge(variant: variant) %>
          <p class="text-xs text-gray-600 mt-2"><%= variant %></p>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

### Storybook Helpers

SwiftUI Rails provides specialized helpers for stories:

```ruby
# Documentation helpers
swift_props_table(ComponentClass)  # Auto-generate props documentation
swift_code_example { ... }          # Formatted code examples

# Preview helpers
swift_preview_container { ... }     # Standard preview wrapper
swift_device_preview(:iphone) { ... }  # Device frame previews
swift_theme_preview([:light, :dark]) { ... }  # Theme variations

# Layout helpers
swift_story_layout(title: "...", description: "...") { ... }
swift_story_grid(columns: 3) { ... }
swift_story_section(title: "...") { ... }
```

### Interactive Stories

Create interactive demos showing different component states:

```ruby
story :interactive do
  component MyComponent
  
  controls do
    swift_text :title, default: "Interactive Demo"
    swift_boolean :show_details, default: false
  end
  
  layout :interactive_demo
end
```

## Testing

### Unit Testing

Test your components with RSpec:

```ruby
# spec/components/button_component_spec.rb
require "rails_helper"

RSpec.describe ButtonComponent, type: :component do
  it "renders with required props" do
    component = described_class.new(title: "Click me")
    
    render_inline(component)
    
    expect(page).to have_button("Click me")
  end
  
  it "applies variant styling" do
    component = described_class.new(title: "Save", variant: :primary)
    
    render_inline(component)
    
    expect(page).to have_css(".bg-blue-600")
  end
  
  it "validates prop types" do
    expect {
      described_class.new(title: 123) # Should be String
    }.to raise_error(TypeError)
  end
end
```

### Visual Testing

Use Storybook for visual regression testing and component documentation. Stories serve as both documentation and test cases.

## Configuration

Configure SwiftUI Rails in an initializer:

```ruby
# config/initializers/swift_ui_rails.rb
SwiftUIRails.configure do |config|
  # Animation defaults
  config.default_transition_duration = 300
  config.default_animation_easing = "ease-out"
  
  # Component settings
  config.component_prefix = "Swift" # SwiftButtonComponent
  
  # Feature flags
  config.tailwind_enabled = true
  
  # Stimulus settings
  config.stimulus_controller_suffix = "component"
end
```

## Best Practices

1. **Keep Components Small**: Each component should have a single responsibility
2. **Use Props for Data**: Pass data down through props, not instance variables
3. **Leverage Slots**: Use slots for maximum flexibility and reusability
4. **Type Your Props**: Always specify types for better error messages
5. **Extract Shared Styles**: Create modifier methods for common patterns
6. **Test Components**: Write tests for props, slots, and interactions

## Examples

Check out the `examples/` directory for complete sample applications:

- **Blog**: A full-featured blog with SwiftUI Rails components
- **Dashboard**: An admin dashboard showcasing data tables and charts
- **E-commerce**: Product listings and shopping cart components

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/swift_ui_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).