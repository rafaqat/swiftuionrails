# frozen_string_literal: true

class HstackComponent < SwiftUIRails::Component::Base
  prop :spacing, type: Integer, default: 8
  prop :alignment, type: Symbol, default: :center
  prop :background_color, type: String, default: ""
  prop :padding, type: String, default: ""

  swift_ui do
    stack = hstack(spacing: spacing, alignment: alignment) do
      button("First")
        .button_style(:primary)
        .button_size(:sm)
      
      text("Middle Text")
        .font_weight("medium")
      
      button("Last")
        .button_style(:secondary)
        .button_size(:sm)
    end
    
    stack = stack.background(background_color) if background_color.present?
    stack = stack.padding(padding) if padding.present?
    
    stack
  end
end