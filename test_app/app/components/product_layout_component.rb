# frozen_string_literal: true

class ProductLayoutComponent < ApplicationComponent
  # Main props
  prop :title, type: String, default: "Products"
  prop :products, type: Array, required: true
  prop :columns, type: Hash, default: { base: 1, sm: 2, md: 3, lg: 4 }
  prop :show_variants, type: [TrueClass, FalseClass], default: true
  
  # Action handlers - passed in for flexibility
  prop :on_product_click, type: Proc, default: nil
  prop :on_add_to_cart, type: Proc, default: nil
  prop :on_variant_select, type: Proc, default: nil
  prop :on_quick_view, type: Proc, default: nil
  
  # Layout options
  prop :card_style, type: Symbol, default: :standard # :standard, :compact, :detailed
  prop :show_quick_actions, type: [TrueClass, FalseClass], default: true
  prop :image_aspect_ratio, type: String, default: "square" # square, video, auto
  
  # Pre-render product cards outside of DSL context
  def rendered_products
    @rendered_products ||= products.map.with_index do |product, index|
      render ProductCardComponent.new(
        product: product,
        card_style: card_style,
        show_variants: show_variants,
        show_quick_actions: show_quick_actions,
        image_aspect_ratio: image_aspect_ratio,
        on_click: on_product_click,
        on_add_to_cart: on_add_to_cart,
        on_variant_select: on_variant_select,
        on_quick_view: on_quick_view,
        index: index
      )
    end
  end
  
  swift_ui do
    create_element(:section, nil, {
      class: "bg-white px-4 py-16 sm:px-6 sm:py-24 max-w-7xl mx-auto"
    }) do
      # Header
      if title.present?
        hstack.mb(6) do
          text(title)
            .text_size("2xl")
            .font_weight("bold")
            .tw("tracking-tight")
            .text_color("gray-900")
          
          spacer
          
          # Optional slot for header actions
          # TODO: Implement slots in DSL context
          # render header_actions if header_actions?
        end
      end
      
      # Product Grid
      create_element(:div, nil, {
        class: "grid grid-cols-#{columns[:base]} sm:grid-cols-#{columns[:sm]} md:grid-cols-#{columns[:md]} lg:grid-cols-#{columns[:lg]} gap-6 lg:gap-x-8"
      }) do
        
        # Insert pre-rendered product cards
        rendered_products.each do |product_html|
          text(product_html.to_s.html_safe)
        end
      end
      
      # Optional footer slot
      # TODO: Implement slots in DSL context
      # render footer if footer?
    end
  end
  
  # Slots for customization
  slot :header_actions
  slot :footer
end