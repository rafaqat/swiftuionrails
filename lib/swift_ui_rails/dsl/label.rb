# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Label
      # Label("Title", system_image: :star)
      # Label { ... } icon: { ... }
      def Label(title = nil, system_image: nil, **attrs, &block)
        # Default styling
        attrs[:class] = class_names("flex items-center gap-2", attrs[:class])
        
        create_element(:div, nil, **attrs) do
          if block_given?
            # Custom content
            yield
          else
            # Standard Icon + Text layout
            if system_image
              # We can use our Shapes or SVG logic here.
              # For now, using a simple symbol-to-icon text mapping or the actual icon if we had an icon set.
              # In a real app, this maps to Heroicons/SF Symbols.
              Image(system_name: system_image).foregroundStyle(:accent)
            end
            
            Text(title).font(:body)
          end
        end
      end

      # Helper for System Images (SF Symbols style)
      def Image(system_name:, **attrs)
        # Mapping common SF Symbol names to simple emojis or SVG paths for the demo
        icon = case system_name
               when :star then "⭐️"
               when :heart then "❤️"
               when :gear then "⚙️"
               when :person then "👤"
               when :envelope then "✉️"
               when :arrow_right then "›"
               when :circle_fill then "●"
               else "•"
               end
        
        # In a real implementation, this renders an SVG
        Text(icon).font(:title3)
      end
    end
  end
end
