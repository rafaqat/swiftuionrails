# frozen_string_literal: true

# Copyright 2025

# A responsive card component that adapts its layout based on orientation
class ResponsiveCardComponent < SwiftUIRails::Component::Base
  prop :title, type: String, required: true
  prop :description, type: String, required: true
  prop :image_url, type: String, required: true
  prop :price, type: String, required: true

  swift_ui do
    card do
      # Use orientation_stack to switch between horizontal/vertical layout
      orientation_stack(spacing: 16, alignment: :center) do
        # Image
        div do
          image(src: image_url, alt: title)
            .width(if_portrait { "full" })
            .width(if_landscape { "48" })
            .height(if_portrait { "48" })
            .height(if_landscape { "full" })
            .object_cover
            .corner_radius("lg")
        end

        # Content
        vstack(spacing: 8, alignment: if_portrait { :center } || :start) do
          # Title
          text(title)
            .font_size(if_portrait { "xl" } || "2xl")
            .font_weight("bold")
            .text_align(if_portrait { "center" } || "left")

          # Description
          text(description)
            .text_color("gray-600")
            .text_align(if_portrait { "center" } || "left")
            .line_clamp(if_portrait { 2 } || 3)

          # Price
          text(price)
            .font_size("lg")
            .font_weight("semibold")
            .text_color("blue-600")
            .margin_top(if_portrait { 2 } || 4)
        end
      end
    end
    .padding(if_portrait { 16 } || 24)
    .max_width(if_landscape { "2xl" })
    .margin_x(if_landscape { "auto" })
  end
end
# Copyright 2025
