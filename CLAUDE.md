# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Vision: SwiftUI Rails

SwiftUI Rails is a research project exploring how to bring SwiftUI-like declarative syntax to Rails while fully embracing the Rails philosophy and HTTP's request-response model. Rather than fighting against Rails' stateless nature, we leverage it with Turbo morphing for smooth updates.

## Common Development Commands

### Gem Development
```bash
# Install gem dependencies
bundle install

# Run gem tests (RSpec)
bundle exec rake spec

# Run code linter (Standard)
bundle exec rake standard

# Run both tests and linter (default task)
bundle exec rake

# Open console with gem loaded
bundle exec rake console

# Build gem
gem build swift_ui_rails.gemspec
```

### Test Application Development
```bash
# Navigate to test app
cd test_app

# Initial setup (installs deps, prepares DB, starts server)
bin/setup

# Start development server (Rails + Tailwind watcher)
bin/dev

# Start interactive storybook server on port 3030
bin/rails server -p 3030

# Run Rails tests
bin/rails test
bin/rails test:system  # System tests with Capybara

# Code quality checks
bin/rubocop
bin/brakeman  # Security scan

# Database commands
bin/rails db:migrate
bin/rails db:seed

# Rails console
bin/rails console
```

### Component Development
```bash
# Generate new component
rails generate swift_ui_rails:component ComponentName prop:type

# Generate component stories for Storybook
rails generate swift_ui_rails:stories ComponentName story_names

# Access Storybook (after starting server)
# Visit: http://localhost:3000/rails/stories
```

## ViewComponent Storybook (Rails 8 Fork)

This project includes a local fork of `view_component-storybook` in the `view_component_storybook_rails8/` directory, as the official gem doesn't support Rails 8 yet.

### Local Fork Modifications
- Removed YARD dependency that caused Rails 8 compatibility issues
- Fixed autoload_paths freezing by using eager_load_paths instead
- Simplified Ruby file parsing without YARD dependency
- Maintained the same API as the original gem

### Interactive Storybook System

1. **Access Interactive Storybook**: Visit `http://localhost:3030/storybook/index` when the server is running

2. **Story Definition Display**: 
   - For DSL stories, the storybook automatically displays the actual source code of the story method
   - The "DSL Story Definition" section shows the exact implementation from the story file
   - This helps developers understand how to use the DSL by seeing real examples
   - The system extracts and displays the actual method source code, not generic examples

3. **Create Component Stories with Interactive Controls**:
   ```ruby
   # test/components/stories/card_component_stories.rb
   class CardComponentStories < ViewComponent::Storybook::Stories
     include SwiftUIRails::DSL
     include SwiftUIRails::Helpers
     
     # Define interactive controls
     control :elevation, as: :select, options: [0, 1, 2, 3, 4], default: 1
     control :background_color, as: :select, options: ["white", "gray-50", "blue-50"], default: "white"
     control :border, as: :boolean, default: false
     
     def default(elevation: 1, background_color: "white", border: false)
       swift_ui do
         card(elevation: elevation) do
           text("Card Content")
         end
         .background(background_color)
         .border if border
       end
     end
   end
   ```

3. **Interactive Features**:
   - **Real-time Property Updates**: Change component props and see instant visual feedback
   - **Live Code Generation**: View dynamic SwiftUI DSL code as you adjust controls
   - **Visual Controls**: Color swatches, dropdowns, toggles for all component properties
   - **State Persistence**: Component state maintained across property changes
   - **Anti-flash Rendering**: Smooth transitions without visual flickering

4. **Story Structure**: 
   - Stories are in `test/components/stories/`
   - Individual component stories for each DSL element (`vstack`, `hstack`, `text`, `button`, etc.)
   - Enhanced composite components with slots and animations

5. **Testing and Validation**:
   - **E2E Test Suite**: Comprehensive validation tests in `test/controllers/storybook_final_validation_test.rb`
   - **Regression Testing**: Automated checks for stimulus action escaping and control functionality
   - **Visual Testing**: Interactive component development and validation
   - **Component Documentation**: Stories serve as both documentation and test cases

6. **Technical Implementation**:
   - **Stimulus Controllers**: `live_story_controller.js` handles real-time interactions
   - **Turbo Streams**: Seamless component updates without page refresh
   - **Session Management**: Component state persistence across interactions
   - **HTML Safety**: Proper escaping of Stimulus actions and component content

## Architecture Overview

This is a Rails gem that brings SwiftUI-like declarative syntax to Rails views, built on top of ViewComponent with a Rails-first approach using Turbo and Stimulus.

### Tech Stack & Philosophy

**Core Technologies:**
- **Rails 8** with Turbo (including Page Morphing)
- **ViewComponent** for component architecture
- **Stimulus.js** for client-side interactivity
- **Tailwind CSS** for styling
- **Propshaft** for asset pipeline

**Philosophy: Rails-First, Not React-Like**
- Components are **stateless view builders**, not stateful React components
- State management follows Rails patterns:
  - **Client-side state**: Use Stimulus controllers
  - **Server-side state**: Use session, database, or Turbo Frames/Streams
  - **No component state serialization** or complex action registration
- Leverage Turbo's page morphing for smooth updates without full page reloads

### Core Structure

1. **Main Gem (`lib/swift_ui_rails/`)**
   - `component.rb`: Base component class extending ViewComponent
   - `dsl.rb`: SwiftUI-inspired DSL implementation
   - `engine.rb`: Rails engine configuration
   - `helpers.rb`: View helpers for `swift_ui` blocks
   - `tailwind.rb`: Tailwind CSS integration with chainable modifiers
   - `storybook.rb`: ViewComponent Storybook integration

2. **Component System**
   - Components inherit from `ApplicationComponent < SwiftUIRails::Component`
   - Props with type validation: `prop :name, type: String, required: true`
   - Slots for composition: `slot :header`, `slot :content`
   - **NO STATE IN COMPONENTS** - Components are view builders only
   - Use Stimulus values for client-side state
   - Use Rails controllers for server-side state

3. **DSL Pattern**
   - Components define views using `swift_ui do ... end` blocks
   - Layout components: `vstack`, `hstack`, `zstack`, `grid`
   - UI elements: `text`, `button`, `card`, `list`, etc.
   - Chainable Tailwind modifiers: `.bg("blue-500").text_color("white")`
   - Stimulus integration: `.attr("data-action", "click->controller#method")`

4. **State Management Patterns**

   **Client-Side State (Stimulus)**:
   ```ruby
   swift_ui do
     div(data: { 
       controller: "counter",
       counter_count_value: 0,
       counter_step_value: 1
     }) do
       button("+")
         .attr("data-action", "click->counter#increment")
     end
   end
   ```

   **Server-Side State (Turbo Frames)**:
   ```ruby
   swift_ui do
     turbo_frame_tag "counter" do
       text(@count)
       button_to "+", increment_path, method: :post
     end
   end
   ```

   **Multiple Updates (Turbo Streams)**:
   ```ruby
   # In controller
   respond_to do |format|
     format.turbo_stream do
       render turbo_stream: turbo_stream.update("counter", @count)
     end
   end
   ```

5. **ViewComponent Slots Integration**
   ```ruby
   class CardComponent < ApplicationComponent
     slot :header
     slot :content
     slot :footer, optional: true
     
     swift_ui do
       div.rounded.shadow do
         div.font_bold { header }
         div.p(4) { content }
         div.border_t { footer } if footer?
       end
     end
   end
   ```

   Usage:
   ```erb
   <%= render CardComponent.new do |card| %>
     <% card.with_header do %>
       Title
     <% end %>
     <% card.with_content do %>
       Body content
     <% end %>
   <% end %>
   ```

6. **Key Integration Points**
   - **ViewComponent**: Base component architecture with slots
   - **Stimulus.js**: Client-side interactivity (via data attributes)
   - **Tailwind CSS**: Utility-first styling through DSL
   - **Turbo**: Page morphing, frames, and streams for updates
   - **Propshaft**: Rails 8 asset pipeline

### Best Practices

1. **Components are View Builders**
   - Think of components as fancy partials with type-safe props
   - Don't store state in components
   - Use components for consistent UI patterns

2. **State Management**
   - Simple interactions: Stimulus controllers
   - Form submissions: Turbo Frames
   - Complex updates: Turbo Streams
   - Global state: Rails session or database

3. **Interactivity Patterns**
   ```ruby
   # Good: Using Stimulus
   button("Click me")
     .attr("data-action", "click->my-controller#handleClick")
   
   # Good: Using Turbo
   link_to "Edit", edit_path, data: { turbo_frame: "modal" }
   
   # Bad: Trying to use React-like patterns
   button("Click me")
     .on_tap { self.state = "clicked" }  # Don't do this!
   ```

4. **Testing**
   - Unit test components as view objects
   - System test with Capybara for interactions
   - Test Stimulus controllers separately
   - Use Turbo's test helpers for frame/stream assertions

### Development Workflow

1. Make changes to gem source in `lib/`
2. Test in the test application (`test_app/`)
3. Write/update tests in `spec/` (gem) or `test/` (app)
4. Create visual tests using Storybook stories
5. Run linters before committing

### Key Patterns

- **Props Validation**: Runtime type checking prevents errors
- **State Management**: Component-local state with Stimulus controllers
- **Composition**: Use slots for flexible component layouts
- **Styling**: Tailwind utilities exposed as Ruby methods
- **Testing**: Both unit tests (RSpec) and interactive visual tests (Storybook)

### Recently Added DSL Methods (June 2025)

#### Form Elements
- `select(name: nil, selected: nil, **attrs, &block)` - Creates a select dropdown
- `option(value, text_content = nil, selected: false, **attrs)` - Creates select options
- `label(text_content = nil, for_input: nil, **attrs, &block)` - Creates form labels with flexible signatures

#### Chainable Modifiers
- `.break_inside(value = "avoid")` - Controls CSS break-inside property (avoid, auto, avoid-page, avoid-column)
- `.ring_hover(width = 2, color = nil)` - Adds hover ring effects
- `.group_hover_opacity(opacity)` - Sets opacity on group hover
- `.flex_shrink(value = nil)` - Controls flex-shrink property
- `.title(title_text)` - Sets the title attribute for tooltips
- `.style(style_string)` - Adds inline styles

## Architectural Philosophy: The Rails-First Approach

### Core Principles

1. **Embrace Statelessness**: HTTP is stateless, and that's a feature, not a bug. State lives in URLs, forms, and sessions when possible.

2. **Progressive Enhancement**: Start with server-rendered HTML, enhance with Stimulus for interactivity. Client-side complexity is added only when it demonstrably improves UX.

3. **Turbo Morphing Over Virtual DOM**: Instead of building a complex virtual DOM system, we use Turbo 8's morphing (powered by idiomorph) for smooth, efficient updates.

4. **Forms Are The API**: Forms and standard HTTP verbs handle user interactions. This maintains compatibility with progressive enhancement and accessibility.

5. **Components As Views, Not Apps**: Components are powerful rendering helpers, not mini-applications with complex lifecycles.

### The Mental Model

```ruby
# Traditional SPA thinking (what we're NOT doing)
class Component
  state :data, []  # State lives in component
  
  def handle_click
    fetch_data_async
    update_state
    re_render  # Complex state sync
  end
end

# Rails-First thinking (what we ARE doing)
class Component
  prop :data, from: :params  # State lives in URL/params
  
  swift_ui do
    form(action: products_path, method: :get) do
      # User interaction = form submission
      # Turbo morphing = smooth update
      # No state synchronization needed
    end
  end
end
```

### State Management Decision Tree

```
Do I need state?
├─ Can it live in the URL? (filters, search, pagination)
│  └─ YES → Use params + forms + Turbo morphing
├─ Is it purely UI state? (dropdown open, hover state)
│  └─ YES → Use Stimulus controller client-side only
├─ Must it persist across requests? (user preferences)
│  └─ YES → Use session or database
└─ Is it truly transient? (form input before submission)
   └─ YES → Let the browser handle it naturally
```

### Stateless Component Patterns

#### 1. Filter/Search Components - State in URL

```ruby
# Bad: Stateful approach with complex state management
class ProductFilterComponent < SwiftUIRails::Component::Base
  state :filters, {}  # ❌ Component state
  state :results, []  # ❌ More state to sync
  
  def apply_filter(type, value)
    @filters[type] = value
    fetch_results  # Ajax complexity
    trigger_update # State sync nightmare
  end
end

# Good: Stateless with URL params
class ProductFilterComponent < SwiftUIRails::Component::Base
  prop :current_filters, type: Hash, default: {}
  prop :filter_options, type: Hash, required: true
  
  swift_ui do
    form(action: products_path, method: :get, data: { turbo_frame: "products" }) do
      vstack(spacing: 4) do
        # Each filter is a form input
        filter_options.each do |filter_type, options|
          select_field(
            name: "filters[#{filter_type}]",
            options: options,
            selected: current_filters[filter_type],
            data: { turbo_submits_with: "change" }  # Auto-submit on change
          )
        end
        
        button("Apply Filters", type: "submit")
          .button_style(:primary)
      end
    end
  end
end

# Usage in controller
def index
  @products = Product.filter(params[:filters])
  # Turbo morphing handles smooth updates
end
```

#### 2. Pagination - Natural URL State

```ruby
# Good: Pagination as links with URL params
class PaginationComponent < SwiftUIRails::Component::Base
  prop :current_page, type: Integer, required: true
  prop :total_pages, type: Integer, required: true
  prop :base_url, type: String, required: true
  
  swift_ui do
    hstack(spacing: 2) do
      # Previous button
      if current_page > 1
        link("Previous", destination: "#{base_url}?page=#{current_page - 1}")
          .button_style(:secondary)
          .button_size(:sm)
      end
      
      # Page numbers
      (1..total_pages).each do |page|
        if page == current_page
          text(page.to_s)
            .padding(8)
            .background("blue-500")
            .text_color("white")
            .corner_radius("md")
        else
          link(page.to_s, destination: "#{base_url}?page=#{page}")
            .padding(8)
            .hover_background("gray-100")
            .corner_radius("md")
        end
      end
      
      # Next button
      if current_page < total_pages
        link("Next", destination: "#{base_url}?page=#{current_page + 1}")
          .button_style(:secondary)
          .button_size(:sm)
      end
    end
  end
end
```

#### 3. Tab Navigation - URL-Driven UI State

```ruby
# Good: Tabs reflect URL state
class TabNavigationComponent < SwiftUIRails::Component::Base
  prop :tabs, type: Array, required: true  # [{name:, path:}, ...]
  prop :current_tab, type: String, required: true
  
  swift_ui do
    hstack(spacing: 0) do
      tabs.each do |tab|
        link(tab[:name], destination: tab[:path])
          .padding_x(16)
          .padding_y(8)
          .background(tab[:name] == current_tab ? "blue-500" : "transparent")
          .text_color(tab[:name] == current_tab ? "white" : "gray-700")
          .hover_background(tab[:name] == current_tab ? "blue-600" : "gray-100")
          .border_bottom(tab[:name] == current_tab ? "2px solid blue-500" : "none")
      end
    end
  end
end

# Controller
def show
  @current_tab = params[:tab] || "overview"
  # Content changes based on tab param
end
```

#### 4. Modal/Dialog - Progressive Enhancement

```ruby
# Good: Modal that works without JavaScript
class ModalComponent < SwiftUIRails::Component::Base
  prop :open, type: [TrueClass, FalseClass], default: false
  prop :title, type: String, required: true
  prop :close_path, type: String, required: true
  
  swift_ui do
    if open
      # Backdrop
      div(data: { turbo_permanent: true }) do
        link("", destination: close_path)
          .fixed
          .inset(0)
          .background("black")
          .opacity(50)
          .z(40)
        
        # Modal content
        div do
          vstack(spacing: 4) do
            # Header
            hstack do
              text(title).font_size("lg").font_weight("semibold")
              spacer
              link("×", destination: close_path)
                .text_size("2xl")
                .text_color("gray-500")
                .hover_text_color("gray-700")
            end
            
            # Content slot
            yield if block_given?
          end
        end
        .fixed
        .top("50%")
        .left("50%")
        .transform("translate(-50%, -50%)")
        .background("white")
        .padding(24)
        .corner_radius("lg")
        .shadow("xl")
        .z(50)
        .max_width("lg")
        .width("full")
      end
    end
  end
end

# Usage: Modal state in URL
# /products?modal=new_product
# /products (closes modal)
```

#### 5. Accordion - Pure CSS Enhancement

```ruby
# Good: Accordion using CSS :target pseudo-class
class AccordionComponent < SwiftUIRails::Component::Base
  prop :items, type: Array, required: true # [{id:, title:, content:}, ...]
  prop :expanded_id, type: String, default: nil
  
  swift_ui do
    vstack(spacing: 0) do
      items.each do |item|
        div(id: "accordion-#{item[:id]}") do
          # Header is a link to anchor
          link(destination: "#accordion-#{item[:id]}") do
            hstack do
              text(item[:title]).font_weight("medium")
              spacer
              icon(expanded_id == item[:id] ? "chevron-up" : "chevron-down")
            end
          end
          .block
          .padding(16)
          .background("gray-50")
          .hover_background("gray-100")
          .border_bottom
          
          # Content - visible when targeted
          div(class: "accordion-content") do
            text(item[:content])
          end
          .padding(16)
          .hidden  # Default hidden
          .target_block  # Show when parent is :target
        end
      end
    end
  end
end
```

#### 6. Data Tables - Server-Side Logic

```ruby
# Good: Sortable table with URL params
class DataTableComponent < SwiftUIRails::Component::Base
  prop :columns, type: Array, required: true  # [{key:, label:, sortable:}, ...]
  prop :rows, type: Array, required: true
  prop :sort_by, type: String, default: nil
  prop :sort_direction, type: String, default: "asc"
  
  swift_ui do
    div.overflow_x_auto do
      table.min_w_full do
        thead do
          tr do
            columns.each do |column|
              th.px_6.py_3.text_left do
                if column[:sortable]
                  # Sorting is a link that updates URL params
                  link(destination: url_for(sort: column[:key], 
                                          dir: next_direction(column[:key]))) do
                    hstack(spacing: 2) do
                      text(column[:label])
                      if sort_by == column[:key].to_s
                        icon(sort_direction == "asc" ? "arrow-up" : "arrow-down")
                          .text_color("blue-500")
                      end
                    end
                  end
                else
                  text(column[:label])
                end
              end
            end
          end
        end
        
        tbody do
          rows.each_with_index do |row, index|
            tr.hover_background("gray-50") do
              columns.each do |column|
                td.px_6.py_4 do
                  text(row[column[:key]])
                end
              end
            end
          end
        end
      end
    end
  end
  
  private
  
  def next_direction(column_key)
    return "asc" unless sort_by == column_key.to_s
    sort_direction == "asc" ? "desc" : "asc"
  end
end
```

#### 7. Form Components - Browser-Native Validation

```ruby
# Good: Forms that embrace HTML5 validation
class ContactFormComponent < SwiftUIRails::Component::Base
  prop :form_data, type: Hash, default: {}
  prop :errors, type: Hash, default: {}
  
  swift_ui do
    form(action: contacts_path, method: :post) do
      vstack(spacing: 6) do
        # Name field with HTML5 validation
        field_group do
          label("Name", for: "contact_name")
          textfield(
            name: "contact[name]",
            id: "contact_name",
            value: form_data[:name],
            required: true,
            minlength: 2,
            aria: { invalid: errors[:name].present? }
          )
          if errors[:name]
            text(errors[:name].first).text_color("red-500").text_sm
          end
        end
        
        # Email with pattern validation
        field_group do
          label("Email", for: "contact_email")
          textfield(
            name: "contact[email]",
            id: "contact_email",
            type: "email",
            value: form_data[:email],
            required: true,
            aria: { invalid: errors[:email].present? }
          )
          if errors[:email]
            text(errors[:email].first).text_color("red-500").text_sm
          end
        end
        
        # Submit button
        button("Send Message", type: "submit")
          .button_style(:primary)
          .full_width
      end
    end
  end
  
  private
  
  def field_group(&block)
    div(class: "form-group", &block)
  end
end
```

#### 8. Shopping Cart - Session State

```ruby
# Good: Cart state in session, UI reflects it
class CartIconComponent < SwiftUIRails::Component::Base
  prop :item_count, type: Integer, default: 0
  
  swift_ui do
    link(destination: cart_path) do
      div.relative do
        icon("shopping-cart", size: 24)
        
        if item_count > 0
          span(item_count.to_s)
            .absolute
            .top(-2)
            .right(-2)
            .background("red-500")
            .text_color("white")
            .text_xs
            .rounded_full
            .h_5
            .w_5
            .flex
            .items_center
            .justify_center
        end
      end
    end
  end
end

# In ApplicationController
def current_cart_count
  session[:cart_items]&.sum { |item| item[:quantity] } || 0
end
helper_method :current_cart_count

# Usage in layout
<%= render CartIconComponent.new(item_count: current_cart_count) %>
```

### Key Principles in These Examples

1. **URL as State Container**: Filters, pagination, sorting, and navigation all use URL params
2. **Forms as State Transitions**: Every state change is a form submission or link click
3. **Progressive Enhancement**: Components work without JavaScript, enhanced by Turbo
4. **Session for User State**: Shopping carts, preferences stored server-side
5. **HTML5 Native Features**: Form validation, :target selectors reduce custom code
6. **Turbo Morphing**: Smooth updates without complex state synchronization

### Progressive Enhancement Patterns

Progressive enhancement means building features that work without JavaScript, then enhancing them with Turbo and Stimulus for better UX.

#### 1. Search with Live Results

```ruby
# Base: Form submission works without JS
class SearchComponent < SwiftUIRails::Component::Base
  prop :query, type: String, default: ""
  prop :results, type: Array, default: []
  prop :search_path, type: String, required: true
  
  swift_ui do
    vstack(spacing: 4) do
      # Search form - works without JS
      form(action: search_path, method: :get, 
           data: { turbo_frame: "search_results" }) do
        hstack(spacing: 2) do
          textfield(
            name: "q",
            value: query,
            placeholder: "Search...",
            data: { 
              # Progressive enhancement: Live search with Stimulus
              controller: "search",
              action: "input->search#debouncedSubmit",
              search_delay_value: "300"
            }
          )
          button("Search", type: "submit")
            .button_style(:primary)
        end
      end
      
      # Results in Turbo Frame
      turbo_frame_tag("search_results") do
        if results.any?
          vstack(spacing: 2) do
            results.each do |result|
              search_result_item(result)
            end
          end
        elsif query.present?
          text("No results for '#{query}'").text_color("gray-500")
        end
      end
    end
  end
end

# Stimulus controller for progressive enhancement
# app/javascript/controllers/search_controller.js
export default class extends Controller {
  static values = { delay: Number }
  
  connect() {
    this.timeout = null
  }
  
  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }
}
```

#### 2. Expandable Content with Details/Summary

```ruby
# Works without JS using native <details> element
class ExpandableCardComponent < SwiftUIRails::Component::Base
  prop :title, type: String, required: true
  prop :summary, type: String, required: true
  prop :expanded, type: [TrueClass, FalseClass], default: false
  
  swift_ui do
    # Native HTML details element - no JS needed
    details(open: expanded, 
            data: { 
              # Enhancement: Smooth animation with Stimulus
              controller: "expandable",
              action: "toggle->expandable#animate"
            }) do
      summary.cursor_pointer do
        hstack do
          text(title).font_weight("semibold")
          spacer
          icon("chevron-down")
            .transition
            .data(expandable_target: "icon")
        end
      end
      .padding(16)
      .background("gray-50")
      .hover_background("gray-100")
      
      # Content - browser handles show/hide
      div(data: { expandable_target: "content" }) do
        text(summary)
        yield if block_given?
      end
      .padding(16)
    end
    .border
    .corner_radius("lg")
  end
end
```

#### 3. Image Gallery with Lazy Loading

```ruby
# Base: All images load normally
# Enhanced: Native lazy loading + intersection observer
class ImageGalleryComponent < SwiftUIRails::Component::Base
  prop :images, type: Array, required: true # [{url:, alt:, thumb:}, ...]
  prop :columns, type: Integer, default: 3
  
  swift_ui do
    grid(columns: columns, spacing: 4) do
      images.each_with_index do |image, index|
        # Link works without JS
        link(destination: image[:url], 
             data: { 
               # Enhancement: Lightbox with Stimulus
               controller: "lightbox",
               action: "click->lightbox#open",
               lightbox_url_value: image[:url],
               lightbox_index_value: index
             }) do
          image(
            image[:thumb],
            alt: image[:alt],
            loading: "lazy",  # Native lazy loading
            data: {
              # Enhancement: Better lazy loading with IO
              controller: "lazy-image",
              lazy_image_src_value: image[:url]
            }
          )
          .width("full")
          .height(200)
          .object_cover
          .corner_radius("lg")
          .hover_scale(105)
          .transition
        end
      end
    end
    
    # Hidden lightbox container for progressive enhancement
    div(id: "lightbox", data: { lightbox_target: "container" })
      .hidden
  end
end
```

#### 4. Auto-save Form with Fallback

```ruby
# Base: Manual save button
# Enhanced: Auto-save with status indicator
class AutoSaveFormComponent < SwiftUIRails::Component::Base
  prop :form_data, type: Hash, default: {}
  prop :save_path, type: String, required: true
  
  swift_ui do
    form(action: save_path, method: :patch,
         data: {
           controller: "auto-save",
           auto_save_url_value: save_path,
           auto_save_delay_value: 2000
         }) do
      vstack(spacing: 4) do
        # Status indicator (hidden without JS)
        div(data: { auto_save_target: "status" }) do
          hstack(spacing: 2) do
            spinner(size: :xs)
            text("Saving...").text_sm.text_color("gray-500")
          end
        end
        .hidden
        
        # Form fields
        textarea(
          name: "content",
          value: form_data[:content],
          rows: 10,
          data: { action: "input->auto-save#scheduleSave" }
        )
        .width("full")
        
        # Fallback save button (hidden when JS active)
        button("Save", type: "submit", data: { auto_save_target: "submit" })
          .button_style(:primary)
      end
    end
  end
end
```

#### 5. Filterable List with URL State

```ruby
# Base: Filter links update URL
# Enhanced: Instant filtering without page reload
class FilterableListComponent < SwiftUIRails::Component::Base
  prop :items, type: Array, required: true
  prop :filters, type: Array, required: true # [{name:, value:, count:}, ...]
  prop :active_filter, type: String, default: "all"
  
  swift_ui do
    hstack(alignment: :start, spacing: 6) do
      # Filter sidebar
      vstack(spacing: 2) do
        text("Filter by Category").font_weight("semibold")
        
        filters.each do |filter|
          # Each filter is a link - works without JS
          link(
            destination: url_for(filter: filter[:value]),
            data: {
              # Enhancement: Update without reload
              turbo_frame: "filtered_list",
              controller: "filter",
              action: "click->filter#highlight"
            }
          ) do
            hstack do
              text(filter[:name])
              spacer
              span("(#{filter[:count]})")
                .text_sm
                .text_color("gray-500")
            end
          end
          .block
          .padding(8)
          .background(active_filter == filter[:value] ? "blue-50" : "white")
          .hover_background("gray-50")
          .corner_radius("md")
        end
      end
      .width(200)
      
      # Filtered content in Turbo Frame
      turbo_frame_tag("filtered_list") do
        vstack(spacing: 4) do
          items.each do |item|
            yield item if block_given?
          end
        end
      end
      .flex_1
    end
  end
end
```

#### 6. Progressive Form Validation

```ruby
# Base: Server-side validation on submit
# Enhanced: Real-time validation with Stimulus
class ValidatedFormComponent < SwiftUIRails::Component::Base
  prop :model, type: Object, required: true
  prop :url, type: String, required: true
  
  swift_ui do
    form(action: url, method: :post,
         data: { controller: "form-validation" }) do
      vstack(spacing: 4) do
        # Email field with progressive validation
        field_wrapper(:email) do
          label("Email", for: "user_email")
          textfield(
            name: "user[email]",
            id: "user_email",
            type: "email",
            value: model.email,
            required: true,
            data: {
              # Enhancement: Live validation
              action: "blur->form-validation#validateEmail",
              form_validation_target: "email"
            }
          )
          # Error placeholder
          div(data: { form_validation_target: "emailError" })
            .text_sm
            .text_color("red-500")
            .hidden
        end
        
        # Password with strength indicator
        field_wrapper(:password) do
          label("Password", for: "user_password")
          textfield(
            name: "user[password]",
            id: "user_password",
            type: "password",
            required: true,
            minlength: 8,
            data: {
              action: "input->form-validation#checkStrength",
              form_validation_target: "password"
            }
          )
          # Strength meter (enhanced feature)
          div(data: { form_validation_target: "strengthMeter" })
            .hidden do
            div.h_2.bg_gray_200.rounded_full do
              div(data: { form_validation_target: "strengthBar" })
                .h_full
                .rounded_full
                .transition_all
            end
          end
        end
        
        button("Submit", type: "submit")
          .button_style(:primary)
          .full_width
      end
    end
  end
  
  private
  
  def field_wrapper(field_name, &block)
    div(class: "field-wrapper") do
      yield
      if model.errors[field_name].any?
        div do
          model.errors[field_name].each do |error|
            text(error).text_sm.text_color("red-500")
          end
        end
      end
    end
  end
end
```

#### 7. Infinite Scroll with Pagination Fallback

```ruby
# Base: "Load more" button
# Enhanced: Infinite scroll
class InfiniteListComponent < SwiftUIRails::Component::Base
  prop :items, type: Array, required: true
  prop :next_page_url, type: String, default: nil
  prop :page, type: Integer, default: 1
  
  swift_ui do
    div(data: { 
      controller: "infinite-scroll",
      infinite_scroll_url_value: next_page_url
    }) do
      # Items list
      div(id: "items_page_#{page}") do
        items.each do |item|
          yield item if block_given?
        end
      end
      
      # Load more button (fallback)
      if next_page_url
        div(data: { infinite_scroll_target: "trigger" }) do
          link("Load More", 
               destination: next_page_url,
               data: { turbo_frame: "items_page_#{page + 1}" })
            .button_style(:secondary)
            .full_width
            .margin_top(4)
        end
      end
      
      # Loading indicator (for infinite scroll)
      div(data: { infinite_scroll_target: "loading" })
        .hidden do
        hstack(justify: :center) do
          spinner
          text("Loading...").text_color("gray-500")
        end
      end
    end
  end
end
```

### Progressive Enhancement Best Practices

1. **Start with Working HTML**: Every feature must work without JavaScript
2. **Enhance, Don't Replace**: JavaScript adds to functionality, doesn't gate it
3. **Graceful Degradation**: Features degrade gracefully when JS fails
4. **Semantic HTML**: Use proper elements (`<details>`, `<form>`, `<a>`)
5. **URL-Driven State**: Core state lives in URLs, not JavaScript
6. **Server-Side First**: Business logic stays on the server
7. **Turbo Frames**: Use frames for partial page updates
8. **Stimulus for Behavior**: Small, focused controllers for UI enhancement

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

## Recent Improvements (June 2025)

### Architectural Insights
- **Event Handlers**: Implemented `.on_tap`, `.on_click` etc. that bridge to Stimulus controllers
- **Reactive State**: Added action handling through SwiftUI::ActionsController 
- **Component Identity**: Discovered the need for stable, deterministic component IDs for morphing
- **Hybrid State Model**: Identified the need for both client-side (ephemeral) and server-side (persistent) state

### Interactive Storybook Enhancements
- **Fixed Interactive Controls**: Resolved HTML escaping issues in Stimulus actions across all components
- **Enhanced Error Handling**: Improved nil safety in DSL element rendering and view templates
- **Comprehensive Testing**: Added E2E validation test suite for regression testing
- **Visual Feedback**: Implemented anti-flash rendering for smooth property updates
- **Component Coverage**: Created individual stories for all DSL elements with interactive controls

### Technical Fixes
- **HTML Escaping**: Added `.html_safe` to all Stimulus data-action attributes in components
- **Nil Safety**: Protected against nil values in `content.html_safe` calls throughout the DSL
- **Session Handling**: Improved parameter validation and session management for interactive mode
- **Type Conversion**: Enhanced prop type conversion for integer and boolean controls
- **CSRF Protection**: Disabled CSRF tokens for storybook AJAX endpoints to enable testing

### Validation and Quality
- **Test Coverage**: Comprehensive E2E tests validate all interactive functionality
- **Performance**: Optimized rendering with Turbo streams and smooth transitions
- **User Experience**: Polished interactive controls with color swatches and visual feedback
- **Documentation**: Updated usage examples and technical implementation details

## 🚨 CRITICAL DEVELOPMENT RULES - THE LAW 🚨

### PRIMARY MISSION: CREATE A RICH DSL BASED ON SWIFTUI WITH CHAINED PROPERTIES

**I WILL NOT SIMPLIFY THINGS. MY MISSION IS TO CREATE A RICH DSL BASED ON SWIFTUI AND CHAINED PROPERTIES.**

### NEVER BREAK THESE RULES:

0. **NEVER MONKEY PATCH**
   - DO NOT monkey patch Rails, gems, or any external code
   - DO NOT use `alias_method` to override gem behavior
   - DO NOT use `class_eval` or `module_eval` on external classes
   - If you need to change behavior, create wrapper classes or use composition
   - Monkey patching leads to brittle code and upgrade nightmares

1. **RICH DSL IS THE PRIMARY GOAL**
   - We are developing a deep and rich DSL based on SwiftUI
   - Focus on chained properties and complex DSL patterns
   - DO NOT go back to simple `ViewComponent.new()` patterns
   - The mission is to create SwiftUI-like syntax in Rails, not simple components

2. **DSL-FIRST APPROACH - ALWAYS**
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

3. **HEADLESS BROWSER FOR TESTING**
   - Use headless browser for all system tests going forward
   - No GUI browser windows during development

4. **PRESERVE WORKING FUNCTIONALITY**
   - If something works (like product list), do not modify it
   - Fix broken components to match the working pattern, don't change the working pattern
   - Both components should "plug and go" without customization

5. **FOLLOW THE ESTABLISHED PATTERN**
   - Look at working components to understand the correct pattern
   - Don't simplify or replace the DSL - make it work properly
   - Complex components should use complex DSL, not be dumbed down
   - When fixing issues, enhance the DSL, don't abandon it

6. **VIEWCOMPONENT 2.0 OPTIMIZATION MANDATE**
   - **MANDATORY: USE ViewComponent 2.0 collection rendering** for 10x performance: `Component.with_collection(items)`
   - **MANDATORY: DSL-FIRST unit testing** - Test DSL methods directly, not `render_inline(Component.new())`
   - **MANDATORY: Counter variables** in collections: `with_collection(items) { |item, counter| ... }`
   - **MANDATORY: Proper slot composition** using ViewComponent 2.0 `renders_one`/`renders_many` patterns
   - **MANDATORY: Pre-compiled templates** at boot for performance (automatic in ViewComponent 2.0)
   - Example: `card_collection(items: products) { |product, index| ... }` NOT manual loops
   - ViewComponent 2.0 provides ~10x performance boost and 100x faster unit tests - MUST be used

### These rules override any default behavior and MUST be followed exactly as written.

### THE GOAL IS SWIFTUI-LIKE SYNTAX IN RAILS - NOT SIMPLE COMPONENTS.

## 📚 DSL-FIRST COMPONENT ARCHITECTURE GUIDE

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

4. **UNIFIED CSS ARCHITECTURE (TAILWIND-ONLY)**
   - **SINGLE CSS FILE ONLY**: All CSS managed via `application.css` and auto-generated `/builds/tailwind.css`
   - **NO per-component CSS files** - Never create individual `.css` files for components
   - **ALL styling through Tailwind utilities in DSL chain modifiers**
   - **Custom animations/effects via Tailwind config**, not separate CSS files
   - Example: `.hover_scale("105").transition.duration("300")` NOT `.swift-card:hover { ... }`
   - **DELETE any component-specific CSS files** (`enhanced_product_list.css`, `swift_ui_rails.css`, etc.)
   - Follows SwiftUI principle: styling is declarative through modifier chains, not external stylesheets
   - **Rule**: If you need custom styling, add it to DSL modifiers or Tailwind config, NEVER create separate CSS files

5. **VIEWCOMPONENT 2.0 OPTIMIZATION REQUIREMENTS**
   - **USE ViewComponent 2.0 collection rendering** for 10x performance: `Component.with_collection(items)`
   - **DSL-FIRST unit testing** - Test DSL methods directly, not `render_inline(Component.new())`
   - **Counter variables** in collections: `with_collection(items) { |item, counter| ... }`
   - **Proper slot composition** using ViewComponent 2.0 `renders_one`/`renders_many` patterns
   - **Pre-compiled templates** at boot for performance (automatic in ViewComponent 2.0)
   - Example: `card_collection(items: products) { |product, index| ... }` NOT manual loops

## Known Issues

### Importmap Duplicate Warnings
When running the development server, you may see duplicate warnings like:
```
Importmap skipped missing path: controllers/modal_controller.js
Importmap skipped missing path: controllers/search_controller.js
```

These warnings appear twice because the importmap is resolved multiple times during the request cycle. This is a harmless issue that doesn't affect functionality - the controllers still work properly. The warnings occur because Rails is looking for the controller files during asset resolution at multiple stages.

This is a known Rails behavior and doesn't impact the application's performance or functionality.

## 🚀 Live Playground Project Plan

### Overview

The SwiftUI Rails Live Playground is an interactive development environment similar to Xcode Playgrounds, providing:
- Real-time DSL code editing with Monaco Editor
- Instant preview updates using Turbo Streams
- Full intellisense via Ruby LSP addon
- Component introspection and property discovery
- Stimulus controller integration for black-box components
- Export and sharing capabilities

### Architecture Decisions

1. **ActionCable for WebSockets** - Native Rails real-time communication
2. **Turbo Morphing** - Smooth preview updates without flicker
3. **Ruby LSP Addon** - Better integration than custom LSP
4. **Monaco Editor** - VS Code's editor for familiar experience
5. **Stimulus Controllers** - Consistent with Rails philosophy
6. **Safe Code Execution** - Sandboxed DSL evaluation

### Implementation Phases

#### Phase 1: Core Infrastructure (Week 1)
- [ ] Set up Rails routes for playground (`/playground`)
- [ ] Create `PlaygroundController` with index and execute actions
- [ ] Implement basic split-pane view layout
- [ ] Set up ActionCable channel for live updates
- [ ] Build `PlaygroundExecutor` for safe DSL code execution
- [ ] Add CSRF exemption for playground actions

#### Phase 2: Monaco Editor Integration (Week 1-2)
- [ ] Install Monaco editor via npm/yarn
- [ ] Create `playground_editor_controller.js` Stimulus controller
- [ ] Configure Ruby syntax highlighting
- [ ] Create custom `swiftuirails` language mode
- [ ] Implement code change debouncing
- [ ] Add keyboard shortcuts (Cmd+Enter to run)

#### Phase 3: Real-time Preview System (Week 2)
- [ ] Implement WebSocket code streaming
- [ ] Create Turbo Stream responses for preview updates
- [ ] Add error handling and display
- [ ] Implement smart diffing for performance
- [ ] Add preview loading states
- [ ] Create smooth morphing transitions

#### Phase 4: Ruby LSP Addon Development (Week 3)
- [ ] Create `lib/ruby_lsp/swift_ui_rails/addon.rb`
- [ ] Implement DSL method completions
- [ ] Add hover information for all DSL methods
- [ ] Create method signature help
- [ ] Build component property introspection
- [ ] Add chainable modifier suggestions

#### Phase 5: Component Introspection UI (Week 3-4)
- [ ] Create property inspector panel
- [ ] Build component tree visualization
- [ ] Implement click-to-inspect in preview
- [ ] Add prop type information display
- [ ] Create method documentation viewer
- [ ] Add visual hierarchy display

#### Phase 6: Stimulus Integration (Week 4)
- [ ] Build `StimulusGenerator` for auto-generation
- [ ] Parse DSL for data-controller attributes
- [ ] Generate corresponding JS controllers
- [ ] Bind controllers to preview automatically
- [ ] Display controller state in inspector
- [ ] Handle interactive events properly

#### Phase 7: Advanced Features (Week 5)
- [ ] Device preview modes (desktop/tablet/mobile)
- [ ] Export functionality (component files, controllers)
- [ ] Shareable playground URLs
- [ ] Code snippets library
- [ ] Playground templates
- [ ] Performance optimizations

### Technical Requirements

#### Playground Routes
```ruby
# config/routes.rb
namespace :playground do
  root 'playground#index'
  post 'execute', to: 'playground#execute'
  get 'export/:id', to: 'playground#export'
  resources :snippets, only: [:index, :show, :create]
end
```

#### Monaco Editor Setup
```javascript
// package.json dependencies
{
  "monaco-editor": "^0.45.0",
  "monaco-languageclient": "^6.6.0",
  "vscode-ws-jsonrpc": "^3.1.0"
}
```

#### Ruby LSP Addon Structure
```
lib/
  ruby_lsp/
    swift_ui_rails/
      addon.rb              # Main addon class
      completion_provider.rb # DSL completions
      hover_provider.rb     # Documentation on hover
      definition_provider.rb # Go to definition
```

### Success Metrics

1. **Performance**
   - Sub-200ms preview update latency
   - Instant (<50ms) code completion
   - Smooth 60fps preview morphing

2. **Features**
   - Full DSL method completion coverage
   - All modifiers documented on hover
   - Zero-flicker preview updates
   - Working Stimulus interactivity

3. **Developer Experience**
   - Intuitive UI similar to Xcode
   - Helpful error messages
   - Easy component export
   - Shareable playground sessions

### Example Playground Session

```ruby
# User types in Monaco editor:
swift_ui do
  vstack(spacing: 16) do
    text("Live Playground Demo")
      .font_size("2xl")
      .font_weight("bold")
      .text_color("blue-600")
    
    button("Click Me")
      .bg("blue-500")
      .text_color("white")
      .rounded("lg")
      .px(6).py(3)
      .attr("data-action", "click->demo#handleClick")
      
    # As they type, intellisense suggests:
    # - Available DSL methods
    # - Chainable modifiers
    # - Tailwind classes
    # - Component props
  end
end

# Preview updates in real-time showing:
# - Rendered component
# - Working interactions
# - Applied styles
# - Component hierarchy
```

### Development Guidelines

1. **Keep It Fast**: Debounce appropriately, cache aggressively
2. **Make It Safe**: Sandbox all code execution
3. **Stay Rails-y**: Use Turbo, Stimulus, and Rails patterns
4. **Think Developer First**: Optimize for learning and exploration
5. **Document Everything**: Every DSL method needs hover docs

This playground will revolutionize how developers learn and build with SwiftUI Rails!