# frozen_string_literal: true

class TextComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :content, as: :text, default: "Sample Text"
  control :font_size, as: :select, options: ["xs", "sm", "base", "lg", "xl", "2xl", "3xl", "4xl"], default: "base"
  control :font_weight, as: :select, options: ["light", "normal", "medium", "semibold", "bold"], default: "normal"
  control :text_color, as: :select, options: ["", "gray-900", "gray-600", "gray-500", "blue-600", "green-600", "red-600"], default: ""
  control :text_align, as: :select, options: ["", "left", "center", "right"], default: ""
  control :line_clamp, as: :select, options: ["", "1", "2", "3", "4"], default: ""
  control :italic, as: :boolean, default: false
  control :underline, as: :boolean, default: false
  
  def default(
    content: "Sample Text",
    font_size: "base",
    font_weight: "normal",
    text_color: "",
    text_align: "",
    line_clamp: "",
    italic: false,
    underline: false
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        text_element = text(content)
        
        text_element = text_element.font_size(font_size) if font_size != "base"
        text_element = text_element.font_weight(font_weight) if font_weight != "normal"
        text_element = text_element.text_color(text_color) if text_color.present?
        text_element = text_element.text_align(text_align) if text_align.present?
        text_element = text_element.line_clamp(line_clamp) if line_clamp.present?
        text_element = text_element.italic if italic
        text_element = text_element.underline if underline
        
        text_element
      end
    end
  end
  
  def typography_scale
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16, alignment: :start) do
          text("Typography Scale Demo")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          text("Extra Small (xs) - Caption text")
            .font_size("xs")
            .text_color("gray-600")
          
          text("Small (sm) - Small body text")
            .font_size("sm")
            .text_color("gray-700")
          
          text("Base - Regular body text")
            .font_size("base")
            .text_color("gray-900")
          
          text("Large (lg) - Larger body text")
            .font_size("lg")
            .font_weight("medium")
          
          text("Extra Large (xl) - Subheading")
            .font_size("xl")
            .font_weight("semibold")
          
          text("2xl - Section title")
            .font_size("2xl")
            .font_weight("bold")
          
          text("3xl - Page heading")
            .font_size("3xl")
            .font_weight("bold")
          
          text("4xl - Hero heading")
            .font_size("4xl")
            .font_weight("bold")
        end
      end
    end
  end
  
  def text_styles
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 12, alignment: :start) do
          text("Text Style Examples")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Weight variations
          hstack(spacing: 16) do
            vstack(spacing: 4, alignment: :start) do
              text("Light weight")
                .font_weight("light")
              
              text("Normal weight")
                .font_weight("normal")
              
              text("Medium weight")
                .font_weight("medium")
              
              text("Semibold weight")
                .font_weight("semibold")
              
              text("Bold weight")
                .font_weight("bold")
            end
            
            # Color variations
            vstack(spacing: 4, alignment: :start) do
              text("Primary text")
                .text_color("gray-900")
              
              text("Secondary text")
                .text_color("gray-600")
              
              text("Muted text")
                .text_color("gray-500")
              
              text("Success text")
                .text_color("green-600")
              
              text("Error text")
                .text_color("red-600")
              
              text("Link text")
                .text_color("blue-600")
            end
          end
          
          # Style modifiers
          text("Italic text example")
            .italic
            .text_color("gray-700")
          
          text("Underlined text example")
            .underline
            .text_color("blue-600")
          
          text("Combined: bold, italic, colored")
            .font_weight("bold")
            .italic
            .text_color("purple-600")
        end
      end
    end
  end
  
  def text_alignment
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16) do
          text("Text Alignment Examples")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Left aligned (default)
          text("Left aligned text - This is the default alignment for text. It starts from the left and flows naturally.")
            .text_align("left")
            .background("gray-50")
            .padding(12)
            .corner_radius("md")
          
          # Center aligned
          text("Center aligned text - This text is centered within its container and creates a balanced appearance.")
            .text_align("center")
            .background("blue-50")
            .padding(12)
            .corner_radius("md")
          
          # Right aligned
          text("Right aligned text - This text is aligned to the right edge, useful for numbers or secondary information.")
            .text_align("right")
            .background("green-50")
            .padding(12)
            .corner_radius("md")
        end
        .max_width("lg")
      end
    end
  end
  
  def truncated_text
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16, alignment: :start) do
          text("Text Truncation Examples")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          text("Single line truncation - This is a very long text that will be truncated to a single line when it exceeds the container width. The rest will be hidden with an ellipsis.")
            .line_clamp("1")
            .background("gray-50")
            .padding(12)
            .corner_radius("md")
          
          text("Two line truncation - This longer text demonstrates how content can be limited to exactly two lines before being cut off with an ellipsis. This is useful for card layouts and previews where you want consistent height.")
            .line_clamp("2")
            .background("blue-50")
            .padding(12)
            .corner_radius("md")
          
          text("Three line truncation - Even longer content can be constrained to three lines, which provides more context while still maintaining layout consistency. This is particularly useful for article previews, product descriptions, and user-generated content where you want to show enough information to be useful but not overwhelm the interface.")
            .line_clamp("3")
            .background("green-50")
            .padding(12)
            .corner_radius("md")
        end
        .max_width("md")
      end
    end
  end
end