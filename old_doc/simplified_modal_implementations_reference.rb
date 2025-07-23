# DEPRECATED: Simplified Modal Implementations - Reference Only
#
# These were simplified implementations created in HeroLandingComponent
# that should NOT be used. This file is kept for reference only.
#
# RULE: Always use the full gem components instead of creating simplified versions!
#
# Use instead:
# - SwiftUIRails::Component::Composed::Auth::LoginDialogComponent
# - SwiftUIRails::Component::Composed::Auth::RegisterDialogComponent

module DeprecatedSimplifiedModals
  # This was the simplified login_modal method - DO NOT USE
  def simplified_login_modal_reference
    # Login Dialog Modal with proper Stimulus targets - based on gem component
    div.fixed.inset(0).bg("black").opacity(50).z(40).flex.items_center.justify_center.p(4)
      .data(
        controller: "login-dialog",
        action: "click->login-dialog#closeOnBackdrop",
        "login-dialog-close-url-value": "/",
        "login-dialog-login-url-value": "/login"
      ) do
      
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
          
          # Login form - INCOMPLETE! Missing password requirements that Stimulus expects
          form.space_y(4)
            .data(
              action: "submit->login-dialog#submitForm",
              "login-dialog-target": "form"
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
            
            # Password field - MISSING REQUIREMENTS SECTION!
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
              
              # MISSING: Password strength indicator and requirements that Stimulus expects!
              # The controller looks for these targets:
              # - requirementLengthIcon
              # - requirementSpecialIcon  
              # - requirementNumberIcon
              # - requirementRepeatingIcon
              # - requirementSequentialIcon
              # - strengthText, strengthIndicator, strengthBar
              # - requirements
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
        end
      end
    end
  end

  # This was the simplified register_modal method - DO NOT USE
  def simplified_register_modal_reference
    # Similar structure for register modal
    div.fixed.inset(0).bg("black").opacity(50).z(40).flex.items_center.justify_center.p(4)
      .data(
        controller: "register-dialog",
        action: "click->register-dialog#closeOnBackdrop",
        "register-dialog-close-url-value": "/"
      ) do
      
      div.relative.bg("white").rounded("lg").shadow("2xl").z(50).w("full").max_w("md")
        .data(
          "register-dialog-target": "modal",
          action: "click->register-dialog#stopPropagation"
        ) do
        
        # Simple register form for testing - INCOMPLETE!
        div.p(6) do
          h2.text_xl.font_weight("semibold").mb(4) { text("Create Account") }
          text("Sign up for a new account").text_sm.text_color("gray-500").mb(6)
          
          # Close button
          button("×")
            .absolute.top(4).right(4)
            .text_color("gray-400")
            .hover_text_color("gray-600")
            .text_size("2xl")
            .data(action: "click->register-dialog#close")
        end
      end
    end
  end
end

# LESSON LEARNED:
# Creating simplified versions leads to:
# 1. Missing Stimulus targets that controllers expect
# 2. Broken functionality and JavaScript errors  
# 3. Maintenance burden of keeping simplified and full versions in sync
# 4. Duplicated code that violates DRY principles
#
# SOLUTION:
# Always use the full gem components and make them work properly!