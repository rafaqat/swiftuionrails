# frozen_string_literal: true

module Playground
  # A layout component that uses ViewComponent slots for maximum flexibility
  class LayoutComponent < ApplicationComponent
    renders_one :header
    renders_one :sidebar
    renders_one :main_content
    renders_one :footer, optional: true
    
    prop :controller_name, type: String, default: "playground-v2"
    
    swift_ui do
      div(data: { controller: controller_name }) do
        # Header slot
        if header?
          header
        end
        
        # Main layout with sidebar and content
        main_container do
          if sidebar?
            sidebar
          end
          
          if main_content?
            main_content
          end
        end
        
        # Optional footer
        if footer?
          footer
        end
      end
      .min_h("screen")
      .bg("gray-50")
    end
    
    private
    
    def main_container(&block)
      hstack(spacing: 0, &block)
        .h("[calc(100vh-64px)]")
    end
  end
end