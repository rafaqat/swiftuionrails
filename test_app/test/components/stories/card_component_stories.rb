# frozen_string_literal: true

class CardComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :title, as: :text, default: "Card Title"
  control :content, as: :text, default: "This is a sample card content. Cards are great for organizing related information and creating visual hierarchy."
  control :elevation, as: :select, options: [0, 1, 2, 3, 4], default: 1
  control :padding, as: :select, options: ["4", "6", "8", "12", "16", "20"], default: "16"
  control :corner_radius, as: :select, options: ["none", "sm", "md", "lg", "xl", "2xl"], default: "lg"
  control :background_color, as: :select, options: ["white", "gray-50", "blue-50", "green-50"], default: "white"
  control :border, as: :boolean, default: false
  control :hover_effect, as: :boolean, default: false
  
  def default(
    title: "Card Title",
    content: "This is a sample card content. Cards are great for organizing related information and creating visual hierarchy.",
    elevation: 1,
    padding: "16",
    corner_radius: "lg",
    background_color: "white",
    border: false,
    hover_effect: false
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        # Build card element with chained modifiers using DSL
        card_element = card(elevation: elevation) do
          vstack(spacing: 12) do
            text(title)
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            text(content)
              .text_color("gray-600")
              .line_clamp(3)
            
            hstack(spacing: 8) do
              button("Primary Action")
                .button_style(:primary)
                .button_size(:sm)
              
              button("Secondary")
                .button_style(:secondary)
                .button_size(:sm)
            end
          end
        end
        
        # Apply dynamic modifiers based on controls using chainable DSL
        card_element = card_element.padding(padding.to_i) if padding.present? && padding != "16"
        card_element = card_element.corner_radius(corner_radius) if corner_radius != "lg"
        card_element = card_element.background(background_color) if background_color != "white"
        card_element = card_element.border if border
        card_element = card_element.hover_scale("105") if hover_effect
        
        card_element
      end
    end
  end
  
  def card_layouts
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Card Layout Examples")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Simple card
          card(elevation: 1) do
            vstack(spacing: 8) do
              text("Simple Card")
                .font_weight("semibold")
                .text_color("gray-900")
              
              text("A basic card with minimal content and clean styling.")
                .font_size("sm")
                .text_color("gray-600")
            end
          end
          .padding(16)
          .corner_radius("lg")
          
          # Card with image
          card(elevation: 2) do
            vstack(spacing: 0) do
              # Image header
              div(class: "h-48 bg-gradient-to-r from-blue-500 to-purple-600 rounded-t-lg flex items-center justify-center") do
                text("Image Area")
                  .text_color("white")
                  .font_weight("semibold")
              end
              
              # Content
              vstack(spacing: 12) do
                text("Card with Image Header")
                  .font_size("lg")
                  .font_weight("semibold")
                  .text_color("gray-900")
                
                text("This card demonstrates how to combine images with content sections for rich layouts.")
                  .font_size("sm")
                  .text_color("gray-600")
                
                hstack(spacing: 8) do
                  button("Learn More")
                    .button_style(:primary)
                    .button_size(:sm)
                  
                  button("Share")
                    .button_style(:outline)
                    .button_size(:sm)
                end
              end
              .padding(16)
            end
          end
          .corner_radius("lg")
          
          # Stats card
          card(elevation: 1) do
            hstack(spacing: 16) do
              # Icon
              div(class: "w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center") do
                text("↗")
                  .font_size("xl")
                  .text_color("green-600")
              end
              
              # Content
              vstack(spacing: 2, alignment: :start) do
                text("$12,345")
                  .font_size("2xl")
                  .font_weight("bold")
                  .text_color("gray-900")
                
                text("Total Revenue")
                  .font_size("sm")
                  .text_color("gray-600")
                
                text("+12.5% from last month")
                  .font_size("xs")
                  .text_color("green-600")
              end
            end
          end
          .padding(20)
          .corner_radius("xl")
          .background("white")
          .border
        end
        .max_width("lg")
      end
    end
  end
  
  def interactive_cards
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("Interactive Card Examples")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Hover card
          card(elevation: 1) do
            vstack(spacing: 12) do
              text("Hover Effect Card")
                .font_size("lg")
                .font_weight("semibold")
                .text_color("gray-900")
              
              text("This card has a subtle hover effect that provides visual feedback.")
                .font_size("sm")
                .text_color("gray-600")
              
              text("Hover over me!")
                .font_size("xs")
                .text_color("blue-600")
                .font_weight("medium")
            end
          end
          .padding(16)
          .corner_radius("lg")
          .hover_scale("102")
          .transition
          
          # Clickable card
          link("", destination: "#") do
            card(elevation: 1) do
              vstack(spacing: 12) do
                text("Clickable Card")
                  .font_size("lg")
                  .font_weight("semibold")
                  .text_color("gray-900")
                
                text("This entire card is clickable and acts as a navigation element.")
                  .font_size("sm")
                  .text_color("gray-600")
                
                hstack do
                  text("Click anywhere on this card")
                    .font_size("xs")
                    .text_color("blue-600")
                    .font_weight("medium")
                  
                  spacer
                  
                  text("→")
                    .text_color("blue-600")
                end
              end
            end
            .padding(16)
            .corner_radius("lg")
            .hover_scale("102")
            .transition
          end
          
          # Grid of cards
          text("Card Grid Layout")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
            .margin_top(16)
          
          grid(columns: 3, spacing: 16) do
            # Card 1
            card(elevation: 1) do
              vstack(spacing: 8) do
                div(class: "w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center") do
                  text("1")
                    .text_color("white")
                    .font_weight("bold")
                    .font_size("sm")
                end
                
                text("Feature One")
                  .font_weight("semibold")
                  .text_color("gray-900")
                
                text("Description of the first feature.")
                  .font_size("sm")
                  .text_color("gray-600")
                  .text_align("center")
              end
            end
            .padding(16)
            .corner_radius("lg")
            .text_align("center")
            
            # Card 2
            card(elevation: 1) do
              vstack(spacing: 8) do
                div(class: "w-8 h-8 bg-green-500 rounded-lg flex items-center justify-center") do
                  text("2")
                    .text_color("white")
                    .font_weight("bold")
                    .font_size("sm")
                end
                
                text("Feature Two")
                  .font_weight("semibold")
                  .text_color("gray-900")
                
                text("Description of the second feature.")
                  .font_size("sm")
                  .text_color("gray-600")
                  .text_align("center")
              end
            end
            .padding(16)
            .corner_radius("lg")
            .text_align("center")
            
            # Card 3
            card(elevation: 1) do
              vstack(spacing: 8) do
                div(class: "w-8 h-8 bg-purple-500 rounded-lg flex items-center justify-center") do
                  text("3")
                    .text_color("white")
                    .font_weight("bold")
                    .font_size("sm")
                end
                
                text("Feature Three")
                  .font_weight("semibold")
                  .text_color("gray-900")
                
                text("Description of the third feature.")
                  .font_size("sm")
                  .text_color("gray-600")
                  .text_align("center")
              end
            end
            .padding(16)
            .corner_radius("lg")
            .text_align("center")
          end
        end
        .max_width("4xl")
      end
    end
  end
end