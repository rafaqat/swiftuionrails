# Authentication Forms with SwiftUI Rails DSL

## Overview
This document describes the authentication form components created using the SwiftUI Rails DSL, providing a pure DSL approach to building login and registration forms.

## Components Created

### 1. AuthFormComponent
A flexible component that can render both login and registration forms based on the `mode` prop.

**Features:**
- Supports both login (`:login`) and registration (`:register`) modes
- Configurable logo, company name, and paths
- Built-in error handling with field-level errors
- Flash message support
- CSRF token integration
- Responsive design with Tailwind CSS

**Usage:**
```ruby
# Login form
render AuthFormComponent.new(
  mode: :login,
  csrf_token: form_authenticity_token,
  forgot_password_path: new_password_path
)

# Registration form with errors
render AuthFormComponent.new(
  mode: :register,
  errors: { email: "has already been taken" },
  flash_message: "Please correct the errors below",
  flash_type: :error
)
```

### 2. LoginFormComponent
A dedicated login form component with all standard features.

**Props:**
- `action_path`: Form submission path
- `logo_url`: Company logo URL
- `show_forgot_password`: Toggle forgot password link
- `show_signup_link`: Toggle registration link
- `csrf_token`: Rails CSRF token

### 3. RegisterFormComponent
A dedicated registration form component with comprehensive fields.

**Props:**
- `require_name`: Toggle first/last name fields
- `show_terms`: Toggle terms and conditions checkbox
- `show_login_link`: Toggle login link
- All standard form configuration props

### 4. Simple Auth Stories
Pure DSL implementations of authentication forms without using components.

**Variants:**
1. **simple_login**: Clean, minimal login form
2. **simple_register**: Full registration form with all fields
3. **gradient_login**: Stylish login with gradient backgrounds and social buttons

## Pure DSL Example

Here's how to create a login form using only the SwiftUI Rails DSL:

```ruby
swift_ui do
  div.flex.justify_center.items_center.min_h("screen").bg("gray-50") do
    div.w("full").max_w("md").bg("white").shadow("xl").rounded("lg").p(8) do
      # Logo and title
      div.text_center.mb(8) do
        div.h(16).w(16).bg("indigo-600").rounded("full").mx("auto").mb(4).flex.items_center.justify_center do
          text("S").text_size("2xl").font_weight("bold").text_color("white")
        end
        text("Sign in to your account").text_size("2xl").font_weight("bold").text_color("gray-900")
      end
      
      # Form
      form(action: "/login", method: "POST") do
        # Email field
        div.mb(4) do
          label("Email", for: "email").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
          input(
            type: "email",
            name: "email",
            id: "email",
            placeholder: "you@example.com",
            required: true
          ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
           .focus_ring(2).focus_ring_color("indigo-500")
        end
        
        # Password field
        div.mb(6) do
          label("Password", for: "password").block.text_size("sm").font_weight("medium").text_color("gray-700")
          input(
            type: "password",
            name: "password",
            id: "password",
            required: true
          ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
           .focus_ring(2).focus_ring_color("indigo-500")
        end
        
        # Submit button
        button("Sign in", type: "submit")
          .w("full")
          .py(2)
          .px(4)
          .bg("indigo-600")
          .text_color("white")
          .font_weight("medium")
          .rounded("md")
          .hover_bg("indigo-700")
      end
    end
  end
end
```

## Key DSL Patterns Used

### 1. Layout and Spacing
- `.flex.justify_center.items_center` - Flexbox centering
- `.min_h("screen")` - Full viewport height
- `.max_w("md")` - Maximum width constraints
- `.p(8)`, `.mb(4)`, `.px(3).py(2)` - Padding and margin

### 2. Styling
- `.bg("indigo-600")` - Background colors
- `.text_color("white")` - Text colors
- `.rounded("lg")` - Border radius
- `.shadow("xl")` - Box shadows
- `.border.border_color("gray-300")` - Borders

### 3. Interactive States
- `.hover_bg("indigo-700")` - Hover effects
- `.focus_ring(2).focus_ring_color("indigo-500")` - Focus states
- `.transform.transition_all.duration(200)` - Transitions

### 4. Form Elements
```ruby
# Text input
input(type: "email", name: "email", id: "email")
  .w("full")
  .px(3).py(2)
  .border.border_color("gray-300")
  .rounded("md")
  .focus_ring(2)

# Submit button
button("Sign in", type: "submit")
  .w("full")
  .bg("indigo-600")
  .text_color("white")
  .hover_bg("indigo-700")

# Checkbox
input(type: "checkbox", name: "remember")
  .h(4).w(4)
  .text_color("indigo-600")
  .rounded
```

### 5. Advanced Patterns

**Gradient Backgrounds:**
```ruby
div.bg("gradient-to-br from-purple-600 to-blue-600")
button.bg("gradient-to-r from-purple-600 to-blue-600")
```

**Icons with Inputs:**
```ruby
div.relative do
  div.absolute.inset_y(0).left(0).pl(3).flex.items_center do
    text("📧").text_color("gray-400")
  end
  input(type: "email").pl(10) # Extra padding for icon
end
```

**Social Login Buttons:**
```ruby
div.grid.grid_cols(2).gap(4) do
  button.flex.items_center.gap(2) do
    text("🌐")
    text("Google")
  end
end
```

## Best Practices

1. **Responsive Design**: Use Tailwind's responsive utilities via `.tw()` method
2. **Accessibility**: Always include proper labels and ARIA attributes
3. **Security**: Include CSRF tokens in forms
4. **Validation**: Use HTML5 input types and required attributes
5. **Styling**: Leverage Tailwind utilities for consistent design
6. **Interactivity**: Add focus states and hover effects for better UX

## Integration with Rails

```ruby
# In your controller
def login
  @auth_component = AuthFormComponent.new(
    mode: :login,
    csrf_token: form_authenticity_token,
    action_path: session_path
  )
end

# In your view
<%= render @auth_component %>

# Or use the DSL directly
<%= swift_ui do %>
  <%= render SimpleAuthStories.new.simple_login %>
<% end %>
```