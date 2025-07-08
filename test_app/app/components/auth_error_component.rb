# frozen_string_literal: true

# Copyright 2025

class AuthErrorComponent < ApplicationComponent
  # Error configuration
  prop :error_type, type: Symbol, default: :not_found # :not_found, :unauthorized, :forbidden, :server_error
  prop :title, type: String, default: nil
  prop :message, type: String, default: nil
  prop :action_text, type: String, default: nil
  prop :action_path, type: String, default: "/"
  prop :show_support, type: [ TrueClass, FalseClass ], default: true
  prop :support_email, type: String, default: "support@example.com"

  swift_ui do
    div do
      div.max_w("md").w_full.bg("white").shadow("xl").rounded("lg").p(8).text_center do
        # Error icon/illustration
        div.mx("auto").mb(8) do
          case error_type
          when :not_found
            div.h(24).w(24).mx("auto").bg("yellow-100").rounded("full").flex.items_center.justify_center do
              text("404").text_color("yellow-600").font_size("2xl").font_weight("bold")
            end
          when :unauthorized
            div.h(24).w(24).mx("auto").bg("red-100").rounded("full").flex.items_center.justify_center do
              text("401").text_color("red-600").font_size("2xl").font_weight("bold")
            end
          when :forbidden
            div.h(24).w(24).mx("auto").bg("orange-100").rounded("full").flex.items_center.justify_center do
              text("403").text_color("orange-600").font_size("2xl").font_weight("bold")
            end
          when :server_error
            div.h(24).w(24).mx("auto").bg("red-100").rounded("full").flex.items_center.justify_center do
              text("500").text_color("red-600").font_size("2xl").font_weight("bold")
            end
          else
            div.h(24).w(24).mx("auto").bg("gray-100").rounded("full").flex.items_center.justify_center do
              text("!").text_color("gray-600").font_size("3xl").font_weight("bold")
            end
          end
        end

        # Error title
        h1(title || default_title).text_size("2xl").font_weight("bold").text_color("gray-900").mb(4)

        # Error message
        p(message || default_message).text_color("gray-600").mb(8).max_w("sm").mx("auto")

        # Action buttons
        div.flex.flex_col.sm("flex-row").gap(4).justify_center.mb(8) do
          link(action_text || default_action_text, destination: action_path)
            .inline_flex
            .items_center
            .px(6)
            .py(3)
            .border
            .border_color("transparent")
            .text_size("base")
            .font_weight("medium")
            .rounded("md")
            .text_color("white")
            .bg("indigo-600")
            .hover_bg("indigo-700")
            .focus("outline-none ring-2 ring-offset-2 ring-indigo-500")

          if error_type == :unauthorized || error_type == :forbidden
            link("Try Again", destination: request.path)
              .inline_flex
              .items_center
              .px(6)
              .py(3)
              .border
              .border_color("gray-300")
              .text_size("base")
              .font_weight("medium")
              .rounded("md")
              .text_color("gray-700")
              .bg("white")
              .hover_bg("gray-50")
              .focus("outline-none ring-2 ring-offset-2 ring-gray-500")
          end
        end

        # Support section
        if show_support
          div.border_t.border_color("gray-200").pt(8) do
            p.text_size("sm").text_color("gray-500").mb(2) do
              text("Need help? Contact our support team")
            end
            link("Email: #{support_email}", destination: "mailto:#{support_email}")
              .text_size("sm")
              .text_color("indigo-600")
              .hover_text_color("indigo-500")
              .font_weight("medium")
          end
        end

        # Additional helpful links
        if error_type == :not_found
          div.mt(8).pt(8).border_t.border_color("gray-200") do
            p.text_size("sm").text_color("gray-600").mb(4) do
              text("Here are some helpful links instead:")
            end
            div.flex.flex_wrap.gap(4).justify_center do
              link("Home", destination: "/")
                .text_size("sm")
                .text_color("indigo-600")
                .hover_text_color("indigo-500")
              span("•").text_color("gray-400")
              link("Dashboard", destination: "/dashboard")
                .text_size("sm")
                .text_color("indigo-600")
                .hover_text_color("indigo-500")
              span("•").text_color("gray-400")
              link("Help Center", destination: "/help")
                .text_size("sm")
                .text_color("indigo-600")
                .hover_text_color("indigo-500")
            end
          end
        end
      end
    end
    .min_h("screen")
    .flex
    .items_center
    .justify_center
    .bg("gray-50")
    .py(12)
    .px(4)
    .sm("px-6 lg:px-8")
  end

  private

  def default_title
    case error_type
    when :not_found
      "Page not found"
    when :unauthorized
      "Authentication required"
    when :forbidden
      "Access denied"
    when :server_error
      "Something went wrong"
    else
      "Oops!"
    end
  end

  def default_message
    case error_type
    when :not_found
      "Sorry, we couldn't find the page you're looking for. Please check the URL or navigate back to a known page."
    when :unauthorized
      "You need to sign in to access this page. Please log in with your credentials."
    when :forbidden
      "You don't have permission to access this resource. Please contact your administrator if you believe this is an error."
    when :server_error
      "We're experiencing technical difficulties. Our team has been notified and is working on a fix."
    else
      "An unexpected error occurred. Please try again later."
    end
  end

  def default_action_text
    case error_type
    when :not_found
      "Go to Homepage"
    when :unauthorized
      "Sign In"
    when :forbidden
      "Go Back"
    when :server_error
      "Refresh Page"
    else
      "Go Back"
    end
  end

  def request
    @request ||= helpers.request
  end
end
# Copyright 2025
