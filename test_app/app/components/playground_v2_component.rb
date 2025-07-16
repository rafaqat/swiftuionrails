# frozen_string_literal: true

# PlaygroundV2Component - SwiftUI DSL Implementation
# 
# This component demonstrates the full SwiftUI Rails DSL architecture
# according to the PLAYGROUND_V2.md specification
class PlaygroundV2Component < ApplicationComponent
  prop :default_code, type: String, required: true
  prop :components, type: Array, default: []
  prop :examples, type: Array, default: []

  swift_ui do
    div(data: { controller: "playground" }) do
      # Header section - inline DSL
      playground_header
      
      # Main content area
      hstack(spacing: 0) do
        # Sidebar - inline DSL
        playground_sidebar
        
        # Editor and preview panels
        hstack(spacing: 0).flex_1 do
          # Editor section - inline DSL
          playground_editor
          
          # Preview section - inline DSL
          playground_preview
        end
      end
      .h("[calc(100vh-64px)]")
    end
    .min_h("screen")
    .bg("gray-50")
  end

  private

  def playground_header
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
  
  def brand_section
    hstack(spacing: 3) do
      logo_icon
      text("SwiftUI Rails Playground")
        .font_size("xl")
        .font_weight("bold")
        .text_color("gray-900")
      badge("DSL Powered")
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
      span { text("▶") }
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

  def playground_sidebar
    div do
      vstack(spacing: 6) do
        search_section
        components_section
        divider
        examples_section
        divider
        favorites_section
      end
      .p(4)
    end
    .w(64)
    .bg("white")
    .border_r
    .overflow_y("auto")
  end
  
  def search_section
    textfield(
      placeholder: "Search components...",
      data: {
        action: "input->playground#filterComponents",
        playground_target: "searchInput"
      }
    )
    .w("full")
  end
  
  def components_section
    vstack(spacing: 4) do
      section_title("Components")
      
      div(data: { playground_target: "componentsContainer" }) do
        grouped_components.each do |category, items|
          component_category(category, items)
        end
      end
    end
  end
  
  def grouped_components
    return {} if components.nil? || !components.respond_to?(:group_by)
    safe_components = components.compact
    return {} if safe_components.empty?
    
    safe_components.group_by { |c| (c.is_a?(Hash) && c[:category]) || "General" }
  end
  
  def component_category(category, items)
    vstack(spacing: 2) do
      category_title(category)
      
      items.each do |component|
        component_item(component)
      end
    end
    .mb(4)
  end
  
  def category_title(title)
    text(title)
      .text_xs
      .font_weight("medium")
      .text_color("gray-500")
      .tw("uppercase")
      .tw("tracking-wider")
  end
  
  def component_item(component)
    interactive_item(component[:name]) do
      component_icon(component[:icon])
      text(component[:name])
        .font_size("sm")
    end
    .data(
      action: "click->playground#insertComponent",
      playground_code_param: component[:code]
    )
  end
  
  def component_icon(icon_name)
    span { text(icon_name || "📦") }
      .tw("mr-2")
  end
  
  def examples_section
    vstack(spacing: 4) do
      section_title("Examples")
      
      div(data: { playground_target: "examplesContainer" }) do
        examples.each do |example|
          example_item(example)
        end
      end
    end
  end
  
  def example_item(example)
    interactive_item do
      vstack(spacing: 1, alignment: :start) do
        text(example[:name])
          .font_size("sm")
          .font_weight("medium")
        
        if example[:description]
          text(example[:description])
            .font_size("xs")
            .text_color("gray-500")
            .line_clamp(2)
        end
      end
    end
    .data(
      action: "click->playground#loadExample",
      playground_code_param: example[:code]
    )
  end
  
  def favorites_section
    vstack(spacing: 4) do
      hstack do
        section_title("Favorites")
        spacer
        add_favorite_button
      end
      
      favorites_list
    end
  end
  
  def add_favorite_button
    button("+")
      .text_sm
      .text_color("blue-600")
      .hover_text_color("blue-700")
      .data(action: "click->playground#saveFavorite")
  end
  
  def favorites_list
    div(data: { playground_target: "favoritesList" }) do
      text("No favorites yet")
        .text_sm
        .text_color("gray-500")
        .tw("italic")
    end
  end
  
  def section_title(title)
    text(title)
      .font_weight("semibold")
      .text_color("gray-700")
  end
  
  def interactive_item(label = nil, &block)
    button do
      if block
        hstack(spacing: 2, &block)
      else
        text(label)
      end
    end
    .w("full")
    .text_align("left")
    .px(3).py(2)
    .rounded("md")
    .hover_bg("gray-100")
    .transition
  end

  def playground_editor
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
      action: "/playground/preview",
      method: "post",
      data: { playground_target: "form" }
    ) do
      input(
        type: "hidden",
        name: "code",
        value: nil,
        data: { playground_target: "codeInput" }
      )
      input(
        type: "hidden",
        name: "authenticity_token",
        value: form_authenticity_token
      )
    end
    .hidden
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

  def playground_preview
    div do
      vstack(spacing: 0) do
        preview_header
        preview_content
      end
    end
    .w("40%")
    .bg("gray-50")
  end
  
  def preview_header
    div do
      hstack do
        text("Preview")
          .font_size("sm")
          .font_weight("medium")
        spacer
        device_selector
      end
    end
    .px(4).py(3)
    .bg("white")
    .border_b
  end
  
  def device_selector
    hstack(spacing: 1) do
      device_button("desktop", "💻", true)
      device_button("tablet", "📱")
      device_button("mobile", "📱")
    end
  end
  
  def device_button(device, icon, active = false)
    btn = button do
      span_element = span { text(icon) }
      device == "tablet" ? span_element.tw("rotate-90") : span_element
    end
    .p(1)
    .rounded
    .data(
      action: "click->playground#switchDevice",
      playground_device_param: device
    )
    
    active ? btn.bg("gray-200") : btn.hover_bg("gray-100")
  end
  
  def preview_content
    div do
      div(
        id: "preview-container",
        data: { playground_target: "preview" }
      )
      .p(8)
    end
    .flex_1
    .bg("white")
    .m(4)
    .rounded("lg")
    .shadow
  end
  
  def spacer
    div.flex_1
  end
  
  def divider
    div.h("px").bg("gray-200").w("full")
  end

  # No private methods needed - components are rendered inline
end