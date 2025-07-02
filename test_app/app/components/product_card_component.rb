# frozen_string_literal: true

class ProductCardComponent < ApplicationComponent
  # Product data
  prop :product, type: Hash, required: true
  prop :index, type: Integer, default: 0
  
  # Display options
  prop :card_style, type: Symbol, default: :standard
  prop :show_variants, type: [TrueClass, FalseClass], default: true
  prop :show_quick_actions, type: [TrueClass, FalseClass], default: true
  prop :image_aspect_ratio, type: String, default: "square"
  
  # Action handlers
  prop :on_click, type: Proc, default: nil
  prop :on_add_to_cart, type: Proc, default: nil
  prop :on_variant_select, type: Proc, default: nil
  prop :on_quick_view, type: Proc, default: nil
  
  swift_ui do
    create_element(:div, nil, {class: "group relative"}) do
      # Product Image with overlay actions
      create_element(:div, nil, {class: "relative"}) do
        # Main product image
        if product[:image_url].present?
          image(product[:image_url])
            .tw("aspect-#{image_aspect_ratio} w-full rounded-md bg-gray-200 object-cover group-hover:opacity-75")
            .tw(image_aspect_ratio == "auto" ? "lg:aspect-auto lg:h-80" : "")
            .attr("alt", product[:name])
        else
          # Placeholder
          create_element(:div, nil, {
            class: "aspect-#{image_aspect_ratio} w-full rounded-md bg-gray-200 flex items-center justify-center #{image_aspect_ratio == "auto" ? "lg:aspect-auto lg:h-80" : ""}"
          }) do
            text("No Image")
              .text_color("gray-400")
              .text_size("sm")
          end
        end
        
        # Quick actions overlay
        if show_quick_actions
          create_element(:div, nil, {
            class: "absolute inset-0 flex items-center justify-center bg-black bg-opacity-0 group-hover:bg-opacity-30 transition duration-300"
          }) do
            
            hstack(spacing: 2)
              .tw("opacity-0")
              .tw("group-hover:opacity-100")
              .transition
              .tw("duration-300") do
              
              # Quick view button
              if on_quick_view
                button
                  .bg("white")
                  .p(2)
                  .rounded("full")
                  .shadow("lg")
                  .data(action: "click->product-card#quickView")
                  .data("product-data": product.to_json) do
                  # Eye icon SVG
                  create_element(:div, nil, {class: "w-5 h-5"}) do
                    text("👁").text_size("sm")
                  end
                end
              end
              
              # Add to cart button
              if on_add_to_cart && product[:in_stock] != false
                button
                  .bg("white")
                  .p(2)
                  .rounded("full")
                  .shadow("lg")
                  .data(action: "click->product-card#addToCart")
                  .data("product-data": product.to_json) do
                  # Cart icon
                  create_element(:div, nil, {class: "w-5 h-5"}) do
                    text("🛒").text_size("sm")
                  end
                end
              end
            end
          end
        end
        
        # Out of stock badge
        if product[:in_stock] == false
          create_element(:div, nil, {
            class: "absolute top-2 right-2 bg-red-600 text-white px-3 py-1 rounded-full text-xs font-semibold"
          }) do
            text("Out of Stock")
          end
        end
        
        # Sale badge
        if product[:on_sale]
          create_element(:div, nil, {
            class: "absolute top-2 left-2 bg-green-600 text-white px-3 py-1 rounded-full text-xs font-semibold"
          }) do
            text("Sale")
          end
        end
      end
      
      # Product details
      create_element(:div, nil, {class: "mt-4"}) do
        # Clickable area
        if on_click
          a
            .cursor("pointer")
            .data(action: "click->product-card#productClick")
            .data("product-data": product.to_json) do
            span
              .absolute
              .inset(0)
              .attr("aria-hidden", "true")
          end
        end
        
        hstack.justify_between.items_start do
          # Product info
          vstack(alignment: :leading, spacing: 1).tw("flex-1") do
            # Product name
            text(product[:name])
              .text_size("sm")
              .text_color("gray-700")
              .font_weight("medium")
              .line_clamp(2)
            
            # Product variant/description
            if product[:variant_label].present?
              text(product[:variant_label])
                .text_size("sm")
                .text_color("gray-500")
            end
            
            # Variants selector
            if show_variants && product[:variants].present?
              text(render(ProductVariantsComponent.new(
                variants: product[:variants],
                selected_variant: selected_variant,
                on_select: ->(variant) { 
                  self.selected_variant = variant
                  on_variant_select&.call(product, variant)
                }
              )).to_s.html_safe)
            end
          end
          
          # Price
          text(render(ProductPriceComponent.new(
            price: product[:price],
            original_price: product[:original_price],
            currency: product[:currency] || "$"
          )).to_s.html_safe)
        end
        
        # Additional info (ratings, etc)
        if product[:rating] || product[:reviews_count]
          hstack(spacing: 2).mt(2) do
            if product[:rating]
              text(render(ProductRatingComponent.new(
                rating: product[:rating],
                max_rating: 5
              )).to_s.html_safe)
            end
            
            if product[:reviews_count]
              text("(#{product[:reviews_count]})")
                .text_size("xs")
                .text_color("gray-500")
            end
          end
        end
      end
    end
    .data(
      "product-id": product[:id],
      "product-index": index
    )
  end
  
  # Component state for selected variant
  state :selected_variant, nil
end