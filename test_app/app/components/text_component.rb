# frozen_string_literal: true

class TextComponent < SwiftUIRails::Component::Base
  prop :content, type: String, required: true
  prop :font_size, type: String, default: "base"
  prop :font_weight, type: String, default: "normal"
  prop :text_color, type: String, default: ""
  prop :text_align, type: String, default: ""
  prop :line_clamp, type: String, default: ""
  prop :italic, type: [TrueClass, FalseClass], default: false
  prop :underline, type: [TrueClass, FalseClass], default: false

  swift_ui do
    text_element = text(content)
    
    text_element = text_element.font_size(font_size) if font_size != "base"
    text_element = text_element.font_weight(font_weight) if font_weight != "normal"
    text_element = text_element.text_color(text_color) if text_color.present?
    text_element = text_element.text_align(text_align) if text_align.present?
    text_element = text_element.line_clamp(line_clamp) if line_clamp.present?
    text_element = text_element.italic if italic
    text_element = text_element.underline if underline
    
    text_element
  end
end
# Copyright 2025
