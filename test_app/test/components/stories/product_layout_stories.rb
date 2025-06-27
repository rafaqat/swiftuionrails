# frozen_string_literal: true

class ProductLayoutStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  # Interactive controls
  control :product_name, as: :text, default: "Basic Tee"
  control :variant, as: :text, default: "Black"
  control :price, as: :number, default: 35, min: 0, max: 1000
  control :image_style, as: :select, options: ["square", "portrait", "landscape"], default: "square"
  control :show_hover, as: :boolean, default: true
  
  def default(product_name: "Basic Tee", variant: "Black", price: 35, image_style: "square", show_hover: true)
    # DSL-FIRST approach - using pure DSL with chained modifiers
    content_tag(:div, class: "p-8") do
      swift_ui do
        # Use DSL components with chained modifiers
        vstack(spacing: 8) do
          # Product Card using card DSL method
          card(class: "bg-gray-50 p-6") do
            # Image container using div with chained modifiers
            div(class: "aspect-square overflow-hidden rounded-md bg-gray-200") do
              # Image with chained modifiers
              img = image(
                src: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg",
                alt: "#{product_name} in #{variant}"
              )
              img.w_full.h_full.object("cover").hover("scale-105").transition.duration(300)
            end
            
            # Product Info using vstack
            vstack(spacing: 2, alignment: :start, class: "mt-4") do
              # Name
              text(product_name)
                .font_weight("semibold")
                .text_color("gray-900")
                .text_size("lg")
              
              # Variant
              text(variant)
                .text_color("gray-600")
                .text_size("sm")
              
              # Price
              text("$#{price}")
                .font_weight("bold")
                .text_color("gray-900")
                .text_size("xl")
                .mt(2)
            end
          end
        end
      end
    end
  end
  
  def with_sale_badge
    swift_ui do
      div.p(8).bg("gray-50") do
        div.max_w("sm").mx("auto") do
          # Product Card with Sale Badge
          div.group.relative do
            # Image Container
            div.relative do
              image(
                src: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-03.jpg",
                alt: "Basic Tee in Charcoal"
              ).aspect("square").w_full.rounded("md").bg("gray-200").object("cover").group_hover("opacity-75").lg("h-80")
              
              # Sale Badge
              div.absolute.top(2).left(2) do
                span.bg("red-500").text_color("white").px(2).py(1).rounded("md").text_size("xs").font_weight("semibold") do
                  text("Sale")
                end
              end
            end
            
            # Product Info with Original Price
            div.mt(4).flex.justify_between do
              div do
                h3.text_size("sm").text_color("gray-700") do
                  a(href: "#") do
                    span.absolute.inset(0).aria_hidden("true")
                    text("Basic Tee")
                  end
                end
                p.mt(1).text_size("sm").text_color("gray-500") do
                  text("Charcoal")
                end
              end
              div.text_right do
                p.text_size("sm").font_weight("medium").text_color("red-600") do
                  text("$25")
                end
                p.text_size("xs").text_color("gray-500").line_through do
                  text("$35")
                end
              end
            end
          end
        end
      end
    end
  end
  
  def grid_of_four
    swift_ui do
      div.p(8).bg("white") do
        div.max_w("7xl").mx("auto") do
          # Product Grid
          div.grid.grid_cols(2).gap(6).lg("grid-cols-4 gap-x-8") do
            # Product 1
            div.group.relative do
              image(
                src: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-01.jpg",
                alt: "Basic Tee in Black"
              ).aspect("square").w_full.rounded("md").bg("gray-200").object("cover").group_hover("opacity-75")
              
              div.mt(4).flex.justify_between do
                div do
                  h3.text_size("sm").text_color("gray-700") do
                    a(href: "#") do
                      span.absolute.inset(0).aria_hidden("true")
                      text("Basic Tee")
                    end
                  end
                  p.mt(1).text_size("sm").text_color("gray-500") do
                    text("Black")
                  end
                end
                p.text_size("sm").font_weight("medium").text_color("gray-900") do
                  text("$35")
                end
              end
            end
            
            # Product 2
            div.group.relative do
              image(
                src: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-02.jpg",
                alt: "Basic Tee in Aspen White",
                class: "aspect-square w-full rounded-md bg-gray-200 object-cover group-hover:opacity-75"
              )
              div.mt(4).flex.justify_between do
                div do
                  h3.text_size("sm").text_color("gray-700") do
                    a(href: "#") do
                      span.absolute.inset(0).data("aria-hidden": "true")
                      text("Basic Tee")
                    end
                  end
                  p.mt(1).text_size("sm").text_color("gray-500") do
                    text("Aspen White")
                  end
                end
                p.text_size("sm").font_weight("medium").text_color("gray-900") do
                  text("$35")
                end
              end
            end
            
            # Product 3
            div.group.relative do
              image(
                src: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-03.jpg",
                alt: "Basic Tee in Charcoal",
                class: "aspect-square w-full rounded-md bg-gray-200 object-cover group-hover:opacity-75"
              )
              div.mt(4).flex.justify_between do
                div do
                  h3.text_size("sm").text_color("gray-700") do
                    a(href: "#") do
                      span.absolute.inset(0).data("aria-hidden": "true")
                      text("Basic Tee")
                    end
                  end
                  p.mt(1).text_size("sm").text_color("gray-500") do
                    text("Charcoal")
                  end
                end
                p.text_size("sm").font_weight("medium").text_color("gray-900") do
                  text("$35")
                end
              end
            end
            
            # Product 4
            div.group.relative do
              image(
                src: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg",
                alt: "Artwork Tee in Iso Dots",
                class: "aspect-square w-full rounded-md bg-gray-200 object-cover group-hover:opacity-75"
              )
              div.mt(4).flex.justify_between do
                div do
                  h3.text_size("sm").text_color("gray-700") do
                    a(href: "#") do
                      span.absolute.inset(0).data("aria-hidden": "true")
                      text("Artwork Tee")
                    end
                  end
                  p.mt(1).text_size("sm").text_color("gray-500") do
                    text("Iso Dots")
                  end
                end
                p.text_size("sm").font_weight("medium").text_color("gray-900") do
                  text("$35")
                end
              end
            end
          end
        end
      end
    end
  end
end