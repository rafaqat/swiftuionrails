# frozen_string_literal: true

module SwiftUIRails
  module Component
    module Composed
      module Layout
        # NotificationsComponent - Toolbar notifications widget
        class NotificationsComponent < SwiftUIRails::Component::Base
          
          # Props
          prop :notification_count, type: Integer, default: 0
          prop :notifications, type: Array, default: []
          prop :show_badge, type: [TrueClass, FalseClass], default: true
          
          swift_ui do
            notifications_widget
          end
          
          private
          
          def notifications_widget
            div.relative do
              button do
                span { "🔔" }
                
                # Notification badge
                if show_badge && notification_count > 0
                  span(notification_count.to_s)
                    .absolute
                    .top(-2)
                    .right(-2)
                    .h(5)
                    .w(5)
                    .bg("red-500")
                    .text_color("white")
                    .text_xs
                    .rounded_full
                    .flex
                    .items_center
                    .justify_center
                end
              end
              .p(2)
              .text_color("gray-400")
              .hover_text_color("gray-600")
              .rounded("md")
              .hover_bg("gray-100")
              .data(
                controller: "notifications",
                action: "click->notifications#toggle",
                "notifications-target": "button"
              )
              
              # Dropdown menu (hidden by default)
              notifications_dropdown
            end
          end
          
          def notifications_dropdown
            div.hidden.absolute.right(0).top("full").mt(2).w(80).bg("white")
              .border.border_color("gray-200").rounded("lg").shadow("lg").z(50)
              .data("notifications-target": "dropdown") do
              
              # Header
              div.px(4).py(3).border_b.border_color("gray-100") do
                hstack(justify: :between) do
                  text("Notifications").font_weight("semibold").text_color("gray-900")
                  if notification_count > 0
                    span("#{notification_count} new")
                      .text_xs.text_color("blue-600").bg("blue-100")
                      .px(2).py(1).rounded("full")
                  end
                end
              end
              
              # Notifications list
              div.max_h(96).overflow_y("auto") do
                if notifications.any?
                  notifications.each { |notification| notification_item(notification) }
                else
                  empty_notifications
                end
              end
              
              # Footer
              div.px(4).py(3).border_t.border_color("gray-100") do
                link("View all notifications", destination: "/notifications")
                  .text_sm.text_color("blue-600").hover_text_color("blue-500")
                  .block.text_center
              end
            end
          end
          
          def notification_item(notification)
            div.px(4).py(3).border_b.border_color("gray-50").hover_bg("gray-50") do
              vstack(spacing: 1) do
                text(notification[:title] || "Notification")
                  .font_weight("medium").text_color("gray-900").text_sm
                
                if notification[:message]
                  text(notification[:message])
                    .text_color("gray-600").text_xs.line_clamp(2)
                end
                
                if notification[:time]
                  text(notification[:time])
                    .text_color("gray-400").text_xs.mt(1)
                end
              end
            end
          end
          
          def empty_notifications
            div.px(4).py(8).text_center do
              text("No new notifications")
                .text_color("gray-500").text_sm
            end
          end
        end
      end
    end
  end
end