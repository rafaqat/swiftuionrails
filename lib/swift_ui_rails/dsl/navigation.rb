# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Navigation
      # NavigationStack { ... }
      # Wraps content in a Turbo Frame that handles navigation events
      def NavigationStack(path: nil, **attrs, &block)
        id = attrs[:id] || "root_navigation"
        
        # Styles for the stack container
        attrs[:class] = class_names("relative w-full h-full overflow-hidden bg-white", attrs[:class])
        
        # We use a Turbo Frame as the navigation container
        create_element("turbo-frame", nil, id: id, **attrs) do
          # Initial view
          yield
        end
      end

      # NavigationLink("Label", destination: "/path")
      # Triggers a Turbo visit to the target frame
      def NavigationLink(label = nil, destination:, **attrs, &block)
        attrs[:href] = destination
        attrs[:data] ||= {}
        attrs[:data][:turbo_frame] = "_top" # Default to full page for now, or target specific frame
        
        # Add slide transition data attributes (requires custom Turbo/Stimulus logic later)
        attrs[:data][:transition] = "slide" 
        
        if block_given?
          # Block content acts as the link trigger
          create_element(:a, nil, **attrs, &block)
        else
          # Standard link style (iOS style list item)
          create_element(:a, nil, class: "flex items-center justify-between w-full p-4 hover:bg-gray-50 transition", **attrs) do
            text(label).font(:body).fg(:black)
            text("›").fg(:gray_400).font(:body)
          end
        end
      end
      
      # NavigationTitle("Title")
      def NavigationTitle(title)
        # Sets the title for the current navigation stack context
        # In a real app, this might update a sticky header
        div(class: "sticky top-0 z-10 bg-white/90 backdrop-blur border-b border-gray-200 px-4 py-3") do
          h1(class: "text-lg font-bold text-center") { text(title) }
        end
      end
    end
  end
end
