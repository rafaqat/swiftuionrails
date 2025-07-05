# frozen_string_literal: true
# Copyright 2025

class ModalComponent < SwiftUIRails::Component::Base
  prop :open, type: [TrueClass, FalseClass], default: false
  prop :title, type: String, required: true
  prop :close_path, type: String, required: true
  prop :size, type: Symbol, default: :md # :sm, :md, :lg, :xl
  
  renders_one :body
  renders_one :footer
  
  swift_ui do
    if open
      div(
        id: "modal-backdrop",
        data: { 
          turbo_permanent: true,
          controller: "modal",
          action: "keydown.esc->modal#close click->modal#closeOnBackdrop"
        }
      ) do
        # Backdrop - clicking closes modal
        link("", destination: close_path, data: { modal_target: "backdrop" })
          .fixed
          .inset(0)
          .background("black")
          .opacity(50)
          .z(40)
        
        # Modal container
        div(role: "dialog", aria: { modal: true, labelledby: "modal-title" }) do
          vstack(spacing: 0) do
            # Header
            div.flex.items_center.justify_between.padding(6).border_b do
              text(title, id: "modal-title")
                .text_xl
                .font_semibold
                .text_color("gray-900")
              
              link(destination: close_path, aria: { label: "Close modal" }) do
                icon("x", size: 24)
                  .text_color("gray-400")
                  .hover_text_color("gray-600")
              end
            end
            
            # Body
            div.padding(6) do
              body || text("Modal content goes here")
            end
            
            # Footer (optional)
            if footer?
              div.padding(6).border_t.background("gray-50") do
                footer
              end
            end
          end
        end
        .fixed
        .top("50%")
        .left("50%")
        .transform("translate(-50%, -50%)")
        .background("white")
        .corner_radius("lg")
        .shadow("xl")
        .z(50)
        .width(modal_width)
        .max_height("90vh")
        .overflow_y_auto
      end
    end
  end
  
  private
  
  def modal_width
    case size
    when :sm then "24rem"
    when :lg then "48rem"
    when :xl then "64rem"
    else "32rem" # :md default
    end
  end
end
# Copyright 2025
