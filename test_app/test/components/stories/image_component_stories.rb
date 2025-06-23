# frozen_string_literal: true

class ImageComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  control :src, as: :text, default: "https://picsum.photos/400/400"
  control :alt_text, as: :text, default: "Sample image"
  control :aspect_ratio, as: :select, options: ["square", "portrait", "landscape", "wide", "auto"], default: "square"
  control :object_fit, as: :select, options: ["cover", "contain", "fill", "scale-down"], default: "cover"
  control :corner_radius, as: :select, options: ["none", "sm", "md", "lg", "xl", "full"], default: "none"
  control :border, as: :boolean, default: false
  control :grayscale, as: :boolean, default: false
  control :blur, as: :boolean, default: false
  
  def default(
    src: "https://picsum.photos/400/400",
    alt_text: "Sample image",
    aspect_ratio: "square",
    object_fit: "cover",
    corner_radius: "none",
    border: false,
    grayscale: false,
    blur: false
  )
    content_tag(:div, class: "p-8") do
      swift_ui do
        img_element = image(src, alt: alt_text)
        
        img_element = img_element.aspect_ratio(aspect_ratio) if aspect_ratio != "auto"
        img_element = img_element.object_fit(object_fit) if object_fit != "cover"
        img_element = img_element.corner_radius(corner_radius) if corner_radius != "none"
        img_element = img_element.border if border
        img_element = img_element.grayscale if grayscale
        img_element = img_element.blur if blur
        
        img_element
      end
    end
  end
  
  def aspect_ratios
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Image Aspect Ratio Examples")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Square aspect ratio
          vstack(spacing: 12) do
            text("Square (1:1)")
              .font_weight("semibold")
              .text_color("gray-900")
            
            image(src: "https://picsum.photos/400/400", alt: "Square image")
              .aspect_ratio("square")
              .object_fit("cover")
              .corner_radius("md")
              .max_width("xs")
          end
          
          # Portrait aspect ratio
          vstack(spacing: 12) do
            text("Portrait (3:4)")
              .font_weight("semibold")
              .text_color("gray-900")
            
            image(src: "https://picsum.photos/300/400", alt: "Portrait image")
              .aspect_ratio("portrait")
              .object_fit("cover")
              .corner_radius("md")
              .max_width("xs")
          end
          
          # Landscape aspect ratio
          vstack(spacing: 12) do
            text("Landscape (4:3)")
              .font_weight("semibold")
              .text_color("gray-900")
            
            image(src: "https://picsum.photos/400/300", alt: "Landscape image")
              .aspect_ratio("landscape")
              .object_fit("cover")
              .corner_radius("md")
              .max_width("sm")
          end
          
          # Wide aspect ratio
          vstack(spacing: 12) do
            text("Wide (16:9)")
              .font_weight("semibold")
              .text_color("gray-900")
            
            image(src: "https://picsum.photos/800/450", alt: "Wide image")
              .aspect_ratio("wide")
              .object_fit("cover")
              .corner_radius("md")
              .max_width("lg")
          end
        end
        .max_width("2xl")
      end
    end
  end
  
  def image_effects
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Image Effects and Styling")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          # Grid of effect examples
          grid(columns: 2, gap: 20) do
            # Original image
            vstack(spacing: 8) do
              text("Original")
                .font_weight("semibold")
                .text_color("gray-900")
                .text_align("center")
              
              image(src: "https://picsum.photos/300/300", alt: "Original image")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("lg")
            end
            
            # Grayscale effect
            vstack(spacing: 8) do
              text("Grayscale")
                .font_weight("semibold")
                .text_color("gray-900")
                .text_align("center")
              
              image(src: "https://picsum.photos/300/300", alt: "Grayscale image")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("lg")
                .grayscale
            end
            
            # Blur effect
            vstack(spacing: 8) do
              text("Blur")
                .font_weight("semibold")
                .text_color("gray-900")
                .text_align("center")
              
              image(src: "https://picsum.photos/300/300", alt: "Blurred image")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("lg")
                .blur
            end
            
            # Combined effects
            vstack(spacing: 8) do
              text("Grayscale + Blur")
                .font_weight("semibold")
                .text_color("gray-900")
                .text_align("center")
              
              image(src: "https://picsum.photos/300/300", alt: "Combined effects image")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("lg")
                .grayscale
                .blur
            end
          end
          
          # Border and corner radius examples
          text("Border and Corner Variations")
            .font_size("xl")
            .font_weight("bold")
            .margin_top(16)
            .margin_bottom(8)
          
          hstack(spacing: 16) do
            # With border
            vstack(spacing: 8) do
              text("With Border")
                .font_size("sm")
                .font_weight("medium")
                .text_color("gray-700")
                .text_align("center")
              
              image(src: "https://picsum.photos/200/200", alt: "Image with border")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("md")
                .border
            end
            
            # Rounded corners
            vstack(spacing: 8) do
              text("Rounded")
                .font_size("sm")
                .font_weight("medium")
                .text_color("gray-700")
                .text_align("center")
              
              image(src: "https://picsum.photos/200/200", alt: "Rounded image")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("xl")
            end
            
            # Circle
            vstack(spacing: 8) do
              text("Circle")
                .font_size("sm")
                .font_weight("medium")
                .text_color("gray-700")
                .text_align("center")
              
              image(src: "https://picsum.photos/200/200", alt: "Circle image")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("full")
                .border
            end
          end
        end
        .max_width("4xl")
      end
    end
  end
  
  def responsive_gallery
    content_tag(:div, class: "p-8") do
      swift_ui do
        vstack(spacing: 24) do
          text("Responsive Image Gallery")
            .font_size("2xl")
            .font_weight("bold")
            .margin_bottom(8)
          
          text("This gallery demonstrates how images adapt to different grid layouts and sizes.")
            .text_color("gray-600")
            .margin_bottom(16)
          
          # Main featured image
          vstack(spacing: 12) do
            text("Featured Image")
              .font_size("lg")
              .font_weight("semibold")
              .text_color("gray-900")
            
            image(src: "https://picsum.photos/800/400", alt: "Featured gallery image")
              .aspect_ratio("wide")
              .object_fit("cover")
              .corner_radius("lg")
              .w_full
          end
          
          # Grid of thumbnails
          text("Thumbnail Grid")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
            .margin_top(8)
          
          grid(columns: 4, gap: 12) do
            # Generate thumbnail images
            (1..8).each do |i|
              image(src: "https://picsum.photos/200/200?random=#{i}", alt: "Gallery thumbnail #{i}")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("md")
                .hover_scale("105")
                .transition
                .cursor("pointer")
            end
          end
          
          # Different sized grid
          text("Mixed Size Gallery")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
            .margin_top(16)
          
          grid(columns: 3, gap: 16) do
            # Large image spanning 2 columns
            image(src: "https://picsum.photos/600/400?random=9", alt: "Large gallery image")
              .aspect_ratio("landscape")
              .object_fit("cover")
              .corner_radius("lg")
              .col_span(2)
            
            # Smaller images
            vstack(spacing: 16) do
              image(src: "https://picsum.photos/300/300?random=10", alt: "Small gallery image 1")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("md")
              
              image(src: "https://picsum.photos/300/300?random=11", alt: "Small gallery image 2")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("md")
            end
          end
          
          # Profile/avatar style images
          text("Profile & Avatar Styles")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
            .margin_top(16)
          
          hstack(spacing: 16, alignment: :center) do
            # Large avatar
            vstack(spacing: 8) do
              image(src: "https://picsum.photos/120/120?random=12", alt: "Large avatar")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("full")
                .border
                .width("120")
                .height("120")
              
              text("Large Avatar")
                .font_size("sm")
                .text_color("gray-600")
                .text_align("center")
            end
            
            # Medium avatar
            vstack(spacing: 8) do
              image(src: "https://picsum.photos/80/80?random=13", alt: "Medium avatar")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("full")
                .border
                .width("80")
                .height("80")
              
              text("Medium Avatar")
                .font_size("sm")
                .text_color("gray-600")
                .text_align("center")
            end
            
            # Small avatar
            vstack(spacing: 8) do
              image(src: "https://picsum.photos/60/60?random=14", alt: "Small avatar")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("full")
                .border
                .width("60")
                .height("60")
              
              text("Small Avatar")
                .font_size("sm")
                .text_color("gray-600")
                .text_align("center")
            end
            
            # Mini avatar
            vstack(spacing: 8) do
              image(src: "https://picsum.photos/40/40?random=15", alt: "Mini avatar")
                .aspect_ratio("square")
                .object_fit("cover")
                .corner_radius("full")
                .border
                .width("40")
                .height("40")
              
              text("Mini Avatar")
                .font_size("xs")
                .text_color("gray-600")
                .text_align("center")
            end
          end
          
          # Card with image examples
          text("Images in Cards")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
            .margin_top(16)
          
          grid(columns: 2, gap: 16) do
            # Image card 1
            card(elevation: 1) do
              vstack(spacing: 0) do
                image(src: "https://picsum.photos/400/200?random=16", alt: "Card image 1")
                  .aspect_ratio("wide")
                  .object_fit("cover")
                  .corner_radius("lg")
                  .margin_bottom(12)
                
                vstack(spacing: 8, alignment: :start) do
                  text("Beautiful Landscape")
                    .font_size("lg")
                    .font_weight("semibold")
                    .text_color("gray-900")
                  
                  text("Discover amazing natural landscapes from around the world.")
                    .font_size("sm")
                    .text_color("gray-600")
                    .line_clamp("2")
                  
                  button("View Details")
                    .button_style(:primary)
                    .button_size(:sm)
                    .margin_top(8)
                end
                .padding_x(16)
                .padding_bottom(16)
              end
            end
            .corner_radius("lg")
            
            # Image card 2
            card(elevation: 1) do
              hstack(spacing: 12) do
                image(src: "https://picsum.photos/150/150?random=17", alt: "Card image 2")
                  .aspect_ratio("square")
                  .object_fit("cover")
                  .corner_radius("md")
                  .flex_shrink(0)
                
                vstack(spacing: 8, alignment: :start) do
                  text("Urban Architecture")
                    .font_weight("semibold")
                    .text_color("gray-900")
                  
                  text("Modern buildings and city structures that define our urban spaces.")
                    .font_size("sm")
                    .text_color("gray-600")
                    .line_clamp("3")
                  
                  text("2 hours ago")
                    .font_size("xs")
                    .text_color("gray-500")
                end
                .flex(1)
              end
            end
            .padding(16)
            .corner_radius("lg")
          end
        end
        .max_width("6xl")
      end
    end
  end
end