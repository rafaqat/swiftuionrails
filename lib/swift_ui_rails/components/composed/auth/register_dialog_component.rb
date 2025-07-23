# frozen_string_literal: true

module SwiftUIRails
  module Component
    module Composed
      module Auth
        # RegisterDialogComponent - A complete registration dialog with built-in functionality
        #
        # Features:
        # - Modal overlay with backdrop
        # - Form validation and submission
        # - Password confirmation matching
        # - Email uniqueness validation
        # - Terms of service acceptance
        # - Password strength validation
        # - Error handling and display
        # - Social registration integration
        # - Progressive enhancement
        # - Stimulus controller integration
        # - Customizable through slots and props
        #
        # Usage:
        #   <%= render RegisterDialogComponent.new(
        #     register_url: register_path,
        #     login_url: login_path,
        #     show_social: true
        #   ) do |dialog| %>
        #     <% dialog.with_header do %>
        #       Create Your Account
        #     <% end %>
        #     <% dialog.with_footer_action type: :link do %>
        #       <%= link_to "Privacy Policy", privacy_path %>
        #     <% end %>
        #   <% end %>
        class RegisterDialogComponent < SwiftUIRails::Component::Base
          
          # Props for configuration
          prop :open, type: [TrueClass, FalseClass], default: false
          prop :register_url, type: String, default: '/register'
          prop :login_url, type: String, default: '/login'
          prop :close_url, type: String, default: nil
          prop :show_social, type: [TrueClass, FalseClass], default: false
          prop :social_providers, type: Array, default: ['google', 'github']
          prop :size, type: Symbol, default: :md # :sm, :md, :lg, :xl
          prop :errors, type: Hash, default: {}
          prop :form_data, type: Hash, default: { 
            email: '', 
            password: '', 
            password_confirmation: '', 
            first_name: '',
            last_name: '',
            terms_accepted: false 
          }
          prop :require_terms, type: [TrueClass, FalseClass], default: true
          prop :terms_url, type: String, default: '/terms'
          prop :privacy_url, type: String, default: '/privacy'
          
          # ViewComponent slots for customization  
          renders_one :header
          renders_many :footer_actions
          
          swift_ui do
            Rails.logger.info "🔥 RegisterDialogComponent swift_ui called with open=#{open}"
            if open
              Rails.logger.info "🔥 RegisterDialogComponent rendering modal"
              # Modal overlay with backdrop
              div(style: "position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0, 0, 0, 0.5); z-index: 40; display: flex; align-items: center; justify-content: center; padding: 1rem;", 
                  data: { 
                    controller: "register-dialog",
                    action: "click->register-dialog#closeOnBackdrop".html_safe,
                    "register-dialog-close-url-value": close_url
                  }) do
                
                # Modal container (prevent backdrop clicks when clicking on modal)
                div(style: "position: relative; background: white; border-radius: 8px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25); z-index: 50; width: 100%; max-width: 30rem; max-height: 90vh; overflow-y: auto;",
                    data: { 
                      "register-dialog-target": "modal",
                      action: "click->register-dialog#stopPropagation".html_safe
                    }) do
                  
                  # Modal header
                  div(style: "padding: 1.5rem 1.5rem 1rem 1.5rem; border-bottom: 1px solid #e5e7eb;") do
                    div(style: "display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;") do
                      text("Create Account").tap do |title|
                        title.instance_variable_set(:@style, "font-size: 1.25rem; font-weight: 600; color: #111827;")
                      end
                      
                      button("×")
                        .text_color("gray-400")
                        .hover_text_color("gray-600")
                        .text_size("2xl")
                        .leading("none")
                        .data(action: "click->register-dialog#close".html_safe)
                    end
                    
                    # Subtitle
                    text("Join us today and get started").tap do |subtitle|
                      subtitle.instance_variable_set(:@style, "font-size: 0.875rem; color: #6b7280;")
                    end
                  end
                  
                  # Modal body
                  div(style: "padding: 1.5rem;") do
                    # Error display placeholder
                    div(style: "display: none; margin-bottom: 1rem; padding: 1rem; background: #fef2f2; border: 1px solid #fecaca; border-radius: 6px;",
                        data: { "register-dialog-target": "errorBanner" }) do
                      text("Error messages will appear here")
                    end
                    
                    # Social registration section
                    if show_social
                      div(style: "margin-bottom: 1.5rem;") do
                        social_providers.each do |provider|
                          social_register_button(provider)
                        end
                        
                        # Divider
                        div(style: "position: relative; margin: 1.5rem 0;") do
                          div(style: "position: absolute; inset: 0; display: flex; align-items: center;") do
                            div(style: "width: 100%; border-top: 1px solid #d1d5db;")
                          end
                          div(style: "position: relative; display: flex; justify-content: center; font-size: 0.875rem;") do
                            text("or", style: "padding: 0 0.5rem; background: white; color: #6b7280;")
                          end
                        end
                      end
                    end
                    
                    # Registration form
                    form(style: "space-y: 1rem;",
                         data: {
                           action: "submit->register-dialog#submitForm",
                           "register-dialog-url-value": register_url
                         }) do
                      
                      # Name fields (side by side)
                      div(style: "display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;") do
                        # First name
                        div do
                          label("First Name", for: "register_first_name", style: "display: block; font-size: 0.875rem; font-weight: 500; color: #374151; margin-bottom: 0.25rem;")
                          
                          input(
                            type: "text",
                            name: "register[first_name]",
                            id: "register_first_name",
                            placeholder: "First name",
                            required: true,
                            style: "width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 0.875rem;",
                            data: {
                              "register-dialog-target": "firstNameInput",
                              action: "input->register-dialog#updateFormData blur->register-dialog#validateFirstName"
                            }
                          )
                          
                          # First name error message
                          div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem; color: #dc2626;",
                              data: { "register-dialog-target": "firstNameError" }) do
                            text("First name error")
                          end
                        end
                        
                        # Last name
                        div do
                          label("Last Name", for: "register_last_name", style: "display: block; font-size: 0.875rem; font-weight: 500; color: #374151; margin-bottom: 0.25rem;")
                          
                          input(
                            type: "text",
                            name: "register[last_name]",
                            id: "register_last_name",
                            placeholder: "Last name",
                            required: true,
                            style: "width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 0.875rem;",
                            data: {
                              "register-dialog-target": "lastNameInput",
                              action: "input->register-dialog#updateFormData blur->register-dialog#validateLastName"
                            }
                          )
                          
                          # Last name error message
                          div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem; color: #dc2626;",
                              data: { "register-dialog-target": "lastNameError" }) do
                            text("Last name error")
                          end
                        end
                      end
                      
                      # Email field
                      div(style: "margin-bottom: 1rem;") do
                        label("Email Address", for: "register_email", style: "display: block; font-size: 0.875rem; font-weight: 500; color: #374151; margin-bottom: 0.25rem;")
                        
                        input(
                          type: "email",
                          name: "register[email]",
                          id: "register_email",
                          placeholder: "Enter your email address",
                          required: true,
                          style: "width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 0.875rem;",
                          data: {
                            "register-dialog-target": "emailInput",
                            action: "input->register-dialog#updateFormData blur->register-dialog#validateEmail"
                          }
                        )
                        
                        # Email error message
                        div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem; color: #dc2626;",
                            data: { "register-dialog-target": "emailError" }) do
                          text("Email error message")
                        end
                        
                        # Email availability indicator
                        div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem;",
                            data: { "register-dialog-target": "emailAvailability" }) do
                          text("Checking availability...")
                        end
                      end
                      
                      # Password field
                      div(style: "margin-bottom: 1rem;") do
                        label("Password", for: "register_password", style: "display: block; font-size: 0.875rem; font-weight: 500; color: #374151; margin-bottom: 0.25rem;")
                        
                        input(
                          type: "password",
                          name: "register[password]",
                          id: "register_password",
                          placeholder: "Create a strong password",
                          required: true,
                          style: "width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 0.875rem;",
                          data: {
                            "register-dialog-target": "passwordInput",
                            action: "input->register-dialog#updateFormData blur->register-dialog#validatePassword"
                          }
                        )
                        
                        # Password error message
                        div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem; color: #dc2626;",
                            data: { "register-dialog-target": "passwordError" }) do
                          text("Password error message")
                        end
                        
                        # Password strength indicator
                        div(style: "margin-top: 0.5rem;", data: { "register-dialog-target": "passwordStrength" }) do
                          div(style: "margin-bottom: 0.5rem;") do
                            text("Password strength:", style: "font-size: 0.75rem; color: #6b7280; font-weight: 500;")
                            text("Weak", style: "font-size: 0.75rem; color: #dc2626; font-weight: 500; margin-left: 0.5rem;", data: { "register-dialog-target": "strengthText strengthIndicator" })
                          end
                          div(style: "height: 0.25rem; background: #e5e7eb; border-radius: 0.125rem; overflow: hidden;") do
                            div(style: "height: 100%; width: 0%; background: #dc2626; transition: all 0.3s ease;", data: { "register-dialog-target": "strengthBar" })
                          end
                        end
                        
                        # Password requirements
                        div(style: "margin-top: 0.75rem; display: none;", data: { "register-dialog-target": "requirements" }) do
                          text("Password must have:", style: "font-size: 0.75rem; color: #6b7280; font-weight: 500; margin-bottom: 0.5rem; display: block;")
                          
                          # Length requirement
                          div(style: "display: flex; align-items: center; margin-bottom: 0.25rem;") do
                            div(style: "width: 0.75rem; height: 0.75rem; border-radius: 50%; background: #d1d5db; margin-right: 0.5rem;",
                                data: { "register-dialog-target": "requirementLengthIcon" })
                            text("At least 8 characters", style: "font-size: 0.75rem; color: #6b7280;")
                          end
                          
                          # Special character requirement
                          div(style: "display: flex; align-items: center; margin-bottom: 0.25rem;") do
                            div(style: "width: 0.75rem; height: 0.75rem; border-radius: 50%; background: #d1d5db; margin-right: 0.5rem;",
                                data: { "register-dialog-target": "requirementSpecialIcon" })
                            text("At least one special character", style: "font-size: 0.75rem; color: #6b7280;")
                          end
                          
                          # Number requirement
                          div(style: "display: flex; align-items: center; margin-bottom: 0.25rem;") do
                            div(style: "width: 0.75rem; height: 0.75rem; border-radius: 50%; background: #d1d5db; margin-right: 0.5rem;",
                                data: { "register-dialog-target": "requirementNumberIcon" })
                            text("At least one number", style: "font-size: 0.75rem; color: #6b7280;")
                          end
                          
                          # Uppercase requirement
                          div(style: "display: flex; align-items: center; margin-bottom: 0.25rem;") do
                            div(style: "width: 0.75rem; height: 0.75rem; border-radius: 50%; background: #d1d5db; margin-right: 0.5rem;",
                                data: { "register-dialog-target": "requirementUppercaseIcon" })
                            text("At least one uppercase letter", style: "font-size: 0.75rem; color: #6b7280;")
                          end
                          
                          # No repeating characters requirement
                          div(style: "display: flex; align-items: center;") do
                            div(style: "width: 0.75rem; height: 0.75rem; border-radius: 50%; background: #d1d5db; margin-right: 0.5rem;",
                                data: { "register-dialog-target": "requirementRepeatingIcon" })
                            text("No repeating characters", style: "font-size: 0.75rem; color: #6b7280;")
                          end
                        end
                      end
                      
                      # Password confirmation field
                      div(style: "margin-bottom: 1rem;") do
                        label("Confirm Password", for: "register_password_confirmation", style: "display: block; font-size: 0.875rem; font-weight: 500; color: #374151; margin-bottom: 0.25rem;")
                        
                        input(
                          type: "password",
                          name: "register[password_confirmation]",
                          id: "register_password_confirmation",
                          placeholder: "Confirm your password",
                          required: true,
                          style: "width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 0.875rem;",
                          data: {
                            "register-dialog-target": "passwordConfirmationInput",
                            action: "input->register-dialog#updateFormData blur->register-dialog#validatePasswordConfirmation"
                          }
                        )
                        
                        # Password confirmation error message
                        div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem; color: #dc2626;",
                            data: { "register-dialog-target": "passwordConfirmationError" }) do
                          text("Password confirmation error")
                        end
                        
                        # Password match indicator
                        div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem;",
                            data: { "register-dialog-target": "passwordMatch" }) do
                          text("Passwords match")
                        end
                      end
                      
                      # Terms of service checkbox (if required)
                      if require_terms
                        div(style: "display: flex; align-items: start; margin-bottom: 1rem;") do
                          input(
                            type: "checkbox",
                            name: "register[terms_accepted]",
                            id: "register_terms_accepted",
                            required: true,
                            style: "height: 1rem; width: 1rem; color: #2563eb; border-radius: 4px; margin-right: 0.75rem; margin-top: 0.125rem;",
                            data: {
                              "register-dialog-target": "termsInput",
                              action: "change->register-dialog#updateFormData"
                            }
                          )
                          div do
                            label("", for: "register_terms_accepted", style: "font-size: 0.875rem; color: #374151; line-height: 1.4;") do
                              text("I agree to the ")
                              link("Terms of Service", destination: terms_url, style: "color: #2563eb; text-decoration: underline;")
                              text(" and ")
                              link("Privacy Policy", destination: privacy_url, style: "color: #2563eb; text-decoration: underline;")
                            end
                          end
                        end
                        
                        # Terms error message
                        div(style: "display: none; margin-top: 0.25rem; font-size: 0.875rem; color: #dc2626;",
                            data: { "register-dialog-target": "termsError" }) do
                          text("You must accept the terms and conditions")
                        end
                      end
                      
                      # Submit button
                      button("Create Account",
                             type: "submit",
                             style: "width: 100%; padding: 0.75rem 1rem; background: #2563eb; color: white; font-weight: 500; border-radius: 6px; border: none; cursor: pointer; transition: background-color 0.2s;",
                             data: { "register-dialog-target": "submitButton" })
                    end
                    
                    # Login link
                    if login_url
                      div(style: "text-align: center; margin-top: 1rem;") do
                        text("Already have an account? ", style: "font-size: 0.875rem; color: #6b7280;")
                        link("Sign in", destination: login_url, style: "font-size: 0.875rem; color: #2563eb; font-weight: 500; text-decoration: none;")
                      end
                    end
                  end
                end
              end
              
              # Embedded Stimulus script
              embedded_stimulus_script
            else
              Rails.logger.info "🔥 RegisterDialogComponent open=false, not rendering modal"
            end
          end
          
          private
          
          def social_register_button(provider)
            button do
              hstack(spacing: 3, justify: :center) do
                social_icon(provider)
                text("Continue with #{provider.humanize}")
              end
            end
            .w("full")
            .py(3)
            .mb(3)
            .border
            .border_color("gray-300")
            .rounded("md")
            .hover_bg("gray-50")
            .transition
            .data(
              action: "click->register-dialog#socialRegister",
              "register-dialog-provider-param": provider
            )
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
          
          def embedded_stimulus_script
            script do
              <<~JAVASCRIPT.html_safe
                // Auto-register the RegisterDialog Stimulus controller
                if (window.Stimulus && !window.Stimulus.controllers.has("register-dialog")) {
                  const { Controller } = window.Stimulus;
                  
                  class RegisterDialogController extends Controller {
                    static targets = [
                      "modal", "form", "firstNameInput", "lastNameInput", "emailInput", 
                      "passwordInput", "passwordConfirmationInput", "termsInput", "submitButton",
                      "firstNameError", "lastNameError", "emailError", "passwordError", 
                      "passwordConfirmationError", "termsError", "errorBanner",
                      "passwordStrength", "strengthText", "strengthBar", "strengthIndicator", "requirements",
                      "requirementLengthIcon", "requirementSpecialIcon", "requirementNumberIcon",
                      "requirementUppercaseIcon", "requirementRepeatingIcon",
                      "emailAvailability", "passwordMatch"
                    ];
                    
                    static values = {
                      closeUrl: String,
                      registerUrl: String
                    };
                    
                    connect() {
                      this.isSubmitting = false;
                      this.validationState = {
                        firstName: false,
                        lastName: false,
                        email: false,
                        password: false,
                        passwordConfirmation: false,
                        terms: false
                      };
                      
                      // Password requirements state
                      this.passwordRequirements = {
                        length: false,
                        special: false,
                        number: false,
                        uppercase: false,
                        repeating: false
                      };
                      
                      // Common passwords list
                      this.commonPasswords = [
                        'password', '123456', '123456789', 'password123', 'admin',
                        'qwerty', 'letmein', 'welcome', 'monkey', '1234567890'
                      ];
                      
                      // Email check timeout
                      this.emailCheckTimeout = null;
                      
                      // Set up escape key listener
                      this.boundEscapeHandler = this.handleEscape.bind(this);
                      document.addEventListener("keydown", this.boundEscapeHandler);
                      
                      // Focus first name input
                      if (this.hasFirstNameInputTarget) {
                        setTimeout(() => this.firstNameInputTarget.focus(), 100);
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
                      if (this.emailCheckTimeout) {
                        clearTimeout(this.emailCheckTimeout);
                      }
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
                    
                    // Form validation methods
                    validateFirstName() {
                      const firstName = this.firstNameInputTarget.value.trim();
                      const isValid = firstName.length >= 2;
                      
                      this.validationState.firstName = isValid;
                      this.showFieldError('firstNameError', !isValid && firstName.length > 0, 
                        'First name must be at least 2 characters long');
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    validateLastName() {
                      const lastName = this.lastNameInputTarget.value.trim();
                      const isValid = lastName.length >= 2;
                      
                      this.validationState.lastName = isValid;
                      this.showFieldError('lastNameError', !isValid && lastName.length > 0,
                        'Last name must be at least 2 characters long');
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    validateEmail() {
                      const email = this.emailInputTarget.value.trim();
                      const isValid = email && /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email);
                      
                      this.validationState.email = isValid;
                      this.showFieldError('emailError', !isValid && email.length > 0,
                        'Please enter a valid email address');
                      
                      // Check email availability (debounced)
                      if (isValid) {
                        this.checkEmailAvailability(email);
                      } else if (this.hasEmailAvailabilityTarget) {
                        this.emailAvailabilityTarget.style.display = 'none';
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
                      this.passwordRequirements.uppercase = /[A-Z]/.test(password);
                      this.passwordRequirements.repeating = !this.hasRepeatingCharacters(password);
                      
                      // Check for common passwords
                      const isCommonPassword = this.commonPasswords.includes(password.toLowerCase());
                      
                      // Update requirement icons
                      this.updateRequirementIcon('requirementLengthIcon', this.passwordRequirements.length);
                      this.updateRequirementIcon('requirementSpecialIcon', this.passwordRequirements.special);
                      this.updateRequirementIcon('requirementNumberIcon', this.passwordRequirements.number);
                      this.updateRequirementIcon('requirementUppercaseIcon', this.passwordRequirements.uppercase);
                      this.updateRequirementIcon('requirementRepeatingIcon', this.passwordRequirements.repeating);
                      
                      // Calculate password strength
                      const strength = this.calculatePasswordStrength(password);
                      this.updatePasswordStrength(strength);
                      
                      // Overall password validity
                      const isValid = Object.values(this.passwordRequirements).every(req => req) && !isCommonPassword;
                      this.validationState.password = isValid;
                      
                      // Show password error
                      if (!isValid && password.length > 0) {
                        let errorMsg = '';
                        if (isCommonPassword) {
                          errorMsg = 'This password is too common. Please choose a more secure password.';
                        } else if (!this.passwordRequirements.length) {
                          errorMsg = 'Password must be at least 8 characters long';
                        } else if (!this.passwordRequirements.uppercase) {
                          errorMsg = 'Password must contain at least one uppercase letter';
                        } else if (!this.passwordRequirements.special) {
                          errorMsg = 'Password must contain at least one special character';
                        } else if (!this.passwordRequirements.number) {
                          errorMsg = 'Password must contain at least one number';
                        } else if (!this.passwordRequirements.repeating) {
                          errorMsg = 'Password cannot contain repeating characters';
                        }
                        this.showFieldError('passwordError', true, errorMsg);
                      } else {
                        this.showFieldError('passwordError', false, '');
                      }
                      
                      // Re-validate password confirmation if it has a value
                      if (this.passwordConfirmationInputTarget.value) {
                        this.validatePasswordConfirmation();
                      }
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    validatePasswordConfirmation() {
                      const password = this.passwordInputTarget.value;
                      const confirmation = this.passwordConfirmationInputTarget.value;
                      const isValid = password === confirmation && password.length > 0;
                      
                      this.validationState.passwordConfirmation = isValid;
                      
                      if (confirmation.length > 0) {
                        this.showFieldError('passwordConfirmationError', !isValid, 
                          'Passwords do not match');
                        
                        // Show match indicator
                        if (this.hasPasswordMatchTarget) {
                          if (isValid) {
                            this.passwordMatchTarget.style.display = 'block';
                            this.passwordMatchTarget.style.color = '#16a34a';
                            this.passwordMatchTarget.textContent = '✓ Passwords match';
                          } else {
                            this.passwordMatchTarget.style.display = 'none';
                          }
                        }
                      } else {
                        this.showFieldError('passwordConfirmationError', false, '');
                        if (this.hasPasswordMatchTarget) {
                          this.passwordMatchTarget.style.display = 'none';
                        }
                      }
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    validateTerms() {
                      if (!this.hasTermsInputTarget) {
                        this.validationState.terms = true;
                        return true;
                      }
                      
                      const isValid = this.termsInputTarget.checked;
                      this.validationState.terms = isValid;
                      
                      this.showFieldError('termsError', !isValid, 
                        'You must accept the terms and conditions');
                      
                      this.updateSubmitButton();
                      return isValid;
                    }
                    
                    updateFormData() {
                      // Update all validations
                      this.validateFirstName();
                      this.validateLastName();
                      this.validateEmail();
                      this.validatePassword();
                      this.validatePasswordConfirmation();
                      this.validateTerms();
                    }
                    
                    // Helper methods
                    showFieldError(targetName, show, message) {
                      const target = this[targetName + 'Target'];
                      if (!target) return;
                      
                      if (show) {
                        target.style.display = 'block';
                        target.textContent = message;
                      } else {
                        target.style.display = 'none';
                      }
                    }
                    
                    hasRepeatingCharacters(password) {
                      for (let i = 0; i < password.length - 2; i++) {
                        if (password[i] === password[i + 1] && password[i] === password[i + 2]) {
                          return true;
                        }
                      }
                      return false;
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
                    
                    updateSubmitButton() {
                      const allValid = Object.values(this.validationState).every(valid => valid);
                      if (this.hasSubmitButtonTarget) {
                        this.submitButtonTarget.disabled = !allValid || this.isSubmitting;
                        this.submitButtonTarget.style.opacity = (!allValid || this.isSubmitting) ? '0.5' : '1';
                        this.submitButtonTarget.style.cursor = (!allValid || this.isSubmitting) ? 'not-allowed' : 'pointer';
                      }
                    }
                    
                    checkEmailAvailability(email) {
                      if (this.emailCheckTimeout) {
                        clearTimeout(this.emailCheckTimeout);
                      }
                      
                      if (!this.hasEmailAvailabilityTarget) return;
                      
                      this.emailCheckTimeout = setTimeout(async () => {
                        try {
                          this.emailAvailabilityTarget.style.display = 'block';
                          this.emailAvailabilityTarget.style.color = '#6b7280';
                          this.emailAvailabilityTarget.textContent = 'Checking availability...';
                          
                          // Simulate API call (replace with real endpoint)
                          const response = await fetch(`/api/check-email?email=${encodeURIComponent(email)}`, {
                            method: 'GET',
                            headers: {
                              'X-Requested-With': 'XMLHttpRequest',
                              'Accept': 'application/json'
                            }
                          });
                          
                          if (response.ok) {
                            const data = await response.json();
                            if (data.available) {
                              this.emailAvailabilityTarget.style.color = '#16a34a';
                              this.emailAvailabilityTarget.textContent = '✓ Email is available';
                            } else {
                              this.emailAvailabilityTarget.style.color = '#dc2626';
                              this.emailAvailabilityTarget.textContent = '✗ Email is already taken';
                              this.validationState.email = false;
                              this.updateSubmitButton();
                            }
                          } else {
                            this.emailAvailabilityTarget.style.display = 'none';
                          }
                        } catch (error) {
                          this.emailAvailabilityTarget.style.display = 'none';
                        }
                      }, 500);
                    }
                    
                    // Social registration
                    socialRegister(event) {
                      const provider = event.target.dataset.registerDialogProviderParam;
                      console.log('Social registration with:', provider);
                      // Implement social registration logic here
                    }
                    
                    // Form submission
                    async submitForm(event) {
                      event.preventDefault();
                      
                      if (this.isSubmitting) return;
                      
                      // Validate all fields
                      const firstNameValid = this.validateFirstName();
                      const lastNameValid = this.validateLastName();
                      const emailValid = this.validateEmail();
                      const passwordValid = this.validatePassword();
                      const passwordConfirmationValid = this.validatePasswordConfirmation();
                      const termsValid = this.validateTerms();
                      
                      if (!firstNameValid || !lastNameValid || !emailValid || 
                          !passwordValid || !passwordConfirmationValid || !termsValid) {
                        this.shake();
                        return;
                      }
                      
                      this.setLoading(true);
                      
                      try {
                        const formData = new FormData();
                        formData.append("register[first_name]", this.firstNameInputTarget.value);
                        formData.append("register[last_name]", this.lastNameInputTarget.value);
                        formData.append("register[email]", this.emailInputTarget.value);
                        formData.append("register[password]", this.passwordInputTarget.value);
                        formData.append("register[password_confirmation]", this.passwordConfirmationInputTarget.value);
                        
                        if (this.hasTermsInputTarget) {
                          formData.append("register[terms_accepted]", this.termsInputTarget.checked);
                        }
                        
                        // Add CSRF token
                        const csrfToken = document.querySelector('meta[name="csrf-token"]');
                        if (csrfToken) {
                          formData.append("authenticity_token", csrfToken.content);
                        }
                        
                        const response = await fetch(this.registerUrlValue, {
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
                        console.error("Registration error:", error);
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
                        this.submitButtonTarget.textContent = loading ? 'Creating Account...' : 'Create Account';
                        this.submitButtonTarget.style.opacity = loading ? '0.5' : '1';
                        this.submitButtonTarget.style.cursor = loading ? 'not-allowed' : 'pointer';
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
                      console.log('Registration successful:', data);
                      setTimeout(() => {
                        window.location.href = data.redirect_url || this.closeUrlValue;
                      }, 1000);
                    }
                    
                    handleError(data) {
                      console.error('Registration error:', data);
                      this.shake();
                      
                      // Show error banner if there are general errors
                      if (data.errors && data.errors.base && this.hasErrorBannerTarget) {
                        this.errorBannerTarget.style.display = 'block';
                        this.errorBannerTarget.innerHTML = data.errors.base.map(error => 
                          `<div style="color: #dc2626; font-size: 0.875rem;">• ${error}</div>`
                        ).join('');
                      }
                    }
                  }
                  
                  // Register the controller
                  window.Stimulus.register("register-dialog", RegisterDialogController);
                  
                  // Add shake animation CSS
                  if (!document.querySelector('#register-dialog-styles')) {
                    const style = document.createElement('style');
                    style.id = 'register-dialog-styles';
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