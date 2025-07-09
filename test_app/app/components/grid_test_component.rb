# frozen_string_literal: true

# Copyright 2025

class GridTestComponent < ApplicationComponent
  include SwiftUIRails::DSL

  swift_ui do
    lazy_vgrid(
      columns: [ grid_item(:flexible), grid_item(:flexible) ],
      spacing: 6
    ) do
      4.times do |i|
        grid_item_wrapper do
          div.bg("gray-100").p(4).rounded do
            text("Item #{i + 1}")
          end
        end
      end
    end
  end
end
# Copyright 2025
