# frozen_string_literal: true

module SwiftUIRails
  module Component
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
          
          # Props for configuration
          prop :open, type: [TrueClass, FalseClass], default: false
          prop :login_url, type: String, default: '/login'
          prop :register_url, type: String, default: nil
          prop :close_url, type: String, default: nil
          prop :show_social, type: [TrueClass, FalseClass], default: false
          prop :social_providers, type: Array, default: ['google', 'github']
          prop :size, type: Symbol, default: :md # :sm, :md, :lg, :xl
          prop :errors, type: Hash, default: {}
          prop :form_data, type: Hash, default: { email: '', password: '', remember_me: false }
          
          # ViewComponent slots for customization  
          renders_one :header
          renders_many :footer_actions
          
          swift_ui do
            # Debug: Log form_data in development
            Rails.logger.debug "LoginDialog form_data: #{form_data.inspect}" if Rails.env.development?
            
            if open
              # Modal overlay with backdrop
              div.fixed.inset(0).bg("black").opacity(50).z(40).flex.items_center.justify_center.p(4)
                .data(
                  controller: "login-dialog",
                  action: "click->login-dialog#closeOnBackdrop",
                  "login-dialog-close-url-value": close_url
                ) do
                
                # Modal container (prevent backdrop clicks when clicking on modal)
                div.relative.bg("white").rounded("lg").shadow("2xl").z(50).w("full").max_w("md")
                  .data(
                    "login-dialog-target": "modal",
                    action: "click->login-dialog#stopPropagation"
                  ) do
                  
                  # Modal header
                  div.px(6).py(4).pt(6).pb(4).border_b.border_color("gray-200") do
                    div.flex.items_center.justify_between.mb(2) do
                      text("Welcome Back")
                        .font_size("xl")
                        .font_weight("semibold")
                        .text_color("gray-900")
                      
                      button("×")
                        .text_color("gray-400")
                        .hover_text_color("gray-600")
                        .text_size("2xl")
                        .leading("none")
                        .data(action: "click->login-dialog#close")
                    end
                    
                    # Subtitle
                    text("Sign in to your account")
                      .text_sm
                      .text_color("gray-500")
                  end
                  
                  # Modal body
                  div.p(6) do
                    # Error display placeholder
                    div.hidden.mb(4).p(4).bg("red-50").border.border_color("red-200").rounded("md")
                      .data("login-dialog-target": "errorBanner") do
                      text("Error messages will appear here")
                    end
                    
                    # Login form
                    form.space_y(4)
                      .data(
                        action: "submit->login-dialog#submitForm",
                        "login-dialog-url-value": login_url
                      ) do
                      
                      # Email field
                      div.mb(4) do
                        label("Email", for: "login_email")
                          .block.text_sm.font_weight("medium").text_color("gray-700").mb(1)
                        
                        # Debug email value
                        email_value = (form_data[:email] || form_data['email'] || '').to_s
                        Rails.logger.debug "Email value being set: #{email_value.inspect}" if Rails.env.development?
                        
                        input(
                          type: "email",
                          name: "login[email]",
                          id: "login_email",
                          placeholder: "Enter your email",
                          required: true,
                          value: email_value
                        )
                        .w("full").px(3).py(2).border.border_color("gray-300").rounded("md").text_sm
                        .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
                        .data(
                          "login-dialog-target": "emailInput",
                          action: "input->login-dialog#updateFormData blur->login-dialog#validateEmail"
                        )
                        
                        # Email error message
                        if errors[:email] && errors[:email].any?
                          div.mt(1).text_sm.text_color("red-600")
                            .data("login-dialog-target": "emailError") do
                            text(errors[:email].first)
                          end
                        else
                          div.hidden.mt(1).text_sm.text_color("red-600")
                            .data("login-dialog-target": "emailError") do
                            text("Email error message")
                          end
                        end
                      end
                      
                      # Password field
                      div.mb(4) do
                        label("Password", for: "login_password")
                          .block.text_sm.font_weight("medium").text_color("gray-700").mb(1)
                        
                        # Debug password value  
                        password_value = (form_data[:password] || form_data['password'] || '').to_s
                        Rails.logger.debug "Password value being set: #{password_value.inspect}" if Rails.env.development?
                        
                        input(
                          type: "password",
                          name: "login[password]",
                          id: "login_password",
                          placeholder: "Enter your password",
                          required: true,
                          value: password_value
                        )
                        .w("full").px(3).py(2).border.border_color("gray-300").rounded("md").text_sm
                        .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
                        .data(
                          "login-dialog-target": "passwordInput",
                          action: "input->login-dialog#updateFormData blur->login-dialog#validatePassword"
                        )
                        
                        # Password error message
                        if errors[:password] && errors[:password].any?
                          div.mt(1).text_sm.text_color("red-600")
                            .data("login-dialog-target": "passwordError") do
                            text(errors[:password].first)
                          end
                        else
                          div.hidden.mt(1).text_sm.text_color("red-600")
                            .data("login-dialog-target": "passwordError") do
                            text("Password error message")
                          end
                        end
                        
                        # Password strength indicator
                        div.mt(2).data("login-dialog-target": "passwordStrength") do
                          div.mb(2) do
                            text("Password strength:").text_xs.text_color("gray-500").font_weight("medium")
                            text("Weak").text_xs.text_color("red-600").font_weight("medium").ml(2)
                              .data("login-dialog-target": "strengthText strengthIndicator")
                          end
                          div.h(1).bg("gray-200").rounded("sm").overflow("hidden") do
                            div.h("full").w(0).bg("red-600").transition_all.duration(300)
                              .data("login-dialog-target": "strengthBar")
                          end
                        end
                        
                        # Password requirements
                        div.mt(3).hidden.data("login-dialog-target": "requirements") do
                          text("Password must have:").text_xs.text_color("gray-500").font_weight("medium").mb(2).block
                          
                          # Length requirement
                          div.flex.items_center.mb(1) do
                            div.w(3).h(3).rounded_full.bg("gray-300").mr(2)
                              .data("login-dialog-target": "requirementLengthIcon")
                            text("At least 8 characters").text_xs.text_color("gray-500")
                          end
                          
                          # Special character requirement
                          div.flex.items_center.mb(1) do
                            div.w(3).h(3).rounded_full.bg("gray-300").mr(2)
                              .data("login-dialog-target": "requirementSpecialIcon")
                            text("At least one special character").text_xs.text_color("gray-500")
                          end
                          
                          # Number requirement
                          div.flex.items_center.mb(1) do
                            div.w(3).h(3).rounded_full.bg("gray-300").mr(2)
                              .data("login-dialog-target": "requirementNumberIcon")
                            text("At least one number").text_xs.text_color("gray-500")
                          end
                          
                          # No repeating characters requirement
                          div.flex.items_center.mb(1) do
                            div.w(3).h(3).rounded_full.bg("gray-300").mr(2)
                              .data("login-dialog-target": "requirementRepeatingIcon")
                            text("No repeating characters").text_xs.text_color("gray-500")
                          end
                          
                          # No sequential characters requirement
                          div.flex.items_center do
                            div.w(3).h(3).rounded_full.bg("gray-300").mr(2)
                              .data("login-dialog-target": "requirementSequentialIcon")
                            text("No sequential characters").text_xs.text_color("gray-500")
                          end
                        end
                      end
                      
                      # Remember me checkbox
                      div.flex.items_center.mb(4) do
                        # Debug checkbox value
                        checkbox_checked = (form_data[:remember_me] || form_data['remember_me']) == true || (form_data[:remember_me] || form_data['remember_me']) == 'true'
                        Rails.logger.debug "Checkbox checked: #{checkbox_checked.inspect}, form_data remember_me: #{(form_data[:remember_me] || form_data['remember_me']).inspect}" if Rails.env.development?
                        
                        input(
                          type: "checkbox",
                          name: "login[remember_me]",
                          id: "login_remember_me",
                          checked: checkbox_checked
                        )
                        .h(4).w(4).text_color("blue-600").rounded.mr(2)
                        .data(
                          "login-dialog-target": "rememberInput",
                          action: "change->login-dialog#updateFormData"
                        )
                        label("Remember me", for: "login_remember_me")
                          .text_sm.text_color("gray-700")
                      end
                      
                      # Submit button
                      button("Sign In", type: "submit")
                        .w("full").px(4).py(3).bg("blue-600").text_color("white")
                        .font_weight("medium").rounded("md").border("none")
                        .cursor("pointer").transition.hover_bg("blue-700")
                        .data("login-dialog-target": "submitButton")
                    end
                    
                    # Social login section (conditional)
                    if show_social
                      div.mt(6) do
                        # Divider with "Or" text
                        div.relative.my(6) do
                          div.absolute.inset(0).flex.items_center do
                            div.w("full").border_t.border_color("gray-300")
                          end
                          div.relative.flex.justify_center.text_sm do
                            span.px(2).bg("white").text_color("gray-500") do
                              text("Or continue with")
                            end
                          end
                        end
                        
                        # Social login buttons
                        div.space_y(3) do
                          social_providers.each do |provider|
                            link(destination: "/auth/#{provider}")
                              .w("full").inline_flex.justify_center.py(2).px(4)
                              .border.border_color("gray-300").rounded("md").shadow("sm")
                              .bg("white").text_sm.font_weight("medium").text_color("gray-500")
                              .hover_bg("gray-50") do
                              
                              # Provider icon and text
                              case provider
                              when 'google'
                                span.mr(2) do
                                  raw(google_icon_svg)
                                end
                                text("Continue with Google")
                              when 'github'
                                span.mr(2) do
                                  raw(github_icon_svg)
                                end
                                text("Continue with GitHub")
                              when 'twitter'
                                span.mr(2) do
                                  raw(twitter_icon_svg)
                                end
                                text("Continue with Twitter")
                              when 'facebook'
                                span.mr(2) do
                                  raw(facebook_icon_svg)
                                end
                                text("Continue with Facebook")
                              else
                                span.mr(2) do
                                  raw(generic_social_icon_svg)
                                end
                                text("Continue with #{provider.capitalize}")
                              end
                            end
                          end
                        end
                      end
                    end
                    
                    # Register link
                    if register_url
                      div.text_center.mt(4) do
                        text("Don't have an account? ").text_sm.text_color("gray-500")
                        link("Sign up", destination: register_url)
                          .text_sm.text_color("blue-600").font_weight("medium").no_underline.hover_text_color("blue-500")
                      end
                    end
                  end
                end
              end
              
              # Stimulus controller loaded via importmap - no embedded assets needed
            end
          end
          
          private
          
          # Social provider SVG icons
          def google_icon_svg
            <<~SVG
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
            SVG
          end

          def github_icon_svg
            <<~SVG
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
              </svg>
            SVG
          end

          def twitter_icon_svg
            <<~SVG
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
              </svg>
            SVG
          end

          def facebook_icon_svg
            <<~SVG
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
              </svg>
            SVG
          end

          def generic_social_icon_svg
            <<~SVG
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
              </svg>
            SVG
          end
          
          # Note: Unused helper methods removed per CodeRabbit feedback
          
          # Component sections (used by older unused methods - can be removed)
          # The error display, social login, and form are now inline in the main DSL block
          
          # All these helper methods are unused since the UI is defined inline in the main DSL block
          # Removed per CodeRabbit feedback to reduce code duplication and maintenance burden
          
          # Helper methods (removed unused methods per CodeRabbit feedback)
          
          # Load external assets for the login dialog
          def load_login_dialog_assets
            # Note: In a proper Rails 8 setup with Propshaft:
            # 1. CSS animations should be in app/assets/stylesheets/login_dialog.css
            # 2. Stimulus controller loaded via importmap in config/importmap.rb
            # 3. This method would only ensure the controller is properly registered
            
            # For now, we only add minimal inline styles that are absolutely necessary
            # and cannot be handled by Tailwind CSS utilities
            if Rails.env.development?
              # Use content_tag to generate style tag instead of conflicting with Tailwind .style() modifier
              content_tag(:style, type: "text/css") do
                raw <<~CSS
                  /* Only essential animations that can't be done with Tailwind */
                  @keyframes fadeIn {
                    from { opacity: 0; transform: scale(0.95); }
                    to { opacity: 1; transform: scale(1); }
                  }
                  
                  .login-dialog-modal {
                    animation: fadeIn 0.2s ease-out;
                  }
                CSS
              end
            end
            
            # Stimulus controller should be loaded via importmap, not inline scripts
            # In production, ensure the controller is available via asset pipeline
          end
        end
      end
    end
  end
end