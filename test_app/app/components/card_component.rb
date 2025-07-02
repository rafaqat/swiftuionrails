# frozen_string_literal: true

class CardComponent < SwiftUIRails::Component::Base
  # ViewComponent 2.0 Collection Support
  prop :collection_item, type: Object, default: nil
  prop :collection_counter, type: Integer, default: nil
  
  # Core props
  prop :title, type: String, default: "Card Title"
  prop :content, type: String, default: "This is a sample card content. Cards are great for organizing related information and creating visual hierarchy."
  prop :elevation, type: Integer, default: 1
  prop :padding, type: String, default: "16"
  prop :corner_radius, type: String, default: "lg"
  prop :background_color, type: String, default: "white"
  prop :border, type: [TrueClass, FalseClass], default: false
  prop :hover_effect, type: [TrueClass, FalseClass], default: false
  
  # ViewComponent 2.0 Slot Support - renders_one/renders_many
  renders_one :header, "CardHeaderComponent"
  renders_one :media, types: {
    image: "CardImageComponent", 
    video: "CardVideoComponent"
  }
  renders_many :actions, "ActionButtonComponent"
  renders_one :footer, "CardFooterComponent"

  swift_ui do
    # Handle collection data if present
    card_title = collection_item ? (collection_item[:title] || collection_item.title) : title
    card_content = collection_item ? (collection_item[:content] || collection_item.content) : content
    
    card_element = card(elevation: elevation) do
      vstack(spacing: 0) do
        # ViewComponent 2.0 Header Slot
        if header
          div(class: "card-header") do
            header
          end
          .padding(16)
          .border_bottom
        else
          # Default header content
          div(class: "card-header") do
            hstack do
              text(card_title)
                .font_size("lg")
                .font_weight("semibold")
                .text_color("gray-900")
                
              spacer
              
              # Collection counter badge
              if collection_counter
                span("#{collection_counter + 1}")
                  .background("blue-100")
                  .text_color("blue-800")
                  .padding_x(2)
                  .padding_y(1)
                  .corner_radius("full")
                  .font_size("xs")
              end
            end
          end
          .padding(16)
        end
        
        # ViewComponent 2.0 Media Slot
        if media
          div(class: "card-media") do
            media
          end
        end
        
        # Main content
        div(class: "card-content") do
          text(card_content)
            .text_color("gray-600")
            .line_clamp(3)
        end
        .padding(16)
        
        # ViewComponent 2.0 Actions Slot (renders_many)
        if actions.any?
          div(class: "card-actions") do
            hstack(spacing: 8) do
              actions.each do |action|
                action
              end
            end
          end
          .padding(16)
          .border_top
        else
          # Default actions
          div(class: "card-actions") do
            hstack(spacing: 8) do
              button("Primary Action")
                .button_style(:primary)
                .button_size(:sm)
              
              button("Secondary")
                .button_style(:secondary)
                .button_size(:sm)
            end
          end
          .padding(16)
          .border_top
        end
        
        # ViewComponent 2.0 Footer Slot
        if footer
          div(class: "card-footer") do
            footer
          end
          .padding(16)
          .border_top
        end
      end
    end
    
    # Apply dynamic modifiers with ViewComponent 2.0 performance
    card_element = card_element.padding(padding.to_i) if padding.present? && padding != "16"
    card_element = card_element.corner_radius(corner_radius) if corner_radius != "lg"
    card_element = card_element.background(background_color) if background_color != "white"
    card_element = card_element.border if border
    card_element = card_element.hover_scale("105") if hover_effect
    
    card_element
  end
  
  # ViewComponent 2.0 Collection Optimization
  class << self
    def card_collection(cards:, **options, &block)
      # Leverage ViewComponent 2.0 with_collection for 10x performance
      with_collection(cards, **options) do |card_data, counter|
        if card_data.is_a?(Hash)
          new(
            title: card_data[:title] || "Card Title",
            content: card_data[:content] || "Card content",
            collection_item: card_data,
            collection_counter: counter,
            **card_data.except(:title, :content)
          )
        else
          new(
            title: card_data.title || "Card Title",
            content: card_data.content || "Card content", 
            collection_item: card_data,
            collection_counter: counter
          )
        end
      end
    end
  end
end