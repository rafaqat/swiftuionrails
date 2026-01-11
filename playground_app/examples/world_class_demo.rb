# frozen_string_literal: true

module WorldClassDemo
  APP_UI = <<~'RUBY'
    swift_ui do
      environment(accent: :indigo, dark_mode: false) do
        NavigationStack do
          NavigationTitle("Messages")
          
          List(style: :plain) do
            LazyVStack do
              ForEach(1..100) do |i|
                NavigationLink(destination: "/message/#{i}") do
                  MessageRow(i)
                end
              end
            end
          end
        end
      end
    end

    # Extracted Sub-View (SwiftUI "ViewBuilder" pattern)
    def MessageRow(i)
      hstack(alignment: :center, spacing: 4) do
        # Avatar
        Circle {
          Text(i.to_s).foregroundStyle(:white).font(:headline)
        }.frame(12).fill(env(:accent))
        
        # Content
        vstack(alignment: :leading, spacing: 1).flex_1 do
          hstack(justify: :between) do
            Text("User #{i}").font(:headline)
            Text("10:30 AM").font(:caption).foregroundStyle(:gray)
          end
          
          # Using the new Label for metadata
          hstack(spacing: 2) do
            Image(system_name: :envelope).foregroundStyle(:gray)
            Text("New message received...").font(:subheadline).foregroundStyle(:gray).line_clamp(1)
          end
        end
        
        Image(system_name: :arrow_right).foregroundStyle(:gray_300)
      end.padding(:y, 2)
    end
  RUBY
end