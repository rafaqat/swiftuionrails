class TailwindNavigationComponent < SwiftUIComponent
  prop :brand, type: Hash # { name: "App", logo: "/logo.svg", href: "/" }
  prop :items, type: Array, required: true
  prop :current_path, type: String
  prop :variant, type: Symbol, default: :navbar # :navbar, :sidebar, :tabs
  
  state :mobile_menu_open, false
  state :dropdown_open, {}
  
  renders_one :actions
  
  swift_ui do
    case variant
    when :navbar
      render_navbar
    when :sidebar
      render_sidebar
    when :tabs
      render_tabs
    end
  end
  
  private
  
  def render_navbar
    nav.tw("bg-white shadow") do
      div.tw("max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
        div.tw("flex justify-between h-16") do
          # Brand
          div.tw("flex") do
            div.tw("flex-shrink-0 flex items-center") do
              if brand
                link(href: brand[:href] || "/") do
                  if brand[:logo]
                    image(brand[:logo], alt: brand[:name]).tw("h-8 w-auto")
                  else
                    text(brand[:name]).tw("text-xl font-bold text-gray-900")
                  end
                end
              end
            end
            
            # Desktop navigation
            div.tw("hidden sm:ml-8 sm:flex sm:space-x-8") do
              items.each do |item|
                if item[:children]
                  render_dropdown(item)
                else
                  link(item[:title], destination: item[:path])
                    .tw(nav_link_classes(item[:path]))
                end
              end
            end
          end
          
          # Actions
          if actions?
            div.tw("hidden sm:ml-6 sm:flex sm:items-center space-x-4") do
              actions
            end
          end
          
          # Mobile menu button
          div.tw("-mr-2 flex items-center sm:hidden") do
            button.tw("inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100")
              .on_tap { self.mobile_menu_open = !mobile_menu_open } do
              span.tw("sr-only") { "Open main menu" }
              # Hamburger icon
              svg(class: "h-6 w-6", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
                if mobile_menu_open
                  path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M6 18L18 6M6 6l12 12")
                else
                  path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M4 6h16M4 12h16M4 18h16")
                end
              end
            end
          end
        end
      end
      
      # Mobile menu
      div.tw(mobile_menu_open ? "block" : "hidden").tw("sm:hidden") do
        div.tw("pt-2 pb-3 space-y-1") do
          items.each do |item|
            link(item[:title], destination: item[:path])
              .tw(mobile_nav_link_classes(item[:path]))
          end
        end
        
        if actions?
          div.tw("pt-4 pb-3 border-t border-gray-200") do
            div.tw("px-4 space-y-3") do
              actions
            end
          end
        end
      end
    end
  end
  
  def render_dropdown(item)
    div.tw("relative") do
      button.tw(nav_link_classes(nil) + " inline-flex items-center")
        .on_tap { toggle_dropdown(item[:id]) } do
        text(item[:title])
        # Chevron icon
        svg(class: "ml-2 h-5 w-5", fill: "currentColor", viewBox: "0 0 20 20") do
          path(fill_rule: "evenodd", d: "M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z", clip_rule: "evenodd")
        end
      end
      
      # Dropdown menu
      div.tw("absolute z-10 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5")
        .tw(dropdown_open[item[:id]] ? "block" : "hidden") do
        div.tw("py-1") do
          item[:children].each do |child|
            link(child[:title], destination: child[:path])
              .tw("block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100")
          end
        end
      end
    end
  end
  
  def render_tabs
    div.tw("border-b border-gray-200") do
      nav.tw("-mb-px flex space-x-8") do
        items.each do |item|
          link(item[:title], destination: item[:path])
            .tw(tab_link_classes(item[:path]))
        end
      end
    end
  end
  
  def nav_link_classes(path)
    if current_path == path
      "border-b-2 border-blue-500 text-gray-900 inline-flex items-center px-1 pt-1 text-sm font-medium"
    else
      "border-b-2 border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 text-sm font-medium"
    end
  end
  
  def mobile_nav_link_classes(path)
    if current_path == path
      "bg-blue-50 border-l-4 border-blue-500 text-blue-700 block pl-3 pr-4 py-2 text-base font-medium"
    else
      "border-l-4 border-transparent text-gray-600 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-800 block pl-3 pr-4 py-2 text-base font-medium"
    end
  end
  
  def tab_link_classes(path)
    if current_path == path
      "border-b-2 border-blue-500 text-blue-600 py-4 px-1 text-sm font-medium"
    else
      "border-b-2 border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 py-4 px-1 text-sm font-medium"
    end
  end
  
  def toggle_dropdown(id)
    self.dropdown_open = dropdown_open.merge(id => !dropdown_open[id])
  end
end