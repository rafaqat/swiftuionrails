# frozen_string_literal: true

# Copyright 2025

class RegisterFormComponent < SwiftUIRails::Component::Base
  prop :action_path, type: String, default: "/register"
  prop :logo_url, type: String, default: "https://tailwindcss.com/plus-assets/img/logos/mark.svg?color=indigo&shade=600"
  prop :company_name, type: String, default: "Your Company"
  prop :show_login_link, type: [ TrueClass, FalseClass ], default: true
  prop :login_path, type: String, default: "/login"
  prop :show_terms, type: [ TrueClass, FalseClass ], default: true
  prop :terms_path, type: String, default: "#"
  prop :privacy_path, type: String, default: "#"
  prop :csrf_token, type: String, default: nil
  prop :require_name, type: [ TrueClass, FalseClass ], default: true

  swift_ui do
    div.flex.min_h_full.flex_col.justify_center.px(6).py(12).lg_px(8) do
      # Logo and title section
      div.sm_mx_auto.sm_w_full.sm_max_w_sm do
        image(
          src: logo_url,
          alt: company_name
        ).mx_auto.h(10).w_auto

        h2.mt(10).text_center.text_size("2xl").leading(9).font_weight("bold").tracking_tight.text_color("gray-900") do
          text("Create your account")
        end
      end

      # Form section
      div.mt(10).sm_mx_auto.sm_w_full.sm_max_w_sm do
        form(action: action_path, method: "POST").space_y(6) do
          # CSRF token if provided
          if csrf_token
            input(type: "hidden", name: "authenticity_token", value: csrf_token)
          end

          # Name fields (optional)
          if require_name
            div.grid.grid_cols(2).gap(4) do
              # First name
              div do
                label(for: "first_name").block.text_size("sm").leading(6).font_weight("medium").text_color("gray-900") do
                  text("First name")
                end
                div.mt(2) do
                  input(
                    type: "text",
                    name: "first_name",
                    id: "first_name",
                    autocomplete: "given-name",
                    required: true
                  ).block.w_full.rounded("md").bg("white").px(3).py(1.5)
                   .text_size("base").text_color("gray-900")
                   .outline("1").outline_offset("-1").outline_color("gray-300")
                   .placeholder("text-gray-400")
                   .focus_outline("2").focus_outline_offset("-2").focus_outline_color("indigo-600")
                   .sm_text_size("sm").sm_leading(6)
                end
              end

              # Last name
              div do
                label(for: "last_name").block.text_size("sm").leading(6).font_weight("medium").text_color("gray-900") do
                  text("Last name")
                end
                div.mt(2) do
                  input(
                    type: "text",
                    name: "last_name",
                    id: "last_name",
                    autocomplete: "family-name",
                    required: true
                  ).block.w_full.rounded("md").bg("white").px(3).py(1.5)
                   .text_size("base").text_color("gray-900")
                   .outline("1").outline_offset("-1").outline_color("gray-300")
                   .placeholder("text-gray-400")
                   .focus_outline("2").focus_outline_offset("-2").focus_outline_color("indigo-600")
                   .sm_text_size("sm").sm_leading(6)
                end
              end
            end
          end

          # Email field
          div do
            label(for: "email").block.text_size("sm").leading(6).font_weight("medium").text_color("gray-900") do
              text("Email address")
            end
            div.mt(2) do
              input(
                type: "email",
                name: "email",
                id: "email",
                autocomplete: "email",
                required: true
              ).block.w_full.rounded("md").bg("white").px(3).py(1.5)
               .text_size("base").text_color("gray-900")
               .outline("1").outline_offset("-1").outline_color("gray-300")
               .placeholder("text-gray-400")
               .focus_outline("2").focus_outline_offset("-2").focus_outline_color("indigo-600")
               .sm_text_size("sm").sm_leading(6)
            end
          end

          # Password field
          div do
            label(for: "password").block.text_size("sm").leading(6).font_weight("medium").text_color("gray-900") do
              text("Password")
            end
            div.mt(2) do
              input(
                type: "password",
                name: "password",
                id: "password",
                autocomplete: "new-password",
                required: true
              ).block.w_full.rounded("md").bg("white").px(3).py(1.5)
               .text_size("base").text_color("gray-900")
               .outline("1").outline_offset("-1").outline_color("gray-300")
               .placeholder("text-gray-400")
               .focus_outline("2").focus_outline_offset("-2").focus_outline_color("indigo-600")
               .sm_text_size("sm").sm_leading(6)
            end
          end

          # Password confirmation field
          div do
            label(for: "password_confirmation").block.text_size("sm").leading(6).font_weight("medium").text_color("gray-900") do
              text("Confirm password")
            end
            div.mt(2) do
              input(
                type: "password",
                name: "password_confirmation",
                id: "password_confirmation",
                autocomplete: "new-password",
                required: true
              ).block.w_full.rounded("md").bg("white").px(3).py(1.5)
               .text_size("base").text_color("gray-900")
               .outline("1").outline_offset("-1").outline_color("gray-300")
               .placeholder("text-gray-400")
               .focus_outline("2").focus_outline_offset("-2").focus_outline_color("indigo-600")
               .sm_text_size("sm").sm_leading(6)
            end
          end

          # Terms and conditions
          if show_terms
            div.flex.items_start do
              div.flex.items_center.h(5) do
                input(
                  type: "checkbox",
                  name: "agree_terms",
                  id: "agree_terms",
                  required: true
                ).h(4).w(4).rounded.border_color("gray-300").text_color("indigo-600")
                 .focus_ring_color("indigo-500")
              end
              div.ml(3).text_size("sm") do
                label(for: "agree_terms").text_color("gray-600") do
                  text("I agree to the ")
                  link("Terms", destination: terms_path)
                    .font_weight("medium")
                    .text_color("indigo-600")
                    .hover_text_color("indigo-500")
                  text(" and ")
                  link("Privacy Policy", destination: privacy_path)
                    .font_weight("medium")
                    .text_color("indigo-600")
                    .hover_text_color("indigo-500")
                end
              end
            end
          end

          # Submit button
          div do
            button("Create account", type: "submit")
              .flex.w_full.justify_center
              .rounded("md")
              .bg("indigo-600")
              .px(3).py(1.5)
              .text_size("sm").leading(6)
              .font_weight("semibold")
              .text_color("white")
              .shadow("xs")
              .hover_bg("indigo-500")
              .focus_visible_outline("2")
              .focus_visible_outline_offset("2")
              .focus_visible_outline_color("indigo-600")
          end
        end

        # Login link
        if show_login_link
          p.mt(10).text_center.text_size("sm").leading(6).text_color("gray-500") do
            text("Already have an account? ")
            link("Sign in", destination: login_path)
              .font_weight("semibold")
              .text_color("indigo-600")
              .hover_text_color("indigo-500")
          end
        end
      end
    end
  end
end
# Copyright 2025
