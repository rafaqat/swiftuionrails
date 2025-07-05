# frozen_string_literal: true

class LoginFormComponent < SwiftUIRails::Component::Base
  prop :action_path, type: String, default: "/login"
  prop :logo_url, type: String, default: "https://tailwindcss.com/plus-assets/img/logos/mark.svg?color=indigo&shade=600"
  prop :company_name, type: String, default: "Your Company"
  prop :show_forgot_password, type: [TrueClass, FalseClass], default: true
  prop :show_signup_link, type: [TrueClass, FalseClass], default: true
  prop :forgot_password_path, type: String, default: "#"
  prop :signup_path, type: String, default: "#"
  prop :csrf_token, type: String, default: nil
  
  swift_ui do
    div.flex.tw("min-h-full flex-col").justify_center.px(6).py(12).tw("lg:px-8") do
      # Logo and title section
      div.sm_mx_auto.sm_w_full.sm_max_w_sm do
        image(
          src: logo_url, 
          alt: company_name
        ).mx_auto.h(10).w_auto
        
        h2.mt(10).text_center.text_size("2xl").leading(9).font_weight("bold").tracking_tight.text_color("gray-900") do
          text("Sign in to your account")
        end
      end
      
      # Form section
      div.mt(10).sm_mx_auto.sm_w_full.sm_max_w_sm do
        form(action: action_path, method: "POST").space_y(6) do
          # CSRF token if provided
          if csrf_token
            input(type: "hidden", name: "authenticity_token", value: csrf_token)
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
            div.flex.items_center.justify_between do
              label(for: "password").block.text_size("sm").leading(6).font_weight("medium").text_color("gray-900") do
                text("Password")
              end
              if show_forgot_password
                div.text_size("sm") do
                  link("Forgot password?", destination: forgot_password_path)
                    .font_weight("semibold")
                    .text_color("indigo-600")
                    .hover_text_color("indigo-500")
                end
              end
            end
            div.mt(2) do
              input(
                type: "password",
                name: "password",
                id: "password",
                autocomplete: "current-password",
                required: true
              ).block.w_full.rounded("md").bg("white").px(3).py(1.5)
               .text_size("base").text_color("gray-900")
               .outline("1").outline_offset("-1").outline_color("gray-300")
               .placeholder("text-gray-400")
               .focus_outline("2").focus_outline_offset("-2").focus_outline_color("indigo-600")
               .sm_text_size("sm").sm_leading(6)
            end
          end
          
          # Submit button
          div do
            button("Sign in", type: "submit")
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
        
        # Sign up link
        if show_signup_link
          p.mt(10).text_center.text_size("sm").leading(6).text_color("gray-500") do
            text("Not a member? ")
            link("Start a 14 day free trial", destination: signup_path)
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
