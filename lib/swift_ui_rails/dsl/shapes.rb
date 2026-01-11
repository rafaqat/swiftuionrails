# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Shapes
      # Circle() or Circle { ... }
      # Renders a div with rounded-full. 
      # If a block is given, it acts as a centering container (ZStack-like behavior).
      def Circle(**attrs, &block)
        classes = "rounded-full"
        
        if block_given?
          # Act as a container that centers content
          classes += " flex items-center justify-center overflow-hidden"
          create_element(:div, nil, class: classes, **attrs, &block)
        else
          # Act as a standalone shape
          create_element(:div, nil, class: classes, **attrs)
        end
      end

      # Rectangle()
      def Rectangle(**attrs, &block)
        if block_given?
          create_element(:div, nil, **attrs, &block)
        else
          create_element(:div, nil, **attrs)
        end
      end

      # RoundedRectangle(radius: 4)
      def RoundedRectangle(radius: 4, **attrs, &block)
        # Map radius to Tailwind classes
        radius_class = case radius
                       when 0..2 then "rounded-sm"
                       when 3..6 then "rounded"
                       when 7..10 then "rounded-md"
                       when 11..16 then "rounded-lg"
                       when 17..24 then "rounded-xl"
                       else "rounded-2xl"
                       end
        
        classes = radius_class
        
        if block_given?
          classes += " flex items-center justify-center overflow-hidden"
          create_element(:div, nil, class: classes, **attrs, &block)
        else
          create_element(:div, nil, class: classes, **attrs)
        end
      end

      # Capsule()
      # Simulates a capsule using large rounded corners
      def Capsule(**attrs, &block)
        classes = "rounded-full" # Tailwind's full is basically capsule for rectangles
        
        if block_given?
          classes += " flex items-center justify-center overflow-hidden"
          create_element(:div, nil, class: classes, **attrs, &block)
        else
          create_element(:div, nil, class: classes, **attrs)
        end
      end
    end
  end
end
