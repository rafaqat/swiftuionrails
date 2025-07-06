# frozen_string_literal: true
# Copyright 2025

class VstackComponent < SwiftUIRails::Component::Base
  prop :spacing, type: Integer, default: 8
  prop :alignment, type: Symbol, default: :center
  prop :background_color, type: String, default: ""
  prop :padding, type: String, default: ""
  prop :corner_radius, type: String, default: ""

  swift_ui do
    stack = vstack(spacing: spacing, alignment: alignment) do
      text("First Item")
        .font_weight("semibold")
        .text_color("gray-900")
      
      text("Second Item")
        .font_size("sm")
        .text_color("gray-600")
      
      button("Action Button")
        .button_style(:primary)
        .button_size(:sm)
      
      text("Last Item")
        .font_size("xs")
        .text_color("gray-500")
    end
    
    stack = stack.background(background_color) if background_color.present?
    stack = stack.padding(padding) if padding.present?
    stack = stack.corner_radius(corner_radius) if corner_radius.present?
    
    stack
  end
end
# Copyright 2025
