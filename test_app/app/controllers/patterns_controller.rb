# frozen_string_literal: true

class PatternsController < ApplicationController
  def index
    @patterns = [
      {
        name: "Cards",
        description: "Various card layouts and styles",
        path: cards_patterns_path
      },
      {
        name: "Lists",
        description: "List components and data display",
        path: lists_patterns_path
      },
      {
        name: "Navigation",
        description: "Navigation bars, tabs, and menus",
        path: navigation_patterns_path
      },
      {
        name: "Modals",
        description: "Modal dialogs and overlays",
        path: modals_patterns_path
      },
      {
        name: "Data Tables",
        description: "Tables with sorting and filtering",
        path: data_tables_patterns_path
      }
    ]
  end
  
  def cards
    @examples = [
      {
        title: "Basic Card",
        code: <<~RUBY
          card(elevation: 1) do
            text("Simple card content")
          end
        RUBY
      },
      {
        title: "Card with Header",
        code: <<~RUBY
          card do
            card_header do
              text("Card Title").font_weight("semibold")
            end
            card_content do
              text("Main content goes here")
            end
            card_footer do
              hstack(justify: :end) do
                button("Cancel").button_style(:ghost)
                button("Save").button_style(:primary)
              end
            end
          end
        RUBY
      },
      {
        title: "Image Card",
        code: <<~RUBY
          card(elevation: 2) do
            image(src: "/placeholder.jpg")
              .w("full").h(48).object_fit("cover")
            
            vstack(spacing: 2, class: "p-4") do
              text("Beautiful Landscape").font_size("lg").font_weight("semibold")
              text("A stunning view of nature").text_color("gray-600")
            end
          end
        RUBY
      }
    ]
  end
  
  def lists
    @examples = [
      {
        title: "Simple List",
        code: <<~RUBY
          list do
            items.each do |item|
              list_item do
                text(item.name)
              end
            end
          end
        RUBY
      },
      {
        title: "List with Actions",
        code: <<~RUBY
          vstack(spacing: 0) do
            items.each_with_index do |item, index|
              hstack(justify: :between, class: "p-4 hover:bg-gray-50 border-b") do
                vstack(alignment: :start) do
                  text(item.title).font_weight("medium")
                  text(item.description).text_sm.text_color("gray-600")
                end
                
                hstack(spacing: 2) do
                  button("Edit").button_size(:sm).button_style(:ghost)
                  button("Delete").button_size(:sm).button_style(:danger)
                end
              end
            end
          end
        RUBY
      }
    ]
  end
  
  def show
    @pattern = params[:id]
    # Load specific pattern details
  end
end