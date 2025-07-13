# frozen_string_literal: true

# Copyright 2025

class CardComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  # Define interactive controls
  control :background_color, as: :select, 
    options: ["white", "gray-50", "gray-100", "blue-50", "green-50"], 
    default: "white"
  control :elevation, as: :select, 
    options: [0, 1, 2, 3, 4], 
    default: 1
  control :padding, as: :select,
    options: ["8", "12", "16", "20", "24"],
    default: "16"
  control :corner_radius, as: :select,
    options: ["none", "sm", "md", "lg", "xl", "2xl", "3xl"],
    default: "lg"
  control :border, as: :boolean, default: false
  control :hover_effect, as: :boolean, default: false

  def default(background_color: "white", elevation: 1, padding: "16", corner_radius: "lg", border: false, hover_effect: false)
    swift_ui do
      card(elevation: elevation) do
        vstack(spacing: 16) do
          text("Card Title").font_size("xl").font_weight("semibold")
          text("This is a sample card component with customizable properties.")
            .text_color("gray-600")
          
          hstack(spacing: 8) do
            button("Action").button_style(:primary).button_size(:sm)
            button("Cancel").button_style(:secondary).button_size(:sm)
          end
        end
      end
      .p(padding)
      .bg(background_color)
      .corner_radius(corner_radius)
      .tap { |c| c.border if border }
      .tap { |c| c.hover_scale(102).transition if hover_effect }
    end
  end

  def with_image(background_color: "white", elevation: 1, padding: "16", corner_radius: "lg", border: false, hover_effect: false)
    swift_ui do
      card(elevation: elevation) do
        vstack(spacing: 0) do
          image(src: "https://via.placeholder.com/400x200", alt: "Card image")
            .width("full")
            .height(200)
            .object_cover
          
          vstack(spacing: 12) do
            text("Card with Image").font_size("lg").font_weight("semibold")
            text("This card includes an image at the top.")
              .text_color("gray-600")
              .text_size("sm")
          end
          .p(padding)
        end
      end
      .bg(background_color)
      .corner_radius(corner_radius)
      .overflow("hidden")
      .tap { |c| c.border if border }
      .tap { |c| c.hover_scale(102).transition if hover_effect }
    end
  end
end
# Copyright 2025