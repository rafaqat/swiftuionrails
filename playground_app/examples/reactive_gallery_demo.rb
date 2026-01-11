# frozen_string_literal: true

module ReactiveGalleryDemo
  APP_UI = <<~'RUBY'
    class ReactiveGallery < SwiftUIRails::Component::Base
      state :notifications_enabled, true
      state :volume, 50
      state :username, "Guest"
      state :selected_tab, "home"

      swift_ui do
        NavigationStack do
          NavigationTitle("Reactive Controls")
          
          List(style: :inset_grouped) do
            Section(header: "Profile") do
              TextField("Username", text: :username)
              
              hstack {
                Text("Hello, ")
                Text(username).font_bold.foreground(:blue)
              }
            end
            
            Section(header: "Settings") do
              Toggle("Enable Notifications", isOn: :notifications_enabled)
              
              if notifications_enabled
                hstack {
                  Image(system_name: :bell).foreground(:green)
                  Text("Notifications are ON")
                }
              else
                hstack {
                  Image(system_name: :bell_slash).foreground(:red)
                  Text("Notifications are OFF")
                }
              end
            end
            
            Section(header: "Volume Control") do
              hstack {
                Image(system_name: :speaker)
                Slider(value: :volume, range: 0..100)
                Image(system_name: :speaker_wave_3)
              }
              Text("Level: #{volume}").font(:caption).foreground(:gray)
            end
          end
        end
      end
    end
    
    # Render the component
    render ReactiveGallery.new
  RUBY
end
