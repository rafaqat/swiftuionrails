# frozen_string_literal: true

class CardComponent < SwiftUIRails::Component::Base
  prop :title, type: String, default: "Card Title"
  prop :content, type: String, default: "This is a sample card content. Cards are great for organizing related information and creating visual hierarchy."
  prop :elevation, type: Integer, default: 1
  prop :padding, type: String, default: "16"
  prop :corner_radius, type: String, default: "lg"
  prop :background_color, type: String, default: "white"
  prop :border, type: [TrueClass, FalseClass], default: false
  prop :hover_effect, type: [TrueClass, FalseClass], default: false

  swift_ui do
    card_element = card(elevation: elevation) do
      vstack(spacing: 12) do
        text(title)
          .font_size("lg")
          .font_weight("semibold")
          .text_color("gray-900")
        
        text(content)
          .text_color("gray-600")
          .line_clamp(3)
        
        hstack(spacing: 8) do
          button("Primary Action")
            .button_style(:primary)
            .button_size(:sm)
          
          button("Secondary")
            .button_style(:secondary)
            .button_size(:sm)
        end
      end
    end
    
    # Apply dynamic modifiers safely
    card_element = card_element.padding(padding.to_i) if padding.present? && padding != "16"
    card_element = card_element.corner_radius(corner_radius) if corner_radius != "lg"
    card_element = card_element.background(background_color) if background_color != "white"
    card_element = card_element.border if border
    card_element = card_element.hover_scale("105") if hover_effect
    
    card_element
  end
end