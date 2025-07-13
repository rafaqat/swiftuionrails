# frozen_string_literal: true

# Copyright 2025

class ResponsiveCardComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  # Interactive controls
  control :orientation, as: :select, options: [ "portrait", "landscape" ], default: "portrait"
  control :title, as: :text, default: "SwiftUI Rails Card"
  control :description, as: :text, default: "This card adapts its layout based on device orientation, demonstrating responsive design with SwiftUI Rails."
  control :price, as: :text, default: "$99.99"
  control :image_url, as: :text, default: "https://picsum.photos/400/300"

  def default(orientation: "portrait", title: "SwiftUI Rails Card", description: "This card adapts its layout based on device orientation.", price: "$99.99", image_url: "https://picsum.photos/400/300")
    # Convert string orientation to symbol
    orientation_sym = orientation.to_sym

    swift_ui do
      vstack(spacing: 16) do
        # Show current orientation
        div do
          text("Current Orientation: #{orientation.capitalize}")
            .font_weight("semibold")
            .text_color("gray-700")
            .padding(8)
            .background("gray-100")
            .corner_radius("md")
        end

        # The responsive card
        ResponsiveCardComponent.new(
          orientation: orientation_sym,
          title: title,
          description: description,
          price: price,
          image_url: image_url
        )
      end
    end
  end

  def portrait_example
    swift_ui do
      vstack(spacing: 16) do
        text("Portrait Layout Example")
          .font_size("xl")
          .font_weight("bold")

        ResponsiveCardComponent.new(
          orientation: :portrait,
          title: "Portrait Product",
          description: "In portrait mode, the image is full width and content is centered.",
          price: "$149.99",
          image_url: "https://picsum.photos/400/300?random=1"
        )
      end
    end
  end

  def landscape_example
    swift_ui do
      vstack(spacing: 16) do
        text("Landscape Layout Example")
          .font_size("xl")
          .font_weight("bold")

        ResponsiveCardComponent.new(
          orientation: :landscape,
          title: "Landscape Product",
          description: "In landscape mode, the image and content are side by side with more space for description.",
          price: "$249.99",
          image_url: "https://picsum.photos/400/300?random=2"
        )
      end
    end
  end
end
# Copyright 2025
