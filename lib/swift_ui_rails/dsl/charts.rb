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
      # Tailwind requires static class names - we use explicit color mappings
      BAR_COLORS = {
        blue: "bg-blue-500 hover:bg-blue-600",
        red: "bg-red-500 hover:bg-red-600",
        green: "bg-green-500 hover:bg-green-600",
        purple: "bg-purple-500 hover:bg-purple-600",
        orange: "bg-orange-500 hover:bg-orange-600",
        pink: "bg-pink-500 hover:bg-pink-600",
        yellow: "bg-yellow-500 hover:bg-yellow-600",
        gray: "bg-gray-500 hover:bg-gray-600",
        indigo: "bg-indigo-500 hover:bg-indigo-600",
        teal: "bg-teal-500 hover:bg-teal-600"
      }.freeze

      def BarMark(x:, y:, color: :blue, **attrs)
        # Simple CSS-based bar
        height_percent = [y, 100].min # Mock scaling
        bar_classes = BAR_COLORS[color.to_sym] || BAR_COLORS[:blue]

        vstack(spacing: 1, alignment: :center, class: "h-full justify-end flex-1") do
          div(
            class: "w-full rounded-t #{bar_classes} transition-all",
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
