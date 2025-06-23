# frozen_string_literal: true

class IconComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :name, as: :select, options: ["star", "heart", "home", "user", "settings", "search", "plus", "minus", "check", "x"], default: "star"
  control :size, as: :select, options: [12, 16, 20, 24, 32, 48, 64], default: 24
  control :color, as: :select, options: ["gray-500", "blue-600", "green-600", "red-600", "purple-600", "yellow-500"], default: "gray-500"
  control :stroke_width, as: :select, options: [1, 1.5, 2, 2.5, 3], default: 2
  control :filled, as: :boolean, default: false
  
  def default(
    name: "star",
    size: 24,
    color: "gray-500",
    stroke_width: 2,
    filled: false
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Icon: #{name}")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
          
          # Icon with current settings
          icon_element = icon(name, size: size)
            .text_color(color)
          
          # Add visual styling to make the placeholder more representative
          icon_element = icon_element
            .background(filled ? color : "transparent")
            .border
            .corner_radius("sm")
            .flex
            .items_center
            .justify_center
          
          # Display current settings
          vstack(spacing: 4, alignment: :start) do
            text("Current Settings:")
              .font_weight("semibold")
              .text_color("gray-700")
              .font_size("sm")
            
            text("Name: #{name}")
              .font_size("xs")
              .text_color("gray-600")
            
            text("Size: #{size}px")
              .font_size("xs")
              .text_color("gray-600")
            
            text("Color: #{color}")
              .font_size("xs")
              .text_color("gray-600")
            
            text("Stroke Width: #{stroke_width}")
              .font_size("xs")
              .text_color("gray-600")
            
            text("Filled: #{filled}")
              .font_size("xs")
              .text_color("gray-600")
          end
          .background("gray-50")
          .padding(12)
          .corner_radius("md")
          
          icon_element
        end
        .items_center
      end
    end
  end
  
  def icon_sizes
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("Icon Sizes")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Size comparison grid
          vstack(spacing: 16) do
            [12, 16, 20, 24, 32, 48, 64].each do |size|
              hstack(spacing: 16, alignment: :center) do
                # Size label
                text("#{size}px")
                  .font_size("sm")
                  .text_color("gray-600")
                  .w(16)
                
                # Icon at this size
                icon("star", size: size)
                  .text_color("blue-600")
                  .background("blue-50")
                  .border
                  .corner_radius("sm")
                  .flex
                  .items_center
                  .justify_center
                
                # Visual context
                text("Perfect for #{size <= 16 ? 'inline text' : size <= 24 ? 'buttons' : size <= 32 ? 'cards' : 'headers'}")
                  .font_size("xs")
                  .text_color("gray-500")
                  .flex("1")
              end
            end
          end
          .background("white")
          .padding(20)
          .corner_radius("lg")
          .shadow("sm")
        end
      end
    end
  end
  
  def icon_colors
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("Icon Colors")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Color palette showcase
          vstack(spacing: 16) do
            # Semantic colors
            vstack(spacing: 12, alignment: :start) do
              text("Semantic Colors")
                .font_weight("semibold")
                .text_color("gray-900")
              
              hstack(spacing: 12) do
                ["gray-500", "blue-600", "green-600", "red-600", "purple-600", "yellow-500"].each do |color|
                  vstack(spacing: 4) do
                    icon("heart", size: 32)
                      .text_color(color)
                      .background("#{color.split('-')[0]}-50")
                      .border
                      .corner_radius("md")
                      .flex
                      .items_center
                      .justify_center
                      .p(2)
                    
                    text(color)
                      .font_size("xs")
                      .text_color("gray-600")
                      .text_center
                  end
                end
              end
            end
            
            # Usage examples
            vstack(spacing: 12, alignment: :start) do
              text("Common Usage")
                .font_weight("semibold")
                .text_color("gray-900")
              
              vstack(spacing: 8) do
                hstack(spacing: 8) do
                  icon("check", size: 20)
                    .text_color("green-600")
                    .background("green-50")
                    .border
                    .corner_radius("full")
                    .flex
                    .items_center
                    .justify_center
                    .p(1)
                  
                  text("Success state")
                    .text_color("green-700")
                end
                
                hstack(spacing: 8) do
                  icon("x", size: 20)
                    .text_color("red-600")
                    .background("red-50")
                    .border
                    .corner_radius("full")
                    .flex
                    .items_center
                    .justify_center
                    .p(1)
                  
                  text("Error state")
                    .text_color("red-700")
                end
                
                hstack(spacing: 8) do
                  icon("settings", size: 20)
                    .text_color("gray-600")
                    .background("gray-50")
                    .border
                    .corner_radius("md")
                    .flex
                    .items_center
                    .justify_center
                    .p(1)
                  
                  text("Neutral action")
                    .text_color("gray-700")
                end
              end
            end
          end
          .background("white")
          .padding(20)
          .corner_radius("lg")
          .shadow("sm")
        end
      end
    end
  end
  
  def icons_in_context
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Icons in Context")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Buttons with icons
          vstack(spacing: 16, alignment: :start) do
            text("Buttons with Icons")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 12) do
              # Icon before text
              button do
                hstack(spacing: 6) do
                  icon("plus", size: 16)
                    .text_color("white")
                    .background("transparent")
                  text("Add Item")
                end
              end
              .button_style(:primary)
              .button_size(:sm)
              
              # Icon after text
              button do
                hstack(spacing: 6) do
                  text("Download")
                  icon("search", size: 16)
                    .text_color("blue-700")
                    .background("transparent")
                end
              end
              .button_style(:secondary)
              .button_size(:sm)
              
              # Icon only button
              button do
                icon("settings", size: 16)
                  .text_color("gray-700")
                  .background("transparent")
              end
              .button_style(:outline)
              .button_size(:sm)
              .corner_radius("full")
              .w(10)
              .h(10)
            end
          end
          .background("gray-50")
          .padding(16)
          .corner_radius("lg")
          
          # Navigation with icons
          vstack(spacing: 16, alignment: :start) do
            text("Navigation Items")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 2) do
              ["home", "user", "settings", "search"].each do |icon_name|
                hstack(spacing: 12) do
                  icon(icon_name, size: 20)
                    .text_color("gray-600")
                    .background("transparent")
                  
                  text(icon_name.capitalize)
                    .text_color("gray-700")
                    .flex("1")
                  
                  spacer
                end
                .padding(8)
                .corner_radius("md")
                .hover_background("gray-100")
                .cursor("pointer")
              end
            end
          end
          .background("white")
          .padding(16)
          .corner_radius("lg")
          .border
          
          # Status indicators
          vstack(spacing: 16, alignment: :start) do
            text("Status Indicators")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 12) do
              hstack(spacing: 8) do
                icon("check", size: 16)
                  .text_color("green-600")
                  .background("green-100")
                  .corner_radius("full")
                  .p(1)
                  .flex
                  .items_center
                  .justify_center
                
                text("Task completed successfully")
                  .text_color("green-700")
                  .font_size("sm")
                
                spacer
                
                text("2 min ago")
                  .text_color("gray-500")
                  .font_size("xs")
              end
              
              hstack(spacing: 8) do
                icon("x", size: 16)
                  .text_color("red-600")
                  .background("red-100")
                  .corner_radius("full")
                  .p(1)
                  .flex
                  .items_center
                  .justify_center
                
                text("Failed to save changes")
                  .text_color("red-700")
                  .font_size("sm")
                
                spacer
                
                text("5 min ago")
                  .text_color("gray-500")
                  .font_size("xs")
              end
              
              hstack(spacing: 8) do
                icon("heart", size: 16)
                  .text_color("purple-600")
                  .background("purple-100")
                  .corner_radius("full")
                  .p(1)
                  .flex
                  .items_center
                  .justify_center
                
                text("New feature available")
                  .text_color("purple-700")
                  .font_size("sm")
                
                spacer
                
                text("1 hour ago")
                  .text_color("gray-500")
                  .font_size("xs")
              end
            end
          end
          .background("white")
          .padding(16)
          .corner_radius("lg")
          .border
          
          # Card headers with icons
          vstack(spacing: 16, alignment: :start) do
            text("Card Headers")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 16) do
              # Stats card
              card(elevation: 1) do
                vstack(spacing: 12) do
                  hstack(spacing: 8) do
                    icon("star", size: 24)
                      .text_color("yellow-600")
                      .background("yellow-100")
                      .corner_radius("md")
                      .p(2)
                      .flex
                      .items_center
                      .justify_center
                    
                    vstack(spacing: 2, alignment: :start) do
                      text("4.8")
                        .font_size("2xl")
                        .font_weight("bold")
                        .text_color("gray-900")
                      
                      text("Average Rating")
                        .font_size("sm")
                        .text_color("gray-600")
                    end
                    
                    spacer
                  end
                end
              end
              .padding(16)
              .flex("1")
              
              # User card
              card(elevation: 1) do
                vstack(spacing: 12) do
                  hstack(spacing: 8) do
                    icon("user", size: 24)
                      .text_color("blue-600")
                      .background("blue-100")
                      .corner_radius("full")
                      .p(2)
                      .flex
                      .items_center
                      .justify_center
                    
                    vstack(spacing: 2, alignment: :start) do
                      text("1,247")
                        .font_size("2xl")
                        .font_weight("bold")
                        .text_color("gray-900")
                      
                      text("Active Users")
                        .font_size("sm")
                        .text_color("gray-600")
                    end
                    
                    spacer
                  end
                end
              end
              .padding(16)
              .flex("1")
            end
          end
          .background("gray-50")
          .padding(16)
          .corner_radius("lg")
        end
        .max_width("4xl")
      end
    end
  end
end