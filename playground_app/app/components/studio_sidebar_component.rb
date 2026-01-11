# frozen_string_literal: true

class StudioSidebarComponent < ApplicationComponent
  include SwiftUIRails::DSL

  swift_ui do
    div(
      class: "hidden w-80 bg-white border-l border-gray-200 flex flex-col h-full",
      data: { 
        playground_v2_target: "studioSidebar",
        controller: "studio" # Separate controller for Studio logic
      }
    ) do
      # Header
      div.px(4).py(3).border_b.border_color("gray-200").bg("gray-50") do
        hstack(justify: :between, alignment: :center) do
          text("Studio").font_weight("bold").text_color("gray-800")
          button("×")
            .text_color("gray-500")
            .hover_text_color("gray-700")
            .data(action: "click->playground-v2#toggleStudio")
        end
      end

      # Content
      div.flex_1.overflow_y_auto.p(4) do
        # Empty State
        div(
          data: { studio_target: "emptyState" },
          class: "text-center py-8"
        ) do
          text("Select a component to edit").text_sm.text_color("gray-500")
        end

        # Controls Container
        div(
          data: { studio_target: "controls" },
          class: "hidden space-y-6"
        ) do
          # Component Name
          div do
            text("Component")
              .text_xs.font_weight("bold").text_color("gray-400").uppercase.tracking("wider")
            text("")
              .font_weight("semibold").text_color("gray-900").mt(1)
              .data(studio_target: "componentName")
          end
          
          # Preview Section (Hidden by default)
          div(data: { studio_target: "previewSection" }, class: "hidden") do
            text("Preview")
              .text_xs.font_weight("bold").text_color("gray-400").uppercase.tracking("wider")
            
            div(class: "mt-2 p-2 border rounded bg-gray-50 overflow-hidden") do
              div(data: { studio_target: "previewContainer" })
            end
          end

          # Props Form
          div(class: "space-y-4") do
            text("Properties")
              .text_xs.font_weight("bold").text_color("gray-400").uppercase.tracking("wider")
            
            div(data: { studio_target: "propsContainer" }, class: "space-y-4")
              # Dynamic controls injected here
          end
        end
      end
    end
  end
end
