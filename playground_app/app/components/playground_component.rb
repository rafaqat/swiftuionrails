# frozen_string_literal: true

# PlaygroundV2Component - Composed with Smaller ViewComponents
# 
# This component now demonstrates composition using separate ViewComponent files
# while still leveraging the Component-as-DSL-Context architecture
class PlaygroundComponent < ApplicationComponent
  prop :default_code, type: String, required: true
  prop :components, type: Array, default: []
  prop :examples, type: Array, default: []

  def call
    content_tag(:div, 
      data: { controller: "playground" }, 
      class: "min-h-screen bg-gray-50"
    ) do
      safe_join([
        render_header,
        main_layout
      ])
    end
  end

  private

  # Render the header component
  def render_header
    # We can still use helper methods to render ViewComponents
    render_component(Playground::HeaderComponent.new(
      title: "SwiftUI Rails Playground",
      badge_text: "Composable Components"
    ))
  end

  # Main layout using standard Rails helpers
  def main_layout
    content_tag(:div, class: "flex h-[calc(100vh-64px)]") do
      safe_join([
        render_sidebar,
        content_area
      ])
    end
  end

  def render_sidebar
    Rails.logger.debug "PlaygroundV2Component#render_sidebar: components=#{components.inspect}"
    Rails.logger.debug "PlaygroundV2Component#render_sidebar: examples=#{examples.inspect}"
    render_component(Playground::SidebarComponent.new(
      components: components,
      examples: examples
    ))
  end

  def content_area
    content_tag(:div, class: "flex flex-1 h-full") do
      safe_join([
        render_editor_panel,
        render_preview_panel
      ])
    end
  end

  def render_editor_panel
    render_component(Playground::EditorPanelComponent.new(
      default_code: default_code,
      preview_path: "/playground/preview",
      width_class: "w-[60%]"
    ))
  end

  def render_preview_panel
    render_component(Playground::PreviewPanelComponent.new(
      width_class: "w-[40%]"
    ))
  end

  # Helper method to render a ViewComponent
  def render_component(component)
    # Simply render the component - no DSL context interference
    render(component)
  end

  # We can still have local helper methods for things specific to this component
  def spacer
    div.flex_1
  end

  # Example of how we can still use deep composition locally
  # while delegating major sections to separate components
  def demo_section
    card do
      vstack(spacing: 4) do
        text("This component uses:")
        list_items
      end
    end
    .p(6).m(4)
  end

  def list_items
    ul do
      list_item("Playground::HeaderComponent")
      list_item("Playground::SidebarComponent") 
      list_item("Playground::EditorPanelComponent")
      list_item("Playground::PreviewPanelComponent")
    end
  end

  def list_item(text_content)
    li do
      text("• #{text_content}")
    end
    .ml(4)
  end

  def card(&block)
    div(&block)
      .bg("white")
      .rounded("lg")
      .shadow
  end
end