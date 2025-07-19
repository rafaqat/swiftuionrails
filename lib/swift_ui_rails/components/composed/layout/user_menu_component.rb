# frozen_string_literal: true

module SwiftUIRails
  module Component
    module Composed
      module Layout
        # UserMenuComponent - Toolbar user menu widget
        class UserMenuComponent < SwiftUIRails::Component::Base
          
          # Props
          prop :current_user, type: Object, required: true
          prop :user_menu_items, type: Array, default: []
          prop :show_avatar, type: [TrueClass, FalseClass], default: true
          
          swift_ui do
            user_menu_widget
          end
          
          private
          
          def user_menu_widget
            div.relative do
              # User button
              button do
                hstack(spacing: 2) do
                  if show_avatar && user_avatar_url
                    image(src: user_avatar_url, alt: user_name)
                      .h(8).w(8).rounded_full.object_cover
                  else
                    div.h(8).w(8).bg("gray-400").rounded_full
                      .flex.items_center.justify_center do
                      text(user_initials).text_color("white").text_sm.font_weight("medium")
                    end
                  end
                  
                  text(user_name).font_weight("medium").text_color("gray-700").text_sm
                  
                  span { "▼" }.text_color("gray-400").text_xs
                end
              end
              .p(2)
              .rounded("md")
              .hover_bg("gray-100")
              .data(
                controller: "user-menu",
                action: "click->user-menu#toggle",
                "user-menu-target": "button"
              )
              
              # Dropdown menu
              user_dropdown_menu
            end
          end
          
          def user_dropdown_menu
            div.hidden.absolute.right(0).top("full").mt(2).w(56).bg("white")
              .border.border_color("gray-200").rounded("lg").shadow("lg").z(50)
              .data("user-menu-target": "dropdown") do
              
              # User info header
              div.px(4).py(3).border_b.border_color("gray-100") do
                vstack(spacing: 1) do
                  text(user_name).font_weight("semibold").text_color("gray-900")
                  if user_email
                    text(user_email).text_color("gray-500").text_sm
                  end
                end
              end
              
              # Menu items
              div.py(1) do
                default_menu_items.each { |item| menu_item(item) }
                
                if user_menu_items.any?
                  div.border_t.border_color("gray-100").my(1)
                  user_menu_items.each { |item| menu_item(item) }
                end
                
                # Logout item
                div.border_t.border_color("gray-100").my(1)
                logout_menu_item
              end
            end
          end
          
          def menu_item(item)
            link(item[:label], destination: item[:url] || "#") do
              hstack(spacing: 3) do
                if item[:icon]
                  span { item[:icon] }.text_color("gray-400")
                end
                text(item[:label]).text_color("gray-700")
              end
            end
            .block
            .px(4)
            .py(2)
            .text_sm
            .hover_bg("gray-100")
            .hover_text_color("gray-900")
          end
          
          def logout_menu_item
            button("Sign out") do
              hstack(spacing: 3) do
                span { "🚪" }.text_color("gray-400")
                text("Sign out").text_color("gray-700")
              end
            end
            .block
            .w("full")
            .text_left
            .px(4)
            .py(2)
            .text_sm
            .hover_bg("gray-100")
            .hover_text_color("gray-900")
            .data(
              action: "click->user-menu#logout",
              method: :delete
            )
          end
          
          def default_menu_items
            [
              { label: "Profile", url: "/profile", icon: "👤" },
              { label: "Settings", url: "/settings", icon: "⚙️" },
              { label: "Help", url: "/help", icon: "❓" }
            ]
          end
          
          # Helper methods for user data
          def user_name
            current_user.respond_to?(:name) ? current_user.name : 
            current_user.respond_to?(:display_name) ? current_user.display_name :
            "User"
          end
          
          def user_email
            current_user.respond_to?(:email) ? current_user.email : nil
          end
          
          def user_avatar_url
            current_user.respond_to?(:avatar_url) ? current_user.avatar_url :
            current_user.respond_to?(:avatar) ? current_user.avatar : nil
          end
          
          def user_initials
            name = user_name
            name.split.map(&:first).join.upcase[0..1]
          end
        end
      end
    end
  end
end