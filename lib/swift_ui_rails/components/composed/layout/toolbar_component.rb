# frozen_string_literal: true

module SwiftUIRails
  module Components
    module Composed
      module Layout
        # ToolbarComponent - A flexible toolbar with built-in functionality
        #
        # Features:
        # - Responsive layout (collapses to hamburger menu on mobile)
        # - Action grouping (left, center, right)
        # - Built-in search functionality
        # - User menu dropdown
        # - Notification center
        # - Breadcrumb navigation
        # - Customizable through slots and props
        # - Stimulus controller integration
        #
        # Usage:
        #   <%= render ToolbarComponent.new(
        #     brand_text: "My App",
        #     show_search: true,
        #     show_notifications: true
        #   ) do |toolbar| %>
        #     <% toolbar.with_left_action type: :button do %>
        #       <%= button "New", onclick: "..." %>
        #     <% end %>
        #     <% toolbar.with_center_content do %>
        #       Current Project: <%= @project.name %>
        #     <% end %>
        #     <% toolbar.with_right_action type: :user_menu do %>
        #       <%= current_user.name %>
        #     <% end %>
        #   <% end %>
        class ToolbarComponent < SwiftUIRails::Component::Base
          include StatefulComponent
          
          # Props for configuration
          prop :brand_text, type: String, default: "App"
          prop :brand_logo, type: String, default: nil
          prop :brand_url, type: String, default: "/"
          prop :height, type: String, default: "16" # h-16 (64px)
          prop :sticky, type: [TrueClass, FalseClass], default: true
          prop :shadow, type: [TrueClass, FalseClass], default: true
          prop :background, type: String, default: "white"
          prop :border, type: [TrueClass, FalseClass], default: true
          
          # Feature toggles
          prop :show_search, type: [TrueClass, FalseClass], default: false
          prop :show_notifications, type: [TrueClass, FalseClass], default: false
          prop :show_user_menu, type: [TrueClass, FalseClass], default: true
          prop :show_breadcrumbs, type: [TrueClass, FalseClass], default: false
          prop :responsive, type: [TrueClass, FalseClass], default: true
          
          # Search configuration
          prop :search_url, type: String, default: "/search"
          prop :search_placeholder, type: String, default: "Search..."
          
          # User menu configuration
          prop :current_user, type: Object, default: nil
          prop :user_menu_items, type: Array, default: []
          
          # Breadcrumb data
          prop :breadcrumbs, type: Array, default: []
          
          # State management
          state :mobile_menu_open, default: false
          state :search_open, default: false
          state :user_menu_open, default: false
          state :search_query, default: ""
          state :notification_count, default: 0
          
          # Computed properties
          computed :has_brand_logo do
            brand_logo.present?
          end
          
          computed :toolbar_classes do
            classes = ["toolbar"]
            classes << "sticky top-0 z-50" if sticky
            classes << "shadow-sm" if shadow
            classes << "border-b border-gray-200" if border
            classes.join(" ")
          end
          
          # Polymorphic slots for maximum flexibility
          slot :brand, default: -> { default_brand }
          slot :left_actions, many: true, types: {
            button: ->(text:, action: nil, variant: :secondary, **options) { 
              action_button(text, action, variant, position: :left, **options) 
            },
            link: ->(text:, url:, **options) { 
              action_link(text, url, position: :left, **options) 
            },
            dropdown: ->(trigger_text:, items: [], **options) { 
              dropdown_menu(trigger_text, items, position: :left, **options) 
            },
            custom: ->(content: nil, &block) { 
              custom_action(content, position: :left, &block) 
            }
          }
          slot :center_content, default: -> { default_center_content }
          slot :right_actions, many: true, types: {
            button: ->(text:, action: nil, variant: :secondary, **options) { 
              action_button(text, action, variant, position: :right, **options) 
            },
            link: ->(text:, url:, **options) { 
              action_link(text, url, position: :right, **options) 
            },
            dropdown: ->(trigger_text:, items: [], **options) { 
              dropdown_menu(trigger_text, items, position: :right, **options) 
            },
            search: ->(**options) { search_widget(**options) },
            notifications: ->(**options) { notifications_widget(**options) },
            user_menu: ->(**options) { user_menu_widget(**options) },
            custom: ->(content: nil, &block) { 
              custom_action(content, position: :right, &block) 
            }
          }
          
          # Effects
          effect :mobile_menu_open do |open|
            toggle_body_scroll(!open)
          end
          
          swift_ui do
            toolbar_container do
              if responsive
                responsive_toolbar
              else
                desktop_toolbar
              end
            end
          end
          
          private
          
          # Main toolbar structure
          def toolbar_container(&block)
            nav.h(height)
              .bg(background)
              .tap { |nav| nav.sticky.top(0).z(50) if sticky }
              .tap { |nav| nav.shadow("sm") if shadow }
              .tap { |nav| nav.border_b.border_color("gray-200") if border }
              .data(
                controller: "toolbar",
                "toolbar-mobile-menu-open-value": mobile_menu_open,
                "toolbar-search-url-value": search_url
              ) do
              yield
            end
          end
          
          def responsive_toolbar
            vstack(spacing: 0) do
              # Main toolbar
              desktop_toolbar
              
              # Mobile menu (hidden by default)
              mobile_menu if responsive
              
              # Breadcrumbs (if enabled)
              breadcrumbs_section if show_breadcrumbs && breadcrumbs.any?
            end
          end
          
          def desktop_toolbar
            div.h("full").px(4).lg_px(6) do
              hstack(spacing: 4, justify: :between) do
                # Left section: Brand + Left Actions
                left_section
                
                # Center section: Custom content or search
                center_section
                
                # Right section: Right Actions
                right_section
              end
              .h("full")
            end
          end
          
          def left_section
            hstack(spacing: 4) do
              # Mobile menu button (responsive only)
              if responsive
                mobile_menu_button
              end
              
              # Brand
              brand_section
              
              # Left actions (hidden on mobile if responsive)
              if left_actions.any?
                hstack(spacing: 2)
                  .tap { |stack| stack.hidden.lg_flex if responsive } do
                  left_actions.each { |action| action }
                end
              end
            end
          end
          
          def center_section
            div.flex_1.flex.justify_center do
              if search_open
                expanded_search_widget
              else
                render_center_content { default_center_content }
              end
            end
          end
          
          def right_section
            hstack(spacing: 2) do
              # Search toggle (mobile)
              if show_search && responsive
                search_toggle_button
              end
              
              # Right actions
              right_actions.each { |action| action }
              
              # Built-in widgets
              if show_notifications
                notifications_widget
              end
              
              if show_user_menu && current_user
                user_menu_widget
              end
            end
          end
          
          # Brand section
          def brand_section
            link(destination: brand_url) do
              hstack(spacing: 3) do
                if has_brand_logo
                  image(src: brand_logo, alt: brand_text)
                    .h(8).w(8).object_contain
                end
                
                text(brand_text)
                  .font_size("xl")
                  .font_weight("bold")
                  .text_color("gray-900")
                  .tap { |text| text.hidden.sm_block if has_brand_logo }
              end
            end
            .flex.items_center
          end
          
          # Mobile menu button
          def mobile_menu_button
            button do
              icon("menu").size(24)
            end
            .lg_hidden
            .p(2)
            .text_color("gray-400")
            .hover_text_color("gray-600")
            .data(
              action: "click->toolbar#toggleMobileMenu",
              "toolbar-target": "mobileMenuButton"
            )
          end
          
          # Mobile menu overlay
          def mobile_menu
            div.lg_hidden
              .tap { |menu| menu.hidden unless mobile_menu_open }
              .data("toolbar-target": "mobileMenu") do
              
              # Backdrop
              div.fixed.inset(0).bg("black").opacity(25).z(40)
                .data(action: "click->toolbar#closeMobileMenu")
              
              # Menu panel
              div.fixed.top(height).left(0).right(0).bg("white").border_b.shadow("lg").z(50) do
                vstack(spacing: 0) do
                  # Mobile left actions
                  if left_actions.any?
                    mobile_action_section("Actions", left_actions)
                  end
                  
                  # Mobile search (if enabled)
                  if show_search
                    mobile_search_section
                  end
                  
                  # Mobile user menu (if enabled)
                  if show_user_menu && current_user
                    mobile_user_section
                  end
                end
                .py(4)
              end
            end
          end
          
          def mobile_action_section(title, actions)
            div.px(4).py(3).border_b.border_color("gray-100") do
              text(title).font_weight("medium").text_color("gray-900").text_sm.mb(2)
              vstack(spacing: 2) do
                actions.each { |action| mobile_action_wrapper { action } }
              end
            end
          end
          
          def mobile_action_wrapper(&block)
            div.py(2) { yield }
          end
          
          # Search functionality
          def search_widget(**options)
            if responsive
              compact_search_widget(**options)
            else
              full_search_widget(**options)
            end
          end
          
          def compact_search_widget(**options)
            button do
              icon("search").size(20)
            end
            .p(2)
            .text_color("gray-400")
            .hover_text_color("gray-600")
            .rounded("md")
            .hover_bg("gray-100")
            .data(action: "click->toolbar#toggleSearch")
          end
          
          def full_search_widget(**options)
            form.flex.items_center
              .data(
                action: "submit->toolbar#performSearch",
                "toolbar-target": "searchForm"
              ) do
              
              div.relative do
                textfield(
                  name: "q",
                  placeholder: search_placeholder,
                  value: search_query
                )
                .pl(10).pr(4).py(2)
                .w(80)
                .border.border_color("gray-300")
                .rounded("md")
                .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
                .data(
                  "toolbar-target": "searchInput",
                  action: "input->toolbar#updateSearchQuery"
                )
                
                # Search icon
                div.absolute.left(3).top("50%").transform("translate-y-1/2") do
                  icon("search").size(16).text_color("gray-400")
                end
              end
            end
          end
          
          def expanded_search_widget
            form.w("full").max_w("lg")
              .data(
                action: "submit->toolbar#performSearch",
                "toolbar-target": "expandedSearchForm"
              ) do
              
              hstack(spacing: 2) do
                # Search input
                textfield(
                  name: "q",
                  placeholder: search_placeholder,
                  value: search_query
                )
                .flex_1
                .px(4).py(2)
                .border.border_color("gray-300")
                .rounded("md")
                .focus_outline_none.focus_ring(2).focus_ring_color("blue-500")
                .data(
                  "toolbar-target": "expandedSearchInput",
                  action: "input->toolbar#updateSearchQuery"
                )
                
                # Close search button
                button("Cancel")
                  .text_sm.text_color("gray-600")
                  .data(action: "click->toolbar#closeSearch")
              end
            end
          end
          
          def search_toggle_button
            button do
              icon("search").size(20)
            end
            .p(2)
            .text_color("gray-400")
            .hover_text_color("gray-600")
            .data(action: "click->toolbar#toggleSearch")
          end
          
          def mobile_search_section
            div.px(4).py(3).border_b.border_color("gray-100") do
              form.w("full")
                .data(action: "submit->toolbar#performSearch") do
                
                textfield(
                  name: "q",
                  placeholder: search_placeholder,
                  value: search_query
                )
                .w("full")
                .px(4).py(2)
                .border.border_color("gray-300")
                .rounded("md")
                .data(action: "input->toolbar#updateSearchQuery")
              end
            end
          end
          
          # Notifications widget
          def notifications_widget(**options)
            div.relative do
              button do
                icon("bell").size(20)
                
                # Notification badge
                if notification_count > 0
                  span(notification_count.to_s)
                    .absolute.top(-1).right(-1)
                    .bg("red-500").text_color("white")
                    .text_xs.rounded_full
                    .h(5).w(5)
                    .flex.items_center.justify_center
                end
              end
              .p(2)
              .text_color("gray-400")
              .hover_text_color("gray-600")
              .rounded("md")
              .hover_bg("gray-100")
              .data(action: "click->toolbar#toggleNotifications")
              
              # Notifications dropdown (would be implemented)
              # notifications_dropdown
            end
          end
          
          # User menu widget
          def user_menu_widget(**options)
            div.relative do
              button do
                if current_user&.avatar_url
                  image(src: current_user.avatar_url, alt: current_user.name)
                    .h(8).w(8).rounded_full.object_cover
                else
                  div.h(8).w(8).bg("gray-300").rounded_full.flex.items_center.justify_center do
                    text(current_user&.initials || "U")
                      .text_sm.font_weight("medium").text_color("white")
                  end
                end
              end
              .data(action: "click->toolbar#toggleUserMenu")
              
              # User menu dropdown
              user_menu_dropdown if user_menu_open
            end
          end
          
          def user_menu_dropdown
            div.absolute.right(0).top("full").mt(2).w(56)
              .bg("white").rounded("md").shadow("lg").border.border_color("gray-200")
              .z(50)
              .data("toolbar-target": "userMenuDropdown") do
              
              # User info section
              div.px(4).py(3).border_b.border_color("gray-100") do
                text(current_user.name).font_weight("medium").text_color("gray-900")
                text(current_user.email).text_sm.text_color("gray-500")
              end
              
              # Menu items
              vstack(spacing: 0) do
                user_menu_items.each do |item|
                  user_menu_item(item)
                end
                
                # Logout
                div.border_t.border_color("gray-100").pt(1) do
                  user_menu_item({
                    text: "Sign out",
                    url: "/logout",
                    method: :delete,
                    class: "text-red-600 hover:text-red-700"
                  })
                end
              end
              .py(1)
            end
          end
          
          def user_menu_item(item)
            if item[:url]
              link(item[:text], destination: item[:url])
                .block.px(4).py(2).text_sm
                .hover_bg("gray-100")
                .text_color(item[:class] || "gray-700")
                .data(method: item[:method]) if item[:method]
            else
              button(item[:text])
                .w("full").text_left.px(4).py(2).text_sm
                .hover_bg("gray-100")
                .text_color(item[:class] || "gray-700")
                .data(action: item[:action]) if item[:action]
            end
          end
          
          def mobile_user_section
            div.px(4).py(3) do
              # User info
              hstack(spacing: 3) do
                if current_user&.avatar_url
                  image(src: current_user.avatar_url, alt: current_user.name)
                    .h(10).w(10).rounded_full.object_cover
                else
                  div.h(10).w(10).bg("gray-300").rounded_full.flex.items_center.justify_center do
                    text(current_user&.initials || "U")
                      .font_weight("medium").text_color("white")
                  end
                end
                
                vstack(spacing: 1) do
                  text(current_user.name).font_weight("medium").text_color("gray-900")
                  text(current_user.email).text_sm.text_color("gray-500")
                end
              end
              
              # Mobile user actions
              vstack(spacing: 1).mt(3) do
                user_menu_items.each do |item|
                  user_menu_item(item)
                end
              end
            end
          end
          
          # Breadcrumbs section
          def breadcrumbs_section
            div.px(4).py(2).bg("gray-50").border_b.border_color("gray-200") do
              breadcrumb_list
            end
          end
          
          def breadcrumb_list
            hstack(spacing: 2) do
              breadcrumbs.each_with_index do |crumb, index|
                if index > 0
                  icon("chevron-right").size(16).text_color("gray-400")
                end
                
                if index == breadcrumbs.length - 1
                  # Current page
                  text(crumb[:text]).text_sm.text_color("gray-900").font_weight("medium")
                else
                  # Breadcrumb link
                  link(crumb[:text], destination: crumb[:url])
                    .text_sm.text_color("gray-600").hover_text_color("gray-900")
                end
              end
            end
          end
          
          # Action helpers
          def action_button(text, action, variant, position:, **options)
            button(text)
              .tap { |btn| apply_button_variant(btn, variant) }
              .data(action: action) if action
          end
          
          def action_link(text, url, position:, **options)
            link(text, destination: url)
              .text_sm.font_weight("medium")
              .text_color("gray-700").hover_text_color("gray-900")
          end
          
          def dropdown_menu(trigger_text, items, position:, **options)
            # Dropdown implementation would go here
            # This would use the same patterns as user_menu_dropdown
            button(trigger_text)
              .text_sm.font_weight("medium")
              .text_color("gray-700").hover_text_color("gray-900")
          end
          
          def custom_action(content, position:, &block)
            if block_given?
              yield
            else
              text(content.to_s)
            end
          end
          
          # Default slot implementations
          def default_brand
            brand_section
          end
          
          def default_center_content
            if show_search && !responsive
              full_search_widget
            else
              # Empty center content
              div
            end
          end
          
          # Helper methods
          def apply_button_variant(button, variant)
            case variant
            when :primary
              button.bg("blue-600").text_color("white").hover_bg("blue-700")
            when :secondary
              button.border.border_color("gray-300").hover_bg("gray-50")
            when :ghost
              button.hover_bg("gray-100")
            end
            
            button.px(3).py(2).text_sm.font_weight("medium").rounded("md").transition
          end
          
          def toggle_body_scroll(enable_scroll)
            # This would be handled by the Stimulus controller
            # to prevent body scroll when mobile menu is open
          end
        end
      end
    end
  end
end