# frozen_string_literal: true

# Copyright 2025

class EnhancedAuthStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  def default_login
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          # Header
          vstack(spacing: 8) do
            text("Welcome Back").font_size("3xl").font_weight("bold")
            text("Sign in to your account").text_color("gray-600")
          end

          # Form
          vstack(spacing: 16) do
            field_group do
              label("Email", for_input: "email")
              textfield(name: "email", type: "email", placeholder: "you@example.com")
            end

            field_group do
              label("Password", for_input: "password")
              textfield(name: "password", type: "password", placeholder: "••••••••")
            end

            button("Sign In").button_style(:primary).w("full")
          end

          # Footer
          hstack do
            text("Don't have an account?").text_color("gray-600")
            link("Sign up", destination: "#").text_color("blue-600").hover_text_color("blue-700")
          end
        end
      end.max_w("md").mx("auto")
    end
  end

  def login_with_error
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          # Error message
          div do
            text("Invalid email or password. Please try again.")
              .text_color("red-600")
              .font_size("sm")
          end.bg("red-50").p(12).rounded("md")

          # Header
          vstack(spacing: 8) do
            text("Welcome Back").font_size("3xl").font_weight("bold")
            text("Sign in to your account").text_color("gray-600")
          end

          # Form with error
          vstack(spacing: 16) do
            field_group do
              label("Email", for_input: "email")
              textfield(name: "email", type: "email", value: "user@example.com")
            end

            field_group do
              label("Password", for_input: "password")
              textfield(name: "password", type: "password")
              text("is incorrect").text_color("red-600").text_size("sm").mt(2)
            end

            button("Sign In").button_style(:primary).w("full")
          end
        end
      end.max_w("md").mx("auto")
    end
  end

  def login_without_social
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          # Header
          vstack(spacing: 8) do
            text("Welcome Back").font_size("3xl").font_weight("bold")
            text("Sign in to your account").text_color("gray-600")
          end

          # Form
          vstack(spacing: 16) do
            field_group do
              label("Email", for_input: "email")
              textfield(name: "email", type: "email", placeholder: "you@example.com")
            end

            field_group do
              label("Password", for_input: "password")
              textfield(name: "password", type: "password", placeholder: "••••••••")
            end

            button("Sign In").button_style(:primary).w("full")
          end
        end
      end.max_w("md").mx("auto")
    end
  end

  def default_register
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          # Header
          vstack(spacing: 8) do
            text("Create Account").font_size("3xl").font_weight("bold")
            text("Join us today").text_color("gray-600")
          end

          # Form
          vstack(spacing: 16) do
            field_group do
              label("Name", for_input: "name")
              textfield(name: "name", placeholder: "John Doe")
            end

            field_group do
              label("Email", for_input: "email")
              textfield(name: "email", type: "email", placeholder: "you@example.com")
            end

            field_group do
              label("Password", for_input: "password")
              textfield(name: "password", type: "password", placeholder: "••••••••")
            end

            field_group do
              label("Confirm Password", for_input: "password_confirmation")
              textfield(name: "password_confirmation", type: "password", placeholder: "••••••••")
            end

            button("Create Account").button_style(:primary).w("full")
          end
        end
      end.max_w("md").mx("auto")
    end
  end

  def register_with_errors
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          # Error message
          div do
            text("Please fix the errors below")
              .text_color("red-600")
              .font_size("sm")
          end.bg("red-50").p(12).rounded("md")

          # Header
          vstack(spacing: 8) do
            text("Create Account").font_size("3xl").font_weight("bold")
            text("Join us today").text_color("gray-600")
          end

          # Form with errors
          vstack(spacing: 16) do
            field_group do
              label("Name", for_input: "name")
              textfield(name: "name", value: "John")
            end

            field_group do
              label("Email", for_input: "email")
              textfield(name: "email", type: "email", value: "john@")
              text("is invalid").text_color("red-600").text_size("sm").mt(2)
            end

            field_group do
              label("Password", for_input: "password")
              textfield(name: "password", type: "password")
              text("is too short (minimum is 8 characters)").text_color("red-600").text_size("sm").mt(2)
            end

            field_group do
              label("Confirm Password", for_input: "password_confirmation")
              textfield(name: "password_confirmation", type: "password")
              text("doesn't match password").text_color("red-600").text_size("sm").mt(2)
            end

            button("Create Account").button_style(:primary).w("full")
          end
        end
      end.max_w("md").mx("auto")
    end
  end

  private

  def field_group(&block)
    div.mb(16, &block)
  end

  def textfield(name:, type: "text", placeholder: nil, value: nil, **attrs)
    input(
      type: type,
      name: name,
      placeholder: placeholder,
      value: value,
      **attrs
    ).w("full")
     .px(12)
     .py(8)
     .border
     .border_color("gray-300")
     .rounded("md")
     .focus_ring(2)
     .focus_ring_color("blue-500")
  end

  def error_404
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          text("404").font_size("6xl").font_weight("bold").text_color("gray-400")
          text("Page Not Found").font_size("2xl").font_weight("semibold")
          text("The page you're looking for doesn't exist.").text_color("gray-600")
          button("Go Home").button_style(:primary)
        end.text_center
      end.max_w("md").mx("auto")
    end
  end

  def error_unauthorized
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          text("401").font_size("6xl").font_weight("bold").text_color("red-400")
          text("Unauthorized").font_size("2xl").font_weight("semibold")
          text("You need to sign in to access this page.").text_color("gray-600")
          link("Sign In", destination: "/login").button_style(:primary)
        end.text_center
      end.max_w("md").mx("auto")
    end
  end

  def error_forbidden
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          text("403").font_size("6xl").font_weight("bold").text_color("orange-400")
          text("Access Forbidden").font_size("2xl").font_weight("semibold")
          text("Your account doesn't have access to this feature. Please upgrade your subscription or contact your administrator.").text_color("gray-600")
          button("Contact Support").button_style(:primary)
        end.text_center
      end.max_w("md").mx("auto")
    end
  end

  def error_server
    swift_ui do
      card(elevation: 2) do
        vstack(spacing: 24) do
          text("500").font_size("6xl").font_weight("bold").text_color("red-500")
          text("Server Error").font_size("2xl").font_weight("semibold")
          text("Something went wrong on our end. Please try again later.").text_color("gray-600")
          button("Try Again").button_style(:primary)
        end.text_center
      end.max_w("md").mx("auto")
    end
  end

  def auth_layout_centered
    swift_ui do
      div.min_h_screen.flex.items_center.justify_center.bg("gray-50").py(48).px(16) do
        div.max_w("md").w("full") do
          # Brand
          div.text_center.mb(32) do
            text("SwiftUI Rails").font_size("2xl").font_weight("bold").text_color("gray-900")
          end

          # Login form
          default_login
        end
      end
    end
  end

  def auth_layout_split
    swift_ui do
      div.min_h_screen.flex do
        # Form side
        div.flex_1.flex.items_center.justify_center.px(16).py(48) do
          div.max_w("md").w("full") do
            # Brand
            div.text_center.mb(32) do
              text("SwiftUI Rails").font_size("2xl").font_weight("bold").text_color("gray-900")
            end

            # Register form
            default_register
          end
        end

        # Image side
        div.hidden.lg_block.relative.w(0).flex_1 do
          image(src: "https://images.unsplash.com/photo-1505904267569-f02eaeb45a4c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1908&q=80", alt: "")
            .absolute
            .inset(0)
            .h_full
            .w_full
            .object_cover

          div.absolute.inset(0).bg_gradient_to_t.from("black").to("transparent").opacity(60)

          div.relative.h_full.flex.items_center.justify_center.p(48) do
            div.text_center do
              text("Build amazing apps").text_size("4xl").font_weight("bold").text_color("white").mb(16)
              text("Join our community of developers").text_size("xl").text_color("white").opacity(90)
            end
          end
        end
      end
    end
  end

  def auth_layout_card
    swift_ui do
      div.min_h_screen.flex.items_center.justify_center.bg("indigo-50").py(48).px(16) do
        div.max_w("lg").w("full") do
          # Card wrapper
          div.bg("white").shadow("xl").rounded("lg").overflow_hidden do
            # Header
            div.text_center.px(24).pt(24).pb(0) do
              text("SwiftUI Rails").font_size("2xl").font_weight("bold").text_color("gray-900").mb(8)
              div.text_center do
                text("Welcome Back!").text_size("lg").font_weight("semibold").text_color("gray-900")
                text("Sign in to continue to your dashboard").text_size("sm").text_color("gray-600").mt(4)
              end
            end

            # Form
            div.px(24).py(32) do
              default_login
            end

            # Footer
            div.px(24).pb(24).border_t.pt(16) do
              div.flex.justify_center.gap(16) do
                link("Help", destination: "/help").text_size("sm").text_color("gray-600").hover_text_color("gray-900")
                span("•").text_color("gray-400")
                link("Status", destination: "/status").text_size("sm").text_color("gray-600").hover_text_color("gray-900")
                span("•").text_color("gray-400")
                link("API", destination: "/api").text_size("sm").text_color("gray-600").hover_text_color("gray-900")
              end
            end
          end
        end
      end
    end
  end

  def complete_auth_flow
    swift_ui do
      # Tabs for different states
      div.data(controller: "tabs") do
        # Tab navigation
        div.border_b.border_color("gray-200") do
          nav.flex.gap(32).px(16) do
            button("Login")
              .px(4)
              .py(16)
              .text_size("sm")
              .font_weight("medium")
              .border_b(2)
              .border_color("indigo-500")
              .text_color("indigo-600")
              .data(action: "click->tabs#show", "tabs-target": "tab", "tabs-panel": "login")

            button("Register")
              .px(4)
              .py(16)
              .text_size("sm")
              .font_weight("medium")
              .border_b(2)
              .border_color("transparent")
              .text_color("gray-500")
              .hover_text_color("gray-700")
              .data(action: "click->tabs#show", "tabs-target": "tab", "tabs-panel": "register")

            button("Error States")
              .px(4)
              .py(16)
              .text_size("sm")
              .font_weight("medium")
              .border_b(2)
              .border_color("transparent")
              .text_color("gray-500")
              .hover_text_color("gray-700")
              .data(action: "click->tabs#show", "tabs-target": "tab", "tabs-panel": "errors")
          end
        end

        # Tab panels
        div.mt(16) do
          # Login panel
          div(data: { "tabs-target": "panel", "tabs-panel-name": "login" }) do
            default_login
          end

          # Register panel
          div.hidden(data: { "tabs-target": "panel", "tabs-panel-name": "register" }) do
            default_register
          end

          # Error states panel
          div.hidden(data: { "tabs-target": "panel", "tabs-panel-name": "errors" }) do
            div.grid.grid_cols(2).gap(16) do
              div do
                text("404 Error").font_weight("semibold").mb(8)
                div.h(300).overflow_hidden.rounded("lg").border do
                  error_404
                end
              end

              div do
                text("401 Unauthorized").font_weight("semibold").mb(8)
                div.h(300).overflow_hidden.rounded("lg").border do
                  error_unauthorized
                end
              end
            end
          end
        end
      end
    end
  end
end
# Copyright 2025
