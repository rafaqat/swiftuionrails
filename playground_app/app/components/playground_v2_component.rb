# frozen_string_literal: true

class PlaygroundV2Component < ApplicationComponent
  include SwiftUIRails::DSL

  prop :default_code, type: String, required: true
  prop :components, type: Array, default: []
  prop :examples, type: Array, default: []

  swift_ui do
    div(data: { controller: "playground-v2" }) do
      # Global Command Palette
      render CommandPaletteComponent.new do |palette|
        palette.group("Playground") do
          palette.command("Run Code", icon: :play, shortcut: "Cmd+Enter", action: "action:playground#run")
          palette.command("Format Code", icon: :cog, shortcut: "Shift+Alt+F", action: "action:playground#format")
          palette.command("Export to File", icon: :share, action: "action:playground#export")
        end
        
        palette.group("Navigation") do
          palette.command("Go Home", icon: :home, action: "visit:/")
          palette.command("Documentation", icon: :book, action: "visit:/docs")
          palette.command("Components Gallery", icon: :grid, action: "visit:/gallery")
        end

        palette.group("Theme") do
          palette.command("Toggle Dark Mode", icon: :moon, action: "theme:toggle", keywords: ["dark", "light", "mode"])
        end
      end

      # Header bar
      header_component

      # Main content area
      hstack(spacing: 0) do
        # Sidebar
        sidebar_component

        # Editor + Preview
        main_content_area

        # Studio Sidebar (Right)
        render StudioSidebarComponent.new
      end.h("screen").pt("16") # Adjust height and padding for fixed header
    end
    .min_h("screen")
    .bg("gray-50")
  end

  private

  def header_component
    header do
      div.px(4).py(3) do
        hstack(justify: :between) do
          # Logo and title
          hstack(spacing: 4) do
            text("SwiftUI Rails Playground")
              .font_size("2xl")
              .font_weight("bold")
              .text_color("gray-900")

            badge("DSL Powered")
              .bg("green-100")
              .text_color("green-800")
          end

          # Action buttons
          hstack(spacing: 4) do
            run_button
            xray_button
            share_button
            export_button
            studio_button
          end
        end
      end
    end
    .bg("white")
    .shadow("sm")
    .border_b
    .fixed.w("full").z(10).top(0)
  end

  def sidebar_component
    aside do
      div.p(3) do
        # Search box
        search_box
        
        # Components section
        text("Components").font_weight("semibold").mb(3)

        components.group_by { |c| c[:category] }.each do |category, items|
          component_category(category, items)
        end

        # Examples section
        divider.my(4)

        text("Examples").font_weight("semibold").mb(3)
        examples.each do |example|
          example_button(example)
        end

        # Favorites
        divider.my(4)
        favorites_section
      end
    end
    .w(64)
    .bg("white")
    .border_r
    .h("full")
    .overflow_y("auto")
  end

  def main_content_area
    hstack(spacing: 0).flex_1.h("full") do
      # Code editor section
      editor_section

      # Preview section
      preview_section
    end
  end

  def editor_section
    div.w("1/2").h("full").relative.flex.flex_col do
      # Editor header
      div.px(4).py(2).bg("gray-100").border_b do
        hstack(justify: :between) do
          text("Ruby DSL Code").text_sm.text_color("gray-700")

          hstack(spacing: 2) do
            theme_switcher
            
            button("Format")
              .text_sm
              .text_color("gray-600")
              .hover_text_color("gray-900")
              .data(action: "click->playground-v2#formatCode")

            button("Clear")
              .text_sm
              .text_color("gray-600")
              .hover_text_color("gray-900")
              .data(action: "click->playground-v2#clearCode")
          end
        end
      end

      # Monaco container
      div(
        id: "monaco-editor-v2",
        data: {
          playground_v2_target: "monacoContainer",
          initial_code: default_code
        }
      ).flex_1.w("full")

      # Hidden form for preview submission
      hidden_preview_form
    end
    .bg("gray-50")
    .border_r
  end

  def preview_section
    div.w("1/2").h("full").flex.flex_col.bg("white") do
      # Preview header
      div.px(4).py(2).bg("gray-50").border_b do
        hstack(justify: :between) do
          text("Preview").font_weight("medium").text_color("gray-700")
          
          device_switcher
        end
      end

      # Preview container wrapper to handle centering and background
      div.flex_1.bg("gray-100").overflow_auto.p(4).flex.justify_center do
        # The actual preview container that gets updated
        div(
            id: "preview-container-v2",
            data: { playground_v2_target: "preview" }
        )
        .bg("white")
        .shadow("lg")
        .w("full") # Default to full width
        .min_h("full")
        .transition_all
      end
    end
  end

  # Helper Components

  def search_box
    textfield(
      name: "search",
      placeholder: "Search components...",
      data: {
        action: "input->playground-v2#filterComponents",
        playground_v2_target: "searchInput"
      }
    ).mb(4)
  end

  def export_button
    button("Export")
      .px(4).py(2)
      .bg("purple-600")
      .text_color("white")
      .rounded("lg")
      .hover_bg("purple-700")
      .transition
      .data(action: "click->playground-v2#exportCode")
  end

  def studio_button
    button("Studio")
      .px(4).py(2)
      .bg("gray-800")
      .text_color("white")
      .rounded("lg")
      .hover_bg("gray-900")
      .transition
      .data(action: "click->playground-v2#toggleStudio")
  end

  def theme_switcher
    select(
      data: {
        action: "change->playground-v2#changeTheme",
        playground_v2_target: "themeSelect"
      }
    ) do
      option("Light", value: "vs-light")
      option("Dark", value: "vs-dark")
      option("High Contrast", value: "hc-black")
    end.text_sm.rounded.border_gray_300
  end

  def device_switcher
    hstack(spacing: 2) do
      ["desktop", "tablet", "mobile"].each do |device|
        button(type: "button")
          .p(1.5)
          .rounded
          .text_color("gray-600")
          .hover_bg("gray-200")
          .data(
            action: "click->playground-v2#switchDevice",
            device: device
          ) do
            case device
            when "desktop"
              text("🖥️") # Placeholder icon
            when "tablet"
              text("📱") # Placeholder icon
            when "mobile"
              text("iphone") # Placeholder icon
            end
        end
      end
    end
  end

  def favorites_section
    vstack(spacing: 2) do
      hstack(justify: :between) do
        text("Favorites").font_weight("semibold")
        button("+")
          .text_sm.text_color("blue-600")
          .data(action: "click->playground-v2#saveFavorite")
      end
      
      div(data: { playground_v2_target: "favoritesList" }) do
        text("No favorites yet").text_sm.text_color("gray-500").italic
      end
    end
  end

  def component_category(category, items)
    div.mb(4).data(category_name: category.downcase) do
      text(category)
        .text_xs
        .font_weight("medium")
        .text_color("gray-500")
        .uppercase
        .tracking("wider")
        .mb(1)

      vstack(spacing: 0.5) do
        items.each do |component|
          hstack(spacing: 0) do
            button(component[:name])
              .flex_1
              .text_align("left")
              .px(2).py(1.5)
              .text_sm
              .rounded_l
              .hover_bg("gray-100")
              .transition
              .data(
                action: "click->playground-v2#insertComponent",
                playground_v2_code_param: component[:code],
                component_name: component[:name].downcase
              )
            
            # Studio Edit Button
            if component[:class_name] # Only show if we have a backing class
              button("⚙️")
                .px(2).py(1.5)
                .text_sm
                .rounded_r
                .hover_bg("gray-200")
                .title("Edit in Studio")
                .data(
                  controller: "studio",
                  action: "click->studio#loadComponent",
                  studio_component_name_param: component[:class_name]
                )
            end
          end
        end
      end
    end
  end

  def example_button(example)
    button(example[:name])
      .w("full")
      .text_align("left")
      .px(2).py(1.5)
      .text_sm
      .rounded
      .hover_bg("gray-100")
      .transition
      .title(example[:description])
      .data(
        action: "click->playground-v2#loadExample",
        playground_v2_code_param: example[:code]
      )
  end

  def run_button
    button do
      hstack(spacing: 2) do
        text("▶ Run")
      end
    end
    .px(4).py(2)
    .bg("green-600")
    .text_color("white")
    .rounded("lg")
    .hover_bg("green-700")
    .transition
    .data(action: "click->playground-v2#runCode")
  end

  def xray_button
    button("X-Ray")
      .px(4).py(2)
      .bg("white")
      .text_color("gray-700")
      .border.border_color("gray-300")
      .rounded("lg")
      .hover_bg("gray-50")
      .transition
      .data(action: "click->playground-v2#toggleXRay")
  end

  def share_button
    button("Share")
      .px(4).py(2)
      .bg("blue-600")
      .text_color("white")
      .rounded("lg")
      .hover_bg("blue-700")
      .transition
      .data(action: "click->playground-v2#shareCode")
  end

  def hidden_preview_form
    # Using form_with helper via raw execution since DSL might not wrap it perfectly yet
    # or using tag helpers directly
    
    form(action: "/v2/playground/preview", method: :post, data: { playground_v2_target: "form" }) do
      input(type: "hidden", name: "code", data: { playground_v2_target: "codeInput" })
    end
  end

  def divider
    div.h("px").bg("gray-200").w("full")
  end

  def badge(text_content)
    span(text_content)
      .text_xs
      .font_weight("medium")
      .px(2).py(1)
      .rounded("full")
  end
end
