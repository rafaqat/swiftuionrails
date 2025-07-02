# frozen_string_literal: true

class DividerComponent < SwiftUIRails::Component::Base
  prop :orientation, type: String, default: "horizontal"
  prop :thickness, type: String, default: "1"
  prop :color, type: String, default: "gray-200"
  prop :style, type: String, default: "solid"
  prop :length, type: String, default: ""

  swift_ui do
    div_element = divider
    
    if orientation == "vertical"
      div_element = div_element.border_l.border_t_0.h_full.w_0
    end
    
    case thickness
    when "2"
      div_element = div_element.border_2
    when "4"
      div_element = div_element.border_4
    when "8"
      div_element = div_element.border_8
    end
    
    div_element = div_element.border_color(color) if color != "gray-200"
    
    case style
    when "dashed"
      div_element = div_element.border_dashed
    when "dotted"
      div_element = div_element.border_dotted
    end
    
    case length
    when "1/2"
      div_element = div_element.w_1_2
    when "1/3"
      div_element = div_element.w_1_3
    when "2/3"
      div_element = div_element.w_2_3
    when "full"
      div_element = div_element.w_full
    end
    
    div_element
  end
end