# frozen_string_literal: true

# Copyright 2025

class AuthFormStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Helpers
  include SwiftUIRails::DSL

  # Simple DSL test
  def simple_dsl_test(**kwargs)
    swift_ui do
      div.bg("blue-50").p(4) do
        text("Simple DSL Test")
      end
    end
  end

  # Basic login form
  def login(**kwargs)
    render AuthFormComponent.new(
      mode: :login,
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Login form with pre-filled email
  def login_with_email(**kwargs)
    render AuthFormComponent.new(
      mode: :login,
      email_value: "user@example.com",
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Login form with error
  def login_with_errors(**kwargs)
    render AuthFormComponent.new(
      mode: :login,
      email_value: "invalid@email",
      errors: {
        email: "Please enter a valid email address",
        password: "Password is incorrect"
      },
      flash_message: "Invalid email or password. Please try again.",
      flash_type: :error,
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Basic registration form
  def register(**kwargs)
    render AuthFormComponent.new(
      mode: :register,
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Registration without name fields
  def register_email_only(**kwargs)
    render AuthFormComponent.new(
      mode: :register,
      require_name: false,
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Registration with validation errors
  def register_with_errors(**kwargs)
    render AuthFormComponent.new(
      mode: :register,
      first_name_value: "John",
      email_value: "john@example",
      errors: {
        last_name: "Last name can't be blank",
        email: "Email is invalid",
        password: "Password is too short (minimum 8 characters)",
        password_confirmation: "Passwords don't match",
        agree_terms: "You must agree to the terms"
      },
      flash_message: "Please correct the errors below.",
      flash_type: :error,
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Custom branded login
  def custom_branded_login(**kwargs)
    render AuthFormComponent.new(
      mode: :login,
      logo_url: "https://tailwindcss.com/plus-assets/img/logos/mark.svg?color=purple&shade=600",
      company_name: "SwiftUI Rails",
      action_path: "/auth/login",
      forgot_password_path: "/auth/password/new",
      signup_path: "/auth/register",
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Success message after registration
  def login_after_registration(**kwargs)
    render AuthFormComponent.new(
      mode: :login,
      flash_message: "Registration successful! Please sign in with your new account.",
      flash_type: :success,
      email_value: "newuser@example.com",
      csrf_token: "dummy_token_for_demo"
    )
  end

  # Login form using DSL directly (without component)
  def pure_dsl_login(**kwargs)
    swift_ui do
      div.flex.min_h("full").flex_col.justify_center.px(6).py(12).lg("px-8").bg("gray-50") do
        # Logo section with animation
        div.sm("mx-auto w-full max-w-sm") do
          div.mx("auto").h(12).w(12).rounded_full.bg("indigo-600").flex.items_center.justify_center do
            text("S").text_size("2xl").font_weight("bold").text_color("white")
          end

          h2.mt(10).text_center.text_size("2xl").leading("9").font_weight("bold").tracking("tight").text_color("gray-900") do
            text("Welcome back")
          end
          p.mt(2).text_center.text_size("sm").text_color("gray-600") do
            text("Sign in to continue to SwiftUI Rails")
          end
        end

        # Card container
        div.mt(10).sm("mx-auto w-full max-w-sm") do
          div.bg("white").py(8).px(4).shadow.rounded("lg").sm("px-10") do
            form(action: "/login", method: "POST").space_y(6) do
              # Email with icon
              div do
                label(for: "email").block.text_size("sm").font_weight("medium").text_color("gray-700") do
                  text("Email")
                end
                div.mt(1).relative.rounded("md").shadow("sm") do
                  div.absolute.inset_y(0).left(0).pl(3).flex.items_center.pointer_events_none do
                    # Email icon
                    text("✉️").text_color("gray-400")
                  end
                  input(
                    type: "email",
                    name: "email",
                    id: "email",
                    placeholder: "you@example.com",
                    required: true
                  ).block.w_full.pl(10).sm("text-sm").border_color("gray-300").rounded("md")
                   .focus_ring_color("indigo-500").focus_border_color("indigo-500")
                end
              end

              # Password with icon
              div do
                label(for: "password").block.text_size("sm").font_weight("medium").text_color("gray-700") do
                  text("Password")
                end
                div.mt(1).relative.rounded("md").shadow("sm") do
                  div.absolute.inset_y(0).left(0).pl(3).flex.items_center.pointer_events_none do
                    # Lock icon
                    text("🔒").text_color("gray-400")
                  end
                  input(
                    type: "password",
                    name: "password",
                    id: "password",
                    placeholder: "••••••••",
                    required: true
                  ).block.w_full.pl(10).sm("text-sm").border_color("gray-300").rounded("md")
                   .focus_ring_color("indigo-500").focus_border_color("indigo-500")
                end
              end

              # Remember me and forgot password
              div.flex.items_center.justify_between do
                div.flex.items_center do
                  input(
                    type: "checkbox",
                    name: "remember_me",
                    id: "remember_me"
                  ).h(4).w(4).text_color("indigo-600").focus_ring_color("indigo-500")
                   .border_color("gray-300").rounded
                  label(for: "remember_me").ml(2).block.text_size("sm").text_color("gray-900") do
                    text("Remember me")
                  end
                end

                div.text_size("sm") do
                  link("Forgot password?", destination: "#")
                    .font_weight("medium")
                    .text_color("indigo-600")
                    .hover_text_color("indigo-500")
                end
              end

              # Submit button with gradient
              div do
                button("Sign in", type: "submit")
                  .flex.w_full.justify_center
                  .rounded("md")
                  .bg_gradient_to_r.from("indigo-500").to("purple-600")
                  .px(4).py(2)
                  .text_size("sm").font_weight("medium")
                  .text_color("white")
                  .shadow("sm")
                  .hover_shadow("lg")
                  .transform.transition_all.duration("200")
                  .hover_scale("105")
                  .focus_outline_none
                  .focus_ring("2")
                  .focus_ring_offset("2")
                  .focus_ring_color("indigo-500")
              end

              # Divider
              div.mt(6) do
                div.relative do
                  div.absolute.inset(0).flex.items_center do
                    div.w_full.border_t.border_color("gray-300")
                  end
                  div.relative.flex.justify_center.text_size("sm") do
                    span.px(2).bg("white").text_color("gray-500") do
                      text("Or continue with")
                    end
                  end
                end
              end

              # Social login buttons
              div.mt(6).grid_class.grid_cols(2).gap(3) do
                button(type: "button")
                  .flex.w_full.justify_center
                  .items_center.gap(2)
                  .rounded("md")
                  .bg("white")
                  .px(4).py(2)
                  .text_size("sm").font_weight("medium")
                  .text_color("gray-700")
                  .shadow("sm")
                  .border.border_color("gray-300")
                  .hover_bg("gray-50") do
                  text("🌐 Google")
                end

                button(type: "button")
                  .flex.w_full.justify_center
                  .items_center.gap(2)
                  .rounded("md")
                  .bg("white")
                  .px(4).py(2)
                  .text_size("sm").font_weight("medium")
                  .text_color("gray-700")
                  .shadow("sm")
                  .border.border_color("gray-300")
                  .hover_bg("gray-50") do
                  text("🐙 GitHub")
                end
              end
            end
          end

          # Sign up link
          p.mt(10).text_center.text_size("sm").text_color("gray-600") do
            text("Not a member? ")
            link("Start your free trial", destination: "#")
              .font_weight("medium")
              .text_color("indigo-600")
              .hover_text_color("indigo-500")
          end
        end
      end
    end
  end
end
# Copyright 2025
