# 🏗️ SwiftUI Rails High-Level Component Library Plan

## Vision: "Lego Blocks" for Modern Web Applications

This document outlines a comprehensive plan for building sophisticated, reusable components that encapsulate both UI and behavior, requiring only configuration through props and slots. Each component should be a complete "lego block" that handles its own state, styling, interactions, and functionality.

## 🎯 Core Philosophy

### Component-as-Complete-Solution
- **Self-Contained**: Each component includes UI, behavior, state management, and styling
- **Configuration-Driven**: Customizable through props and slots, not code modification
- **Progressive Enhancement**: Works without JavaScript, enhanced with Stimulus
- **Rails-First**: Leverages Rails patterns (forms, sessions, URLs) over client-side complexity

### SwiftUI-Inspired Architecture
- **Declarative Syntax**: Components describe what they should look like, not how to build them
- **Composition Over Inheritance**: Build complex UIs by composing simple components
- **Single Source of Truth**: Props and state flow down, events flow up
- **Natural Helper Methods**: Component-as-DSL-context enables infinite composition

## 📚 Component Library Structure

```
lib/swift_ui_rails/components/
├── foundation/                    # Base building blocks
│   ├── base_component.rb         # Enhanced base with state management
│   ├── layout_component.rb       # Common layout patterns
│   ├── interactive_component.rb  # Interactive behavior base
│   └── form_component.rb         # Form handling base
├── ui/                           # Mid-level UI components
│   ├── atoms/                    # Smallest building blocks
│   │   ├── button_component.rb
│   │   ├── input_component.rb
│   │   ├── avatar_component.rb
│   │   └── badge_component.rb
│   ├── molecules/                # Composed UI elements
│   │   ├── card_component.rb
│   │   ├── modal_component.rb
│   │   ├── dropdown_component.rb
│   │   └── tabs_component.rb
│   └── organisms/               # Complex UI sections
│       ├── navigation_component.rb
│       ├── sidebar_component.rb
│       └── footer_component.rb
└── composed/                    # High-level domain components
    ├── auth/                    # Authentication & authorization
    │   ├── login_dialog_component.rb      ✅ IMPLEMENTED
    │   ├── register_form_component.rb
    │   ├── password_reset_component.rb
    │   ├── social_login_component.rb
    │   └── auth_guard_component.rb
    ├── layout/                  # Layout and navigation
    │   ├── toolbar_component.rb           ✅ IMPLEMENTED  
    │   ├── dashboard_layout_component.rb
    │   ├── app_shell_component.rb
    │   ├── breadcrumb_component.rb
    │   └── page_header_component.rb
    ├── data/                    # Data display and management
    │   ├── data_table_component.rb
    │   ├── data_grid_component.rb
    │   ├── search_results_component.rb
    │   ├── pagination_component.rb
    │   └── infinite_scroll_component.rb
    ├── forms/                   # Advanced form components
    │   ├── form_builder_component.rb
    │   ├── wizard_form_component.rb
    │   ├── validation_component.rb
    │   ├── file_upload_component.rb
    │   └── auto_save_form_component.rb
    ├── ecommerce/               # E-commerce specific
    │   ├── product_grid_component.rb
    │   ├── product_card_component.rb
    │   ├── shopping_cart_component.rb
    │   ├── checkout_flow_component.rb
    │   ├── price_display_component.rb
    │   └── review_system_component.rb
    ├── marketing/               # Marketing and landing pages
    │   ├── hero_section_component.rb
    │   ├── feature_grid_component.rb
    │   ├── testimonials_component.rb
    │   ├── pricing_table_component.rb
    │   ├── newsletter_signup_component.rb
    │   └── call_to_action_component.rb
    ├── analytics/              # Analytics and dashboards
    │   ├── dashboard_component.rb
    │   ├── analytics_widget_component.rb
    │   ├── chart_component.rb
    │   ├── kpi_card_component.rb
    │   └── time_range_picker_component.rb
    └── communication/          # Communication features
        ├── chat_component.rb
        ├── notification_center_component.rb
        ├── comment_system_component.rb
        ├── feedback_form_component.rb
        └── contact_form_component.rb
```

## 🏛️ Enhanced Architecture Features

### 1. Advanced State Management

```ruby
module SwiftUIRails
  module Component
    module StatefulComponent
      extend ActiveSupport::Concern
      
      class_methods do
        # Define reactive state properties
        def state(name, default: nil, reactive: true, persist: false)
          state_config = { 
            default: default, 
            reactive: reactive, 
            persist: persist 
          }
          state_configurations[name] = state_config
          
          # Getter
          define_method name do
            load_state(name, state_config)
          end
          
          # Setter with reactivity
          define_method "#{name}=" do |value|
            set_state(name, value, state_config)
          end
        end
        
        # Define computed properties
        def computed(name, &block)
          computed_configurations[name] = block
          
          define_method name do
            @computed ||= {}
            @computed[name] ||= instance_eval(&block)
          end
          
          # Cache invalidation
          define_method "invalidate_#{name}" do
            @computed&.delete(name)
          end
        end
        
        # Define side effects
        def effect(state_name, &block)
          effects[state_name] ||= []
          effects[state_name] << block
        end
        
        # Define watchers
        def watch(*state_names, &block)
          state_names.each do |state_name|
            watchers[state_name] ||= []
            watchers[state_name] << block
          end
        end
      end
      
      private
      
      def load_state(name, config)
        @state ||= {}
        
        if @state[name].nil?
          @state[name] = if config[:persist]
            load_persisted_state(name) || evaluate_default(config[:default])
          else
            evaluate_default(config[:default])
          end
        end
        
        @state[name]
      end
      
      def set_state(name, value, config)
        @state ||= {}
        old_value = @state[name]
        @state[name] = value
        
        # Persist if configured
        if config[:persist]
          persist_state(name, value)
        end
        
        # Trigger effects and watchers
        if config[:reactive] && old_value != value
          trigger_effects(name, value, old_value)
          trigger_watchers(name, value, old_value)
          invalidate_computed_dependencies(name)
        end
      end
    end
  end
end
```

### 2. Enhanced Slot System with Polymorphism

```ruby
module SwiftUIRails
  module Component
    module AdvancedSlots
      extend ActiveSupport::Concern
      
      class_methods do
        # Define polymorphic slots
        def slot(name, types: nil, many: false, required: false, default: nil, &default_block)
          slot_config = {
            types: types,
            many: many,
            required: required,
            default: default || default_block
          }
          
          slot_configurations[name] = slot_config
          
          if types
            define_polymorphic_slot(name, types, many, required)
          else
            define_regular_slot(name, many, required, default, &default_block)
          end
          
          # Validation for required slots
          if required
            validate_required_slot(name)
          end
        end
        
        private
        
        def define_polymorphic_slot(name, types, many, required)
          types.each do |type_name, component_class_or_proc|
            method_name = many ? "with_#{name}_#{type_name}" : "with_#{name}_as_#{type_name}"
            
            define_method method_name do |*args, **kwargs, &block|
              component = if component_class_or_proc.respond_to?(:call)
                component_class_or_proc.call(*args, **kwargs, &block)
              else
                component_class_or_proc.new(*args, **kwargs, &block)
              end
              
              store_slot_content(name, component, many)
              self
            end
          end
          
          # Generic slot setter
          define_method "with_#{name}" do |type:, **kwargs, &block|
            send("with_#{name}_#{type}", **kwargs, &block)
          end if types.size > 1
        end
      end
    end
  end
end
```

### 3. Built-in Form Handling

```ruby
module SwiftUIRails
  module Component
    module FormComponent
      extend ActiveSupport::Concern
      
      included do
        prop :model, type: Object, default: nil
        prop :form_url, type: String, required: true
        prop :form_method, type: Symbol, default: :post
        prop :validate_on, type: Array, default: [:submit]
        prop :auto_save, type: [TrueClass, FalseClass], default: false
        
        state :form_data, default: {}
        state :errors, default: {}
        state :touched_fields, default: Set.new
        state :submitting, default: false
        state :dirty, default: false
        
        computed :valid do
          errors.empty?
        end
        
        computed :can_submit do
          valid && !submitting && dirty
        end
        
        effect :form_data do |new_data, old_data|
          self.dirty = true if old_data && new_data != old_data
          validate_form if validate_on.include?(:change)
        end
      end
      
      private
      
      def form_wrapper(&block)
        form(
          action: form_url,
          method: form_method,
          data: {
            controller: "form-handler",
            "form-handler-auto-save-value": auto_save,
            "form-handler-validate-on-value": validate_on.join(',')
          }
        ) do
          # CSRF token
          hidden_field_tag(:authenticity_token, form_authenticity_token)
          
          # Form content
          yield if block_given?
        end
      end
      
      def form_field(name, type: :text, **options, &block)
        field_wrapper(name) do
          case type
          when :text, :email, :password
            text_input(name, type, **options)
          when :textarea
            textarea_input(name, **options)
          when :select
            select_input(name, **options)
          when :checkbox
            checkbox_input(name, **options)
          when :radio
            radio_input(name, **options)
          when :file
            file_input(name, **options)
          when :custom
            yield if block_given?
          end
        end
      end
      
      def field_wrapper(name, &block)
        field_errors = errors[name] || []
        field_touched = touched_fields.include?(name.to_s)
        
        div(class: "form-field", data: { field: name }) do
          yield
          
          # Error display
          if field_errors.any? && field_touched
            div(class: "field-errors") do
              field_errors.each do |error|
                text(error).text_sm.text_color("red-600").mt(1)
              end
            end
          end
        end
      end
    end
  end
end
```

## 📋 Implementation Roadmap

### Phase 1: Foundation Enhancement ✅ COMPLETED
- [x] Enhanced component base with state management
- [x] Advanced slot system with polymorphism  
- [x] Canonical Login Dialog Component
- [x] Canonical Toolbar Component
- [x] Stimulus controller integration patterns

### Phase 2: Core UI Components (Next Sprint)
- [ ] Enhanced Modal Component with multiple variants
- [ ] Advanced Form Builder Component
- [ ] Data Table Component with sorting/filtering
- [ ] Dashboard Layout Component
- [ ] Navigation Component with responsive behavior

### Phase 3: Domain-Specific Components
- [ ] E-commerce product components
- [ ] Marketing landing page components
- [ ] Analytics dashboard components
- [ ] Communication components (chat, notifications)

### Phase 4: Developer Experience
- [ ] Component generator with templates
- [ ] Interactive documentation system
- [ ] Performance monitoring and optimization
- [ ] TypeScript definitions for Stimulus controllers

## 🎨 Design Patterns and Best Practices

### 1. Component Composition Patterns

#### Slot-Based Composition
```ruby
class ProductCardComponent < ApplicationComponent
  slot :image, default: -> { default_product_image }
  slot :title, required: true
  slot :price, required: true
  slot :actions, many: true
  slot :badges, many: true
  
  swift_ui do
    card.group.hover_scale(105).transition do
      # Slots automatically compose
      image_section { render_image }
      content_section do
        title_section { render_title }
        price_section { render_price }
        badges_section { render_badges } if badges.any?
      end
      actions_section { render_actions } if actions.any?
    end
  end
end
```

#### Helper Method Composition
```ruby
class DashboardComponent < ApplicationComponent
  swift_ui do
    dashboard_shell do
      sidebar_section
      main_content_area do
        metrics_row
        charts_section
        activity_feed
      end
    end
  end
  
  private
  
  def metrics_row
    grid(columns: 4, gap: 6) do
      metric_card("Users", user_count, trend: "+12%")
      metric_card("Revenue", revenue, trend: "+8%")  
      metric_card("Orders", orders, trend: "+23%")
      metric_card("Conversion", conversion, trend: "-2%")
    end
  end
  
  def metric_card(title, value, trend:)
    # This method naturally composes with DSL
    card.p(6).hover_shadow("lg").transition do
      metric_content(title, value, trend)
    end
  end
end
```

### 2. State Management Patterns

#### Component-Local State
```ruby
class SearchComponent < ApplicationComponent
  state :query, default: ""
  state :results, default: []
  state :loading, default: false
  state :suggestions_open, default: false
  
  computed :has_results do
    results.any?
  end
  
  effect :query do |new_query|
    if new_query.length >= 2
      perform_search(new_query)
    else
      self.results = []
    end
  end
end
```

#### Cross-Component Communication
```ruby
class NotificationCenterComponent < ApplicationComponent
  # Listen to custom events from other components
  def connect_stimulus_controller
    {
      controller: "notification-center",
      action: [
        "login-success@window->notification-center#showSuccess",
        "form-error@window->notification-center#showError"
      ].join(" ")
    }
  end
end
```

### 3. Progressive Enhancement Patterns

#### Base Functionality Without JavaScript
```ruby
class FilterableListComponent < ApplicationComponent
  swift_ui do
    form(action: current_path, method: :get) do
      # Filters work with form submission
      filter_section
      
      # Results update via page reload
      turbo_frame_tag("results") do
        results_section
      end
    end
  end
end
```

#### Enhanced with Stimulus
```ruby
# The same component gets enhanced interactivity
def filter_section
  vstack(spacing: 4) do
    filters.each do |filter|
      select_field(
        filter[:name],
        options: filter[:options],
        data: {
          action: "change->filterable-list#updateFilter",
          turbo_submit_with: "change"  # Progressive enhancement
        }
      )
    end
  end
end
```

## 🚀 Usage Examples

### E-commerce Product Catalog
```ruby
<%= render ProductGridComponent.new(products: @products) do |grid| %>
  <% grid.with_filter type: :category, options: @categories %>
  <% grid.with_filter type: :price_range, min: 0, max: 1000 %>
  <% grid.with_sort_option "price", "Price" %>
  <% grid.with_sort_option "popularity", "Popularity" %>
  
  <% grid.with_empty_state do %>
    No products found. Try adjusting your filters.
  <% end %>
<% end %>
```

### Marketing Landing Page
```ruby
<%= render HeroSectionComponent.new(
  headline: "Build Amazing Apps",
  subheadline: "With SwiftUI Rails components",
  background_image: "/hero-bg.jpg"
) do |hero| %>
  <% hero.with_cta_button text: "Get Started", url: signup_path, variant: :primary %>
  <% hero.with_cta_button text: "Learn More", url: docs_path, variant: :secondary %>
  
  <% hero.with_feature_highlight icon: "⚡", text: "Lightning Fast" %>
  <% hero.with_feature_highlight icon: "🎨", text: "Beautiful Design" %>
  <% hero.with_feature_highlight icon: "🛡️", text: "Secure by Default" %>
<% end %>
```

### Dashboard with Real-time Updates
```ruby
<%= render DashboardComponent.new(user: current_user) do |dashboard| %>
  <% dashboard.with_widget type: :chart, title: "Revenue", data: @revenue_data %>
  <% dashboard.with_widget type: :metric, title: "Active Users", value: @active_users %>
  <% dashboard.with_widget type: :table, title: "Recent Orders", data: @recent_orders %>
  
  <% dashboard.with_action text: "Export Data", action: "dashboard#export" %>
  <% dashboard.with_action text: "Refresh", action: "dashboard#refresh" %>
<% end %>
```

## 🔧 Developer Tools and Workflow

### Component Generator
```bash
rails generate swift_ui_rails:component ProductCard \
  --slots="image,title,price,actions:many" \
  --props="product:Product:required,variant:symbol:default_normal" \
  --stimulus \
  --story
```

### Interactive Development Environment
- **Storybook Integration**: Visual component development and testing
- **Hot Reloading**: Instant feedback during development  
- **Prop Controls**: Interactive property manipulation
- **Slot Playground**: Test different slot configurations
- **Responsive Preview**: Multi-device testing

### Performance Monitoring
- **Render Time Tracking**: Component-level performance metrics
- **Collection Optimization**: Automatic ViewComponent 2.0 collection rendering
- **Memory Usage**: State management efficiency monitoring
- **Bundle Size**: JavaScript controller optimization

## 📊 Success Metrics

### Developer Experience
- **Reduced Implementation Time**: 75% faster component development
- **Code Reusability**: 90% of UI patterns available as components
- **Maintainability**: Single source of truth for component behavior
- **Consistency**: Unified design system across applications

### Performance
- **10x Faster Rendering**: ViewComponent 2.0 collection optimization
- **Reduced JavaScript**: Server-side rendering with progressive enhancement
- **Better Caching**: Component-level caching strategies
- **Smaller Bundles**: Modular Stimulus controller loading

### User Experience
- **Accessibility**: Built-in ARIA labels and keyboard navigation
- **Progressive Enhancement**: Works without JavaScript
- **Mobile Responsiveness**: Automatic responsive behavior
- **Loading States**: Built-in loading and error states

This plan creates a comprehensive component library that rivals modern frontend frameworks while maintaining Rails' simplicity and server-side rendering benefits. Each component is a complete "lego block" that can be dropped into any Rails application with minimal configuration.