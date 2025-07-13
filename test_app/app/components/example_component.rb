# frozen_string_literal: true

# Copyright 2025

class ExampleComponent < ApplicationComponent
  prop :title, type: String, default: "Hello from SwiftUI Rails!"
  prop :description, type: String
  prop :counter, type: Integer, default: 0
  prop :show_details, type: [TrueClass, FalseClass], default: false

  swift_ui do
    vstack(spacing: 16) do
      text(title).text_size("2xl").font_weight("bold")

      hstack(spacing: 12) do
        button("-")
          .px(4).py(2)
          .bg("red-500")
          .text_color("white")
          .rounded
          .data(action: "click->example#decrement")
          
        text("Count: #{counter}").text_size("lg")
        
        button("+")
          .px(4).py(2)
          .bg("green-500")
          .text_color("white")
          .rounded
          .data(action: "click->example#increment")
      end

      button(show_details ? "Hide Details" : "Show Details")
        .px(4).py(2)
        .bg("blue-500")
        .text_color("white")
        .rounded
        .hover_bg("blue-600")
        .data(action: "click->example#toggleDetails")

      if show_details && description
        divider.my(4)
        text(description).text_color("gray-600")
      end
    end
    .bg("white")
    .rounded("lg")
    .shadow("md")
    .p(6)
  end
end
# Copyright 2025