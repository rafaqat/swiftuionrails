# SwiftUI Rails Playground Showcase

## Overview

The SwiftUI Rails Playground demonstrates how we've brought SwiftUI-like declarative syntax to Rails, enabling developers to build interactive UIs with a familiar, composable DSL while maintaining Rails' server-first architecture.

## 1. DSL Natural Composition in PlaygroundV2Component

The playground leverages our SwiftUI-inspired DSL to create complex layouts with natural, readable composition:

```ruby
class PlaygroundV2Component < ApplicationComponent
  include SwiftUIRails::ComponentHelper
  
  swift_ui do
    vstack(spacing: 0, data: { controller: "playground" }) do
      # Header with gradient background
      header_section
      
      # Main content area with responsive layout
      div(class: "flex-1 overflow-hidden") do
        hstack(spacing: 0, class: "h-full") do
          # Editor panel
          editor_panel
          
          # Preview panel  
          preview_panel
        end
      end
    end
  end
end
```

### Key DSL Patterns Demonstrated

#### 1. **Nested Layout Composition**
```ruby
vstack(spacing: 4) do
  # Typography with chainable modifiers
  text("SwiftUI Rails Playground")
    .font_size("2xl")
    .font_weight("bold")
    .text_color("white")
  
  text("Build beautiful UIs with Rails")
    .font_size("sm")
    .text_color("gray-200")
    .opacity(80)
end
```

#### 2. **Interactive Elements with Stimulus Integration**
```ruby
button("Run Code")
  .bg("green-600")
  .text_color("white")
  .px(6).py(2)
  .rounded("lg")
  .hover("bg-green-700")
  .transition
  .data(action: "click->playground#runCode")
```

#### 3. **Component Templates as Building Blocks**
```ruby
def template_button(name, code)
  button(name)
    .bg("gray-700")
    .text_color("gray-300")
    .px(3).py(1)
    .rounded("md")
    .text_size("xs")
    .hover("bg-gray-600")
    .transition
    .data(
      action: "click->playground#loadTemplate",
      playground_template_value: code
    )
end
```

## 2. Componentized Architecture

The playground showcases proper ViewComponent composition patterns:

### Component Hierarchy
```
PlaygroundV2Component (Main Container)
├── HeaderSection (Branding & Actions)
├── EditorPanel
│   ├── TemplateButtons
│   ├── CodeMirror Editor
│   └── ActionButtons
└── PreviewPanel
    ├── PreviewHeader
    ├── PreviewFrame (Turbo Frame)
    └── ErrorDisplay
```

### Slot-Based Composition Example
```ruby
class CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer
  renders_many :actions
  
  swift_ui do
    div do
      # Conditional slot rendering
      if header?
        div.border_b { header }
      end
      
      # Main content
      div.p(4) { content }
      
      # Actions bar
      if actions.any?
        hstack(justify: :end, spacing: 2) do
          actions.each { |action| action }
        end
      end
    end
    .bg("white")
    .rounded("lg")
    .shadow("md")
  end
end
```

## 3. JavaScript Integration Points

The playground seamlessly integrates with Stimulus for rich interactivity:

### Stimulus Controller Integration
```javascript
// playground_controller.js
export default class extends Controller {
  static targets = ["editor", "preview", "error"]
  static values = { template: String }
  
  connect() {
    this.initializeEditor()
    this.loadInitialCode()
  }
  
  runCode() {
    const code = this.editor.getValue()
    this.updatePreview(code)
  }
  
  loadTemplate(event) {
    const template = event.params.template
    this.editor.setValue(template)
    this.runCode()
  }
}
```

### DSL-Stimulus Bridge
```ruby
# DSL methods automatically generate proper Stimulus attributes
textarea
  .data(
    playground_target: "editor",
    controller: "code-editor",
    action: "keydown.cmd+enter->playground#runCode"
  )
```

## 4. Sample Playground Creations

### Example 1: Interactive Product Card
```ruby
swift_ui do
  card(elevation: 2) do
    vstack(spacing: 4) do
      # Product image with overlay
      div.relative do
        image("/products/laptop.jpg", alt: "MacBook Pro")
          .w("full").h(48).object_cover
        
        # Sale badge overlay
        div.absolute.top(2).right(2) do
          span("SALE")
            .bg("red-500")
            .text_color("white")
            .px(2).py(1)
            .rounded("md")
            .text_size("xs")
            .font_weight("bold")
        end
      end
      
      # Product details
      vstack(spacing: 2, class: "p-4") do
        text("MacBook Pro 14\"")
          .font_size("lg")
          .font_weight("semibold")
        
        text("M3 Pro chip, 18GB RAM")
          .text_color("gray-600")
          .text_size("sm")
        
        hstack(justify: :between, align: :center) do
          text("$1,999")
            .font_size("xl")
            .font_weight("bold")
            .text_color("green-600")
          
          button("Add to Cart")
            .bg("blue-600")
            .text_color("white")
            .px(4).py(2)
            .rounded("lg")
            .hover("bg-blue-700")
            .data(action: "click->cart#add")
        end
      end
    end
  end
end
```

### Example 2: Dynamic Form with Validation
```ruby
swift_ui do
  form(data: { controller: "form-validation" }) do
    vstack(spacing: 4) do
      # Email field with live validation
      vstack(spacing: 1, align: :start) do
        label("Email", for: "email")
          .font_weight("medium")
        
        textfield(
          name: "email",
          type: "email",
          placeholder: "you@example.com"
        )
        .w("full")
        .data(
          action: "blur->form-validation#validateEmail",
          form_validation_target: "email"
        )
        
        text("")
          .text_size("sm")
          .text_color("red-600")
          .data(form_validation_target: "emailError")
          .hidden
      end
      
      # Password with strength indicator
      vstack(spacing: 1, align: :start) do
        label("Password", for: "password")
          .font_weight("medium")
        
        textfield(
          name: "password",
          type: "password",
          placeholder: "••••••••"
        )
        .w("full")
        .data(
          action: "input->form-validation#checkStrength",
          form_validation_target: "password"
        )
        
        # Strength meter
        div.h(2).bg("gray-200").rounded("full").w("full") do
          div
            .h("full")
            .rounded("full")
            .transition_all
            .data(form_validation_target: "strengthBar")
        end
      end
      
      button("Create Account", type: "submit")
        .bg("blue-600")
        .text_color("white")
        .w("full")
        .py(3)
        .rounded("lg")
        .hover("bg-blue-700")
        .disabled_opacity(50)
    end
  end
end
```

### Example 3: Real-time Dashboard Widget
```ruby
swift_ui do
  turbo_frame_tag "metrics_dashboard" do
    grid(cols: 3, gap: 4) do
      # Revenue card
      metric_card(
        title: "Revenue",
        value: "$12,345",
        change: "+12%",
        trend: :up
      )
      
      # Users card
      metric_card(
        title: "Active Users",
        value: "1,234",
        change: "+5%",
        trend: :up
      )
      
      # Conversion card
      metric_card(
        title: "Conversion",
        value: "3.4%",
        change: "-0.2%",
        trend: :down
      )
    end
  end
end

def metric_card(title:, value:, change:, trend:)
  card do
    vstack(spacing: 2) do
      text(title)
        .text_color("gray-600")
        .text_size("sm")
      
      text(value)
        .font_size("2xl")
        .font_weight("bold")
      
      hstack(spacing: 1, align: :center) do
        icon(trend == :up ? "trending-up" : "trending-down")
          .text_color(trend == :up ? "green-600" : "red-600")
          .size(4)
        
        text(change)
          .text_size("sm")
          .text_color(trend == :up ? "green-600" : "red-600")
          .font_weight("medium")
      end
    end
  end
end
```

## 5. Key Features Demonstrated

### 1. **Composable DSL Elements**
- Natural nesting: `vstack > hstack > text`
- Chainable modifiers: `.bg().text_color().padding()`
- Conditional rendering with Ruby logic

### 2. **State Management Patterns**
- Client-side: Stimulus values and targets
- Server-side: Turbo Frames for partial updates
- Form state: Native HTML form handling

### 3. **Responsive Design**
- Flexbox utilities: `.flex`, `.flex_1`, `.items_center`
- Grid layouts: `grid(cols: 3, gap: 4)`
- Responsive modifiers: `.sm_hidden`, `.lg_grid_cols(4)`

### 4. **Interactive Features**
- Live code execution
- Template loading
- Error handling with visual feedback
- Keyboard shortcuts (Cmd+Enter to run)

### 5. **Performance Optimizations**
- Turbo Frame updates for preview
- Debounced code execution
- Efficient DOM updates via morphing

## Conclusion

The SwiftUI Rails Playground showcases how we've successfully brought SwiftUI's declarative, composable syntax to Rails while maintaining the framework's core strengths:

- **Server-first architecture** with progressive enhancement
- **Natural Ruby DSL** that feels familiar to SwiftUI developers
- **Seamless integration** with Rails' ecosystem (Turbo, Stimulus, ViewComponent)
- **High performance** through smart component composition and Turbo morphing

This approach enables developers to build rich, interactive UIs with the elegance of SwiftUI and the power of Rails.