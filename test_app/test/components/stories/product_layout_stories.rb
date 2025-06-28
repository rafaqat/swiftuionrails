# frozen_string_literal: true

class ProductLayoutStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  # Layout controls
  control :columns, as: :select, options: [1, 2, 4], default: 4
  control :show_filters, as: :boolean, default: true
  control :filter_position, as: :select, options: ["sidebar", "top"], default: "sidebar"
  
  # Filter controls
  control :show_price_filter, as: :boolean, default: true
  control :show_color_filter, as: :boolean, default: true
  control :show_category_filter, as: :boolean, default: true
  control :show_sort_dropdown, as: :boolean, default: true
  
  # Product card controls
  control :show_cta_button, as: :boolean, default: true
  control :cta_text, as: :text, default: "Add to cart"
  control :currency, as: :select, options: ["$", "£", "€", "¥"], default: "$"
  control :card_elevation, as: :select, options: [0, 1, 2, 3], default: 1
  
  def default(columns: 4, show_filters: true, filter_position: "sidebar",
              show_price_filter: true, show_color_filter: true, show_category_filter: true,
              show_sort_dropdown: true, show_cta_button: true, cta_text: "Add to cart",
              currency: "$", card_elevation: 1)
    
    # Sample product data - in real app this would come from Rails models
    products = generate_sample_products
    
    content_tag(:div, class: "min-h-screen bg-gray-50") do
      swift_ui do
        # Main container
        div.max_w("7xl").mx("auto").px(4).py(8).add_class("sm:px-6 lg:px-8") do
          # Page header
          hstack(alignment: :center).mb(8) do
            vstack(alignment: :start, spacing: 2) do
              text("Products")
                .text_size("3xl")
                .font_weight("bold")
                .text_color("gray-900")
              
              text("#{products.length} items")
                .text_size("base")
                .text_color("gray-600")
            end
            
            spacer
            
            # Sort dropdown
            if show_sort_dropdown
              div.relative do
                select_element.block.w("full").pl(3).pr(10).py(2).text_size("base")
                  .border("gray-300").rounded("md")
                  .add_class("focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm") do
                  option("popular", "Most Popular")
                  option("newest", "Newest")
                  option("price_asc", "Price: Low to High")
                  option("price_desc", "Price: High to Low")
                end
              end
            end
          end
          
          # Layout based on filter position
          if show_filters && filter_position == "top"
            # Top filters layout
            vstack(spacing: 6) do
              # Inline top filters for now
              div.bg("white").p(4).rounded("lg").shadow("sm").border.border_color("gray-200") do
                hstack(spacing: 8, alignment: :center) do
                  text("Top filters would go here")
                  spacer
                  text("24 Results").text_size("sm").text_color("gray-600")
                end
              end
              
              # Inline product grid
              grid_class = case columns
              when 1
                "grid-cols-1"
              when 2
                "grid-cols-1 sm:grid-cols-2"
              else
                "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"
              end
              
              grid(cols: columns, gap: 6).add_class(grid_class) do
                products.each do |product|
                  # Inline product card
                  card(elevation: card_elevation) do
                    # Product image
                    div.aspect("square").overflow("hidden").rounded("md").bg("gray-200").group do
                      image(
                        src: product[:image],
                        alt: "#{product[:name]} in #{product[:variant]}"
                      ).w_full.h_full.object("cover").transition.duration(300)
                        .add_class("group-hover:scale-105")
                    end
                    
                    # Product details
                    vstack(spacing: 2, alignment: :start).mt(4) do
                      text(product[:name])
                        .font_weight("semibold")
                        .text_color("gray-900")
                        .text_size("lg")
                      
                      if product[:variant]
                        text(product[:variant])
                          .text_color("gray-600")
                          .text_size("sm")
                      end
                      
                      text("#{currency}#{product[:price]}")
                        .font_weight("bold")
                        .text_color("gray-900")
                        .text_size("xl")
                        .mt(2)
                    end
                    
                    # CTA Button
                    if show_cta_button
                      button(cta_text).w_full.mt(4).px(4).py(2).bg("black").text_color("white")
                        .rounded("md").transition_colors.font_weight("medium")
                        .add_class("hover:bg-gray-800")
                    end
                  end.p(6).bg("white")
                end
              end
            end
          elsif show_filters && filter_position == "sidebar"
            # Sidebar filters layout
            div.flex.add_class("gap-8") do
              # Filters sidebar
              div.w(64).flex_shrink(0) do
                vstack(spacing: 8).add_class("sticky top-8") do
                  # Filters header
                  hstack(alignment: :center) do
                    text("Filters")
                      .font_weight("semibold")
                      .text_size("lg")
                      .text_color("gray-900")
                    
                    spacer
                    
                    button("Clear all").text_size("sm").text_color("gray-500")
                      .add_class("hover:text-gray-700")
                  end
                  
                  divider
                  
                  # Price filter
                  if show_price_filter
                    vstack(spacing: 4) do
                      text("Price")
                        .font_weight("medium")
                        .text_color("gray-900")
                      
                      vstack(spacing: 2) do
                        # Simple checkbox display
                        ["Under $50", "$50 - $100", "$100 - $200", "Over $200"].each do |label|
                          hstack(alignment: :center, spacing: 3) do
                            div.w(4).h(4).border.border_color("gray-300").rounded.bg("white")
                            text(label).text_size("sm").text_color("gray-700")
                          end
                        end
                      end
                    end
                  end
                  
                  # Color filter
                  if show_color_filter
                    vstack(spacing: 4) do
                      text("Color")
                        .font_weight("medium")
                        .text_color("gray-900")
                      
                      div.grid.add_class("grid-cols-4 gap-2") do
                        # Inline color swatches
                        [
                          ["black", "#000000", ""],
                          ["white", "#FFFFFF", "border border-gray-300"],
                          ["gray", "#6B7280", ""],
                          ["brown", "#92400E", ""]
                        ].each do |name, hex, extra_classes|
                          button.w(8).h(8).rounded("full").ring_hover(2).add_class("ring-offset-2 ring-gray-400")
                            .add_class(extra_classes)
                            .style("background-color: #{hex}")
                            .title(name.capitalize)
                        end
                      end
                    end
                  end
                end
              end
              
              # Product grid
              div.add_class("flex-1") do
                grid_class = case columns
                when 1
                  "grid-cols-1"
                when 2
                  "grid-cols-1 sm:grid-cols-2"
                else
                  "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"
                end
                
                grid(cols: columns).add_class("gap-6 #{grid_class}") do
                  products.each do |product|
                    # Product card
                    card(elevation: card_elevation) do
                      # Product image
                      div.add_class("aspect-square overflow-hidden rounded-md bg-gray-200 group") do
                        image(
                          src: product[:image],
                          alt: "#{product[:name]} in #{product[:variant]}"
                        ).w_full.h_full.object("cover").transition.duration(300)
                          .add_class("group-hover:scale-105")
                      end
                      
                      # Product details
                      vstack(spacing: 2, alignment: :start).mt(4) do
                        text(product[:name])
                          .font_weight("semibold")
                          .text_color("gray-900")
                          .text_size("lg")
                        
                        if product[:variant]
                          text(product[:variant])
                            .text_color("gray-600")
                            .text_size("sm")
                        end
                        
                        text("#{currency}#{product[:price]}")
                          .font_weight("bold")
                          .text_color("gray-900")
                          .text_size("xl")
                          .mt(2)
                      end
                      
                      # CTA Button
                      if show_cta_button
                        button(cta_text).w_full.mt(4).px(4).py(2).bg("black").text_color("white")
                          .rounded("md").add_class("transition-colors hover:bg-gray-800").font_weight("medium")
                      end
                    end.p(6).bg("white")
                  end
                end
              end
            end
          else
            # No filters - just grid
            grid_class = case columns
            when 1
              "grid-cols-1"
            when 2
              "grid-cols-1 sm:grid-cols-2"
            else
              "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"
            end
            
            grid(cols: columns, gap: 6).add_class(grid_class) do
              products.each do |product|
                # Inline product card
                card(elevation: card_elevation) do
                  # Product image
                  div.aspect("square").overflow("hidden").rounded("md").bg("gray-200").group do
                    image(
                      src: product[:image],
                      alt: "#{product[:name]} in #{product[:variant]}"
                    ).w_full.h_full.object("cover").transition.duration(300)
                      .add_class("group-hover:scale-105")
                  end
                  
                  # Product details
                  vstack(spacing: 2, alignment: :start).mt(4) do
                    text(product[:name])
                      .font_weight("semibold")
                      .text_color("gray-900")
                      .text_size("lg")
                    
                    if product[:variant]
                      text(product[:variant])
                        .text_color("gray-600")
                        .text_size("sm")
                    end
                    
                    text("#{currency}#{product[:price]}")
                      .font_weight("bold")
                      .text_color("gray-900")
                      .text_size("xl")
                      .mt(2)
                  end
                  
                  # CTA Button
                  if show_cta_button
                    button(cta_text).w_full.mt(4).px(4).py(2).bg("black").text_color("white")
                      .rounded("md").transition_colors.font_weight("medium")
                      .add_class("hover:bg-gray-800")
                  end
                end.p(6).bg("white")
              end
            end
          end
        end
      end
    end
  end
  
  # Mobile-first responsive layout
  def responsive(columns: 4, show_filters: true, filter_position: "top",
                 show_price_filter: true, show_color_filter: true, show_category_filter: true,
                 show_sort_dropdown: true, show_cta_button: true, cta_text: "Add to cart",
                 currency: "$", card_elevation: 1)
    
    products = generate_sample_products
    
    content_tag(:div, class: "min-h-screen bg-gray-50") do
      swift_ui do
        div.max_w("7xl").mx("auto").px(4).py(6) do
          # Mobile-optimized header
          vstack(spacing: 4).mb(6) do
            text("Products")
              .text_size("2xl")
              .font_weight("bold")
              .text_color("gray-900")
              .add_class("lg:text-3xl")
            
            hstack(alignment: :center, spacing: 4) do
              text("#{products.length} items")
                .text_size("sm")
                .text_color("gray-600")
              
              spacer
              
              # Mobile filter toggle
              button("Filters").px(4).py(2).bg("white").border.border_color("gray-300")
                .rounded("md").text_size("sm").font_weight("medium").text_color("gray-700")
                .add_class("lg:hidden")
            end
          end
          
          # Responsive grid
          render_product_grid(products, columns, currency, show_cta_button, cta_text, card_elevation)
        end
      end
    end
  end
  
  # Masonry layout variant
  def masonry(columns: 4, show_filters: false, filter_position: "top",
              show_price_filter: true, show_color_filter: true, show_category_filter: true,
              show_sort_dropdown: true, show_cta_button: true, cta_text: "Quick Shop",
              currency: "$", card_elevation: 0)
    
    products = generate_masonry_products
    
    content_tag(:div, class: "min-h-screen bg-white") do
      swift_ui do
        div.max_w("7xl").mx("auto").px(4).py(8) do
          # Page header
          vstack(spacing: 2).mb(8) do
            text("Products")
              .text_size("3xl")
              .font_weight("bold")
              .text_color("gray-900")
            
            text("#{products.length} items")
              .text_size("base")
              .text_color("gray-600")
          end
          
          # Masonry grid using columns
          div.add_class("columns-1 sm:columns-2 lg:columns-4 gap-4") do
            products.each_with_index do |product, index|
              div.mb(4).break_inside("avoid") do
                card(elevation: card_elevation).overflow("hidden") do
                  # Variable height images for masonry effect
                  div.relative.group do
                    image(
                      src: product[:image],
                      alt: product[:name]
                    ).w_full.object("cover").add_class(product[:image_class])
                    
                    # Overlay on hover
                    div.absolute.inset(0).bg("black").opacity(0).group_hover_opacity(40).transition
                    
                    # Quick shop button on hover
                    if show_cta_button
                      div.absolute.bottom(4).left(4).right(4).opacity(0).group_hover_opacity(100).transition do
                        button(cta_text).w_full.py(2).px(4).bg("white").text_color("black")
                          .rounded("md").font_weight("medium").text_size("sm")
                      end
                    end
                  end
                  
                  # Product info
                  vstack(spacing: 1).p(4) do
                    text(product[:name])
                      .font_weight("medium")
                      .text_color("gray-900")
                    
                    text("#{currency}#{product[:price]}")
                      .text_color("gray-600")
                      .text_size("sm")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  private
  
  def generate_sample_products
    [
      { name: "Basic Tee", variant: "Black", price: 35, color: "black", category: "shirts", 
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg" },
      { name: "Basic Tee", variant: "White", price: 35, color: "white", category: "shirts",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-01.jpg" },
      { name: "Nomad Tumbler", variant: "White", price: 35, color: "white", category: "accessories",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-02.jpg" },
      { name: "Travel Mug", variant: "Black", price: 25, color: "black", category: "accessories",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-03.jpg" },
      { name: "Leather Jacket", variant: "Brown", price: 250, color: "brown", category: "outerwear",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-03.jpg" },
      { name: "Cotton Hoodie", variant: "Gray", price: 89, color: "gray", category: "outerwear",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-02.jpg" },
      { name: "Wool Blanket", variant: "Brown", price: 120, color: "brown", category: "home",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-04.jpg" },
      { name: "Machined Pen", variant: "Black", price: 35, color: "black", category: "accessories",
        image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-01.jpg" }
    ]
  end
  
  def generate_masonry_products
    products = generate_sample_products
    # Add varying heights for masonry effect
    products.map.with_index do |product, index|
      product.merge(
        image_class: ["h-48", "h-64", "h-80", "h-56", "h-72", "h-96", "h-60", "h-52"][index]
      )
    end
  end
  
  def render_product_grid(products, columns, currency, show_cta_button, cta_text, card_elevation)
    grid_class = case columns
    when 1
      "grid-cols-1"
    when 2
      "grid-cols-1 sm:grid-cols-2"
    else
      "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"
    end
    
    grid(cols: columns, gap: 6).add_class(grid_class) do
      products.each do |product|
        render_product_card(product, currency, show_cta_button, cta_text, card_elevation)
      end
    end
  end
  
  def render_product_card(product, currency, show_cta_button, cta_text, card_elevation)
    card(elevation: card_elevation) do
      # Product image
      div.aspect("square").overflow("hidden").rounded("md").bg("gray-200").group do
        image(
          src: product[:image],
          alt: "#{product[:name]} in #{product[:variant]}"
        ).w_full.h_full.object("cover").transition.duration(300)
          .add_class("group-hover:scale-105")
      end
      
      # Product details
      vstack(spacing: 2, alignment: :start).mt(4) do
        text(product[:name])
          .font_weight("semibold")
          .text_color("gray-900")
          .text_size("lg")
        
        if product[:variant]
          text(product[:variant])
            .text_color("gray-600")
            .text_size("sm")
        end
        
        text("#{currency}#{product[:price]}")
          .font_weight("bold")
          .text_color("gray-900")
          .text_size("xl")
          .mt(2)
      end
      
      # CTA Button
      if show_cta_button
        button(cta_text).w_full.mt(4).px(4).py(2).bg("black").text_color("white")
          .rounded("md").transition_colors.font_weight("medium")
          .add_class("hover:bg-gray-800")
      end
    end.p(6).bg("white")
  end
  
  def render_filters_sidebar(show_price_filter, show_color_filter, show_category_filter)
    vstack(spacing: 8).sticky.top(8) do
      # Filters header
      hstack(alignment: :center) do
        text("Filters")
          .font_weight("semibold")
          .text_size("lg")
          .text_color("gray-900")
        
        spacer
        
        button("Clear all").text_size("sm").text_color("gray-500")
          .add_class("hover:text-gray-700")
      end
      
      divider
      
      # Price filter
      if show_price_filter
        vstack(spacing: 4) do
          text("Price")
            .font_weight("medium")
            .text_color("gray-900")
          
          vstack(spacing: 2) do
            checkbox_item("Under $50", "price_under_50")
            checkbox_item("$50 - $100", "price_50_100")
            checkbox_item("$100 - $200", "price_100_200")
            checkbox_item("Over $200", "price_over_200")
          end
        end
      end
      
      # Color filter
      if show_color_filter
        vstack(spacing: 4) do
          text("Color")
            .font_weight("medium")
            .text_color("gray-900")
          
          div.grid.add_class("grid-cols-4 gap-2") do
            color_swatch("black", "#000000")
            color_swatch("white", "#FFFFFF", "border border-gray-300")
            color_swatch("gray", "#6B7280")
            color_swatch("brown", "#92400E")
            color_swatch("blue", "#3B82F6")
            color_swatch("green", "#10B981")
            color_swatch("red", "#EF4444")
            color_swatch("purple", "#8B5CF6")
          end
        end
      end
      
      # Category filter
      if show_category_filter
        vstack(spacing: 4) do
          text("Category")
            .font_weight("medium")
            .text_color("gray-900")
          
          vstack(spacing: 2) do
            checkbox_item("Shirts", "category_shirts", 12)
            checkbox_item("Outerwear", "category_outerwear", 8)
            checkbox_item("Accessories", "category_accessories", 15)
            checkbox_item("Home", "category_home", 5)
          end
        end
      end
    end
  end
  
  def render_filters_horizontal(show_price_filter, show_color_filter, show_category_filter)
    div.bg("white").p(4).rounded("lg").shadow("sm").border.border_color("gray-200") do
      hstack(spacing: 8, alignment: :center) do
        if show_price_filter
          dropdown_filter("Price", ["Any Price", "Under $50", "$50-$100", "$100-$200", "Over $200"])
        end
        
        if show_color_filter
          dropdown_filter("Color", ["All Colors", "Black", "White", "Gray", "Brown", "Blue"])
        end
        
        if show_category_filter
          dropdown_filter("Category", ["All Categories", "Shirts", "Outerwear", "Accessories", "Home"])
        end
        
        spacer
        
        text("24 Results")
          .text_size("sm")
          .text_color("gray-600")
      end
    end
  end
  
  def checkbox_item(label, value, count = nil)
    hstack(alignment: :center, spacing: 3) do
      input(type: "checkbox", id: value).h(4).w(4).text_color("indigo-600")
        .border_color("gray-300").rounded
      label_element(for: value).text_size("sm").text_color("gray-700").flex_1 { label }
      if count
        text("(#{count})")
          .text_size("xs")
          .text_color("gray-500")
      end
    end
  end
  
  def color_swatch(name, hex, extra_classes = "")
    button.w(8).h(8).rounded("full").ring_hover(2).ring_offset(2).ring_color("gray-400")
      .add_class(extra_classes)
      .style("background-color: #{hex}")
      .title(name.capitalize)
  end
  
  def dropdown_filter(label, options)
    div.relative do
      select_element.pl(3).pr(10).py(2).text_size("sm").border_color("gray-300")
        .rounded("md").add_class("focus:outline-none focus:ring-indigo-500 focus:border-indigo-500") do
        options.each { |opt| option(opt.downcase.gsub(/\s+/, '_'), opt) }
      end
    end
  end
  
  # Helper methods for form elements
  def select_element(**attrs, &block)
    create_element(:select, nil, attrs, &block)
  end
  
  def option_element(text, **attrs)
    create_element(:option, text, attrs)
  end
  
  def label_element(**attrs, &block)
    create_element(:label, nil, attrs, &block)
  end
end