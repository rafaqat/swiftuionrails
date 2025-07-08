# frozen_string_literal: true

# Copyright 2025

class LinkComponent < SwiftUIRails::Component::Base
  # Default styling constants
  DEFAULT_TEXT_COLOR = "blue-600"
  DEFAULT_HOVER_COLOR = "blue-800"
  DEFAULT_FONT_WEIGHT = "normal"
  DEFAULT_FONT_SIZE = "base"
  DEFAULT_UNDERLINE = "hover"

  # Valid underline options
  UNDERLINE_OPTIONS = %w[none always hover].freeze

  prop :text, type: String, default: "Learn More"
  prop :destination, type: String, default: "#"
  prop :target, type: String, default: ""
  prop :text_color, type: String, default: DEFAULT_TEXT_COLOR
  prop :hover_color, type: String, default: DEFAULT_HOVER_COLOR
  prop :underline, type: String, default: DEFAULT_UNDERLINE
  prop :font_weight, type: String, default: DEFAULT_FONT_WEIGHT
  prop :font_size, type: String, default: DEFAULT_FONT_SIZE

  swift_ui do
    link(text, destination: destination).tap do |l|
      l.target(target) if target.present?
      l.text_color(text_color) if text_color != DEFAULT_TEXT_COLOR
      l.hover_text_color(hover_color) if hover_color != DEFAULT_HOVER_COLOR

      case underline
      when "none"
        l.no_underline
      when "always"
        l.underline
      when "hover"
        l.hover_underline
      end

      l.font_weight(font_weight) if font_weight != DEFAULT_FONT_WEIGHT
      l.font_size(font_size) if font_size != DEFAULT_FONT_SIZE
    end
  end
end
# Copyright 2025
