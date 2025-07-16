# frozen_string_literal: true

module Playground
  class EditorPanelComponent < ApplicationComponent
    prop :default_code, type: String, required: true
    prop :preview_path, type: String, default: "/playground/preview"
    
    swift_ui do
      div do
        vstack(spacing: 0) do
          editor_header
          editor_content
        end
      end
      .flex_1
      .bg("white")
      .border_r
      .h("full")
    end
    
    private
    
    def editor_header
      div do
        hstack do
          text("Code Editor")
            .font_size("sm")
            .font_weight("medium")
          spacer
          editor_actions
        end
      end
      .px(4).py(3)
      .bg("gray-50")
      .border_b
    end
    
    def editor_actions
      hstack(spacing: 2) do
        theme_selector
        format_button
        clear_button
      end
    end
    
    def theme_selector
      select(
        data: {
          action: "change->playground#changeTheme",
          playground_target: "themeSelect"
        }
      ) do
        option("Light", value: "vs-light", selected: true)
        option("Dark", value: "vs-dark")
        option("High Contrast", value: "hc-black")
      end
      .text_xs
      .rounded
      .border
      .px(2).py(1)
    end
    
    def format_button
      text_button("Format")
        .data(action: "click->playground#formatCode")
    end
    
    def clear_button
      text_button("Clear")
        .data(action: "click->playground#clearCode")
    end
    
    def text_button(label)
      button(label)
        .text_xs
        .text_color("gray-600")
        .hover_text_color("gray-900")
        .px(2).py(1)
        .rounded
        .hover_bg("gray-100")
    end
    
    def editor_content
      div do
        editor_loading
        monaco_editor
        preview_form
      end
      .flex_1
      .relative
      .h("full")
      .min_h("400px")
    end
    
    def monaco_editor
      div(
        id: "monaco-editor",
        data: {
          playground_target: "monacoContainer",
          initial_code: default_code
        }
      )
      .absolute.top(0).left(0).right(0).bottom(0)
      .w("full")
      .h("full")
    end
    
    def preview_form
      form(
        action: preview_path,
        method: "post",
        data: { playground_target: "form" }
      ) do
        hidden_field("code")
        hidden_field("authenticity_token", form_authenticity_token)
      end
      .hidden
    end
    
    def hidden_field(name, value = nil)
      input(
        type: "hidden",
        name: name,
        value: value,
        data: name == "code" ? { playground_target: "codeInput" } : {}
      )
    end
    
    def editor_loading
      div(id: "editor-loading") do
        # Background with animated gradient
        div.absolute.inset(0).bg_gradient_to_br.from_blue_50.via_purple_50.to_pink_50.tw("animate-gradient")
        
        # Main content
        vstack(spacing: 8) do
          # Logo/Brand area
          vstack(spacing: 4) do
            div.relative do
              # Main rotating ring with enhanced animation
              div.w_20.h_20.border_4.border_blue_200.rounded_full.tw("spinner-ring") do
                div.absolute.top_0.left_0.w_4.h_4.bg_blue_500.rounded_full.animate_pulse
              end
              
              # Inner pulsing elements
              div.absolute.top_2.left_2.w_16.h_16.bg_gradient_to_br.from_blue_400.to_purple_500.rounded_full.animate_pulse.opacity_30
              div.absolute.top_4.left_4.w_12.h_12.bg_gradient_to_br.from_purple_400.to_pink_400.rounded_full.animate_pulse.opacity_20
              
              # Center Monaco icon with glow effect
              div.absolute.top_6.left_6.w_8.h_8.flex.items_center.justify_center.bg_white.rounded_full.tw("glow-icon") do
                text("⚡")
                  .text_2xl
                  .animate_bounce
                  .text_color("blue-600")
              end
            end
            
            # Brand text
            text("Monaco Editor")
              .font_size("xl")
              .font_weight("bold")
              .text_color("gray-800")
              .text_center
          end
          
          # Loading status
          vstack(spacing: 3) do
            text("Initializing your coding environment")
              .text_sm
              .text_color("gray-700")
              .text_center
              .font_weight("medium")
            
            # Animated progress bar
            div.w_64.h_1.bg_gray_200.rounded_full.overflow_hidden do
              div.h_full.bg_gradient_to_r.from_blue_500.to_purple_500.rounded_full.tw("progress-bar")
            end
            
            # Status text
            text("Loading syntax highlighting and IntelliSense...")
              .text_xs
              .text_color("gray-500")
              .text_center
              .animate_pulse
          end
          
          # Feature highlights
          vstack(spacing: 2) do
            hstack(spacing: 3).tw("fade-in-up").style("animation-delay: 0.2s") do
              text("✨").text_sm
              text("Syntax highlighting").text_xs.text_color("gray-600")
            end
            hstack(spacing: 3).tw("fade-in-up").style("animation-delay: 0.4s") do
              text("🚀").text_sm
              text("IntelliSense completion").text_xs.text_color("gray-600")
            end
            hstack(spacing: 3).tw("fade-in-up").style("animation-delay: 0.6s") do
              text("⚡").text_sm
              text("Real-time preview").text_xs.text_color("gray-600")
            end
          end
          
          # Bottom animation
          hstack(spacing: 2) do
            5.times do |i|
              div
                .w_2.h_2
                .bg_blue_400
                .rounded_full
                .animate_bounce
                .style("animation-delay: #{i * 0.15}s; animation-duration: 1s;")
            end
          end
        end
      end
      .absolute
      .top(0).left(0).right(0).bottom(0)
      .flex
      .items_center
      .justify_center
      .z(20)
      .transition_all.duration_500
    end

    def spacer
      div.flex_1
    end
  end
end