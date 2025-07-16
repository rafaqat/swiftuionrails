# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # E-commerce specific components for SwiftUI Rails DSL
    module Commerce
      # DSL Product Card - Reusable product card following DSL-first pattern
      def dsl_product_card(name:, price:, image_url: nil, variant: nil, currency: '$',
                           show_cta: true, cta_text: 'Add to Cart', cta_style: 'primary',
                           elevation: 2, **attrs)
        # Build product card using pure DSL chaining
        # Main container with group and relative for hover effects
        div(class: 'group relative') do
          card(elevation: elevation) do
            # Product image container
            if image_url
              div.aspect('square').overflow('hidden').rounded('md').bg('gray-200') do
                image(src: image_url, alt: "#{name}#{variant ? " in #{variant}" : ''}")
                  .w('full').h('full').object('cover')
                  .hover_scale(105).transition.duration(300)
              end
            end

            # Product details
            vstack(spacing: 2, alignment: :start) do
              # Product name
              text(name)
                .font_weight('semibold')
                .text_color('gray-900')
                .text_size('lg')
                .line_clamp(1)

              # Variant/color
              if variant
                text(variant)
                  .text_color('gray-600')
                  .text_size('sm')
              end

              # Price with flex layout for better alignment
              div(class: 'flex justify-between items-baseline') do
                text("#{currency}#{price}")
                  .font_weight('bold')
                  .text_color('gray-900')
                  .text_size('xl')
              end.mt(2)
            end.mt(4)

            # CTA Button
            if show_cta
              button_classes = case cta_style
                               when 'primary'
                                 'w-full mt-4 px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 transition-colors'
                               when 'outline'
                                 'w-full mt-4 px-4 py-2 border-2 border-gray-900 text-gray-900 rounded-md hover:bg-gray-900 hover:text-white transition-colors'
                               else # secondary
                                 'w-full mt-4 px-4 py-2 bg-gray-200 text-gray-900 rounded-md hover:bg-gray-300 transition-colors'
                               end

              button(cta_text, class: button_classes).font_weight('medium')
            end

            # Allow custom content via block
            yield if block_given?
          end
          .p(6)
          .bg('white')
          .hover_shadow('lg')
          .transition
        end
        .merge_attributes(attrs)
      end

      # Product list DSL method - renders ProductListComponent with DSL chaining
      def product_list(products:, **attrs)
        # Extract component props from attrs
        columns = attrs.delete(:columns)

        # Convert column symbols to integers for the component
        columns_int = case columns
                      when :one then 1
                      when :two then 2
                      when :three then 3
                      when :four then 4
                      when :five then 5
                      when :six then 6
                      else columns || 3
                      end

        # Build props hash
        component_props = {
          products: products,
          columns: columns_int,
          title: attrs.delete(:title),
          show_filters: attrs.delete(:show_filters),
          gap: attrs.delete(:gap),
          background_color: attrs.delete(:background_color),
          title_size: attrs.delete(:title_size),
          title_color: attrs.delete(:title_color),
          container_padding: attrs.delete(:container_padding),
          max_width: attrs.delete(:max_width),
          image_aspect: attrs.delete(:image_aspect),
          show_colors: attrs.delete(:show_colors),
          currency_symbol: attrs.delete(:currency_symbol)
        }.compact

        # Create a wrapper element that can be chained
        create_element(:div, nil, **attrs) do
          if defined?(::ProductListComponent)
            # Render the actual component if it exists
            render ::ProductListComponent.new(**component_props)
          else
            # Fallback: render a simple grid of products using DSL
            div do
              # Title
              if component_props[:title]
                h2 { text(component_props[:title]) }.mb(6)
              end

              # Product grid
              grid(columns: columns_int || 3, spacing: component_props[:gap] || 6) do
                products.each do |product|
                  dsl_product_card(
                    name: product[:name] || product['name'] || 'Product',
                    price: product[:price] || product['price'] || 0,
                    image_url: product[:image_url] || product['image_url'] || product[:image] || product['image'],
                    currency: component_props[:currency_symbol] || '$'
                  ) do
                    # Additional content from product
                    if product[:description]
                      text(product[:description]).text_sm.text_color('gray-600').mt(2)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end