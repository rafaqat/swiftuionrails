# frozen_string_literal: true

class LinkComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :text, as: :text, default: "Learn More"
  control :destination, as: :text, default: "#"
  control :target, as: :select, options: ["", "_blank", "_self"], default: ""
  control :text_color, as: :select, options: ["blue-600", "purple-600", "green-600", "gray-900"], default: "blue-600"
  control :hover_color, as: :select, options: ["blue-800", "purple-800", "green-800", "gray-700"], default: "blue-800"
  control :underline, as: :select, options: ["none", "hover", "always"], default: "hover"
  control :font_weight, as: :select, options: ["normal", "medium", "semibold", "bold"], default: "normal"
  control :font_size, as: :select, options: ["sm", "base", "lg", "xl"], default: "base"
  
  def default(
    text: "Learn More",
    destination: "#",
    target: "",
    text_color: "blue-600",
    hover_color: "blue-800",
    underline: "hover",
    font_weight: "normal",
    font_size: "base"
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        link_element = link(text, destination: destination)
        
        link_element = link_element.tw("target-#{target}") if target.present?
        link_element = link_element.text_color(text_color)
        link_element = link_element.tw("hover:text-#{hover_color}")
        
        case underline
        when "none"
          link_element = link_element.tw("no-underline")
        when "hover"
          link_element = link_element.tw("no-underline hover:underline")
        when "always"
          link_element = link_element.underline
        end
        
        link_element = link_element.font_weight(font_weight) if font_weight != "normal"
        link_element = link_element.font_size(font_size) if font_size != "base"
        
        # Add target attribute if specified
        if target.present?
          link_element.options[:target] = target
        end
        
        link_element
      end
    end
  end
  
  def link_styles
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 16, alignment: :start) do
          text("Link Style Variants")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Color variations
          vstack(spacing: 8, alignment: :start) do
            text("Color Variations")
              .font_weight("semibold")
              .text_color("gray-900")
              .margin_bottom(4)
            
            hstack(spacing: 16) do
              link("Primary Link", destination: "#")
                .text_color("blue-600")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Purple Link", destination: "#")
                .text_color("purple-600")
                .tw("hover:text-purple-800 hover:underline")
              
              link("Green Link", destination: "#")
                .text_color("green-600")
                .tw("hover:text-green-800 hover:underline")
              
              link("Gray Link", destination: "#")
                .text_color("gray-900")
                .tw("hover:text-gray-700 hover:underline")
            end
          end
          
          # Underline styles
          vstack(spacing: 8, alignment: :start) do
            text("Underline Styles")
              .font_weight("semibold")
              .text_color("gray-900")
              .margin_bottom(4)
            
            vstack(spacing: 4, alignment: :start) do
              link("No underline", destination: "#")
                .text_color("blue-600")
                .tw("no-underline hover:text-blue-800")
              
              link("Hover underline", destination: "#")
                .text_color("blue-600")
                .tw("no-underline hover:underline hover:text-blue-800")
              
              link("Always underlined", destination: "#")
                .text_color("blue-600")
                .underline
                .tw("hover:text-blue-800")
            end
          end
          
          # Font weights
          vstack(spacing: 8, alignment: :start) do
            text("Font Weight Variations")
              .font_weight("semibold")
              .text_color("gray-900")
              .margin_bottom(4)
            
            vstack(spacing: 4, alignment: :start) do
              link("Normal weight link", destination: "#")
                .text_color("blue-600")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Medium weight link", destination: "#")
                .text_color("blue-600")
                .font_weight("medium")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Semibold link", destination: "#")
                .text_color("blue-600")
                .font_weight("semibold")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Bold link", destination: "#")
                .text_color("blue-600")
                .font_weight("bold")
                .tw("hover:text-blue-800 hover:underline")
            end
          end
          
          # Font sizes
          vstack(spacing: 8, alignment: :start) do
            text("Font Size Variations")
              .font_weight("semibold")
              .text_color("gray-900")
              .margin_bottom(4)
            
            vstack(spacing: 4, alignment: :start) do
              link("Small link", destination: "#")
                .text_color("blue-600")
                .font_size("sm")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Base size link", destination: "#")
                .text_color("blue-600")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Large link", destination: "#")
                .text_color("blue-600")
                .font_size("lg")
                .tw("hover:text-blue-800 hover:underline")
              
              link("Extra large link", destination: "#")
                .text_color("blue-600")
                .font_size("xl")
                .tw("hover:text-blue-800 hover:underline")
            end
          end
        end
      end
    end
  end
  
  def navigation_links
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("Navigation Link Examples")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Header navigation
          card do
            vstack(spacing: 12) do
              text("Header Navigation")
                .font_weight("semibold")
                .text_color("gray-900")
              
              hstack(spacing: 24) do
                link("Home", destination: "/")
                  .text_color("gray-700")
                  .font_weight("medium")
                  .tw("hover:text-gray-900 no-underline")
                
                link("Products", destination: "/products")
                  .text_color("gray-700")
                  .font_weight("medium")
                  .tw("hover:text-gray-900 no-underline")
                
                link("About", destination: "/about")
                  .text_color("gray-700")
                  .font_weight("medium")
                  .tw("hover:text-gray-900 no-underline")
                
                link("Contact", destination: "/contact")
                  .text_color("gray-700")
                  .font_weight("medium")
                  .tw("hover:text-gray-900 no-underline")
              end
            end
          end
          .padding(16)
          
          # Breadcrumb navigation
          card do
            vstack(spacing: 12) do
              text("Breadcrumb Navigation")
                .font_weight("semibold")
                .text_color("gray-900")
              
              hstack(spacing: 8) do
                link("Home", destination: "/")
                  .text_color("blue-600")
                  .font_size("sm")
                  .tw("hover:text-blue-800 hover:underline")
                
                text("/")
                  .text_color("gray-400")
                  .font_size("sm")
                
                link("Products", destination: "/products")
                  .text_color("blue-600")
                  .font_size("sm")
                  .tw("hover:text-blue-800 hover:underline")
                
                text("/")
                  .text_color("gray-400")
                  .font_size("sm")
                
                text("Laptop")
                  .text_color("gray-600")
                  .font_size("sm")
              end
            end
          end
          .padding(16)
          
          # Footer links
          card do
            vstack(spacing: 12) do
              text("Footer Links")
                .font_weight("semibold")
                .text_color("gray-900")
              
              hstack(spacing: 32) do
                vstack(spacing: 6, alignment: :start) do
                  text("Company")
                    .font_weight("semibold")
                    .font_size("sm")
                    .text_color("gray-900")
                  
                  link("About Us", destination: "/about")
                    .text_color("gray-600")
                    .font_size("sm")
                    .tw("hover:text-gray-900 no-underline")
                  
                  link("Careers", destination: "/careers")
                    .text_color("gray-600")
                    .font_size("sm")
                    .tw("hover:text-gray-900 no-underline")
                  
                  link("Press", destination: "/press")
                    .text_color("gray-600")
                    .font_size("sm")
                    .tw("hover:text-gray-900 no-underline")
                end
                
                vstack(spacing: 6, alignment: :start) do
                  text("Support")
                    .font_weight("semibold")
                    .font_size("sm")
                    .text_color("gray-900")
                  
                  link("Help Center", destination: "/help")
                    .text_color("gray-600")
                    .font_size("sm")
                    .tw("hover:text-gray-900 no-underline")
                  
                  link("Contact Us", destination: "/contact")
                    .text_color("gray-600")
                    .font_size("sm")
                    .tw("hover:text-gray-900 no-underline")
                  
                  link("Privacy Policy", destination: "/privacy")
                    .text_color("gray-600")
                    .font_size("sm")
                    .tw("hover:text-gray-900 no-underline")
                end
              end
            end
          end
          .padding(16)
          .background("gray-50")
        end
        .max_width("2xl")
      end
    end
  end
  
  def content_links
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 20) do
          text("Content Link Examples")
            .font_size("xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Inline text links
          card do
            vstack(spacing: 12, alignment: :start) do
              text("Inline Text Links")
                .font_weight("semibold")
                .text_color("gray-900")
              
              text do
                concat("This is a paragraph of text with an ")
                concat(link("inline link", destination: "#").text_color("blue-600").tw("hover:text-blue-800 hover:underline").to_s)
                concat(" that demonstrates how links work within content. You can also have ")
                concat(link("multiple links", destination: "#").text_color("blue-600").tw("hover:text-blue-800 hover:underline").to_s)
                concat(" in the same paragraph.")
              end
              .text_color("gray-700")
              .tw("leading-relaxed")
            end
          end
          .padding(20)
          
          # External links
          card do
            vstack(spacing: 12, alignment: :start) do
              text("External Links")
                .font_weight("semibold")
                .text_color("gray-900")
              
              vstack(spacing: 8, alignment: :start) do
                hstack(spacing: 8) do
                  link("Visit our GitHub", destination: "https://github.com")
                    .text_color("blue-600")
                    .tw("hover:text-blue-800 hover:underline")
                    .tap { |l| l.options[:target] = "_blank" }
                  
                  text("↗")
                    .text_color("gray-400")
                    .font_size("sm")
                end
                
                hstack(spacing: 8) do
                  link("Read the documentation", destination: "https://docs.example.com")
                    .text_color("blue-600")
                    .tw("hover:text-blue-800 hover:underline")
                    .tap { |l| l.options[:target] = "_blank" }
                  
                  text("↗")
                    .text_color("gray-400")
                    .font_size("sm")
                end
                
                hstack(spacing: 8) do
                  link("Join our community", destination: "https://discord.gg/example")
                    .text_color("blue-600")
                    .tw("hover:text-blue-800 hover:underline")
                    .tap { |l| l.options[:target] = "_blank" }
                  
                  text("↗")
                    .text_color("gray-400")
                    .font_size("sm")
                end
              end
            end
          end
          .padding(20)
          
          # Call-to-action links
          card do
            vstack(spacing: 12) do
              text("Call-to-Action Links")
                .font_weight("semibold")
                .text_color("gray-900")
              
              vstack(spacing: 16) do
                # Primary CTA
                link("Get Started Free")
                  .text_color("blue-600")
                  .font_weight("semibold")
                  .font_size("lg")
                  .tw("hover:text-blue-800 no-underline hover:underline")
                  .padding(12)
                  .tw("border border-blue-200 rounded-lg hover:border-blue-300 transition-colors")
                
                # Secondary CTA
                hstack(spacing: 12) do
                  link("Learn More", destination: "#")
                    .text_color("gray-700")
                    .font_weight("medium")
                    .tw("hover:text-gray-900 hover:underline")
                  
                  text("or")
                    .text_color("gray-500")
                  
                  link("Watch Demo", destination: "#")
                    .text_color("purple-600")
                    .font_weight("medium")
                    .tw("hover:text-purple-800 hover:underline")
                end
                
                # Download links
                hstack(spacing: 16) do
                  link("Download for macOS", destination: "#")
                    .text_color("green-600")
                    .font_weight("medium")
                    .tw("hover:text-green-800 no-underline")
                    .padding(8)
                    .tw("bg-green-50 rounded-md hover:bg-green-100 transition-colors")
                  
                  link("Download for Windows", destination: "#")
                    .text_color("blue-600")
                    .font_weight("medium")
                    .tw("hover:text-blue-800 no-underline")
                    .padding(8)
                    .tw("bg-blue-50 rounded-md hover:bg-blue-100 transition-colors")
                end
              end
            end
          end
          .padding(20)
          .tw("text-center")
        end
        .max_width("2xl")
      end
    end
  end
end