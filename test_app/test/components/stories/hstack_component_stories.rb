# frozen_string_literal: true

class HstackComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :spacing, as: :select, options: [0, 2, 4, 6, 8, 10, 12, 16, 20], default: 8
  control :alignment, as: :select, options: [:start, :center, :end], default: :center
  control :background_color, as: :select, options: ["", "gray-50", "blue-50", "green-50", "red-50"], default: ""
  control :padding, as: :select, options: ["", "4", "6", "8", "12", "16"], default: ""
  
  def default(
    spacing: 8,
    alignment: :center,
    background_color: "",
    padding: ""
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        stack = hstack(spacing: spacing, alignment: alignment) do
          button("First")
            .button_style(:primary)
            .button_size(:sm)
          
          text("Middle Text")
            .font_weight("medium")
          
          button("Last")
            .button_style(:secondary)
            .button_size(:sm)
        end
        
        stack = stack.background(background_color) if background_color.present?
        stack = stack.padding(padding) if padding.present?
        
        stack
      end
    end
  end
  
  def navigation_bar
    content_tag(:div, class: "p-8") do
      swift_ui do
        hstack(spacing: 0, alignment: :center) do
          # Logo/Brand
          text("MyApp")
            .font_size("xl")
            .font_weight("bold")
            .text_color("blue-600")
          
          spacer
          
          # Navigation links
          hstack(spacing: 24) do
            link("Home", destination: "#")
              .text_color("gray-700")
              .hover_effect("text-blue-600")
            
            link("About", destination: "#")
              .text_color("gray-700")
              .hover_effect("text-blue-600")
            
            link("Contact", destination: "#")
              .text_color("gray-700")
              .hover_effect("text-blue-600")
          end
          
          spacer
          
          # Actions
          hstack(spacing: 8) do
            button("Sign In")
              .button_style(:secondary)
              .button_size(:sm)
            
            button("Sign Up")
              .button_style(:primary)
              .button_size(:sm)
          end
        end
        .background("white")
        .padding_horizontal(24)
        .padding_vertical(16)
        .shadow("sm")
      end
    end
  end
  
  def card_layout
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("HStack Card Layouts")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Product card
          hstack(spacing: 16) do
            # Image placeholder
            div(class: "w-20 h-20 bg-gray-200 rounded-lg flex items-center justify-center") do
              text("IMG")
                .font_size("xs")
                .text_color("gray-500")
            end
            
            # Content
            vstack(spacing: 4, alignment: :start) do
              text("Product Name")
                .font_weight("semibold")
                .text_color("gray-900")
              
              text("Short description of the product")
                .font_size("sm")
                .text_color("gray-600")
              
              text("$29.99")
                .font_weight("bold")
                .text_color("green-600")
            end
            
            spacer
            
            # Actions
            vstack(spacing: 8) do
              button("Buy")
                .button_style(:primary)
                .button_size(:sm)
              
              button("♡")
                .button_style(:secondary)
                .button_size(:sm)
            end
          end
          .background("white")
          .padding(16)
          .corner_radius("lg")
          .shadow("sm")
          
          # Notification
          hstack(spacing: 12) do
            div(class: "w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center") do
              text("!")
                .font_weight("bold")
                .text_color("white")
                .font_size("sm")
            end
            
            vstack(spacing: 2, alignment: :start) do
              text("New Feature Available")
                .font_weight("semibold")
                .text_color("gray-900")
              
              text("Check out our latest update with improved performance")
                .font_size("sm")
                .text_color("gray-600")
            end
            
            spacer
            
            button("×")
              .button_style(:secondary)
              .button_size(:sm)
          end
          .background("blue-50")
          .padding(16)
          .corner_radius("lg")
        end
        .max_width("lg")
      end
    end
  end
end