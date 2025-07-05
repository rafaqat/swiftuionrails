# frozen_string_literal: true

class EnhancedAuthStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  def default_login
    swift_ui do
      render EnhancedLoginComponent.new
    end
  end
  
  def login_with_error
    swift_ui do
      render EnhancedLoginComponent.new(
        email: "user@example.com",
        general_error: "Invalid email or password. Please try again.",
        errors: {
          password: ["is incorrect"]
        }
      )
    end
  end
  
  def login_without_social
    swift_ui do
      render EnhancedLoginComponent.new(
        show_social: false
      )
    end
  end
  
  def default_register
    swift_ui do
      render EnhancedRegisterComponent.new
    end
  end
  
  def register_with_errors
    swift_ui do
      render EnhancedRegisterComponent.new(
        name: "John",
        email: "john@",
        general_error: "Please fix the errors below",
        errors: {
          email: ["is invalid"],
          password: ["is too short (minimum is 8 characters)"],
          password_confirmation: ["doesn't match password"]
        }
      )
    end
  end
  
  def error_404
    swift_ui do
      render AuthErrorComponent.new(
        error_type: :not_found
      )
    end
  end
  
  def error_unauthorized
    swift_ui do
      render AuthErrorComponent.new(
        error_type: :unauthorized,
        action_path: "/login"
      )
    end
  end
  
  def error_forbidden
    swift_ui do
      render AuthErrorComponent.new(
        error_type: :forbidden,
        message: "Your account doesn't have access to this feature. Please upgrade your subscription or contact your administrator."
      )
    end
  end
  
  def error_server
    swift_ui do
      render AuthErrorComponent.new(
        error_type: :server_error
      )
    end
  end
  
  def auth_layout_centered
    swift_ui do
      render AuthLayoutComponent.new(variant: :centered, brand_name: "SwiftUI Rails") do |layout|
        layout.with_form do
          render EnhancedLoginComponent.new
        end
      end
    end
  end
  
  def auth_layout_split
    swift_ui do
      render AuthLayoutComponent.new(variant: :split, brand_name: "SwiftUI Rails") do |layout|
        layout.with_form do
          render EnhancedRegisterComponent.new
        end
        
        layout.with_sidebar do
          div.h_full.relative do
            image(src: "https://images.unsplash.com/photo-1505904267569-f02eaeb45a4c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1908&q=80", alt: "")
              .absolute
              .inset(0)
              .h_full
              .w_full
              .object("cover")
            
            div.absolute.inset(0).bg_gradient_to_t.from("black").to("transparent").opacity(60)
            
            div.relative.h_full.flex.items_center.justify_center.p(12) do
              div.text_center do
                h2("Build amazing apps").text_size("4xl").font_weight("bold").text_color("white").mb(4)
                p("Join our community of developers").text_size("xl").text_color("white").opacity(90)
              end
            end
          end
        end
      end
    end
  end
  
  def auth_layout_card
    swift_ui do
      render AuthLayoutComponent.new(
        variant: :card,
        brand_name: "SwiftUI Rails",
        background_color: "indigo-50"
      ) do |layout|
        layout.with_header do
          div.text_center do
            h3("Welcome Back!").text_size("lg").font_weight("semibold").text_color("gray-900")
            p("Sign in to continue to your dashboard").text_size("sm").text_color("gray-600").mt(1)
          end
        end
        
        layout.with_form do
          render EnhancedLoginComponent.new
        end
        
        layout.with_footer do
          div.flex.justify_center.space_x(4) do
            link("Help", destination: "/help").text_size("sm").text_color("gray-600").hover_text_color("gray-900")
            span("•").text_color("gray-400")
            link("Status", destination: "/status").text_size("sm").text_color("gray-600").hover_text_color("gray-900")
            span("•").text_color("gray-400")
            link("API", destination: "/api").text_size("sm").text_color("gray-600").hover_text_color("gray-900")
          end
        end
      end
    end
  end
  
  def complete_auth_flow
    swift_ui do
      # Tabs for different states
      div.data(controller: "tabs") do
        # Tab navigation
        div.border_b.border_color("gray-200") do
          nav.flex.space_x(8).px(4) do
            button("Login")
              .px(1)
              .py(4)
              .text_size("sm")
              .font_weight("medium")
              .border_b(2)
              .border_color("indigo-500")
              .text_color("indigo-600")
              .data(action: "click->tabs#show", "tabs-target": "tab", "tabs-panel": "login")
            
            button("Register")
              .px(1)
              .py(4)
              .text_size("sm")
              .font_weight("medium")
              .border_b(2)
              .border_color("transparent")
              .text_color("gray-500")
              .hover_text_color("gray-700")
              .data(action: "click->tabs#show", "tabs-target": "tab", "tabs-panel": "register")
            
            button("Error States")
              .px(1)
              .py(4)
              .text_size("sm")
              .font_weight("medium")
              .border_b(2)
              .border_color("transparent")
              .text_color("gray-500")
              .hover_text_color("gray-700")
              .data(action: "click->tabs#show", "tabs-target": "tab", "tabs-panel": "errors")
          end
        end
        
        # Tab panels
        div.mt(4) do
          # Login panel
          div(data: { "tabs-target": "panel", "tabs-panel-name": "login" }) do
            render EnhancedLoginComponent.new
          end
          
          # Register panel
          div.hidden(data: { "tabs-target": "panel", "tabs-panel-name": "register" }) do
            render EnhancedRegisterComponent.new
          end
          
          # Error states panel
          div.hidden(data: { "tabs-target": "panel", "tabs-panel-name": "errors" }) do
            div.grid.grid_cols(2).gap(4) do
              div do
                h4("404 Error").font_weight("semibold").mb(2)
                div.h(300).overflow_hidden.rounded("lg").border do
                  render AuthErrorComponent.new(error_type: :not_found)
                end
              end
              
              div do
                h4("401 Unauthorized").font_weight("semibold").mb(2)
                div.h(300).overflow_hidden.rounded("lg").border do
                  render AuthErrorComponent.new(error_type: :unauthorized)
                end
              end
            end
          end
        end
      end
    end
  end
end
# Copyright 2025
