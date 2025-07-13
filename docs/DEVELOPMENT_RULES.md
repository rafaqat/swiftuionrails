# 🚨 CRITICAL DEVELOPMENT RULES - THE LAW 🚨

## PRIMARY MISSION: CREATE A RICH DSL BASED ON SWIFTUI WITH CHAINED PROPERTIES

**I WILL NOT SIMPLIFY THINGS. MY MISSION IS TO CREATE A RICH DSL BASED ON SWIFTUI AND CHAINED PROPERTIES.**

## NEVER BREAK THESE RULES:

### 0. NEVER MONKEY PATCH
   - DO NOT monkey patch Rails, gems, or any external code
   - DO NOT use `alias_method` to override gem behavior
   - DO NOT use `class_eval` or `module_eval` on external classes
   - If you need to change behavior, create wrapper classes or use composition
   - Monkey patching leads to brittle code and upgrade nightmares

### 1. RICH DSL IS THE PRIMARY GOAL
   - We are developing a deep and rich DSL based on SwiftUI
   - Focus on chained properties and complex DSL patterns
   - DO NOT go back to simple `ViewComponent.new()` patterns
   - The mission is to create SwiftUI-like syntax in Rails, not simple components

### 2. DSL-FIRST APPROACH - ALWAYS
   - ALL components MUST use the SwiftUI DSL pattern: `swift_ui do...end`
   - Use chainable DSL methods: `.background()`, `.padding()`, `.corner_radius()`
   - Components inherit from `SwiftUIRails::Component::Base`
   - Props defined with: `prop :name, type: Type, default: value`
   - Complex DSL should be made to work, not replaced with simple ViewComponent patterns
   - NEVER use `render ComponentName.new()` in stories - use DSL blocks instead
   - Stories should include DSL helpers and use `swift_ui do...end` syntax
   - **CREATE A HIERARCHY OF RICH COMPONENTS**: Build powerful, reusable components by composing smaller building blocks
     - Start with base DSL primitives like `text`, `div`, `span`, `image` (just like SwiftUI's Text, View)
     - Compose these into mid-level components like `button`, `card`, `list_item`
     - Build rich, feature-complete components like `dsl_product_card`, `nav_bar`, `data_table`
     - Each level adds functionality while maintaining composability
     - Example hierarchy: `text` → `label` → `form_field` → `validated_form`

### 3. HEADLESS BROWSER FOR TESTING
   - Use headless browser for all system tests going forward
   - No GUI browser windows during development

### 4. PRESERVE WORKING FUNCTIONALITY
   - If something works (like product list), do not modify it
   - Fix broken components to match the working pattern, don't change the working pattern
   - Both components should "plug and go" without customization

### 5. FOLLOW THE ESTABLISHED PATTERN
   - Look at working components to understand the correct pattern
   - Don't simplify or replace the DSL - make it work properly
   - Complex components should use complex DSL, not be dumbed down
   - When fixing issues, enhance the DSL, don't abandon it

### 6. VIEWCOMPONENT 2.0 OPTIMIZATION MANDATE
   - **MANDATORY: USE ViewComponent 2.0 collection rendering** for 10x performance: `Component.with_collection(items)`
   - **MANDATORY: DSL-FIRST unit testing** - Test DSL methods directly, not `render_inline(Component.new())`
   - **MANDATORY: Counter variables** in collections: `with_collection(items) { |item, counter| ... }`
   - **MANDATORY: Proper slot composition** using ViewComponent 2.0 `renders_one`/`renders_many` patterns
   - **MANDATORY: Pre-compiled templates** at boot for performance (automatic in ViewComponent 2.0)
   - Example: `card_collection(items: products) { |product, index| ... }` NOT manual loops
   - ViewComponent 2.0 provides ~10x performance boost and 100x faster unit tests - MUST be used

## These rules override any default behavior and MUST be followed exactly as written.

## THE GOAL IS SWIFTUI-LIKE SYNTAX IN RAILS - NOT SIMPLE COMPONENTS.

## 📚 DSL-FIRST COMPONENT ARCHITECTURE GUIDE

### Core Principles for Building DSL Components

#### 1. Component Structure
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

#### 2. Composition Over Configuration
- Build complex UIs by composing primitive DSL elements
- Each DSL element is a building block: `text`, `button`, `vstack`, `hstack`, `card`
- Chain modifiers for styling: `.bg()`, `.text_color()`, `.padding()`, `.rounded()`
- State management via Stimulus: `.data(controller: "name", action: "click->name#method")`

#### 3. Maximum Reusability Patterns

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

#### 4. Component Examples

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

#### 5. Reusability Best Practices

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

#### 6. Testing DSL Components
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

### 7. UNIFIED CSS ARCHITECTURE (TAILWIND-ONLY)
- **SINGLE CSS FILE ONLY**: All CSS managed via `application.css` and auto-generated `/builds/tailwind.css`
- **NO per-component CSS files** - Never create individual `.css` files for components
- **ALL styling through Tailwind utilities in DSL chain modifiers**
- **Custom animations/effects via Tailwind config**, not separate CSS files
- Example: `.hover_scale("105").transition.duration("300")` NOT `.swift-card:hover { ... }`
- **DELETE any component-specific CSS files** (`enhanced_product_list.css`, `swift_ui_rails.css`, etc.)
- Follows SwiftUI principle: styling is declarative through modifier chains, not external stylesheets
- **Rule**: If you need custom styling, add it to DSL modifiers or Tailwind config, NEVER create separate CSS files

### 8. VIEWCOMPONENT 2.0 OPTIMIZATION REQUIREMENTS
- **USE ViewComponent 2.0 collection rendering** for 10x performance: `Component.with_collection(items)`
- **DSL-FIRST unit testing** - Test DSL methods directly, not `render_inline(Component.new())`
- **Counter variables** in collections: `with_collection(items) { |item, counter| ... }`
- **Proper slot composition** using ViewComponent 2.0 `renders_one`/`renders_many` patterns
- **Pre-compiled templates** at boot for performance (automatic in ViewComponent 2.0)
- Example: `card_collection(items: products) { |product, index| ... }` NOT manual loops