# frozen_string_literal: true

module CompositeFormExample
  SETTINGS_UI = <<~'RUBY'
    swift_ui do
      # 1. Register a custom modifier (meta-style)
      SwiftUIRails::DSL.register_modifier(:settings_icon) do |el|
        el.w(8).h(8).rounded(:md).flex.items_center.justify_center.fg(:white)
      end

      # 2. Build the Settings Screen
      List(style: :inset_grouped) do
        
        # Section 1: Connectivity
        Section(header: "Connectivity") do
          
          # Airplane Mode
          hstack do
            div.style(:settings_icon).bg(:orange) do
              text("✈️")
            end
            toggle("Airplane Mode", is_on: false).flex_1.padding(:leading, 3)
          end.padding
          
          # Wi-Fi
          hstack do
            div.style(:settings_icon).bg(:blue) do
              text("📶")
            end
            hstack(justify: :between).flex_1.padding(:leading, 3) do
              text("Wi-Fi")
              hstack(spacing: 2) do
                text("Home Network").fg(:gray_500)
                text("›").fg(:gray_400)
              end
            end
          end.padding
          
        end

        # Section 2: Notifications
        Section(header: "Notifications", footer: "Customize how apps send you alerts.") do
          hstack do
            div.style(:settings_icon).bg(:red) do
              text("🔔")
            end
            hstack(justify: :between).flex_1.padding(:leading, 3) do
              text("Notifications")
              text("›").fg(:gray_400)
            end
          end.padding
        end

      end
    end
  RUBY
end
