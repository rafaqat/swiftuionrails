# frozen_string_literal: true
# Copyright 2025

class DslButtonStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :text, as: :text, default: "Click Me"
  control :background_color, as: :select, options: [
    "blue-600", "green-600", "red-600", "purple-600", "yellow-500", "gray-600"
  ], default: "blue-600"
  control :text_color, as: :select, options: [
    "white", "gray-900", "blue-900", "green-900", "red-900", "purple-900"
  ], default: "white"
  control :size, as: :select, options: ["sm", "md", "lg", "xl"], default: "md"
  control :rounded, as: :select, options: ["none", "sm", "md", "lg", "xl", "full"], default: "md"
  control :disabled, as: :boolean, default: false
  
  # Powerful properties
  control :stimulus_controller, as: :text, default: ""
  control :stimulus_action, as: :text, default: ""
  control :stimulus_target, as: :text, default: ""
  control :aria_label, as: :text, default: ""
  control :hover_effect, as: :select, options: [
    "none", "opacity-90", "scale-105", "shadow-lg", "brightness-110"
  ], default: "opacity-90"
  control :focus_ring_color, as: :select, options: [
    "blue-500", "purple-500", "green-500", "red-500", "yellow-500", "gray-500"
  ], default: "blue-500"
  control :transition_enabled, as: :boolean, default: true
  
  def default(
    text: "Click Me",
    background_color: "blue-600",
    text_color: "white", 
    size: "md",
    rounded: "md",
    disabled: false,
    stimulus_controller: "",
    stimulus_action: "",
    stimulus_target: "",
    aria_label: "",
    hover_effect: "opacity-90",
    focus_ring_color: "blue-500",
    transition_enabled: true
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          # Title section
          vstack(spacing: 4) do
            text("DSL Button - Full Power Showcase")
              .font_size("2xl")
              .font_weight("bold")
              .text_color("gray-900")
            
            text("All properties are customizable via the controls on the right")
              .text_size("sm")
              .text_color("gray-600")
          end
          
          # Main button with all properties
          hstack(spacing: 16, alignment: :center) do
            # The button - create and render in one chain
            button(text)
              .bg(background_color)
              .text_color(text_color)
              .px(size.to_s == "sm" ? 4 : size.to_s == "md" ? 6 : size.to_s == "lg" ? 8 : 10)
              .py(size.to_s == "sm" ? 2 : size.to_s == "md" ? 3 : size.to_s == "lg" ? 4 : 5)
              .text_size(size.to_s == "sm" ? "sm" : size.to_s == "md" ? "base" : size.to_s == "lg" ? "lg" : "xl")
              .rounded(rounded)
              .font_weight("medium")
              .disabled(disabled)
              .tap do |btn|
                # Apply hover effect
                btn.hover(hover_effect) if hover_effect != "none"
                
                # Apply focus ring
                btn.focus("ring-2 ring-#{focus_ring_color}")
                
                # Apply transition
                btn.transition if transition_enabled
                
                # Apply Stimulus properties if provided
                btn.stimulus_controller(stimulus_controller) if stimulus_controller.present?
                btn.stimulus_action(stimulus_action) if stimulus_action.present?
                btn.stimulus_target(stimulus_target) if stimulus_target.present?
                
                # Apply aria label if provided
                btn.aria_label(aria_label) if aria_label.present?
              end
          end
          
          # Properties display
          vstack(spacing: 12, alignment: :start) do
            text("Active Properties:")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-800")
            
            # Visual properties
            div(class: "bg-gray-50 p-4 rounded-lg w-full") do
              vstack(spacing: 8, alignment: :start) do
                text("Visual Properties")
                  .font_weight("medium")
                  .text_color("gray-700")
                  .margin_bottom(2)
                
                grid(columns: 2, spacing: 4) do
                  # Background
                  hstack(spacing: 2) do
                    text("Background:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(background_color.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Text Color
                  hstack(spacing: 2) do
                    text("Text Color:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(text_color.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Size
                  hstack(spacing: 2) do
                    text("Size:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(size.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Rounded
                  hstack(spacing: 2) do
                    text("Rounded:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(rounded.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Hover Effect
                  hstack(spacing: 2) do
                    text("Hover Effect:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(hover_effect.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Focus Ring
                  hstack(spacing: 2) do
                    text("Focus Ring:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(focus_ring_color.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Transition
                  hstack(spacing: 2) do
                    text("Transition:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(transition_enabled ? "Enabled" : "Disabled").text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                  # Disabled
                  hstack(spacing: 2) do
                    text("Disabled:").text_size("sm").font_weight("medium").text_color("gray-600")
                    text(disabled ? "Yes" : "No").text_size("sm").text_color("gray-900").tw("font-mono")
                  end
                end
              end
            end
            
            # Interactive properties
            if stimulus_controller.present? || stimulus_action.present? || stimulus_target.present? || aria_label.present?
              div(class: "bg-blue-50 p-4 rounded-lg w-full") do
                vstack(spacing: 8, alignment: :start) do
                  text("Interactive Properties")
                    .font_weight("medium")
                    .text_color("blue-800")
                    .margin_bottom(2)
                  
                  vstack(spacing: 3, alignment: :start) do
                    if stimulus_controller.present?
                      hstack(spacing: 2) do
                        text("Stimulus Controller:").text_size("sm").font_weight("medium").text_color("gray-600")
                        text(stimulus_controller.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                      end
                    end
                    if stimulus_action.present?
                      hstack(spacing: 2) do
                        text("Stimulus Action:").text_size("sm").font_weight("medium").text_color("gray-600")
                        text(stimulus_action.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                      end
                    end
                    if stimulus_target.present?
                      hstack(spacing: 2) do
                        text("Stimulus Target:").text_size("sm").font_weight("medium").text_color("gray-600")
                        text(stimulus_target.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                      end
                    end
                    if aria_label.present?
                      hstack(spacing: 2) do
                        text("ARIA Label:").text_size("sm").font_weight("medium").text_color("gray-600")
                        text(aria_label.to_s).text_size("sm").text_color("gray-900").tw("font-mono")
                      end
                    end
                  end
                end
              end
            end
            
            # Usage examples
            div(class: "bg-purple-50 p-4 rounded-lg w-full") do
              vstack(spacing: 4, alignment: :start) do
                text("Example Stimulus Usage:")
                  .font_weight("medium")
                  .text_color("purple-800")
                  .margin_bottom(2)
                
                text("Controller: \"counter\"")
                  .text_size("sm")
                  .tw("font-mono")
                  .text_color("purple-700")
                
                text("Action: \"click->counter#increment\"")
                  .text_size("sm")
                  .tw("font-mono")
                  .text_color("purple-700")
                
                text("Target: \"counterButton\"")
                  .text_size("sm")
                  .tw("font-mono")
                  .text_color("purple-700")
              end
            end
          end
        end
      end
    end
  end
  
  private
  
  def property_item(label, value)
    hstack(spacing: 2) do
      text("#{label}:")
        .text_size("sm")
        .font_weight("medium")
        .text_color("gray-600")
      
      text(value.to_s)
        .text_size("sm")
        .text_color("gray-900")
        .tw("font-mono")
    end
  end
  
  def interactive_showcase
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Interactive DSL Button Showcase")
            .font_size("2xl")
            .font_weight("bold")
            .text_color("gray-900")
            .margin_bottom(8)
          
          # Hover effects demo
          vstack(spacing: 8, alignment: :start) do
            text("Hover Effects")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-800")
            
            hstack(spacing: 4) do
              button("Scale Up")
                .bg("blue-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("md")
                .animate_on_hover("scale-105")
                .transition
              
              button("Glow Effect")
                .bg("purple-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("md")
                .hover("shadow-lg shadow-purple-500/50")
                .transition
              
              button("Color Change")
                .bg("green-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("md")
                .hover("bg-green-700")
                .transition
            end
          end
          
          # Stimulus integration demo
          vstack(spacing: 8, alignment: :start) do
            text("Stimulus Integration")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-800")
            
            hstack(spacing: 4) do
              button("Counter")
                .bg("red-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("md")
                .stimulus_controller("counter")
                .stimulus_action("click->counter#increment")
                .stimulus_target("counterButton")
              
              div
                .text_color("gray-700")
                .stimulus_controller("counter")
                .stimulus_target("counterValue") do
                  text("Clicks: 0")
                end
            end
          end
          
          # Responsive design demo
          vstack(spacing: 8, alignment: :start) do
            text("Responsive Design")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-800")
            
            button("Responsive Button")
              .bg("orange-600")
              .text_color("white")
              .px(2).py(1)
              .text_size("sm")
              .sm("px-4 py-2 text-base")
              .md("px-6 py-3 text-lg")
              .lg("px-8 py-4 text-xl")
              .rounded("md")
              .w_full
              .sm("w-auto")
          end
        end
      end
    end
  end
end
# Copyright 2025
