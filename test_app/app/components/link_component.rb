# frozen_string_literal: true

class LinkComponent < SwiftUIRails::Component::Base
  prop :text, type: String, default: "Learn More"
  prop :destination, type: String, default: "#"
  prop :target, type: String, default: ""
  prop :text_color, type: String, default: "blue-600"
  prop :hover_color, type: String, default: "blue-800"
  prop :underline, type: String, default: "hover"
  prop :font_weight, type: String, default: "normal"
  prop :font_size, type: String, default: "base"

  swift_ui do
    link_element = link(text, destination: destination)
    
    link_element = link_element.target(target) if target.present?
    link_element = link_element.text_color(text_color) if text_color != "blue-600"
    link_element = link_element.hover_text_color(hover_color) if hover_color != "blue-800"
    
    case underline
    when "none"
      link_element = link_element.no_underline
    when "always"
      link_element = link_element.underline
    when "hover"
      link_element = link_element.hover_underline
    end
    
    link_element = link_element.font_weight(font_weight) if font_weight != "normal"
    link_element = link_element.font_size(font_size) if font_size != "base"
    
    link_element
  end
end