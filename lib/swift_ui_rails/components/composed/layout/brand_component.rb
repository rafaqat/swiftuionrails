# frozen_string_literal: true

module SwiftUIRails
  module Component
    module Composed
      module Layout
        # BrandComponent - Toolbar brand section with logo and text
        class BrandComponent < SwiftUIRails::Component::Base
          
          # Props
          prop :brand_text, type: String, required: true
          prop :brand_logo, type: String, default: nil
          prop :brand_url, type: String, default: "/"
          
          swift_ui do
            brand_section
          end
          
          private
          
          def brand_section
            link(destination: brand_url) do
              hstack(spacing: 3) do
                if has_brand_logo
                  image(src: brand_logo, alt: brand_text)
                    .h(8).w(8).object_contain
                end
                
                text(brand_text)
                  .font_size("xl")
                  .font_weight("bold")
                  .text_color("gray-900")
                  .tap { |text| text.block if has_brand_logo }
              end
            end
            .flex.items_center
          end
          
          def has_brand_logo
            brand_logo.present?
          end
        end
      end
    end
  end
end