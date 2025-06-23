# frozen_string_literal: true

class SpacerComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :min_length, as: :select, options: ["", "4", "8", "16", "32", "64"], default: ""
  control :direction, as: :select, options: [:horizontal, :vertical, :both], default: :horizontal
  control :background_color, as: :select, options: ["", "red-100", "blue-100", "green-100"], default: ""
  
  def default(
    min_length: "",
    direction: :horizontal,
    background_color: ""
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Basic Spacer Demonstration")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Horizontal spacer example
          hstack(spacing: 0) do
            text("Left")
              .padding(8)
              .background("gray-200")
              .corner_radius("md")
            
            spacer_element = spacer
            spacer_element = spacer_element.min_length(min_length) if min_length.present?
            spacer_element = spacer_element.background(background_color) if background_color.present?
            spacer_element
            
            text("Right")
              .padding(8)
              .background("gray-200")
              .corner_radius("md")
          end
          .background("gray-50")
          .padding(16)
          .corner_radius("lg")
          
          text("The spacer above pushes 'Left' and 'Right' to opposite ends")
            .font_size("sm")
            .text_color("gray-600")
            .text_align("center")
        end
      end
    end
  end
  
  def layout_examples
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Spacers in Different Layouts")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # HStack with spacers
          vstack(spacing: 8) do
            text("HStack with Spacers")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              button("Start")
                .button_style(:primary)
                .button_size(:sm)
              
              spacer.background("red-100")
              
              text("Center")
                .font_weight("medium")
              
              spacer.background("blue-100")
              
              button("End")
                .button_style(:secondary)
                .button_size(:sm)
            end
            .background("gray-50")
            .padding(12)
            .corner_radius("lg")
          end
          
          # VStack with spacers
          vstack(spacing: 8) do
            text("VStack with Spacers")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 0) do
              text("Top")
                .padding(8)
                .background("gray-200")
                .corner_radius("md")
              
              spacer.background("green-100").min_length("32")
              
              text("Middle")
                .padding(8)
                .background("gray-200")
                .corner_radius("md")
              
              spacer.background("yellow-100").min_length("16")
              
              text("Bottom")
                .padding(8)
                .background("gray-200")
                .corner_radius("md")
            end
            .background("gray-50")
            .padding(12)
            .corner_radius("lg")
            .height("200")
          end
          
          # Nested spacers
          vstack(spacing: 8) do
            text("Nested Layout with Spacers")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              vstack(spacing: 0) do
                text("Col 1 Top")
                  .font_size("sm")
                  .padding(4)
                
                spacer.background("purple-100")
                
                text("Col 1 Bottom")
                  .font_size("sm")
                  .padding(4)
              end
              .background("gray-100")
              .padding(8)
              .corner_radius("md")
              .height("120")
              
              spacer.background("orange-100")
              
              vstack(spacing: 0) do
                text("Col 2 Top")
                  .font_size("sm")
                  .padding(4)
                
                spacer.background("pink-100")
                
                text("Col 2 Bottom")
                  .font_size("sm")
                  .padding(4)
              end
              .background("gray-100")
              .padding(8)
              .corner_radius("md")
              .height("120")
            end
            .background("gray-50")
            .padding(12)
            .corner_radius("lg")
          end
        end
      end
    end
  end
  
  def flexible_layouts
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Flexible Layouts with Spacers")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Navigation bar layout
          vstack(spacing: 8) do
            text("Navigation Bar Pattern")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              text("Logo")
                .font_weight("bold")
                .text_color("blue-600")
                .padding(8)
              
              spacer.background("red-100")
              
              hstack(spacing: 16) do
                link("Home", destination: "#")
                  .text_color("gray-700")
                  .font_size("sm")
                
                link("About", destination: "#")
                  .text_color("gray-700")
                  .font_size("sm")
                
                link("Contact", destination: "#")
                  .text_color("gray-700")
                  .font_size("sm")
              end
              
              spacer.background("blue-100")
              
              button("Login")
                .button_style(:primary)
                .button_size(:sm)
            end
            .background("white")
            .padding(12)
            .corner_radius("lg")
            .shadow("sm")
          end
          
          # Card with action buttons
          vstack(spacing: 8) do
            text("Card with Flexible Actions")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 0) do
              # Header
              hstack(spacing: 0) do
                text("Card Title")
                  .font_weight("semibold")
                  .font_size("lg")
                
                spacer.background("green-100")
                
                button("×")
                  .button_style(:secondary)
                  .button_size(:sm)
              end
              .padding(16)
              
              # Content
              text("This is some card content that demonstrates how spacers can be used to create flexible layouts with proper spacing and alignment.")
                .font_size("sm")
                .text_color("gray-600")
                .padding_horizontal(16)
              
              spacer.background("yellow-100").min_length("16")
              
              # Footer actions
              hstack(spacing: 0) do
                text("Last updated: 2 hours ago")
                  .font_size("xs")
                  .text_color("gray-500")
                
                spacer.background("purple-100")
                
                hstack(spacing: 8) do
                  button("Cancel")
                    .button_style(:secondary)
                    .button_size(:sm)
                  
                  button("Save")
                    .button_style(:primary)
                    .button_size(:sm)
                end
              end
              .padding(16)
            end
            .background("white")
            .corner_radius("lg")
            .shadow("sm")
            .height("200")
          end
          
          # Sidebar layout
          vstack(spacing: 8) do
            text("Sidebar Layout Pattern")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              # Sidebar
              vstack(spacing: 8, alignment: :start) do
                text("Menu")
                  .font_weight("semibold")
                  .margin_bottom(8)
                
                link("Dashboard", destination: "#")
                  .font_size("sm")
                  .text_color("gray-700")
                
                link("Settings", destination: "#")
                  .font_size("sm")
                  .text_color("gray-700")
                
                link("Profile", destination: "#")
                  .font_size("sm")
                  .text_color("gray-700")
                
                spacer.background("red-100")
                
                button("Logout")
                  .button_style(:danger)
                  .button_size(:sm)
                  .w_full
              end
              .background("gray-100")
              .padding(16)
              .width("48")
              .height("200")
              
              # Main content
              vstack(spacing: 0) do
                text("Main Content Area")
                  .font_weight("semibold")
                  .padding(16)
                
                spacer.background("blue-100")
                
                text("Content goes here...")
                  .font_size("sm")
                  .text_color("gray-600")
                  .padding(16)
              end
              .background("white")
              .flex_grow
              .height("200")
            end
            .corner_radius("lg")
            .shadow("sm")
          end
        end
      end
    end
  end
  
  def spacing_comparison
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Spacing Comparison: Spacers vs Fixed Spacing")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Fixed spacing approach
          vstack(spacing: 12) do
            text("Fixed Spacing (spacing: 12)")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 12) do
              button("Button 1")
                .button_style(:primary)
                .button_size(:sm)
              
              button("Button 2")
                .button_style(:secondary)
                .button_size(:sm)
              
              button("Button 3")
                .button_style(:secondary)
                .button_size(:sm)
            end
            .background("gray-50")
            .padding(16)
            .corner_radius("lg")
            
            text("All elements have equal 12px spacing between them")
              .font_size("sm")
              .text_color("gray-600")
          end
          
          # Spacer approach
          vstack(spacing: 12) do
            text("Flexible Spacing with Spacers")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              button("Button 1")
                .button_style(:primary)
                .button_size(:sm)
              
              spacer.background("red-100")
              
              button("Button 2")
                .button_style(:secondary)
                .button_size(:sm)
              
              button("Button 3")
                .button_style(:secondary)
                .button_size(:sm)
            end
            .background("gray-50")
            .padding(16)
            .corner_radius("lg")
            
            text("Button 1 is pushed left, Buttons 2 & 3 are grouped on the right")
              .font_size("sm")
              .text_color("gray-600")
          end
          
          # Multiple spacers
          vstack(spacing: 12) do
            text("Multiple Spacers for Even Distribution")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              button("Left")
                .button_style(:primary)
                .button_size(:sm)
              
              spacer.background("red-100")
              
              button("Center")
                .button_style(:secondary)
                .button_size(:sm)
              
              spacer.background("blue-100")
              
              button("Right")
                .button_style(:secondary)
                .button_size(:sm)
            end
            .background("gray-50")
            .padding(16)
            .corner_radius("lg")
            
            text("Equal spacers create even distribution across available space")
              .font_size("sm")
              .text_color("gray-600")
          end
          
          # Min length spacers
          vstack(spacing: 12) do
            text("Spacers with Minimum Length")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 0) do
              text("Item 1")
                .padding(8)
                .background("gray-200")
                .corner_radius("md")
              
              spacer.background("green-100").min_length("64")
              
              text("Item 2")
                .padding(8)
                .background("gray-200")
                .corner_radius("md")
              
              spacer.background("yellow-100").min_length("32")
              
              text("Item 3")
                .padding(8)
                .background("gray-200")
                .corner_radius("md")
            end
            .background("gray-50")
            .padding(16)
            .corner_radius("lg")
            
            text("First spacer: 64px minimum, Second spacer: 32px minimum")
              .font_size("sm")
              .text_color("gray-600")
          end
          
          # Responsive behavior
          vstack(spacing: 12) do
            text("Responsive Behavior")
              .font_weight("semibold")
              .text_color("gray-900")
            
            text("Resize your browser window to see how spacers adapt to available space while maintaining minimum requirements.")
              .font_size("sm")
              .text_color("gray-600")
              .margin_bottom(8)
            
            # Container with fixed width to demonstrate
            div(class: "max-w-xs mx-auto") do
              swift_ui do
                hstack(spacing: 0) do
                  text("A")
                    .padding(8)
                    .background("blue-200")
                    .corner_radius("md")
                  
                  spacer.background("red-100").min_length("8")
                  
                  text("Long Text Content")
                    .padding(8)
                    .background("green-200")
                    .corner_radius("md")
                  
                  spacer.background("purple-100").min_length("8")
                  
                  text("B")
                    .padding(8)
                    .background("yellow-200")
                    .corner_radius("md")
                end
                .background("gray-50")
                .padding(12)
                .corner_radius("lg")
              end
            end
            
            text("Spacers maintain minimum 8px spacing even in constrained width")
              .font_size("sm")
              .text_color("gray-600")
              .text_align("center")
              .margin_top(8)
          end
        end
      end
    end
  end
end