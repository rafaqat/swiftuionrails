# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Charts
      # Chart { BarMark(...) }
      def Chart(**attrs, &block)
        # In a real app, this would serialize the data for a JS library like Chart.js
        # For this DSL demo, we'll render a simple SVG container
        
        attrs[:class] = class_names("w-full h-64 bg-gray-50 rounded-lg flex items-end justify-between p-4 gap-2", attrs[:class])
        
        create_element(:div, nil, **attrs, &block)
      end

      # BarMark(x: "Day", y: 10)
      def BarMark(x:, y:, color: :blue, **attrs)
        # Simple CSS-based bar
        height_percent = [y, 100].min # Mock scaling
        
        vstack(spacing: 1, alignment: :center, class: "h-full justify-end flex-1") do
          div(
            class: "w-full rounded-t bg-#{color}-500 hover:bg-#{color}-600 transition-all",
            style: "height: #{height_percent}%"
          )
          Text(x.to_s).font(:caption).foreground(:gray)
        end
      end
      
      # LineMark would be harder in pure CSS, typically requires SVG path generation
      # For now, we focus on BarMark as proof of concept
    end
  end
end
