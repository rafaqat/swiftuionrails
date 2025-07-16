# frozen_string_literal: true

module Playground
  class EditorPanelComponent < ApplicationComponent
    prop :default_code, type: String, required: true
    prop :preview_path, type: String, default: "/playground/preview"
    prop :width_class, type: String, default: nil
    
    swift_ui do
      div do
        vstack(spacing: 0) do
          editor_header
          editor_content
        end
      end
      .tap { |el| width_class ? el.tw(width_class) : el.flex_1 }
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
        monaco_editor
        preview_form
      end
      .flex_1
      .flex
      .relative
      .min_h("[400px]")
      .overflow("hidden")
      .w("full")
    end
    
    def monaco_editor
      # Container for both loading indicator and Monaco editor
      div do
        # Loading indicator - using DSL CSS only, visible by default
        div(
          id: "editor-loading",
          style: "display: flex;"
        ) do
          text("Loading Monaco editor...")
            .text_color("gray-600")
            .font_weight("medium")
        end
        .absolute
        .inset(0)
        .flex
        .items_center
        .justify_center
        .bg("white")
        .z(10)
        
        # Monaco Editor Container (hidden initially) - using DSL CSS only
        div(
          id: "monaco-editor",
          data: {
            playground_target: "monacoContainer",
            initial_code: default_code
          },
          style: "display: none;"
        )
        .absolute
        .inset(0)
        .w("full")
        .h("full")
      end
      .relative
      .w("full")
      .h("full")
      .min_h("[400px]")
    end
    
    def preview_form
      form(
        action: preview_path,
        method: "post",
        data: { 
          playground_target: "form",
          turbo_stream: ""
        }
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
    
    def spacer
      div.flex_1
    end
  end
end