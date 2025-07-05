# frozen_string_literal: true

class TestGridStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  def default
    swift_ui do
      div.p(4) do
        text("Grid Test").text_size("xl").font_weight("bold").mb(4)
        
        lazy_vgrid(
          columns: [grid_item(:flexible), grid_item(:flexible)],
          spacing: 6
        ) do
          4.times do |i|
            grid_item_wrapper do
              div.bg("gray-100").p(4).rounded.border do
                text("Item #{i + 1}")
              end
            end
          end
        end
      end
    end
  end
  
  def three_columns
    swift_ui do
      div.p(4) do
        text("Three Column Grid").text_size("xl").font_weight("bold").mb(4)
        
        lazy_vgrid(
          columns: [grid_item(:flexible), grid_item(:flexible), grid_item(:flexible)],
          spacing: 4
        ) do
          6.times do |i|
            grid_item_wrapper do
              div.bg("blue-100").p(4).rounded.text_center do
                text("Item #{i + 1}")
              end
            end
          end
        end
      end
    end
  end
  
  def adaptive
    swift_ui do
      div.p(4) do
        text("Adaptive Grid").text_size("xl").font_weight("bold").mb(4)
        
        lazy_vgrid(
          columns: [grid_item(:adaptive, min: 150)],
          spacing: 6
        ) do
          8.times do |i|
            grid_item_wrapper do
              div.bg("green-100").p(4).rounded.border.border_color("green-300") do
                text("Adaptive Item #{i + 1}")
              end
            end
          end
        end
      end
    end
  end
end