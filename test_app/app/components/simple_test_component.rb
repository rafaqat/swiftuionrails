# frozen_string_literal: true

class SimpleTestComponent < SwiftUIRails::Component::Base
  prop :message, type: String, default: "Hello World"
  
  swift_ui do
    div do
      text(message)
        .font_size("2xl")
        .font_weight("bold")
        .text_color("blue-600")
    end
  end
end