# frozen_string_literal: true

module SwiftUIRails
  module Components
    module Composed
      module Auth
        # LoginDialogComponent - A complete login dialog with built-in functionality
        #
        # Features:
        # - Modal overlay with backdrop
        # - Form validation and submission
        # - Error handling and display
        # - Social login integration
        # - Progressive enhancement
        # - Stimulus controller integration
        # - Customizable through slots and props
        #
        # Usage:
        #   <%= render LoginDialogComponent.new(
        #     login_url: login_path,
        #     register_url: register_path,
        #     show_social: true
        #   ) do |dialog| %>
        #     <% dialog.with_header do %>
        #       Welcome Back
        #     <% end %>
        #     <% dialog.with_footer_action type: :link do %>
        #       <%= link_to "Forgot Password?", forgot_password_path %>
        #     <% end %>
        #   <% end %>
        class LoginDialogComponent < SwiftUIRails::Component::Base
          include StatefulComponent
          
          # Props for configuration
          prop :open, type: [TrueClass, FalseClass], default: false
          prop :login_url, type: String, required: true
          prop :register_url, type: String, default: nil
          prop :close_url, type: String, default: nil
          prop :show_social, type: [TrueClass, FalseClass], default: false
          prop :social_providers, type: Array, default: ['google', 'github']
          prop :size, type: Symbol, default: :md # :sm, :md, :lg, :xl
          
          # State management
          state :loading, default: false
          state :errors, default: {}
          state :form_data, default: { email: '', password: '', remember_me: false }
          
          # Computed properties
          computed :has_errors do
            errors.any?
          end
          
          computed :submit_disabled do
            loading || form_data[:email].blank? || form_data[:password].blank?
          end
          
          # Polymorphic slots for customization
          slot :header, default: -> { default_header }
          slot :social_buttons, default: -> { default_social_buttons }
          slot :form_fields, types: {
            email: ->(placeholder: "Enter your email") { email_field(placeholder: placeholder) },
            password: ->(placeholder: "Enter your password") { password_field(placeholder: placeholder) },
            custom: ->(field_type:, **options) { custom_field(field_type, **options) }
          }
          slot :footer_actions, many: true, types: {
            button: ->(text:, variant: :primary, **options) { action_button(text, variant, **options) },
            link: ->(text:, url:, **options) { action_link(text, url, **options) }
          }
          
          # Effects for reactive behavior
          effect :loading do |loading_state|
            update_submit_button_state(loading_state)
          end
          
          swift_ui do
            if open
              modal_overlay do
                modal_container do
                  modal_header
                  modal_body
                  modal_footer
                end
              end
            end
          end
          
          private
          
          # Modal structure methods
          def modal_overlay(&block)
            div.fixed.inset(0).bg("black").opacity(50).z(40)
              .data(
                controller: "login-dialog",
                action: "click->login-dialog#closeOnBackdrop",
                "login-dialog-close-url-value": close_url
              ) do
              yield
            end
          end
          
          def modal_container(&block)
            div.fixed.top("50%").left("50%").transform("translate(-50%, -50%)")
              .bg("white").rounded("lg").shadow("xl").p(0).z(50)
              .tap { |container| apply_modal_size(container) }
              .data("login-dialog-target": "modal") do
              yield
            end
          end
          
          def modal_header
            div.px(6).py(4).border_b.border_color("gray-200") do
              hstack do
                div.flex_1 do
                  render_header { default_header }
                end
                
                # Close button
                close_button
              end
            end
          end
          
          def modal_body
            div.px(6).py(6) do
              # Error display
              if has_errors
                error_banner
              end
              
              # Social login section
              if show_social
                social_login_section
                divider_with_text("or")
              end
              
              # Login form
              login_form
            end
          end
          
          def modal_footer
            div.px(6).py(4).bg("gray-50").rounded_b("lg") do
              vstack(spacing: 4) do
                # Submit button
                submit_button
                
                # Footer actions
                if footer_actions.any?
                  footer_actions_section
                end
                
                # Register link
                if register_url
                  register_link_section
                end
              end
            end
          end
          
          # Component sections
          def error_banner
            div.mb(4).p(4).bg("red-50").border.border_color("red-200").rounded("md") do
              vstack(spacing: 2) do
                hstack(spacing: 2) do
                  icon("exclamation-triangle").text_color("red-400").size(20)
                  text("Please fix the following errors:").text_color("red-800").font_weight("medium")
                end
                
                vstack(spacing: 1) do
                  errors.each do |field, messages|
                    Array(messages).each do |message|
                      text("• #{field.humanize}: #{message}").text_color("red-700").text_sm
                    end
                  end
                end
              end
            end
          end
          
          def social_login_section
            vstack(spacing: 3) do
              social_providers.each do |provider|
                social_login_button(provider)
              end
            end.mb(6)
          end
          
          def social_login_button(provider)
            button do
              hstack(spacing: 3, justify: :center) do
                social_icon(provider)
                text("Continue with #{provider.humanize}")
              end
            end
            .w("full")
            .py(3)
            .border
            .border_color("gray-300")
            .rounded("md")
            .hover_bg("gray-50")
            .transition
            .data(
              action: "click->login-dialog#socialLogin",
              "login-dialog-provider-param": provider
            )
          end
          
          def divider_with_text(text)
            div.relative.my(6) do
              div.absolute.inset(0).flex.items_center do
                div.w("full").border_t.border_color("gray-300")
              end
              div.relative.flex.justify_center.text_sm do
                span.px(2).bg("white").text_color("gray-500") { text(text) }
              end
            end
          end
          
          def login_form
            form.space_y(4)
              .data(
                controller: "form-validation",
                action: "submit->login-dialog#submitForm",
                "form-validation-url-value": login_url
              ) do
              
              # Email field
              form_field_group(:email) do
                email_input
              end
              
              # Password field
              form_field_group(:password) do
                password_input
              end
              
              # Remember me checkbox
              remember_me_field
            end
          end
          
          def form_field_group(field_name, &block)
            div.space_y(1) do
              label(field_name.to_s.humanize, for: "login_#{field_name}")
                .text_sm.font_weight("medium").text_color("gray-700")
              
              yield
              
              # Field-specific errors
              if errors[field_name]
                text(errors[field_name].first)
                  .text_sm.text_color("red-600").mt(1)
              end
            end
          end
          
          def email_input
            textfield(
              name: "login[email]",
              id: "login_email",
              type: "email",
              value: form_data[:email],
              placeholder: "Enter your email",
              required: true
            )
            .w("full")
            .px(3).py(2)
            .border.border_color("gray-300")
            .rounded("md")
            .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
            .data(
              "login-dialog-target": "emailInput",
              action: "input->login-dialog#updateFormData"
            )
          end
          
          def password_input
            textfield(
              name: "login[password]",
              id: "login_password",
              type: "password",
              placeholder: "Enter your password",
              required: true
            )
            .w("full")
            .px(3).py(2)
            .border.border_color("gray-300")
            .rounded("md")
            .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
            .data(
              "login-dialog-target": "passwordInput",
              action: "input->login-dialog#updateFormData"
            )
          end
          
          def remember_me_field
            div.flex.items_center do
              input(
                type: "checkbox",
                name: "login[remember_me]",
                id: "login_remember_me",
                checked: form_data[:remember_me]
              )
              .h(4).w(4).text_color("blue-600").rounded
              .data(
                "login-dialog-target": "rememberInput",
                action: "change->login-dialog#updateFormData"
              )
              
              label("Remember me", for: "login_remember_me")
                .ml(2).text_sm.text_color("gray-700")
            end
          end
          
          def submit_button
            button("Sign In", type: "submit")
              .w("full")
              .py(3)
              .px(4)
              .bg(submit_disabled ? "gray-400" : "blue-600")
              .text_color("white")
              .font_weight("medium")
              .rounded("md")
              .hover_bg(submit_disabled ? "gray-400" : "blue-700")
              .transition
              .tap { |btn| btn.cursor("not-allowed") if submit_disabled }
              .data(
                "login-dialog-target": "submitButton",
                action: "click->login-dialog#submitForm"
              )
              .disabled(submit_disabled)
          end
          
          def footer_actions_section
            hstack(spacing: 4, justify: :center) do
              footer_actions.each { |action| action }
            end
          end
          
          def register_link_section
            div.text_center.mt(4) do
              text("Don't have an account? ").text_sm.text_color("gray-600")
              link("Sign up", destination: register_url)
                .text_sm.text_color("blue-600").hover_text_color("blue-500")
                .font_weight("medium")
            end
          end
          
          def close_button
            button("×")
              .text_color("gray-400")
              .hover_text_color("gray-600")
              .text_size("2xl")
              .leading_none
              .data(action: "click->login-dialog#close")
          end
          
          # Default slot implementations
          def default_header
            text("Sign In").font_size("xl").font_weight("semibold").text_color("gray-900")
          end
          
          def default_social_buttons
            render_social_buttons if show_social
          end
          
          # Helper methods
          def apply_modal_size(container)
            case size
            when :sm
              container.max_w("sm").w("full")
            when :md
              container.max_w("md").w("full")
            when :lg
              container.max_w("lg").w("full")
            when :xl
              container.max_w("xl").w("full")
            end
          end
          
          def social_icon(provider)
            case provider.to_s
            when 'google'
              icon('google').size(20)
            when 'github'
              icon('github').size(20)
            when 'facebook'
              icon('facebook').size(20)
            else
              icon('user-circle').size(20)
            end
          end
          
          def update_submit_button_state(loading_state)
            # This would trigger UI updates via Stimulus
            # Implementation depends on the Stimulus controller
          end
        end
      end
    end
  end
end