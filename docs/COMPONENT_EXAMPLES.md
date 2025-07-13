# SwiftUI Rails Component Examples

This document contains practical examples of building components using the SwiftUI Rails DSL-first approach.

## Table of Contents
1. [DSL-First Component Architecture Guide](#dsl-first-component-architecture-guide)
2. [Real-World Stateless Component Examples](#real-world-stateless-component-examples)
3. [Simple Counter Example](#simple-counter-example---rails-first-architecture)

## DSL-First Component Architecture Guide

### Core Principles for Building DSL Components

1. **Component Structure**
   ```ruby
   class ComponentName < SwiftUIRails::Component::Base
     # Props are immutable - components are stateless view builders
     prop :text, type: String, required: true
     prop :size, type: Symbol, default: :md
     prop :color, type: String, default: "blue-500"
     
     swift_ui do
       # Pure DSL composition - no HTML strings
       vstack do
         text(text)
           .font_size(size_class)
           .text_color(color)
           .modifier_chain
       end
     end
   end
   ```

2. **Composition Over Configuration**
   - Build complex UIs by composing primitive DSL elements
   - Each DSL element is a building block: `text`, `button`, `vstack`, `hstack`, `card`
   - Chain modifiers for styling: `.bg()`, `.text_color()`, `.padding()`, `.rounded()`
   - State management via Stimulus: `.data(controller: "name", action: "click->name#method")`

3. **Maximum Reusability Patterns**
   
   **Base DSL Elements (Primitives):**
   - `text(content)` - Text display
   - `button(label)` - Interactive button
   - `div(&block)` - Container element
   - `span(content)` - Inline container
   - `image(src:, alt:)` - Image display
   
   **Layout Containers:**
   - `vstack(spacing: n, &block)` - Vertical stack
   - `hstack(spacing: n, &block)` - Horizontal stack
   - `zstack(&block)` - Layered stack
   - `grid(cols: n, gap: n, &block)` - Grid layout
   
   **Modifier Chains (All Reusable):**
   ```ruby
   element
     # Spacing
     .p(4)                    # padding
     .m(2)                    # margin
     .px(4).py(2)            # padding x/y
     .mx("auto")             # margin x auto
     
     # Colors
     .bg("blue-500")         # background
     .text_color("white")    # text color
     .border_color("gray-200")
     
     # Typography
     .font_size("xl")        # text size
     .font_weight("bold")    # font weight
     .text_align("center")   # alignment
     
     # Layout
     .w("full")              # width
     .h(64)                  # height
     .flex                   # display flex
     .items_center           # align items
     .justify_between        # justify content
     
     # Effects
     .rounded("lg")          # border radius
     .shadow("md")           # box shadow
     .opacity(90)            # opacity
     .transition             # transitions
     
     # State & Interaction
     .hover("bg-blue-600")   # hover state
     .focus("ring-2")        # focus state
     .data(controller: "x")  # Stimulus binding
   ```

4. **Component Examples**

   **Counter Component (Stateless with Stimulus):**
   ```ruby
   class CounterComponent < SwiftUIRails::Component::Base
     prop :initial_count, type: Integer, default: 0
     prop :step, type: Integer, default: 1
     
     swift_ui do
       vstack(spacing: 4) do
         text("")
           .font_size("6xl")
           .font_weight("black")
           .data("counter-target": "count")
         
         hstack(spacing: 2) do
           button("-")
             .bg("red-500")
             .text_color("white")
             .px(4).py(2)
             .rounded("lg")
             .data(action: "click->counter#decrement")
           
           button("+")
             .bg("green-500")
             .text_color("white")
             .px(4).py(2)
             .rounded("lg")
             .data(action: "click->counter#increment")
         end
       end
       .data(controller: "counter",
             "counter-count-value": initial_count,
             "counter-step-value": step)
     end
   end
   ```

   **Card Component (Composition with Slots):**
   ```ruby
   class CardComponent < SwiftUIRails::Component::Base
     prop :title, type: String, required: true
     prop :elevation, type: Integer, default: 1
     
     renders_one :header
     renders_one :footer
     renders_many :actions
     
     swift_ui do
       div do
         # Header slot or default
         if header?
           header
         else
           text(title).font_size("xl").font_weight("bold")
         end
         
         # Content (yielded)
         div { content }.py(4)
         
         # Actions
         if actions.any?
           hstack(spacing: 2) do
             actions.each { |action| action }
           end
         end
       end
       .bg("white")
       .rounded("lg")
       .shadow(shadow_class)
       .p(6)
     end
   end
   ```

5. **Reusability Best Practices**

   **Extract Common Patterns:**
   ```ruby
   # In a helper or concern
   def primary_button(text, action: nil)
     button(text)
       .bg("blue-600")
       .text_color("white")
       .px(6).py(3)
       .rounded("lg")
       .hover("bg-blue-700")
       .transition
       .tap { |b| b.data(action: action) if action }
   end
   
   def error_text(message)
     text(message)
       .text_color("red-600")
       .font_size("sm")
       .mt(1)
   end
   ```

   **Use Composition for Complex UIs:**
   ```ruby
   swift_ui do
     card(elevation: 2) do
       vstack(spacing: 4) do
         hstack do
           avatar(user.image_url)
           vstack(align: :start) do
             text(user.name).font_weight("semibold")
             text(user.email).text_color("gray-600").font_size("sm")
           end
         end
         
         divider
         
         text(post.content).line_clamp(3)
         
         hstack(justify: :between) do
           button("Like").variant(:ghost)
           button("Share").variant(:ghost)
         end
       end
     end
   end
   ```

6. **Testing DSL Components**
   ```ruby
   # Test the DSL directly
   test "renders with correct structure" do
     component = CounterComponent.new(initial_count: 5)
     
     # Test DSL output
     assert_selector "[data-controller='counter']"
     assert_selector "[data-counter-count-value='5']"
     assert_selector "button", count: 2
   end
   ```

### Remember: Every modifier returns self for chaining. Every element is composable. State lives in Stimulus, not components.

## Real-World Stateless Component Examples

### 1. Toggle Switch Component - Pure Stimulus
```ruby
class ToggleSwitchComponent < SwiftUIRails::Component::Base
  prop :name, type: String, required: true
  prop :checked, type: [TrueClass, FalseClass], default: false
  prop :label, type: String, required: true
  
  swift_ui do
    div(data: { controller: "toggle" }) do
      label(class: "flex items-center cursor-pointer") do
        # Hidden checkbox for form submission
        input(
          type: "checkbox",
          name: name,
          checked: checked,
          class: "sr-only",
          data: { "toggle-target": "input" }
        )
        
        # Visual toggle switch
        div(data: { action: "click->toggle#switch" }) do
          div(data: { "toggle-target": "track" })
            .relative
            .inline_block
            .w(10)
            .h(6)
            .bg(checked ? "blue-600" : "gray-200")
            .rounded_full
            .transition
          
          div(data: { "toggle-target": "thumb" })
            .absolute
            .left(checked ? 4 : 0)
            .top(0)
            .w(6)
            .h(6)
            .bg("white")
            .border_2
            .border(checked ? "blue-600" : "gray-200")
            .rounded_full
            .transition
            .transform
        end
        
        span(label).ml(3)
      end
    end
  end
end
```

### 2. Typeahead Search - URL + Stimulus Hybrid
```ruby
class TypeaheadSearchComponent < SwiftUIRails::Component::Base
  prop :search_path, type: String, required: true
  prop :placeholder, type: String, default: "Search..."
  prop :min_chars, type: Integer, default: 2
  
  swift_ui do
    div(data: { 
      controller: "typeahead",
      "typeahead-url-value": search_path,
      "typeahead-min-chars-value": min_chars
    }) do
      # Search input
      textfield(
        placeholder: placeholder,
        data: {
          "typeahead-target": "input",
          action: "input->typeahead#search"
        }
      ).w("full")
      
      # Results dropdown (hidden by default)
      div(data: { "typeahead-target": "results" })
        .absolute
        .top("full")
        .left(0)
        .right(0)
        .bg("white")
        .border
        .rounded_b("lg")
        .shadow("lg")
        .max_h(96)
        .overflow_y("auto")
        .hidden
        .z(50)
    end.relative
  end
end

# Stimulus controller
class TypeaheadController < ApplicationController
  def search
    @results = Product.search(params[:q])
    render turbo_stream: turbo_stream.update(
      "typeahead-results",
      partial: "shared/typeahead_results",
      locals: { results: @results }
    )
  end
end
```

### 3. Toast Notification - Ephemeral UI State
```ruby
class ToastComponent < SwiftUIRails::Component::Base
  prop :message, type: String, required: true
  prop :type, type: Symbol, default: :info # :success, :error, :warning, :info
  prop :duration, type: Integer, default: 5000
  
  swift_ui do
    div(
      data: { 
        controller: "toast",
        "toast-duration-value": duration
      }
    ) do
      hstack(spacing: 3) do
        # Icon based on type
        icon(icon_name).text_color(icon_color)
        
        # Message
        text(message).flex_1
        
        # Close button
        button("×")
          .text_2xl
          .text_color("gray-500")
          .hover_text_color("gray-700")
          .data(action: "click->toast#close")
      end
    end
    .fixed
    .bottom(4)
    .right(4)
    .bg(background_color)
    .text_color(text_color)
    .px(4).py(3)
    .rounded("lg")
    .shadow("lg")
    .transform
    .transition
    .data("toast-target": "container")
  end
  
  private
  
  def icon_name
    case type
    when :success then "check-circle"
    when :error then "x-circle"
    when :warning then "exclamation-triangle"
    else "info-circle"
    end
  end
  
  def background_color
    case type
    when :success then "green-50"
    when :error then "red-50"
    when :warning then "yellow-50"
    else "blue-50"
    end
  end
end
```

### 4. Infinite Carousel - Client-Side Only
```ruby
class CarouselComponent < SwiftUIRails::Component::Base
  prop :images, type: Array, required: true # [{url:, alt:}, ...]
  prop :auto_play, type: [TrueClass, FalseClass], default: false
  prop :interval, type: Integer, default: 3000
  
  swift_ui do
    div(data: { 
      controller: "carousel",
      "carousel-auto-play-value": auto_play,
      "carousel-interval-value": interval,
      "carousel-total-value": images.count
    }) do
      # Main carousel container
      div.relative.overflow_hidden do
        # Images container
        div(data: { "carousel-target": "container" })
          .flex
          .transition_transform
          .duration_300 do
          
          images.each_with_index do |image, index|
            image(
              src: image[:url],
              alt: image[:alt],
              data: { "carousel-index": index }
            )
            .w("full")
            .h("full")
            .object_cover
            .flex_shrink(0)
          end
        end
        
        # Navigation buttons
        button("<")
          .absolute
          .left(2)
          .top("1/2")
          .transform("-translate-y-1/2")
          .bg("black")
          .bg_opacity(50)
          .text_color("white")
          .p(2)
          .rounded("full")
          .data(action: "click->carousel#previous")
        
        button(">")
          .absolute
          .right(2)
          .top("1/2")
          .transform("-translate-y-1/2")
          .bg("black")
          .bg_opacity(50)
          .text_color("white")
          .p(2)
          .rounded("full")
          .data(action: "click->carousel#next")
      end
      
      # Dots indicator
      hstack(justify: :center, spacing: 2).mt(4) do
        images.count.times do |index|
          div
            .w(2)
            .h(2)
            .rounded("full")
            .bg("gray-400")
            .data("carousel-target": "dot", "carousel-dot-index": index)
            .cursor("pointer")
            .data(action: "click->carousel#goTo")
        end
      end
    end
  end
end
```

### 5. Keyboard Shortcuts - Pure Stimulus Enhancement
```ruby
class CommandPaletteComponent < SwiftUIRails::Component::Base
  prop :commands, type: Array, required: true # [{name:, description:, action:}, ...]
  
  swift_ui do
    div(data: { 
      controller: "command-palette",
      "command-palette-open-class": "block",
      "command-palette-closed-class": "hidden"
    }) do
      # Backdrop
      div(data: { 
        "command-palette-target": "backdrop",
        action: "click->command-palette#close" 
      })
      .fixed
      .inset_0
      .bg("black")
      .bg_opacity(25)
      .hidden
      
      # Command palette
      div(data: { "command-palette-target": "panel" })
        .fixed
        .top(20)
        .left("1/2")
        .transform("-translate-x-1/2")
        .w("full")
        .max_w("2xl")
        .bg("white")
        .rounded("lg")
        .shadow("2xl")
        .hidden do
        
        # Search input
        textfield(
          placeholder: "Type a command or search...",
          data: {
            "command-palette-target": "search",
            action: "input->command-palette#filter"
          }
        )
        .w("full")
        .border_b
        .px(4).py(3)
        .text_lg
        
        # Commands list
        div(data: { "command-palette-target": "results" })
          .max_h(96)
          .overflow_y("auto") do
          
          commands.each do |command|
            div(data: { 
              "command-palette-target": "command",
              "command-action": command[:action],
              action: "click->command-palette#execute"
            }) do
              vstack(align: :start, spacing: 1) do
                text(command[:name]).font_weight("medium")
                text(command[:description]).text_sm.text_color("gray-600")
              end
            end
            .px(4).py(3)
            .hover_bg("gray-50")
            .cursor("pointer")
          end
        end
      end
    end
  end
end

# Usage: Add keyboard shortcut to open
# document.addEventListener('keydown', (e) => {
#   if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
#     e.preventDefault()
#     document.querySelector('[data-controller="command-palette"]')
#       ?.dispatchEvent(new CustomEvent('command-palette:open'))
#   }
# })
```

## Simple Counter Example - Rails-First Architecture

The home page (`/`) demonstrates a clean implementation of our Rails-first architecture with a simple counter component:

### Implementation Details

1. **Stateless Component** (`app/components/counter_component.rb`):
   - Pure view builder with no state
   - Renders HTML structure with Stimulus data attributes
   - Props initialize Stimulus values

2. **Stimulus Controller** (`app/javascript/controllers/counter_controller.js`):
   - Manages all client-side state (count, step, label)
   - Handles user interactions (increment/decrement/reset)
   - Updates DOM reactively
   - Tracks history of changes

3. **Clean Home Page** (`app/views/home/index.html.erb`):
   - Simple centered layout
   - Just renders the CounterComponent
   - No distractions or complex layouts

### Key Architecture Patterns

- **No Component State**: Components are stateless view builders
- **Client-Side State**: Managed entirely by Stimulus
- **Progressive Enhancement**: Works without JavaScript (shows initial values)
- **Reactive Updates**: Stimulus handles all DOM updates
- **No Serialization**: No complex state management or action registration

### Usage

```erb
<%= render CounterComponent.new(
  initial_count: 0,
  step: 1,
  label: "Counter"
) %>
```

### Counter Component Implementation

```ruby
class CounterComponent < SwiftUIRails::Component::Base
  prop :initial_count, type: Integer, default: 0
  prop :step, type: Integer, default: 1
  prop :label, type: String, default: "Counter"
  
  swift_ui do
    vstack(spacing: 4) do
      # Display the current count
      text("")
        .font_size("6xl")
        .font_weight("black")
        .data("counter-target": "count")
      
      # Control buttons
      hstack(spacing: 2) do
        button("-")
          .bg("red-500")
          .text_color("white")
          .px(4).py(2)
          .rounded("lg")
          .data(action: "click->counter#decrement")
        
        button("Reset")
          .bg("gray-500")
          .text_color("white")
          .px(4).py(2)
          .rounded("lg")
          .data(action: "click->counter#reset")
        
        button("+")
          .bg("green-500")
          .text_color("white")
          .px(4).py(2)
          .rounded("lg")
          .data(action: "click->counter#increment")
      end
      
      # History display
      div(data: { "counter-target": "history" })
        .text_sm
        .text_color("gray-600")
        .mt(4)
    end
    .data(controller: "counter",
          "counter-count-value": initial_count,
          "counter-step-value": step,
          "counter-label-value": label)
  end
end
```

### Stimulus Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "history"]
  static values = { 
    count: Number, 
    step: Number,
    label: String
  }
  
  connect() {
    this.updateDisplay()
    this.history = []
  }
  
  increment() {
    this.countValue += this.stepValue
    this.addToHistory("increment")
  }
  
  decrement() {
    this.countValue -= this.stepValue
    this.addToHistory("decrement")
  }
  
  reset() {
    this.countValue = 0
    this.addToHistory("reset")
  }
  
  countValueChanged() {
    this.updateDisplay()
  }
  
  updateDisplay() {
    this.countTarget.textContent = this.countValue
  }
  
  addToHistory(action) {
    this.history.push({
      action: action,
      value: this.countValue,
      time: new Date().toLocaleTimeString()
    })
    
    // Keep only last 5 actions
    if (this.history.length > 5) {
      this.history.shift()
    }
    
    // Update history display
    this.historyTarget.innerHTML = this.history
      .map(h => `${h.time}: ${h.action} → ${h.value}`)
      .join("<br>")
  }
}
```

This example perfectly demonstrates the SwiftUI Rails philosophy:
- Components are pure view builders with no state
- All interactivity is handled by Stimulus controllers
- The DSL provides a clean, SwiftUI-like syntax
- Progressive enhancement ensures it works without JavaScript
- No complex state management or serialization needed