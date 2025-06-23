# frozen_string_literal: true

class ButtonComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :title, as: :text, default: "Click Me"
  control :variant, as: :select, options: [:primary, :secondary, :success, :danger, :outline], default: :primary
  control :size, as: :select, options: [:xs, :sm, :md, :lg, :xl], default: :md
  control :disabled, as: :boolean, default: false
  control :full_width, as: :boolean, default: false
  control :corner_radius, as: :select, options: ["sm", "md", "lg", "xl", "full"], default: "md"
  control :custom_background, as: :select, options: ["", "purple-600", "pink-500", "indigo-600", "gray-800"], default: ""
  control :custom_text_color, as: :select, options: ["", "white", "gray-900", "blue-600"], default: ""
  
  def default(
    title: "Click Me",
    variant: :primary,
    size: :md,
    disabled: false,
    full_width: false,
    corner_radius: "md",
    custom_background: "",
    custom_text_color: ""
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        btn = button(title)
          .button_style(variant)
          .button_size(size)
        
        btn = btn.disabled if disabled
        btn = btn.w_full if full_width
        btn = btn.corner_radius(corner_radius) if corner_radius != "md"
        btn = btn.background(custom_background) if custom_background.present?
        btn = btn.text_color(custom_text_color) if custom_text_color.present?
        
        btn
      end
    end
  end
  
  def button_variants
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Button Style Variants")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Primary buttons
          vstack(spacing: 8, alignment: :start) do
            text("Primary Buttons")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 8) do
              button("Primary")
                .button_style(:primary)
                .button_size(:sm)
              
              button("Secondary")
                .button_style(:secondary)
                .button_size(:sm)
              
              button("Success")
                .button_style(:success)
                .button_size(:sm)
              
              button("Danger")
                .button_style(:danger)
                .button_size(:sm)
              
              button("Outline")
                .button_style(:outline)
                .button_size(:sm)
            end
          end
          
          # Size variations
          vstack(spacing: 8, alignment: :start) do
            text("Size Variations")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 8, alignment: :center) do
              button("XS")
                .button_style(:primary)
                .button_size(:xs)
              
              button("Small")
                .button_style(:primary)
                .button_size(:sm)
              
              button("Medium")
                .button_style(:primary)
                .button_size(:md)
              
              button("Large")
                .button_style(:primary)
                .button_size(:lg)
              
              button("XL")
                .button_style(:primary)
                .button_size(:xl)
            end
          end
          
          # States
          vstack(spacing: 8, alignment: :start) do
            text("Button States")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 8) do
              button("Normal")
                .button_style(:primary)
                .button_size(:sm)
              
              button("Disabled")
                .button_style(:primary)
                .button_size(:sm)
                .disabled
              
              button("Loading")
                .button_style(:primary)
                .button_size(:sm)
                .loading
            end
          end
        end
      end
    end
  end
  
  def button_with_icons
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Buttons with Icons")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Icon buttons
          hstack(spacing: 12) do
            # Left icon
            button do
              hstack(spacing: 6) do
                icon("plus", size: 16)
                text("Add Item")
              end
            end
            .button_style(:primary)
            .button_size(:sm)
            
            # Right icon
            button do
              hstack(spacing: 6) do
                text("Download")
                icon("download", size: 16)
              end
            end
            .button_style(:secondary)
            .button_size(:sm)
            
            # Icon only
            button do
              icon("settings", size: 16)
            end
            .button_style(:outline)
            .button_size(:sm)
            .corner_radius("full")
          end
          
          # Social buttons
          hstack(spacing: 8) do
            button do
              hstack(spacing: 8) do
                icon("github", size: 18)
                text("GitHub")
              end
            end
            .button_style(:secondary)
            .background("gray-900")
            .text_color("white")
            
            button do
              hstack(spacing: 8) do
                icon("twitter", size: 18)
                text("Twitter")
              end
            end
            .button_style(:secondary)
            .background("blue-500")
            .text_color("white")
          end
        end
      end
    end
  end
  
  def action_buttons
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("Real-world Button Examples")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # CTA section
          vstack(spacing: 12) do
            text("Call to Action")
              .font_weight("semibold")
              .text_color("gray-900")
            
            button("Get Started Free")
              .button_style(:primary)
              .button_size(:lg)
              .w_full
              .corner_radius("lg")
            
            button("View Pricing")
              .button_style(:outline)
              .button_size(:md)
              .w_full
          end
          .background("white")
          .padding(20)
          .corner_radius("xl")
          .shadow("sm")
          
          # Form actions
          vstack(spacing: 12) do
            text("Form Actions")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 8) do
              button("Cancel")
                .button_style(:secondary)
                .button_size(:md)
              
              spacer
              
              button("Save Draft")
                .button_style(:outline)
                .button_size(:md)
              
              button("Publish")
                .button_style(:success)
                .button_size(:md)
            end
          end
          .background("gray-50")
          .padding(16)
          .corner_radius("lg")
          
          # Destructive actions
          vstack(spacing: 8) do
            text("Destructive Actions")
              .font_weight("semibold")
              .text_color("gray-900")
            
            hstack(spacing: 8) do
              button("Delete Account")
                .button_style(:danger)
                .button_size(:sm)
              
              button("Remove Item")
                .button_style(:outline)
                .text_color("red-600")
                .border_color("red-300")
                .button_size(:sm)
            end
          end
          .background("red-50")
          .padding(16)
          .corner_radius("lg")
        end
        .max_width("md")
      end
    end
  end
end