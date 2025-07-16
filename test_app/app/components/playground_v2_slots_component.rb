# frozen_string_literal: true

# PlaygroundV2SlotsComponent - Using ViewComponent Slots Pattern
# 
# This demonstrates using ViewComponent's slots feature for even more flexibility
class PlaygroundV2SlotsComponent < ApplicationComponent
  prop :default_code, type: String, required: true
  prop :components, type: Array, default: []
  prop :examples, type: Array, default: []

  swift_ui do
    # Use the layout component with slots
    render Playground::LayoutComponent.new(controller_name: "playground-v2") do |layout|
      layout.with_header do
        render Playground::HeaderComponent.new(
          title: "SwiftUI Rails Playground V2",
          badge_text: "Slots Pattern"
        )
      end
      
      layout.with_sidebar do
        render Playground::SidebarComponent.new(
          components: components,
          examples: examples
        )
      end
      
      layout.with_main_content do
        content_area
      end
    end
  end

  private

  def content_area
    hstack(spacing: 0) do
      render Playground::EditorPanelComponent.new(
        default_code: default_code,
        preview_path: "/playground-v2/preview"
      )
      
      render Playground::PreviewPanelComponent.new(
        width_percentage: "40%"
      )
    end
    .flex_1
  end
end