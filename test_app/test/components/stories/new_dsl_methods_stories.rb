# Copyright 2025
class NewDslMethodsStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  # Form controls story
  control :selected_color, as: :select, options: [ "red", "blue", "green", "yellow" ], default: "blue"
  control :show_label, as: :boolean, default: true
  control :label_text, as: :text, default: "Choose a color:"

  def form_controls(selected_color: "blue", show_label: true, label_text: "Choose a color:")
    swift_ui do
      vstack(spacing: 4, alignment: :start) do
        if show_label
          label(label_text, for_input: "color-select")
            .font_weight("medium")
            .text_color("gray-700")
        end

        select(name: "color", selected: selected_color) do
          option("red", "Red")
          option("blue", "Blue")
          option("green", "Green")
          option("yellow", "Yellow")
        end
        .p(2)
        .rounded("md")
        .border
        .border_color("gray-300")
        .bg("white")
        .w("64")
      end
    end
  end

  # Advanced styling story
  control :break_mode, as: :select, options: [ "avoid", "auto", "avoid-page" ], default: "avoid"
  control :ring_width, as: :select, options: [ 1, 2, 4, 8 ], default: 2
  control :ring_color, as: :select, options: [ "blue-500", "indigo-500", "purple-500", "pink-500" ], default: "blue-500"
  control :group_opacity, as: :select, options: [ 0, 25, 50, 75, 100 ], default: 75

  def advanced_styling(break_mode: "avoid", ring_width: 2, ring_color: "blue-500", group_opacity: 75)
    swift_ui do
      div.p(8).bg("gray-50") do
        # Group hover example
        div.tw("group").mb(8) do
          h3.text_size("lg").font_weight("semibold").mb(4) do
            text("Group Hover Example (hover over the box)")
          end

          div
            .p(6)
            .bg("white")
            .rounded("lg")
            .shadow
            .border
            .transition
            .group_hover_opacity(group_opacity) do
            text("This content will change opacity on parent hover")
          end
        end

        # Break inside example
        div.mb(8) do
          h3.text_size("lg").font_weight("semibold").mb(4) do
            text("Break Inside Example")
          end

          div.tw("columns-2").gap(4) do
            (1..4).each do |i|
              div
                .p(4)
                .mb(4)
                .bg("white")
                .rounded
                .shadow
                .break_inside(break_mode) do
                text("Card #{i}: This card uses break-inside-#{break_mode} to control column breaks")
              end
            end
          end
        end

        # Ring hover example
        div do
          h3.text_size("lg").font_weight("semibold").mb(4) do
            text("Ring Hover Example")
          end

          button("Hover Me")
            .px(6)
            .py(3)
            .bg("white")
            .rounded("lg")
            .shadow
            .transition
            .ring_hover(ring_width, ring_color)
            .focus_ring(ring_color)
        end
      end
    end
  end

  # Flex and inline styles story
  control :flex_shrink_value, as: :select, options: [ nil, 0, 1 ], default: 0
  control :custom_style, as: :text, default: "background: linear-gradient(to right, #667eea, #764ba2);"
  control :tooltip_text, as: :text, default: "This is a custom tooltip"

  def flex_and_styles(flex_shrink_value: 0, custom_style: "background: linear-gradient(to right, #667eea, #764ba2);", tooltip_text: "This is a custom tooltip")
    swift_ui do
      vstack(spacing: 6) do
        # Flex shrink example
        div.flex.gap(4).mb(6) do
          div.flex_grow.p(4).bg("blue-100").rounded do
            text("Flex grow")
          end

          div_element = div.p(4).bg("purple-100").rounded
          div_element = div_element.flex_shrink(flex_shrink_value) if flex_shrink_value
          div_element.tw("min-w-0") do
            text("Flex shrink: #{flex_shrink_value || 'default'}")
          end

          div.p(4).bg("green-100").rounded.w("32") do
            text("Fixed width")
          end
        end

        # Custom style example
        div
          .p(6)
          .text_color("white")
          .rounded("lg")
          .shadow("lg")
          .style(custom_style)
          .title(tooltip_text) do
          text("Custom styled element with tooltip (hover to see)")
            .font_weight("bold")
            .text_size("lg")
        end
      end
    end
  end
end
# Copyright 2025
