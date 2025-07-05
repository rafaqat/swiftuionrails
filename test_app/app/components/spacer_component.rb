# frozen_string_literal: true

class SpacerComponent < SwiftUIRails::Component::Base
  prop :min_length, type: String, default: ""
  prop :direction, type: String, default: "horizontal"
  prop :background_color, type: String, default: ""

  swift_ui do
    spacer_element = spacer(min_length: min_length.present? ? min_length.to_i : nil)
    spacer_element = spacer_element.background(background_color) if background_color.present?
    spacer_element
  end
end
# Copyright 2025
