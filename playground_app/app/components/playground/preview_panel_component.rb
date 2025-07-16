# frozen_string_literal: true

module Playground
  class PreviewPanelComponent < ApplicationComponent
    prop :width_class, type: String, default: nil
    
    swift_ui do
      div do
        vstack(spacing: 0) do
          preview_header
          preview_content
        end
      end
      .tap { |el| width_class ? el.tw(width_class) : el.flex_1 }
      .bg("gray-50")
    end
    
    private
    
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
  end
end