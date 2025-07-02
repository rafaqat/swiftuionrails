# frozen_string_literal: true

class IconComponent < SwiftUIRails::Component::Base
  prop :name, type: String, default: "star"
  prop :size, type: Integer, default: 24
  prop :color, type: String, default: "gray-500"
  prop :stroke_width, type: Float, default: 2.0
  prop :filled, type: [TrueClass, FalseClass], default: false

  swift_ui do
    icon_element = icon(name, size: size)
    icon_element = icon_element.text_color(color) if color != "gray-500"
    icon_element = icon_element.stroke_width(stroke_width) if stroke_width != 2.0
    icon_element = icon_element.filled if filled
    icon_element
  end
end