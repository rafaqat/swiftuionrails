# frozen_string_literal: true

class DividerComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :orientation, as: :select, options: ["horizontal", "vertical"], default: "horizontal"
  control :thickness, as: :select, options: ["1", "2", "4", "8"], default: "1"
  control :color, as: :select, options: ["gray-200", "gray-300", "gray-400", "blue-200", "red-200"], default: "gray-300"
  control :style, as: :select, options: ["solid", "dashed", "dotted"], default: "solid"
  control :length, as: :select, options: ["", "1/2", "1/3", "2/3", "full"], default: ""
  
  def default(
    orientation: "horizontal",
    thickness: "1",
    color: "gray-300",
    style: "solid",
    length: ""
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Divider Example")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
          
          text("Content above the divider")
            .text_color("gray-600")
          
          # Create the divider with dynamic properties
          divider_element = divider
          
          # Apply orientation
          if orientation == "vertical"
            divider_element = divider_element.tw("border-l border-t-0 h-16 w-0")
          end
          
          # Apply thickness
          case thickness
          when "2"
            divider_element = divider_element.tw("border-t-2") if orientation == "horizontal"
            divider_element = divider_element.tw("border-l-2") if orientation == "vertical"
          when "4"
            divider_element = divider_element.tw("border-t-4") if orientation == "horizontal"
            divider_element = divider_element.tw("border-l-4") if orientation == "vertical"
          when "8"
            divider_element = divider_element.tw("border-t-8") if orientation == "horizontal"
            divider_element = divider_element.tw("border-l-8") if orientation == "vertical"
          end
          
          # Apply color
          divider_element = divider_element.tw("border-#{color}")
          
          # Apply style
          case style
          when "dashed"
            divider_element = divider_element.tw("border-dashed")
          when "dotted"
            divider_element = divider_element.tw("border-dotted")
          end
          
          # Apply length
          if length.present?
            if orientation == "horizontal"
              divider_element = divider_element.tw("w-#{length}")
            else
              divider_element = divider_element.tw("h-#{length == 'full' ? '32' : '16'}")
            end
          end
          
          if orientation == "horizontal"
            divider_element
          else
            hstack(spacing: 16, alignment: :center) do
              text("Left content")
                .text_color("gray-600")
              
              divider_element
              
              text("Right content")
                .text_color("gray-600")
            end
          end
          
          text("Content below the divider")
            .text_color("gray-600")
        end
        .max_width("lg")
      end
    end
  end
  
  def section_dividers
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 0) do
          text("Section Dividers Example")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(24)
          
          # Header section
          vstack(spacing: 12) do
            text("Introduction")
              .font_size("xl")
              .font_weight("semibold")
              .text_color("gray-900")
            
            text("This section introduces the main concepts. Dividers help separate different content areas and create visual hierarchy in your layouts.")
              .text_color("gray-600")
              .line_height("relaxed")
          end
          .padding(24)
          
          # Section divider
          divider
            .tw("border-gray-200")
          
          # Main content section
          vstack(spacing: 12) do
            text("Main Content")
              .font_size("xl")
              .font_weight("semibold")
              .text_color("gray-900")
            
            text("Here's the primary content of the page. Notice how the divider above creates a clear separation from the introduction section.")
              .text_color("gray-600")
              .line_height("relaxed")
            
            text("Additional paragraph to show more content in this main section. Dividers are particularly useful in long-form content to break up text.")
              .text_color("gray-600")
              .line_height("relaxed")
          end
          .padding(24)
          
          # Thick accent divider
          divider
            .tw("border-blue-300 border-t-2")
          
          # Call-to-action section
          vstack(spacing: 12) do
            text("Call to Action")
              .font_size("xl")
              .font_weight("semibold")
              .text_color("gray-900")
            
            text("This final section uses a thicker, colored divider to draw attention and separate the call-to-action from the main content.")
              .text_color("gray-600")
              .line_height("relaxed")
            
            button("Get Started")
              .tw("bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors")
          end
          .padding(24)
        end
        .max_width("2xl")
        .background("white")
        .corner_radius("lg")
        .tw("shadow-sm")
      end
    end
  end
  
  def list_separators
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("List Separators Example")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Simple list with dividers
          vstack(spacing: 0) do
            text("Navigation Menu")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
              .margin_bottom(16)
            
            # Menu items
            [
              { title: "Home", description: "Return to the main page" },
              { title: "Products", description: "Browse our product catalog" },
              { title: "Services", description: "Learn about our services" },
              { title: "About", description: "Company information and history" },
              { title: "Contact", description: "Get in touch with our team" }
            ].each_with_index do |item, index|
              # Menu item
              hstack(spacing: 12) do
                vstack(spacing: 2, alignment: :start) do
                  text(item[:title])
                    .font_weight("medium")
                    .text_color("gray-900")
                  
                  text(item[:description])
                    .font_size("sm")
                    .text_color("gray-600")
                end
                
                spacer
                
                text("→")
                  .text_color("gray-400")
              end
              .padding_y(12)
              .padding_x(16)
              .tw("hover:bg-gray-50 transition-colors cursor-pointer")
              
              # Add divider except for last item
              unless index == 4
                divider
                  .tw("border-gray-200")
              end
            end
          end
          .background("white")
          .corner_radius("lg")
          .tw("shadow-sm border border-gray-200")
          
          # Settings list with different divider styles
          vstack(spacing: 0) do
            text("Settings")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
              .margin_bottom(16)
            
            # Notification settings
            hstack do
              text("Push Notifications")
                .font_weight("medium")
                .text_color("gray-900")
              
              spacer
              
              toggle("notifications", is_on: true)
            end
            .padding_y(12)
            .padding_x(16)
            
            divider.tw("border-gray-200")
            
            # Privacy settings
            hstack do
              text("Privacy Mode")
                .font_weight("medium")
                .text_color("gray-900")
              
              spacer
              
              toggle("privacy", is_on: false)
            end
            .padding_y(12)
            .padding_x(16)
            
            # Thicker divider for section separation
            divider.tw("border-gray-300 border-t-2")
            
            # Account settings
            hstack do
              text("Account Settings")
                .font_weight("medium")
                .text_color("gray-900")
              
              spacer
              
              text("→")
                .text_color("gray-400")
            end
            .padding_y(12)
            .padding_x(16)
            .tw("hover:bg-gray-50 transition-colors cursor-pointer")
          end
          .background("white")
          .corner_radius("lg")
          .tw("shadow-sm border border-gray-200")
          .margin_top(16)
        end
        .max_width("lg")
      end
    end
  end
  
  def decorative_dividers
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 32) do
          text("Decorative Dividers Example")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Simple colored dividers
          vstack(spacing: 24) do
            text("Colored Dividers")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 16) do
              text("Blue accent divider")
                .text_color("gray-600")
              
              divider.tw("border-blue-300 border-t-2")
              
              text("Content after blue divider")
                .text_color("gray-600")
              
              divider.tw("border-green-300 border-t-2")
              
              text("Content after green divider")
                .text_color("gray-600")
              
              divider.tw("border-purple-300 border-t-2")
              
              text("Content after purple divider")
                .text_color("gray-600")
            end
          end
          
          # Styled dividers
          vstack(spacing: 24) do
            text("Styled Dividers")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 16) do
              text("Dashed divider style")
                .text_color("gray-600")
              
              divider.tw("border-gray-400 border-dashed border-t-2")
              
              text("Content between dashed dividers")
                .text_color("gray-600")
              
              divider.tw("border-red-300 border-dotted border-t-4")
              
              text("Content after dotted divider")
                .text_color("gray-600")
            end
          end
          
          # Thick decorative dividers
          vstack(spacing: 24) do
            text("Thick Decorative Dividers")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 20) do
              text("Medium thickness (4px)")
                .text_color("gray-600")
              
              divider.tw("border-blue-400 border-t-4")
              
              text("Heavy emphasis (8px)")
                .text_color("gray-600")
              
              divider.tw("border-purple-400 border-t-8")
              
              text("Content after heavy divider")
                .text_color("gray-600")
            end
          end
          
          # Partial width dividers
          vstack(spacing: 24) do
            text("Partial Width Dividers")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            vstack(spacing: 16, alignment: :center) do
              text("Centered half-width divider")
                .text_color("gray-600")
              
              divider.tw("border-gray-400 border-t-2 w-1/2 mx-auto")
              
              text("One-third width divider")
                .text_color("gray-600")
              
              divider.tw("border-green-400 border-t-2 w-1/3 mx-auto")
              
              text("Two-thirds width divider")
                .text_color("gray-600")
              
              divider.tw("border-blue-400 border-t-2 w-2/3 mx-auto")
            end
          end
          
          # Vertical dividers in horizontal layout
          vstack(spacing: 24) do
            text("Vertical Dividers")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 16, alignment: :start) do
              vstack(spacing: 8, alignment: :start) do
                text("First Column")
                  .font_weight("medium")
                  .text_color("gray-900")
                
                text("Content in the first column with some descriptive text.")
                  .font_size("sm")
                  .text_color("gray-600")
              end
              
              # Vertical divider
              div.tw("border-l border-gray-300 h-16")
              
              vstack(spacing: 8, alignment: :start) do
                text("Second Column")
                  .font_weight("medium")
                  .text_color("gray-900")
                
                text("Content in the second column, separated by a vertical divider.")
                  .font_size("sm")
                  .text_color("gray-600")
              end
              
              # Thicker vertical divider
              div.tw("border-l-2 border-blue-300 h-16")
              
              vstack(spacing: 8, alignment: :start) do
                text("Third Column")
                  .font_weight("medium")
                  .text_color("gray-900")
                
                text("Final column with a thicker, colored vertical divider.")
                  .font_size("sm")
                  .text_color("gray-600")
              end
            end
            .padding(20)
            .background("gray-50")
            .corner_radius("lg")
          end
        end
        .max_width("2xl")
      end
    end
  end
end