# frozen_string_literal: true

class SimpleAuthStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Helpers
  include SwiftUIRails::DSL
  
  # Simple login form using pure DSL
  def simple_login(**kwargs)
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
               .focus("outline-none ring-2 ring-indigo-500 border-indigo-500")
            end
            
            # Password field
            div.mb(6) do
              div.flex.justify_between.mb(2) do
                label("Password", for: "password").block.text_size("sm").font_weight("medium").text_color("gray-700")
                link("Forgot password?", destination: "#").text_size("sm").text_color("indigo-600").hover("text-indigo-500")
              end
              input(
                type: "password",
                name: "password",
                id: "password",
                placeholder: "••••••••",
                required: true
              ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
               .focus("outline-none ring-2 ring-indigo-500 border-indigo-500")
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
              .hover("bg-indigo-700")
              .focus("outline-none ring-2 ring-offset-2 ring-indigo-500")
          end
          
          # Sign up link
          div.mt(6).text_center do
            text("Don't have an account? ").text_color("gray-600")
            link("Sign up", destination: "#").font_weight("medium").text_color("indigo-600").hover("text-indigo-500")
          end
        end
      end
    end
  end
  
  # Registration form
  def simple_register(**kwargs)
    swift_ui do
      div.flex.justify_center.items_center.min_h("screen").bg("gray-50") do
        div.w("full").max_w("md").bg("white").shadow("xl").rounded("lg").p(8) do
          # Title
          div.text_center.mb(8) do
            text("Create your account").text_size("2xl").font_weight("bold").text_color("gray-900")
          end
          
          # Form
          form(action: "/register", method: "POST") do
            # Name fields
            div.grid.grid_cols(2).gap(4).mb(4) do
              div do
                label("First name", for: "first_name").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
                input(
                  type: "text",
                  name: "first_name",
                  id: "first_name",
                  required: true
                ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
                 .focus("outline-none ring-2 ring-indigo-500")
              end
              
              div do
                label("Last name", for: "last_name").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
                input(
                  type: "text",
                  name: "last_name",
                  id: "last_name",
                  required: true
                ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
                 .focus("outline-none ring-2 ring-indigo-500")
              end
            end
            
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
               .focus("outline-none ring-2 ring-indigo-500")
            end
            
            # Password fields
            div.mb(4) do
              label("Password", for: "password").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
              input(
                type: "password",
                name: "password",
                id: "password",
                placeholder: "••••••••",
                required: true
              ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
               .focus("outline-none ring-2 ring-indigo-500")
            end
            
            div.mb(6) do
              label("Confirm password", for: "password_confirmation").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
              input(
                type: "password",
                name: "password_confirmation",
                id: "password_confirmation",
                placeholder: "••••••••",
                required: true
              ).w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
               .focus("outline-none ring-2 ring-indigo-500")
            end
            
            # Terms checkbox
            div.mb(6).flex.items_start do
              input(
                type: "checkbox",
                name: "agree_terms",
                id: "agree_terms",
                required: true
              ).mt(1).mr(2).h(4).w(4).text_color("indigo-600").rounded.border_color("gray-300")
               .focus("ring-indigo-500")
              
              label(for: "agree_terms").text_size("sm").text_color("gray-600") do
                text("I agree to the ")
                link("Terms", destination: "#").text_color("indigo-600").hover("text-indigo-500")
                text(" and ")
                link("Privacy Policy", destination: "#").text_color("indigo-600").hover("text-indigo-500")
              end
            end
            
            # Submit button
            button("Create account", type: "submit")
              .w("full")
              .py(2)
              .px(4)
              .bg("indigo-600")
              .text_color("white")
              .font_weight("medium")
              .rounded("md")
              .hover("bg-indigo-700")
              .focus("outline-none ring-2 ring-offset-2 ring-indigo-500")
          end
          
          # Sign in link
          div.mt(6).text_center do
            text("Already have an account? ").text_color("gray-600")
            link("Sign in", destination: "#").font_weight("medium").text_color("indigo-600").hover("text-indigo-500")
          end
        end
      end
    end
  end
  
  # Login with gradient styling
  def gradient_login(**kwargs)
    swift_ui do
      div.flex.justify_center.items_center.min_h("screen").bg("gradient-to-br from-purple-600 to-blue-600") do
        div.w("full").max_w("md").bg("white/95").tw("backdrop-blur-lg").shadow("2xl").rounded("xl").p(10) do
          # Logo
          div.text_center.mb(8) do
            div.h(20).w(20).bg("gradient-to-r from-purple-600 to-blue-600").rounded("full").mx("auto").mb(4).flex.items_center.justify_center.shadow("lg") do
              text("✨").text_size("3xl")
            end
            text("Welcome Back").text_size("3xl").font_weight("bold").text_color("gray-900").mb(2)
            text("Sign in to continue your journey").text_size("sm").text_color("gray-600")
          end
          
          # Form
          form(action: "/login", method: "POST") do
            # Email field with icon
            div.mb(6) do
              label("Email", for: "email").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
              div.relative do
                div.absolute.tw("inset-y-0").left(0).pl(3).flex.items_center.pointer_events_none do
                  text("📧").text_color("gray-400")
                end
                input(
                  type: "email",
                  name: "email",
                  id: "email",
                  placeholder: "you@example.com",
                  required: true
                ).w("full").pl(10).pr(3).py(3).border.border_color("gray-300").rounded("lg")
                 .focus("outline-none ring-2 ring-purple-500 border-purple-500")
                 .transition.duration(200)
              end
            end
            
            # Password field with icon
            div.mb(8) do
              label("Password", for: "password").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
              div.relative do
                div.absolute.tw("inset-y-0").left(0).pl(3).flex.items_center.pointer_events_none do
                  text("🔒").text_color("gray-400")
                end
                input(
                  type: "password",
                  name: "password",
                  id: "password",
                  placeholder: "••••••••",
                  required: true
                ).w("full").pl(10).pr(3).py(3).border.border_color("gray-300").rounded("lg")
                 .focus("outline-none ring-2 ring-purple-500 border-purple-500")
                 .transition.duration(200)
              end
            end
            
            # Submit button with gradient
            button("Sign in", type: "submit")
              .w("full")
              .py(3)
              .px(4)
              .bg("gradient-to-r from-purple-600 to-blue-600")
              .text_color("white")
              .font_weight("semibold")
              .rounded("lg")
              .tw("transform")
              .tw("transition-all")
              .duration(200)
              .hover("scale-105 shadow-lg")
              .focus("outline-none ring-2 ring-offset-2 ring-purple-500")
          end
          
          # Divider
          div.my(8).relative do
            div.absolute.inset(0).flex.items_center do
              div.w("full").border_t.border_color("gray-300")
            end
            div.relative.flex.justify_center.text_size("sm") do
              span.px(4).bg("white").text_color("gray-500") do
                text("Or continue with")
              end
            end
          end
          
          # Social buttons
          div.grid.grid_cols(2).gap(4) do
            button(type: "button")
              .flex.justify_center.items_center.gap(2)
              .w("full").py(2).px(4)
              .bg("white").border.border_color("gray-300")
              .rounded("lg")
              .hover("bg-gray-50")
              .transition.duration(200) do
              text("🌐")
              text("Google").font_weight("medium").text_color("gray-700")
            end
            
            button(type: "button")
              .flex.justify_center.items_center.gap(2)
              .w("full").py(2).px(4)
              .bg("gray-900")
              .rounded("lg")
              .hover("bg-gray-800")
              .transition.duration(200) do
              text("🐙")
              text("GitHub").font_weight("medium").text_color("white")
            end
          end
        end
      end
    end
  end
end