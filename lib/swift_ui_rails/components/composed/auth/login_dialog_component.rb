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
                  action: "click->login-dialog#closeOnBackdrop".html_safe,
                  "login-dialog-close-url-value": close_url
                ) do
                
                # Modal container (prevent backdrop clicks when clicking on modal)
                div.relative.bg("white").rounded("lg").shadow("2xl").z(50).w("full").max_w("md")
                  .data(
                    "login-dialog-target": "modal",
                    action: "click->login-dialog#stopPropagation".html_safe
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
                        .data(action: "click->login-dialog#close".html_safe)
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
                          div.h(1).bg("gray-200").rounded_sm.overflow("hidden") do
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
              
              # Embedded Stimulus script
              embedded_stimulus_script
            end
          end
          
          private
          
          # Modal structure methods
          def modal_overlay(&block)
            div.fixed.inset(0).bg("red-500").z(40)
              .data(
                controller: "login-dialog",
                action: "click->login-dialog#closeOnBackdrop".html_safe,
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
                  header || default_header
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
                  icon("exclamation-triangle").text_color("red-400").width(5).height(5)
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
              action: "click->login-dialog#socialLogin".html_safe,
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
                action: "submit->login-dialog#submitForm".html_safe,
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
              action: "input->login-dialog#updateFormData blur->login-dialog#validateEmail".html_safe
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
              action: "input->login-dialog#updateFormData blur->login-dialog#validatePassword".html_safe
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
                action: "change->login-dialog#updateFormData".html_safe
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
                action: "click->login-dialog#submitForm".html_safe
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
              .leading("none")
              .data(action: "click->login-dialog#close".html_safe)
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
              icon('google').width(5).height(5)
            when 'github'
              icon('github').width(5).height(5)
            when 'facebook'
              icon('facebook').width(5).height(5)
            else
              icon('user-circle').width(5).height(5)
            end
          end
          
          # Helper methods to replace computed properties
          def has_errors
            errors.any?
          end
          
          def submit_disabled
            form_data[:email].blank? || form_data[:password].blank?
          end
          
          def embedded_stimulus_script
            script do
              <<~JAVASCRIPT.html_safe
                // Auto-register the LoginDialog Stimulus controller
                if (window.Stimulus && !window.Stimulus.controllers.has("login-dialog")) {
                  const { Controller } = window.Stimulus;
                  
                  class LoginDialogController extends Controller {
                    static targets = [
                      "modal", "form", "emailInput", "passwordInput", "rememberInput", "submitButton",
                      "emailError", "passwordError", "emailIcon", "emailSuccessIcon", "errorBanner",
                      "passwordStrength", "strengthText", "strengthBar", "strengthIndicator", "requirements",
                      "requirementLengthIcon", "requirementSpecialIcon", "requirementNumberIcon",
                      "requirementRepeatingIcon", "requirementSequentialIcon"
                    ];
                    
                    static values = {
                      closeUrl: String,
                      loginUrl: String
                    };
                    
                    connect() {
                      this.isSubmitting = false;
                      this.validationState = {
                        email: false,
                        password: false
                      };
                      
                      // Password requirements state
                      this.passwordRequirements = {
                        length: false,
                        special: false,
                        number: false,
                        repeating: false,
                        sequential: false
                      };
                      
                      // Common passwords list (simplified)
                      this.commonPasswords = [
                        'password', '123456', '123456789', 'password123', 'admin',
                        'qwerty', 'letmein', 'welcome', 'monkey', '1234567890'
                      ];
                      
                      // Set up escape key listener
                      this.boundEscapeHandler = this.handleEscape.bind(this);
                      document.addEventListener("keydown", this.boundEscapeHandler);
                      
                      // Focus email input
                      if (this.hasEmailInputTarget) {
                        setTimeout(() => this.emailInputTarget.focus(), 100);
                      }
                      
                      // Show password requirements on password focus
                      if (this.hasPasswordInputTarget && this.hasRequirementsTarget) {
                        this.passwordInputTarget.addEventListener('focus', () => {
                          this.requirementsTarget.style.display = 'block';
                        });
                      }
                      
                      // Prevent body scroll
                      document.body.style.overflow = 'hidden';
                    }
                    
                    disconnect() {
                      document.removeEventListener("keydown", this.boundEscapeHandler);
                      document.body.style.overflow = '';
                    }
                    
                    // Modal control methods
                    close() {
                      window.location.href = this.closeUrlValue;
                    }
                    
                    closeOnBackdrop(event) {
                      if (event.target === event.currentTarget) {
                        this.close();
                      }
                    }
                    
                    handleEscape(event) {
                      if (event.key === 'Escape') {
                        this.close();
                      }
                    }
                    
                    // Form validation
                    validateEmail() {
                      const email = this.emailInputTarget.value.trim();
                      const isValid = email && /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email);
                      
                      this.validationState.email = isValid;
                      
                      // Show/hide email error
                      if (this.hasEmailErrorTarget) {
                        if (!isValid && email.length > 0) {
                          this.emailErrorTarget.style.display = 'block';
                          this.emailErrorTarget.textContent = 'Please enter a valid email address';
                        } else {
                          this.emailErrorTarget.style.display = 'none';
                        }
                      }
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    validatePassword() {
                      const password = this.passwordInputTarget.value;
                      
                      // Check individual requirements
                      this.passwordRequirements.length = password.length >= 8;
                      this.passwordRequirements.special = /[!@#$%^&*(),.?":{}|<>]/.test(password);
                      this.passwordRequirements.number = /\\d/.test(password);
                      this.passwordRequirements.repeating = !this.hasRepeatingCharacters(password);
                      this.passwordRequirements.sequential = !this.hasSequentialCharacters(password);
                      
                      // Check for common passwords
                      const isCommonPassword = this.commonPasswords.includes(password.toLowerCase());
                      
                      // Update requirement icons
                      this.updateRequirementIcon('requirementLengthIcon', this.passwordRequirements.length);
                      this.updateRequirementIcon('requirementSpecialIcon', this.passwordRequirements.special);
                      this.updateRequirementIcon('requirementNumberIcon', this.passwordRequirements.number);
                      this.updateRequirementIcon('requirementRepeatingIcon', this.passwordRequirements.repeating);
                      this.updateRequirementIcon('requirementSequentialIcon', this.passwordRequirements.sequential);
                      
                      // Calculate password strength
                      const strength = this.calculatePasswordStrength(password);
                      this.updatePasswordStrength(strength);
                      
                      // Overall password validity
                      const isValid = Object.values(this.passwordRequirements).every(req => req) && !isCommonPassword;
                      this.validationState.password = isValid;
                      
                      // Show/hide password error
                      if (this.hasPasswordErrorTarget) {
                        if (!isValid && password.length > 0) {
                          let errorMsg = '';
                          if (isCommonPassword) {
                            errorMsg = 'This password is too common. Please choose a more secure password.';
                          } else if (!this.passwordRequirements.length) {
                            errorMsg = 'Password must be at least 8 characters long';
                          } else if (!this.passwordRequirements.special) {
                            errorMsg = 'Password must contain at least one special character';
                          } else if (!this.passwordRequirements.number) {
                            errorMsg = 'Password must contain at least one number';
                          } else if (!this.passwordRequirements.repeating) {
                            errorMsg = 'Password cannot contain repeating characters';
                          } else if (!this.passwordRequirements.sequential) {
                            errorMsg = 'Password cannot contain sequential characters';
                          }
                          this.passwordErrorTarget.style.display = 'block';
                          this.passwordErrorTarget.textContent = errorMsg;
                        } else {
                          this.passwordErrorTarget.style.display = 'none';
                        }
                      }
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    updateFormData() {
                      // Update form validation
                      this.validateEmail();
                      this.validatePassword();
                    }
                    
                    updateSubmitButton() {
                      const allValid = this.validationState.email && this.validationState.password;
                      if (this.hasSubmitButtonTarget) {
                        this.submitButtonTarget.disabled = !allValid || this.isSubmitting;
                        this.submitButtonTarget.classList.toggle('opacity-50', !allValid);
                        this.submitButtonTarget.classList.toggle('cursor-not-allowed', !allValid);
                      }
                    }
                    
                    // Password validation helpers
                    hasRepeatingCharacters(password) {
                      for (let i = 0; i < password.length - 2; i++) {
                        if (password[i] === password[i + 1] && password[i] === password[i + 2]) {
                          return true;
                        }
                      }
                      return false;
                    }
                    
                    hasSequentialCharacters(password) {
                      const sequences = ['123', '234', '345', '456', '567', '678', '789', '890', 
                                       'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi', 'hij', 
                                       'ijk', 'jkl', 'klm', 'lmn', 'mno', 'nop', 'opq', 'pqr', 
                                       'qrs', 'rst', 'stu', 'tuv', 'uvw', 'vwx', 'wxy', 'xyz'];
                      const lower = password.toLowerCase();
                      return sequences.some(seq => lower.includes(seq) || lower.includes(seq.split('').reverse().join('')));
                    }
                    
                    calculatePasswordStrength(password) {
                      let score = 0;
                      
                      // Length bonus
                      if (password.length >= 8) score += 1;
                      if (password.length >= 12) score += 1;
                      
                      // Character variety
                      if (/[a-z]/.test(password)) score += 1;
                      if (/[A-Z]/.test(password)) score += 1;
                      if (/\\d/.test(password)) score += 1;
                      if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) score += 1;
                      
                      // Penalties
                      if (this.hasRepeatingCharacters(password)) score -= 1;
                      if (this.hasSequentialCharacters(password)) score -= 1;
                      if (this.commonPasswords.includes(password.toLowerCase())) score -= 2;
                      
                      return Math.max(0, Math.min(5, score));
                    }
                    
                    updatePasswordStrength(strength) {
                      if (!this.hasPasswordStrengthTarget) return;
                      
                      const strengthText = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong', 'Very Strong'][strength];
                      const strengthColors = ['#dc2626', '#ea580c', '#ca8a04', '#65a30d', '#16a34a', '#059669'];
                      const strengthWidths = ['10%', '20%', '40%', '60%', '80%', '100%'];
                      
                      if (this.hasStrengthTextTarget) {
                        this.strengthTextTarget.textContent = strengthText;
                        this.strengthTextTarget.style.color = strengthColors[strength];
                      }
                      
                      if (this.hasStrengthBarTarget) {
                        this.strengthBarTarget.style.width = strengthWidths[strength];
                        this.strengthBarTarget.style.background = strengthColors[strength];
                      }
                    }
                    
                    updateRequirementIcon(targetName, isValid) {
                      const target = this[targetName + 'Target'];
                      if (!target) return;
                      
                      if (isValid) {
                        target.style.background = '#16a34a'; // green
                        target.classList.remove('bg-gray-300');
                        target.classList.add('bg-green-500');
                      } else {
                        target.style.background = '#d1d5db'; // gray
                        target.classList.remove('bg-green-500');
                        target.classList.add('bg-gray-300');
                      }
                    }
                    
                    // Social login
                    socialLogin(event) {
                      const provider = event.target.dataset.loginDialogProviderParam;
                      console.log('Social login with:', provider);
                      // Implement social login logic here
                    }
                    
                    // Form submission
                    async submitForm(event) {
                      event.preventDefault();
                      
                      if (this.isSubmitting) return;
                      
                      // Validate all fields
                      const emailValid = this.validateEmail();
                      const passwordValid = this.validatePassword();
                      
                      if (!emailValid || !passwordValid) {
                        this.shake();
                        return;
                      }
                      
                      this.setLoading(true);
                      
                      try {
                        const formData = new FormData();
                        formData.append("login[email]", this.emailInputTarget.value);
                        formData.append("login[password]", this.passwordInputTarget.value);
                        
                        if (this.hasRememberInputTarget) {
                          formData.append("login[remember_me]", this.rememberInputTarget.checked);
                        }
                        
                        // Add CSRF token
                        const csrfToken = document.querySelector('meta[name="csrf-token"]');
                        if (csrfToken) {
                          formData.append("authenticity_token", csrfToken.content);
                        }
                        
                        const response = await fetch(this.loginUrlValue, {
                          method: "POST",
                          body: formData,
                          headers: {
                            "X-Requested-With": "XMLHttpRequest",
                            "Accept": "application/json"
                          }
                        });
                        
                        if (response.ok) {
                          const data = await response.json();
                          this.handleSuccess(data);
                        } else {
                          const errorData = await response.json();
                          this.handleError(errorData);
                        }
                      } catch (error) {
                        console.error("Login error:", error);
                        this.handleError({ 
                          errors: { 
                            base: ["Network error. Please check your connection and try again."] 
                          } 
                        });
                      } finally {
                        this.setLoading(false);
                      }
                    }
                    
                    setLoading(loading) {
                      this.isSubmitting = loading;
                      
                      if (this.hasSubmitButtonTarget) {
                        this.submitButtonTarget.disabled = loading;
                        this.submitButtonTarget.textContent = loading ? 'Signing In...' : 'Sign In';
                        this.submitButtonTarget.classList.toggle('opacity-50', loading);
                        this.submitButtonTarget.classList.toggle('cursor-not-allowed', loading);
                      }
                    }
                    
                    shake() {
                      if (this.hasModalTarget) {
                        this.modalTarget.style.animation = 'shake 0.5s ease-in-out';
                        setTimeout(() => {
                          this.modalTarget.style.animation = '';
                        }, 500);
                      }
                    }
                    
                    handleSuccess(data) {
                      console.log('Login successful:', data);
                      setTimeout(() => {
                        window.location.href = data.redirect_url || this.closeUrlValue;
                      }, 1000);
                    }
                    
                    handleError(data) {
                      console.error('Login error:', data);
                      this.shake();
                    }
                  }
                  
                  // Register the controller
                  window.Stimulus.register("login-dialog", LoginDialogController);
                  
                  // Add shake animation CSS
                  if (!document.querySelector('#login-dialog-styles')) {
                    const style = document.createElement('style');
                    style.id = 'login-dialog-styles';
                    style.textContent = `
                      @keyframes shake {
                        0%, 100% { transform: translate(-50%, -50%) translateX(0); }
                        25% { transform: translate(-50%, -50%) translateX(-5px); }
                        75% { transform: translate(-50%, -50%) translateX(5px); }
                      }
                    `;
                    document.head.appendChild(style);
                  }
                }
              JAVASCRIPT
            end
          end
        end
      end
    end
  end
end