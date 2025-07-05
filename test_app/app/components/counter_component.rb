# frozen_string_literal: true

class CounterComponent < SwiftUIRails::Component::Base
  # Props - components are stateless view builders
  prop :initial_count, type: Integer, default: 0
  prop :step, type: Integer, default: 1
  prop :label, type: String, default: "Counter"
  prop :counter_id, type: String, default: -> { "counter-#{SecureRandom.hex(4)}" }
  
  swift_ui do
    # Rails-first approach: Components are stateless view builders
    # State is managed by Stimulus controller on the client side
    comp = @component
    vstack(spacing: 4) do
      # Title - bound to Stimulus values
      text("")
        .font_size("2xl")
        .font_weight("bold")
        .tw("transition-colors duration-200")
        .data("counter-target": "label")
      
      # Count display with animation
      text("")
        .font_size("6xl")
        .font_weight("black")
        .tw("transition-all duration-300")
        .data("counter-target": "count")
      
      # Controls - client-side actions via Stimulus
      hstack(spacing: 2) do
        button("-")
          .bg("red-500")
          .text_color("white")
          .px(4)
          .py(2)
          .rounded("lg")
          .tw("transition-opacity duration-200")
          .data({
            action: "click->counter#decrement",
            "counter-target": "decrementBtn"
          })
        
        button("Reset")
          .bg("gray-500")
          .text_color("white")
          .px(4)
          .py(2)
          .rounded("lg")
          .data(action: "click->counter#reset")
        
        button("+")
          .bg("green-500")
          .text_color("white")
          .px(4)
          .py(2)
          .rounded("lg")
          .tw("transition-opacity duration-200")
          .data({
            action: "click->counter#increment",
            "counter-target": "incrementBtn"
          })
      end
      
      # History display
      div(data: { "counter-target": "history" }) do
        # History will be rendered by Stimulus controller
      end
    end
    .p(6)
    .bg("white")
    .rounded("xl")
    .shadow("lg")
    .border
    .border_color("gray-200")
    .data({
      controller: "counter",
      "counter-count-value": initial_count,
      "counter-step-value": step,
      "counter-label-value": comp.label
    })
    .attr("id", counter_id)
  end
end
# Copyright 2025
