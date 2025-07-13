# frozen_string_literal: true

# Copyright 2025

class EnhancedProductListComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  # Define interactive controls
  control :columns, as: :select, options: [ :two, :three, :four, :auto ], default: :three
  control :filterable, as: :boolean, default: true
  control :sortable, as: :boolean, default: true
  control :filter_by_color, as: :boolean, default: true
  control :background_color, as: :select, options: [ "white", "gray-50", "blue-50" ], default: "white"
  control :gap, as: :select, options: [ "4", "6", "8", "12" ], default: "6"

  def default(columns: :three, filterable: true, sortable: true, filter_by_color: true, background_color: "white", gap: "6")
    # Sample product data
    products = [
      { id: 1, name: "Basic Tee", price: 35, image_url: "https://via.placeholder.com/300", variant: "Black" },
      { id: 2, name: "Nomad Tumbler", price: 35, image_url: "https://via.placeholder.com/300", variant: "White" },
      { id: 3, name: "Zip Tote Basket", price: 140, image_url: "https://via.placeholder.com/300", variant: "Natural" },
      { id: 4, name: "Earthen Bottle", price: 48, image_url: "https://via.placeholder.com/300", variant: "Gray" }
    ]

    EnhancedProductListComponent.new(
      products: products,
      columns: columns,
      filterable: filterable,
      sortable: sortable,
      filter_by_color: filter_by_color,
      background_color: background_color,
      gap: gap
    )
  end
end
# Copyright 2025
