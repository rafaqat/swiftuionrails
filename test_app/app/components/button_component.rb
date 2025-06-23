# frozen_string_literal: true

class ButtonComponent < SwiftUIRails::Component::Base
  prop :title, type: String, required: true
  prop :variant, type: Symbol, default: :primary
  prop :size, type: Symbol, default: :md
  prop :disabled, type: [TrueClass, FalseClass], default: false
  prop :full_width, type: [TrueClass, FalseClass], default: false
  prop :corner_radius, type: String, default: "md"
  prop :custom_background, type: String, default: ""
  prop :custom_text_color, type: String, default: ""

  swift_ui do
    btn = button(title)
      .button_style(variant)
      .button_size(size)
    
    btn = btn.disabled if disabled
    btn = btn.w_full if full_width
    btn = btn.corner_radius(corner_radius) if corner_radius != "md"
    btn = btn.background(custom_background) if custom_background.present?
    btn = btn.text_color(custom_text_color) if custom_text_color.present?
    
    btn
  end
end