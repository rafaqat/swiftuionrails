# SwiftUI Rails

A declarative, component-based view system for Rails that brings SwiftUI's intuitive API to web development with Tailwind CSS and ViewComponent.

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-red)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-%3E%3D%206.1.0-red)](https://rubyonrails.org)
[![ViewComponent](https://img.shields.io/badge/view__component-~%3E%203.0-blue)](https://viewcomponent.org)

## Features

- 🎨 **SwiftUI-inspired DSL** - Write views with familiar patterns like `vstack`, `hstack`, `text`, and `button`
- 🧩 **Component-based architecture** - Built on ViewComponent for performance and testability
- 💨 **Tailwind CSS integration** - Chainable utility methods for styling
- ⚡ **Stimulus.js interactivity** - Add behavior without complex state management
- 🔄 **Turbo integration** - Smooth updates with morphing, no full page reloads
- 🛡️ **Security-first design** - Built-in protections against XSS, CSRF, and injection attacks
- 📱 **Progressive enhancement** - Works without JavaScript, enhanced with it
- 🧪 **Interactive Storybook** - Visual component development and testing

## Installation

Add to your Gemfile:

```ruby
gem 'swift_ui_rails'
```

Then run:

```bash
bundle install
rails generate swift_ui_rails:install
```

## Quick Start

### 1. Create a Component

```ruby
# app/components/card_component.rb
class CardComponent < ApplicationComponent
  prop :title, type: String, required: true
  prop :description, type: String, default: ""
  
  swift_ui do
    div do
      text(title)
        .font_size("xl")
        .font_weight("bold")
        .mb(2)
      
      text(description)
        .text_color("gray-600")
    end
    .p(6)
    .bg("white")
    .rounded("lg")
    .shadow("md")
  end
end
```

### 2. Use in Views

```erb
<%= render CardComponent.new(
  title: "Welcome", 
  description: "Build beautiful UIs with SwiftUI syntax"
) %>
```

### 3. Interactive Components with Stimulus

```ruby
class CounterComponent < ApplicationComponent
  prop :initial_count, type: Integer, default: 0
  
  swift_ui do
    vstack(spacing: 4) do
      text("")
        .font_size("4xl")
        .font_weight("bold")
        .data("counter-target": "display")
      
      hstack(spacing: 2) do
        button("-")
          .bg("red-500")
          .text_color("white")
          .px(4).py(2)
          .rounded
          .data(action: "click->counter#decrement")
        
        button("+")
          .bg("green-500")
          .text_color("white")
          .px(4).py(2)
          .rounded
          .data(action: "click->counter#increment")
      end
    end
    .data(
      controller: "counter",
      "counter-count-value": initial_count
    )
  end
end
```

## DSL Reference

### Layout Components

```ruby
# Vertical stack
vstack(spacing: 4) { ... }

# Horizontal stack  
hstack(spacing: 2, align: :center) { ... }

# Grid layout
grid(cols: 3, gap: 4) { ... }

# Layered stack
zstack { ... }
```

### UI Elements

```ruby
# Text
text("Hello").font_size("xl").font_weight("bold")

# Buttons
button("Click me")
  .button_style(:primary)
  .button_size(:lg)

# Links
link("Learn more", destination: "/docs")
  .text_color("blue-600")
  .hover_underline

# Images
image(src: "/logo.png", alt: "Logo")
  .w(32).h(32)
  .rounded("full")

# Forms
form(action: "/submit", method: :post) do
  textfield(name: "email", placeholder: "Email")
  button("Submit", type: "submit")
end
```

### Styling with Tailwind

All Tailwind utilities are available as chainable methods:

```ruby
element
  # Spacing
  .p(4)           # padding
  .m(2)           # margin  
  .px(4).py(2)    # padding x/y
  
  # Colors
  .bg("blue-500")      # background
  .text_color("white") # text color
  
  # Typography
  .font_size("xl")     # text size
  .font_weight("bold") # font weight
  
  # Layout
  .w("full")      # width
  .h(64)          # height
  .flex           # display flex
  
  # Effects
  .rounded("lg")  # border radius
  .shadow("md")   # box shadow
  .transition     # transitions
```

## Component Architecture

### Props with Type Validation

```ruby
class UserCardComponent < ApplicationComponent
  # Type alias for boolean props
  Boolean = [TrueClass, FalseClass].freeze
  
  prop :name, type: String, required: true
  prop :age, type: Integer, default: 0
  prop :verified, type: Boolean, default: false
  prop :tags, type: Array, default: []
  
  # Custom validations
  validates_inclusion :status, in: %w[active inactive pending]
  validates_number :age, min: 0, max: 150
end
```

### Slots for Composition

```ruby
class CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer
  renders_many :actions
  
  swift_ui do
    div do
      header if header?
      
      div { content }.p(4)
      
      if actions.any?
        hstack do
          actions.each { |action| action }
        end
      end
      
      footer if footer?
    end
  end
end
```

Usage:

```erb
<%= render CardComponent.new do |card| %>
  <% card.with_header do %>
    <h2>Card Title</h2>
  <% end %>
  
  Main content here
  
  <% card.with_action do %>
    <%= button_to "Save", save_path %>
  <% end %>
<% end %>
```

## State Management Patterns

SwiftUI Rails follows Rails conventions for state management:

### Client-Side State (Stimulus)

For UI interactions and ephemeral state:

```javascript
// app/javascript/controllers/counter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { count: Number }
  static targets = [ "display" ]
  
  connect() {
    this.updateDisplay()
  }
  
  increment() {
    this.countValue++
    this.updateDisplay()
  }
  
  decrement() {
    this.countValue--
    this.updateDisplay()
  }
  
  updateDisplay() {
    this.displayTarget.textContent = this.countValue
  }
}
```

### Server-Side State (Turbo)

For persistent state and business logic:

```ruby
# Using Turbo Frames for partial updates
swift_ui do
  turbo_frame_tag "search_results" do
    form(action: search_path, method: :get) do
      textfield(name: "q", value: params[:q])
      button("Search", type: "submit")
    end
    
    div do
      @results.each do |result|
        search_result_card(result)
      end
    end
  end
end
```

## Interactive Storybook

### Creating Stories

```ruby
# test/components/stories/button_component_stories.rb
class ButtonComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  
  # Define interactive controls
  control :text, as: :text, default: "Click me"
  control :style, as: :select, 
    options: [:primary, :secondary, :danger], 
    default: :primary
  control :size, as: :select,
    options: [:sm, :md, :lg],
    default: :md
  control :disabled, as: :boolean, default: false
  
  def default(text:, style:, size:, disabled:)
    swift_ui do
      button(text)
        .button_style(style)
        .button_size(size)
        .disabled(disabled)
    end
  end
end
```

Access the storybook at `http://localhost:3000/rails/stories`

## Security Features

### Built-in Protections

- **CSS Injection Prevention**: Whitelisted color and size values
- **XSS Protection**: Automatic HTML escaping and data attribute sanitization
- **CSRF Protection**: Automatic token inclusion in forms
- **URL Validation**: Domain whitelisting for external resources
- **Component Validation**: Type-safe props with sanitization

### Example: Secure Form Component

```ruby
class LoginFormComponent < ApplicationComponent
  include SwiftUIRails::Security::FormHelpers
  
  swift_ui do
    # Automatically includes CSRF token
    secure_form(action: "/login", method: :post) do
      vstack(spacing: 4) do
        textfield(
          name: "email",
          type: "email",
          required: true,
          placeholder: "Email"
        )
        
        textfield(
          name: "password",
          type: "password",
          required: true,
          placeholder: "Password"
        )
        
        button("Sign In", type: "submit")
          .button_style(:primary)
          .w("full")
      end
    end
  end
end
```

## Testing

### Component Tests

```ruby
require "test_helper"

class CardComponentTest < ViewComponent::TestCase
  def test_renders_with_required_props
    component = CardComponent.new(title: "Test")
    render_inline(component)
    
    assert_selector "div", text: "Test"
  end
  
  def test_applies_tailwind_classes
    component = CardComponent.new(title: "Test")
    render_inline(component)
    
    assert_selector ".bg-white.rounded-lg.shadow-md"
  end
end
```

### System Tests

```ruby
class InteractiveComponentsTest < ApplicationSystemTestCase
  test "counter increments and decrements" do
    visit root_path
    
    assert_selector "[data-counter-target='display']", text: "0"
    
    click_button "+"
    assert_selector "[data-counter-target='display']", text: "1"
    
    click_button "-"
    assert_selector "[data-counter-target='display']", text: "0"
  end
end
```

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/swift_ui_rails.git
cd swift_ui_rails

# Install dependencies
bundle install

# Run tests
bundle exec rake

# Start the test app
cd test_app
bin/dev
```

### Running Tests

```bash
# Gem tests
bundle exec rspec

# Test app tests
cd test_app
bin/rails test
bin/rails test:system
```

### Code Quality

```bash
# Run all checks
bundle exec rake

# Individual checks
bundle exec rubocop         # Linting
bundle exec rspec           # Unit tests
bundle exec standardrb      # Style guide
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Tests pass (`bundle exec rake`)
- Code follows the style guide
- Security implications are considered
- Documentation is updated

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

- Built on [ViewComponent](https://viewcomponent.org) for component architecture
- Inspired by [SwiftUI](https://developer.apple.com/xcode/swiftui/) declarative syntax
- Powered by [Tailwind CSS](https://tailwindcss.com) for styling
- Enhanced with [Stimulus](https://stimulus.hotwired.dev) and [Turbo](https://turbo.hotwired.dev)