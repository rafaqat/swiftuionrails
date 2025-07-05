# frozen_string_literal: true
# Copyright 2025

class ExampleComponent < ApplicationComponent
  prop :title, type: String, default: "Hello from SwiftUI Rails!"
  prop :description, type: String
  
  state :counter, 0
  state :show_details, false
  
  computed :button_text do
    show_details ? "Hide Details" : "Show Details"
  end
  
  swift_ui do
    card(elevation: 2).p(6) do
      vstack(spacing: 16) do
        # Title
        text(title).text_size("2xl").font_weight("bold")
        
        # Counter section
        hstack(spacing: 12) do
          button("-").on_tap { self.counter -= 1 }.tw("px-4 py-2 bg-red-500 text-white rounded")
          text("Count: #{counter}").text_size("lg")
          button("+").on_tap { self.counter += 1 }.tw("px-4 py-2 bg-green-500 text-white rounded")
        end
        
        # Toggle section
        button(button_text)
          .on_tap { self.show_details = !show_details }
          .tw("px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600")
        
        # Conditional content
        if show_details && description
          divider.my(4)
          text(description).text_color("gray-600")
        end
      end
    end
  end
end
# Copyright 2025
