class Auth::RegisterFormComponent < ApplicationComponent
  prop :email_value, type: String, default: ""
  prop :user, type: Object, default: nil
  prop :show_errors, type: [TrueClass, FalseClass], default: false

  swift_ui do
    div.mx("auto").w("full").max_w("md") do
      # Flash messages for validation errors
      if show_errors && user&.errors&.any?
        div.py(2).px(3).bg("red-50").mb(5).text_color("red-500").font_weight("medium").rounded("lg") do
          user.errors.full_messages.each do |error|
            div do
              text(error).text_size("sm")
            end
          end
        end
      end

      # Title
      h1.font_weight("bold").font_size("4xl").mb(8) do
        text("Create Account")
      end

      # Registration form
      form(action: registrations_path, method: :post, class: "space-y-6") do
        # CSRF token
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        # Email field
        div do
          label("Email address", for: "user_email_address").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
          textfield(
            type: "email",
            name: "user[email_address]",
            id: "user_email_address",
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "Enter your email address",
            value: email_value
          )
          .block.w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
          .shadow("sm")
        end

        # Password field
        div do
          label("Password", for: "user_password").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
          textfield(
            type: "password",
            name: "user[password]",
            id: "user_password",
            required: true,
            autocomplete: "new-password",
            placeholder: "Enter your password (min 8 characters)",
            minlength: 8,
            maxlength: 72
          )
          .block.w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
          .shadow("sm")
          
          # Password requirements
          div.mt(1) do
            text("Minimum 8 characters").text_size("xs").text_color("gray-500")
          end
        end

        # Password confirmation field
        div do
          label("Confirm Password", for: "user_password_confirmation").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
          textfield(
            type: "password",
            name: "user[password_confirmation]",
            id: "user_password_confirmation",
            required: true,
            autocomplete: "new-password",
            placeholder: "Confirm your password",
            maxlength: 72
          )
          .block.w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
          .shadow("sm")
        end

        # Submit button
        div do
          button("Create Account", type: "submit")
            .w("full").flex.justify_center.py(2).px(4).border.border_color("transparent")
            .rounded("md").shadow("sm").text_size("sm").font_weight("medium").text_color("white")
            .bg("green-600").hover_bg("green-700")
        end

        # Links
        div.flex.items_center.justify_center do
          text("Already have an account? ").text_size("sm").text_color("gray-600")
          link("Sign in", destination: new_session_path)
            .text_size("sm").text_color("blue-600").hover_text_color("blue-500").ml(1)
        end
      end
    end
  end
end