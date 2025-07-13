# SwiftUI Rails Architecture Guide

This document provides a comprehensive overview of the SwiftUI Rails architecture, philosophy, and patterns.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Architectural Philosophy: The Rails-First Approach](#architectural-philosophy-the-rails-first-approach)
3. [State Management Decision Tree](#state-management-decision-tree)
4. [Stateless Component Patterns](#stateless-component-patterns)
5. [Progressive Enhancement Patterns](#progressive-enhancement-patterns)

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

## State Management Decision Tree

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

## Stateless Component Patterns

### 1. Filter/Search Components - State in URL

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

### 2. Pagination - Natural URL State

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

### 3. Tab Navigation - URL-Driven UI State

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

### 4. Modal/Dialog - Progressive Enhancement

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

### 5. Accordion - Pure CSS Enhancement

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

### 6. Data Tables - Server-Side Logic

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

### 7. Form Components - Browser-Native Validation

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

### 8. Shopping Cart - Session State

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

## Progressive Enhancement Patterns

Progressive enhancement means building features that work without JavaScript, then enhancing them with Turbo and Stimulus for better UX.

### 1. Search with Live Results

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

### 2. Expandable Content with Details/Summary

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

### 3. Image Gallery with Lazy Loading

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

### 4. Auto-save Form with Fallback

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

### 5. Filterable List with URL State

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

### 6. Progressive Form Validation

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

### 7. Infinite Scroll with Pagination Fallback

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

## Real-World Component Examples

### Toggle Switch Component - Pure Stimulus

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

### Typeahead Search - URL + Stimulus Hybrid

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

### Toast Notification - Ephemeral UI State

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

### Infinite Carousel - Client-Side Only

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

### Command Palette - Keyboard Shortcuts Enhancement

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

## Summary

SwiftUI Rails embraces Rails' stateless architecture while providing a rich, SwiftUI-inspired DSL for building modern web applications. By leveraging URL state, progressive enhancement, and Rails' built-in patterns, we create applications that are fast, accessible, and maintainable without the complexity of client-side state management frameworks.

The key insight is that most "state" in web applications naturally belongs in URLs, sessions, or databases. By accepting this reality and building with it rather than against it, we create simpler, more robust applications that fully leverage the power of Rails and modern browser capabilities.