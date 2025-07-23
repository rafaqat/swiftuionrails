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
                        
                        input(
                          type: "email",
                          name: "login[email]",
                          id: "login_email",
                          placeholder: "Enter your email",
                          required: true
                        )
                        .w("full").px(3).py(2).border.border_color("gray-300").rounded("md").text_sm
                        .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
                        .data(
                          "login-dialog-target": "emailInput",
                          action: "input->login-dialog#updateFormData blur->login-dialog#validateEmail"
                        )
                        
                        # Email error message
                        div.hidden.mt(1).text_sm.text_color("red-600")
                          .data("login-dialog-target": "emailError") do
                          text("Email error message")
                        end
                      end
                      
                      # Password field
                      div.mb(4) do
                        label("Password", for: "login_password")
                          .block.text_sm.font_weight("medium").text_color("gray-700").mb(1)
                        
                        input(
                          type: "password",
                          name: "login[password]",
                          id: "login_password",
                          placeholder: "Enter your password",
                          required: true
                        )
                        .w("full").px(3).py(2).border.border_color("gray-300").rounded("md").text_sm
                        .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
                        .data(
                          "login-dialog-target": "passwordInput",
                          action: "input->login-dialog#updateFormData blur->login-dialog#validatePassword"
                        )
                        
                        # Password error message
                        div.hidden.mt(1).text_sm.text_color("red-600")
                          .data("login-dialog-target": "passwordError") do
                          text("Password error message")
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
                        input(
                          type: "checkbox",
                          name: "login[remember_me]",
                          id: "login_remember_me"
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
              
              # Load external Stimulus controller and styles
              load_login_dialog_assets
            end
          end
          
          private
          
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