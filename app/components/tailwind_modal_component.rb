class TailwindModalComponent < SwiftUIComponent
  prop :title, type: String
  prop :size, type: Symbol, default: :md # :sm, :md, :lg, :xl, :full
  prop :dismissible, type: [TrueClass, FalseClass], default: true
  prop :backdrop, type: Symbol, default: :dark # :dark, :light, :blur
  
  state :open, false
  
  renders_one :trigger
  renders_one :content
  renders_one :footer
  
  SIZE_CLASSES = {
    sm: "max-w-md",
    md: "max-w-lg",
    lg: "max-w-2xl",
    xl: "max-w-4xl",
    full: "max-w-7xl"
  }.freeze
  
  BACKDROP_CLASSES = {
    dark: "bg-gray-900 bg-opacity-50",
    light: "bg-gray-100 bg-opacity-75",
    blur: "bg-gray-900 bg-opacity-25 backdrop-blur-sm"
  }.freeze
  
  swift_ui do
    div do
      # Trigger
      if trigger?
        div.on_tap { self.open = true } do
          trigger
        end
      end
      
      # Modal
      div(
        class: "fixed inset-0 z-50 overflow-y-auto",
        aria_labelledby: "modal-title",
        role: "dialog",
        aria_modal: "true"
      ).tw(open ? "block" : "hidden") do
        div.tw("flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0") do
          # Backdrop
          div(
            class: "fixed inset-0 transition-opacity",
            aria_hidden: "true"
          ).tw(BACKDROP_CLASSES[backdrop])
           .on_tap { self.open = false if dismissible }
          
          # Center modal
          span.tw("hidden sm:inline-block sm:align-middle sm:h-screen") { "&#8203;" }
          
          # Modal panel
          div.tw("inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle #{SIZE_CLASSES[size]} w-full") do
            # Header
            if title || dismissible
              div.tw("bg-gray-50 px-6 py-4 border-b border-gray-200") do
                div.tw("flex items-center justify-between") do
                  h3(id: "modal-title").tw("text-lg leading-6 font-medium text-gray-900") do
                    text(title) if title
                  end
                  
                  if dismissible
                    button(type: "button").tw("ml-3 bg-white rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500")
                      .on_tap { self.open = false } do
                      span.tw("sr-only") { "Close" }
                      # X icon
                      svg(class: "h-6 w-6", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
                        path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M6 18L18 6M6 6l12 12")
                      end
                    end
                  end
                end
              end
            end
            
            # Content
            div.tw("bg-white px-6 py-4") do
              content
            end
            
            # Footer
            if footer?
              div.tw("bg-gray-50 px-6 py-4 border-t border-gray-200") do
                footer
              end
            end
          end
        end
      end
    end
  end
end