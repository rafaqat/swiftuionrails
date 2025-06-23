# frozen_string_literal: true

class VstackComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :spacing, as: :select, options: [0, 2, 4, 6, 8, 10, 12, 16, 20], default: 8
  control :alignment, as: :select, options: [:start, :center, :end], default: :center
  control :background_color, as: :select, options: ["", "gray-50", "blue-50", "green-50", "red-50"], default: ""
  control :padding, as: :select, options: ["", "4", "6", "8", "12", "16"], default: ""
  control :corner_radius, as: :select, options: ["", "sm", "md", "lg", "xl"], default: ""
  
  def default(
    spacing: 8,
    alignment: :center,
    background_color: "",
    padding: "",
    corner_radius: ""
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        stack = vstack(spacing: spacing, alignment: alignment) do
          text("First Item")
            .font_weight("semibold")
            .text_color("gray-900")
          
          text("Second Item")
            .font_size("sm")
            .text_color("gray-600")
          
          button("Action Button")
            .button_style(:primary)
            .button_size(:sm)
          
          text("Last Item")
            .font_size("xs")
            .text_color("gray-500")
        end
        
        stack = stack.background(background_color) if background_color.present?
        stack = stack.padding(padding) if padding.present?
        stack = stack.corner_radius(corner_radius) if corner_radius.present?
        
        stack
      end
    end
  end
  
  def with_nested_stacks
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Nested VStack Example")
            .font_size("xl")
            .font_weight("bold")
          
          hstack(spacing: 12) do
            vstack(spacing: 4) do
              text("Left Column")
                .font_weight("semibold")
              text("Content here")
                .font_size("sm")
            end
            .background("blue-50")
            .padding(8)
            .corner_radius("md")
            
            vstack(spacing: 4) do
              text("Right Column")
                .font_weight("semibold")
              text("More content")
                .font_size("sm")
            end
            .background("green-50")
            .padding(8)
            .corner_radius("md")
          end
        end
        .background("gray-50")
        .padding(16)
        .corner_radius("lg")
      end
    end
  end
  
  def real_world_example
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          # Header
          vstack(spacing: 4) do
            text("User Profile")
              .font_size("2xl")
              .font_weight("bold")
              .text_color("gray-900")
            
            text("Manage your account settings")
              .text_color("gray-600")
          end
          
          # Content sections
          vstack(spacing: 12) do
            # Profile section
            hstack(spacing: 12) do
              div(class: "w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center") do
                text("JD")
                  .font_weight("bold")
                  .text_color("white")
              end
              
              vstack(spacing: 2, alignment: :start) do
                text("John Doe")
                  .font_weight("semibold")
                
                text("john@example.com")
                  .font_size("sm")
                  .text_color("gray-600")
              end
            end
            .background("white")
            .padding(16)
            .corner_radius("lg")
            .shadow("sm")
            
            # Actions
            vstack(spacing: 8) do
              button("Edit Profile")
                .button_style(:primary)
                .w_full
              
              button("Change Password")
                .button_style(:secondary)
                .w_full
              
              button("Delete Account")
                .button_style(:danger)
                .w_full
            end
          end
        end
        .max_width("md")
        .background("gray-50")
        .padding(24)
        .corner_radius("xl")
      end
    end
  end
end