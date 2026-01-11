class Auth::LoginFormComponent < ApplicationComponent
  prop :email_value, type: String, default: ""
  prop :show_error, type: [TrueClass, FalseClass], default: false
  prop :error_message, type: String, default: ""

  swift_ui do
    div.mx("auto").w("full").max_w("md") do
      # Flash messages
      if show_error && error_message.present?
        div.py(2).px(3).bg("red-50").mb(5).text_color("red-500").font_weight("medium").rounded("lg") do
          text(error_message)
        end
      end

      # Title
      h1.font_weight("bold").font_size("4xl").mb(8) do
        text("Welcome Back")
      end

      # Login form
      form(action: session_path, method: :post, class: "space-y-6") do
        # CSRF token
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        # Email field
        div do
          label("Email address", for: "email_address").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
          textfield(
            type: "email",
            name: "email_address",
            id: "email_address",
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "Enter your email address",
            value: email_value
          )
          .block.w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
          .shadow("sm").focus_border_color("blue-500").focus_ring("2").focus_ring_color("blue-200")
        end

        # Password field
        div do
          label("Password", for: "password").block.text_size("sm").font_weight("medium").text_color("gray-700").mb(2)
          textfield(
            type: "password",
            name: "password",
            id: "password",
            required: true,
            autocomplete: "current-password",
            placeholder: "Enter your password",
            maxlength: 72
          )
          .block.w("full").px(3).py(2).border.border_color("gray-300").rounded("md")
          .shadow("sm").focus_border_color("blue-500").focus_ring("2").focus_ring_color("blue-200")
        end

        # Submit button
        div do
          button("Sign In", type: "submit")
            .w("full").flex.justify_center.py(2).px(4).border.border_color("transparent")
            .rounded("md").shadow("sm").text_size("sm").font_weight("medium").text_color("white")
            .bg("blue-600").hover_bg("blue-700").transition
        end

        # Links
        div.flex.items_center.justify_between do
          link("Forgot your password?", destination: "/passwords/new")
          link("Sign up", destination: new_registration_path)
        end
      end
    end
  end
end