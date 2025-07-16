# frozen_string_literal: true

module Playground
  class SidebarComponent < ApplicationComponent
    prop :components, type: Array, default: []
    prop :examples, type: Array, default: []
    
    swift_ui do
      div do
        vstack(spacing: 6) do
          search_section
          components_section
          divider
          examples_section
          divider
          favorites_section
        end
        .p(4)
      end
      .w(32)
      .bg("white")
      .border_r
      .overflow_y("auto")
    end
    
    private
    
    def search_section
      textfield(
        placeholder: "Search components...",
        data: {
          action: "input->playground#filterComponents",
          playground_target: "searchInput"
        }
      )
      .w("full")
    end
    
    def components_section
      vstack(spacing: 4) do
        section_title("Components")
        
        div(data: { playground_target: "componentsContainer" }) do
          grouped_components.each do |category, items|
            component_category(category, items)
          end
        end
      end
    end
    
    def grouped_components
      return {} if components.nil? || !components.respond_to?(:group_by)
      # Additional nil safety - filter out nil components
      safe_components = components.compact
      return {} if safe_components.empty?
      
      safe_components.group_by { |c| (c.is_a?(Hash) && c[:category]) || "General" }
    end
    
    def component_category(category, items)
      vstack(spacing: 2) do
        category_title(category)
        
        items.each do |component|
          component_item(component)
        end
      end
      .mb(4)
    end
    
    def category_title(title)
      text(title)
        .text_xs
        .font_weight("medium")
        .text_color("gray-500")
        .tw("uppercase")
        .tw("tracking-wider")
    end
    
    def component_item(component)
      interactive_item(component[:name]) do
        component_icon(component[:icon])
        text(component[:name])
          .font_size("sm")
      end
      .data(
        action: "click->playground#insertComponent",
        playground_code_param: component[:code]
      )
    end
    
    def component_icon(icon_name)
      span { text(icon_name || "📦") }
        .tw("mr-2")
    end
    
    def examples_section
      vstack(spacing: 4) do
        section_title("Examples")
        
        div(data: { playground_target: "examplesContainer" }) do
          examples.each do |example|
            example_item(example)
          end
        end
      end
    end
    
    def example_item(example)
      interactive_item do
        vstack(spacing: 1, alignment: :start) do
          text(example[:name])
            .font_size("sm")
            .font_weight("medium")
          
          if example[:description]
            text(example[:description])
              .font_size("xs")
              .text_color("gray-500")
              .line_clamp(2)
          end
        end
      end
      .data(
        action: "click->playground#loadExample",
        playground_code_param: example[:code]
      )
    end
    
    def favorites_section
      vstack(spacing: 4) do
        hstack do
          section_title("Favorites")
          spacer
          add_favorite_button
        end
        
        favorites_list
      end
    end
    
    def add_favorite_button
      button("+")
        .text_sm
        .text_color("blue-600")
        .hover_text_color("blue-700")
        .data(action: "click->playground#saveFavorite")
    end
    
    def favorites_list
      div(data: { playground_target: "favoritesList" }) do
        text("No favorites yet")
          .text_sm
          .text_color("gray-500")
          .tw("italic")
      end
    end
    
    def section_title(title)
      text(title)
        .font_weight("semibold")
        .text_color("gray-700")
    end
    
    def interactive_item(label = nil, &block)
      button do
        if block
          hstack(spacing: 2, &block)
        else
          text(label)
        end
      end
      .w("full")
      .text_align("left")
      .px(3).py(2)
      .rounded("md")
      .hover_bg("gray-100")
      .transition
    end
    
    def divider
      div.h("px").bg("gray-200").w("full")
    end
    
    def spacer
      div.flex_1
    end
  end
end