# frozen_string_literal: true

module Playground
  class HeaderComponent < ApplicationComponent
    prop :title, type: String, default: "SwiftUI Rails Playground"
    prop :badge_text, type: String, default: "Component-as-DSL"
    
    swift_ui do
      # Use div instead of header for now to test
      div.bg("white").shadow("sm").border_b do
        hstack(spacing: 4) do
          brand_section
          spacer
          action_buttons
        end
        .px(6).py(4)
      end
    end
    
    private
    
    def brand_section
      hstack(spacing: 3) do
        logo_icon
        h1 { text(title) }
          .font_size("xl")
          .font_weight("bold")
          .text_color("gray-900")
        badge(badge_text)
      end
    end
    
    def logo_icon
      div do
        text("🚀")
      end
      .text_size("2xl")
    end
    
    def badge(label)
      span do
        text(label)
      end
      .text_xs
      .font_weight("medium")
      .px(2).py(1)
      .bg("green-100")
      .text_color("green-800")
      .rounded("full")
    end
    
    def action_buttons
      hstack(spacing: 3) do
        run_button
        share_button
        export_button
      end
    end
    
    def run_button
      action_button("Run", "green") do
        play_icon
        text("Run")
      end
      .data(action: "click->playground#runCode")
    end
    
    def share_button
      action_button("Share", "blue")
        .data(action: "click->playground#shareCode")
    end
    
    def export_button
      action_button("Export", "purple")
        .data(action: "click->playground#exportCode")
    end
    
    def action_button(label, color = "gray", &block)
      button do
        if block
          hstack(spacing: 2, &block)
        else
          text(label)
        end
      end
      .px(4).py(2)
      .bg("#{color}-600")
      .text_color("white")
      .rounded("lg")
      .hover_bg("#{color}-700")
      .transition
    end
    
    def play_icon
      span { text("▶") }
    end
    
    def spacer
      div.flex_1
    end
  end
end