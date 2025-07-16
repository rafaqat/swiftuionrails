# frozen_string_literal: true

require_relative "component_showcase_base"

class EcommerceComponentsShowcaseTest < ComponentShowcaseBase
  test "creates product grid with filters and sorting" do
    test_component(
      name: "Product Grid with Filters",
      category: "E-commerce",
      code: <<~'RUBY',
        swift_ui do
          div(class: "p-6") do
            grid(columns: { base: 1, md: 4 }, column_gap: 8) do
              # Filters sidebar
              div(class: "md:col-span-1") do
                card(elevation: 1) do
                  h3(class: "text-lg font-semibold text-gray-900 mb-6") { text("Filters") }
                  
                  vstack(spacing: 6) do
                    # Category filter
                    div do
                      h4(class: "text-sm font-medium text-gray-700") { text("Category") }
                      vstack(spacing: 2) do
                        categories = ["Electronics", "Clothing", "Home & Garden", "Sports", "Books"]
                        categories.each do |category|
                          label(class: "flex items-center") do
                            input(type: "checkbox", name: "category[]", value: category.downcase.gsub(" ", "_"), class: "rounded text-blue-600")
                            span(class: "ml-2 text-sm text-gray-700") { text(category) }
                          end
                        end
                      end
                    end
                    
                    # Price range
                    div do
                      h4(class: "text-sm font-medium text-gray-700") { text("Price Range") }
                      vstack(spacing: 2) do
                        price_ranges = ["Under $25", "$25 - $50", "$50 - $100", "$100 - $250", "Over $250"]
                        price_ranges.each do |range|
                          label(class: "flex items-center") do
                            input(type: "radio", name: "price_range", value: range.downcase.gsub(/[^0-9a-z]/, "_"), class: "text-blue-600")
                            span(class: "ml-2 text-sm text-gray-700") { text(range) }
                          end
                        end
                      end
                    end
                    
                    # Brand filter
                    div do
                      h4(class: "text-sm font-medium text-gray-700") { text("Brand") }
                      vstack(spacing: 2) do
                        brands = ["Apple", "Samsung", "Sony", "Nike", "Adidas"]
                        brands.each do |brand|
                          label(class: "flex items-center") do
                            input(type: "checkbox", name: "brand[]", value: brand.downcase, class: "rounded text-blue-600")
                            span(class: "ml-2 text-sm text-gray-700") { text(brand) }
                          end
                        end
                      end
                    end
                    
                    # Rating filter
                    div do
                      h4(class: "text-sm font-medium text-gray-700") { text("Customer Rating") }
                      vstack(spacing: 2) do
                        [4, 3, 2, 1].each do |rating|
                          label(class: "flex items-center") do
                            input(type: "checkbox", name: "rating[]", value: rating, class: "rounded text-blue-600")
                            hstack(spacing: 1) do
                              rating.times { span(class: "text-yellow-400 text-sm") { text("★") } }
                              (5 - rating).times { span(class: "text-gray-300 text-sm") { text("★") } }
                              span(class: "ml-2 text-sm text-gray-700") { text("& up") }
                            end
                          end
                        end
                      end
                    end
                    
                    # Clear filters button
                    button { text("Clear All Filters") }
                      .full_width
                      .py(2)
                      .border
                      .rounded("md")
                      .text_sm
                      .font_weight("medium")
                      .hover("bg-gray-50")
                  end
                end.p(6)
              end
              
              # Main content area
              div(class: "md:col-span-3") do
                # Results header
                hstack(justify: :between) do
                  p(class: "text-sm text-gray-700") do
                    text("Showing ")
                    span(class: "font-medium") { text("247") }
                    text(" results")
                  end
                  
                  # Sort dropdown
                  select(name: "sort", class: "text-sm border rounded-md px-3 py-1") do
                    option(value: "relevance") { text("Sort by: Relevance") }
                    option(value: "price_low") { text("Price: Low to High") }
                    option(value: "price_high") { text("Price: High to Low") }
                    option(value: "rating") { text("Customer Rating") }
                    option(value: "newest") { text("Newest First") }
                  end
                end
                
                # Product grid
                grid(columns: 3, spacing: 6) do
                  products = [
                    { 
                      name: "Wireless Headphones Pro", 
                      price: "$249.99", 
                      original: "$299.99",
                      rating: 4.5,
                      reviews: 234,
                      image_bg: "gradient-to-br from-blue-100 to-purple-100",
                      badge: "Best Seller"
                    },
                    {
                      name: "Smart Watch Series 7",
                      price: "$399.99",
                      original: nil,
                      rating: 4.8,
                      reviews: 567,
                      image_bg: "gradient-to-br from-gray-100 to-gray-200",
                      badge: "New"
                    },
                    {
                      name: "4K Webcam Ultra",
                      price: "$149.99",
                      original: "$199.99",
                      rating: 4.2,
                      reviews: 89,
                      image_bg: "gradient-to-br from-red-100 to-orange-100",
                      badge: "25% OFF"
                    },
                    {
                      name: "Mechanical Keyboard RGB",
                      price: "$179.99",
                      original: nil,
                      rating: 4.7,
                      reviews: 421,
                      image_bg: "gradient-to-br from-green-100 to-teal-100",
                      badge: nil
                    },
                    {
                      name: "USB-C Hub 7-in-1",
                      price: "$59.99",
                      original: "$79.99",
                      rating: 4.4,
                      reviews: 156,
                      image_bg: "gradient-to-br from-yellow-100 to-amber-100",
                      badge: "Limited Stock"
                    },
                    {
                      name: "Wireless Mouse Ergonomic",
                      price: "$89.99",
                      original: nil,
                      rating: 4.6,
                      reviews: 312,
                      image_bg: "gradient-to-br from-indigo-100 to-blue-100",
                      badge: nil
                    }
                  ]
                  
                  products.each_with_index do |product, idx|
                    card(elevation: 1) do
                      div(class: "relative") do
                        # Badge
                        if product[:badge]
                          div(class: "absolute top-2 left-2 z-10") do
                            span(class: "px-2 py-1 text-xs font-bold text-white bg-red-500 rounded") do
                              text(product[:badge])
                            end
                          end
                        end
                        
                        # Wishlist button
                        button(class: "absolute top-2 right-2 z-10 w-8 h-8 bg-white rounded-full shadow-md flex items-center justify-center") do
                          span(class: "text-gray-400 hover:text-red-500") { text("♡") }
                        end
                        
                        # Product image placeholder
                        div(class: "h-48 bg-" + product[:image_bg] + " rounded-t-lg flex items-center justify-center") do
                          span(class: "text-4xl text-gray-400") { text("📦") }
                        end
                      end
                      
                      # Product info
                      div(class: "p-4") do
                        # Name
                        h4(class: "font-medium text-gray-900 line-clamp-2") { text(product[:name]) }
                        
                        # Rating
                        hstack(spacing: 2) do
                          hstack(spacing: 1) do
                            full_stars = product[:rating].floor
                            has_half = (product[:rating] % 1) >= 0.5
                            
                            full_stars.times { span(class: "text-yellow-400 text-sm") { text("★") } }
                            if has_half
                              span(class: "text-yellow-400 text-sm") { text("★") }
                            end
                            (5 - full_stars - (has_half ? 1 : 0)).times { span(class: "text-gray-300 text-sm") { text("★") } }
                          end
                          
                          span(class: "text-sm text-gray-600") { text("(" + product[:reviews].to_s + ")") }
                        end
                        
                        # Price
                        hstack(spacing: 2) do
                          span(class: "text-lg font-bold text-gray-900") { text(product[:price]) }
                          if product[:original]
                            span(class: "text-sm text-gray-500 line-through") { text(product[:original]) }
                          end
                        end
                        
                        # Add to cart button
                        button { text("Add to Cart") }
                          .full_width
                          .mt(3)
                          .py(2)
                          .bg("blue-600")
                          .text_color("white")
                          .rounded("md")
                          .font_weight("medium")
                          .hover("bg-blue-700")
                      end
                    end
                  end
                end.mt(6)
                
                # Pagination
                hstack(justify: :center) do
                  button { text("Previous") }
                    .px(4).py(2)
                    .border
                    .rounded("md")
                    .text_sm
                    .disabled
                  
                  pages = [1, 2, 3, "...", 8, 9]
                  pages.each do |page|
                    if page == 1
                      button { text(page.to_s) }
                        .px(3).py(2)
                        .bg("blue-600")
                        .text_color("white")
                        .rounded("md")
                        .text_sm
                    elsif page == "..."
                      span(class: "px-3 py-2 text-gray-500") { text("...") }
                    else
                      button { text(page.to_s) }
                        .px(3).py(2)
                        .border
                        .rounded("md")
                        .text_sm
                        .hover("bg-gray-50")
                    end
                  end
                  
                  button { text("Next") }
                    .px(4).py(2)
                    .border
                    .rounded("md")
                    .text_sm
                end.mt(8).spacing(2)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has filters" => -> { assert_text "Filters" ; assert_text "Category" ; assert_text "Price Range" },
        "has categories" => -> { assert_text "Electronics" ; assert_text "Clothing" },
        "has price ranges" => -> { assert_text "Under $25" ; assert_text "$50 - $100" },
        "has brands" => -> { assert_text "Apple" ; assert_text "Samsung" },
        "has products" => -> { assert_text "Wireless Headphones Pro" ; assert_text "Smart Watch Series 7" },
        "has prices" => -> { assert_text "$249.99" ; assert_text "$299.99" },
        "has ratings" => -> { assert_selector "span.text-yellow-400" },
        "has badges" => -> { assert_text "Best Seller" ; assert_text "25% OFF" },
        "has pagination" => -> { assert_text "Previous" ; assert_text "Next" }
      }
    )
  end

  test "creates shopping cart with complex calculations" do
    test_component(
      name: "Shopping Cart",
      category: "E-commerce",
      code: <<~'RUBY',
        swift_ui do
          div(class: "max-w-4xl mx-auto p-6") do
            h1(class: "text-3xl font-bold text-gray-900 mb-8") { text("Shopping Cart") }
            
            grid(columns: { base: 1, lg: 3 }, column_gap: 8) do
              # Cart items
              div(class: "lg:col-span-2") do
                cart_items = [
                  {
                    id: 1,
                    name: "Wireless Headphones Pro",
                    description: "Noise-cancelling, 30-hour battery",
                    price: 249.99,
                    quantity: 1,
                    color: "Space Gray",
                    image_bg: "gradient-to-br from-gray-200 to-gray-300"
                  },
                  {
                    id: 2,
                    name: "Smart Watch Series 7",
                    description: "GPS, Heart Rate, Always-on Display",
                    price: 399.99,
                    quantity: 2,
                    color: "Blue",
                    image_bg: "gradient-to-br from-blue-200 to-blue-300"
                  },
                  {
                    id: 3,
                    name: "USB-C Hub 7-in-1",
                    description: "HDMI, USB 3.0, SD Card Reader",
                    price: 59.99,
                    quantity: 1,
                    color: "Silver",
                    image_bg: "gradient-to-br from-gray-100 to-gray-200"
                  }
                ]
                
                vstack(spacing: 4) do
                  cart_items.each do |item|
                    card(elevation: 1) do
                      hstack(spacing: 4) do
                        # Product image
                        div(class: "w-24 h-24 bg-" + item[:image_bg] + " rounded-lg flex items-center justify-center flex-shrink-0") do
                          span(class: "text-3xl") { text("📦") }
                        end
                        
                        # Product details
                        div(class: "flex-1") do
                          hstack(justify: :between) do
                            div do
                              h3(class: "font-semibold text-gray-900") { text(item[:name]) }
                              p(class: "text-sm text-gray-600") { text(item[:description]) }
                              p(class: "text-sm text-gray-500 mt-1") do
                                text("Color: ")
                                span(class: "font-medium") { text(item[:color]) }
                              end
                            end
                            
                            # Price
                            p(class: "text-lg font-semibold text-gray-900") do
                              text("$" + (item[:price] * item[:quantity]).round(2).to_s)
                            end
                          end
                          
                          # Quantity and actions
                          hstack(justify: :between) do
                            # Quantity selector
                            hstack(spacing: 2) do
                              button(class: "w-8 h-8 border rounded flex items-center justify-center") do
                                text("-")
                              end
                              input(
                                type: "number",
                                value: item[:quantity],
                                min: 1,
                                class: "w-16 text-center border rounded"
                              )
                              button(class: "w-8 h-8 border rounded flex items-center justify-center") do
                                text("+")
                              end
                            end
                            
                            # Actions
                            hstack(spacing: 4) do
                              button(class: "text-sm text-blue-600 hover:text-blue-800") do
                                text("Save for later")
                              end
                              button(class: "text-sm text-red-600 hover:text-red-800") do
                                text("Remove")
                              end
                            end
                          end
                        end
                      end
                    end.p(4)
                  end
                  
                  # Promo code
                  card(elevation: 1) do
                    hstack(spacing: 3) do
                      textfield(
                        type: "text",
                        placeholder: "Enter promo code",
                        class: "flex-1 px-3 py-2 border rounded-md"
                      )
                      button { text("Apply") }
                        .px(4).py(2)
                        .bg("gray-800")
                        .text_color("white")
                        .rounded("md")
                        .font_weight("medium")
                    end
                  end.p(4)
                end
              end
              
              # Order summary
              div(class: "lg:col-span-1") do
                card(elevation: 2) do
                  h3(class: "text-lg font-semibold text-gray-900 mb-4") { text("Order Summary") }
                  
                  vstack(spacing: 3) do
                    # Calculate totals
                    subtotal = cart_items.sum { |item| item[:price] * item[:quantity] }
                    shipping = 15.00
                    tax = (subtotal * 0.08).round(2)
                    discount = 50.00
                    total = (subtotal + shipping + tax - discount).round(2)
                    
                    # Line items
                    [
                      { label: "Subtotal", value: "$" + subtotal.round(2).to_s },
                      { label: "Shipping", value: "$" + shipping.to_s },
                      { label: "Tax", value: "$" + tax.to_s },
                      { label: "Discount", value: "-$" + discount.to_s, color: "text-green-600" }
                    ].each do |line|
                      hstack(justify: :between) do
                        text(line[:label]).text_sm.text_color("gray-600")
                        text(line[:value]).text_sm.font_weight("medium").text_color(line[:color] || "gray-900")
                      end
                    end
                    
                    # Total
                    div(class: "pt-3 border-t") do
                      hstack(justify: :between) do
                        text("Total").font_weight("semibold").text_gray("900")
                        text("$" + total.to_s).text_xl.font_weight("bold").text_color("gray-900")
                      end
                    end
                  end
                  
                  # Checkout button
                  button { text("Proceed to Checkout") }
                    .full_width
                    .mt(6)
                    .py(3)
                    .bg("blue-600")
                    .text_color("white")
                    .rounded("lg")
                    .font_weight("semibold")
                    .text_size("lg")
                    .hover("bg-blue-700")
                  
                  # Security badges
                  hstack(justify: :center, spacing: 4) do
                    span(class: "text-xs text-gray-500") { text("🔒 Secure checkout") }
                    span(class: "text-xs text-gray-500") { text("💳 All cards accepted") }
                  end.mt(4)
                  
                  # Shipping info
                  div(class: "mt-6 p-4 bg-blue-50 rounded-lg") do
                    p(class: "text-sm text-blue-800") do
                      text("🚚 Free shipping on orders over $100")
                    end
                  end
                end.p(6).bg("white")
              end
            end
            
            # Recently viewed
            div(class: "mt-12") do
              h2(class: "text-xl font-semibold text-gray-900 mb-4") { text("Recently Viewed") }
              
              grid(columns: 4, spacing: 4) do
                recent_products = [
                  { name: "Phone Case", price: "$29", image: "📱" },
                  { name: "Screen Protector", price: "$19", image: "🛡️" },
                  { name: "Charging Cable", price: "$15", image: "🔌" },
                  { name: "Power Bank", price: "$45", image: "🔋" }
                ]
                
                recent_products.each do |product|
                  card(elevation: 0) do
                    vstack(spacing: 2, alignment: :center) do
                      div(class: "w-full h-24 bg-gray-100 rounded flex items-center justify-center") do
                        span(class: "text-2xl") { text(product[:image]) }
                      end
                      p(class: "text-sm font-medium text-gray-900") { text(product[:name]) }
                      p(class: "text-sm font-bold text-gray-900") { text(product[:price]) }
                    end
                  end.p(3).border
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has cart title" => -> { assert_text "Shopping Cart" },
        "has products" => -> { assert_text "Wireless Headphones Pro" ; assert_text "Smart Watch Series 7" },
        "has quantities" => -> { assert_selector "input[type='number']" },
        "has order summary" => -> { assert_text "Order Summary" ; assert_text "Subtotal" ; assert_text "Total" },
        "has promo code" => -> { assert_selector "input[placeholder='Enter promo code']" },
        "has checkout button" => -> { assert_text "Proceed to Checkout" },
        "has recently viewed" => -> { assert_text "Recently Viewed" }
      }
    )
  end

  test "creates product detail page with gallery and reviews" do
    test_component(
      name: "Product Detail Page",
      category: "E-commerce",
      code: <<~'RUBY',
        swift_ui do
          div(class: "max-w-7xl mx-auto p-6") do
            grid(columns: { base: 1, md: 2 }, spacing: 12) do
              # Product images
              div do
                # Main image
                div(class: "bg-gradient-to-br from-gray-100 to-gray-200 rounded-lg h-96 flex items-center justify-center mb-4") do
                  span(class: "text-6xl") { text("🎧") }
                end
                
                # Thumbnail gallery
                grid(columns: 4, spacing: 4) do
                  4.times do |i|
                    div(class: "bg-gray-100 rounded-lg h-20 flex items-center justify-center cursor-pointer hover:ring-2 hover:ring-blue-500") do
                      span(class: "text-2xl") { text("🎧") }
                    end
                  end
                end
              end
              
              # Product info
              div do
                # Breadcrumb
                hstack(spacing: 2, class: "text-sm text-gray-600 mb-4") do
                  link("Home", destination: "#", class: "hover:text-gray-900")
                  span { text("/") }
                  link("Electronics", destination: "#", class: "hover:text-gray-900")
                  span { text("/") }
                  link("Headphones", destination: "#", class: "hover:text-gray-900")
                end
                
                # Title and brand
                p(class: "text-sm text-gray-600 uppercase tracking-wide") { text("PREMIUM AUDIO") }
                h1(class: "text-3xl font-bold text-gray-900 mt-1") { text("Wireless Headphones Pro") }
                
                # Rating and reviews
                hstack(spacing: 4) do
                  hstack(spacing: 1) do
                    5.times do |i|
                      span(class: i < 4 ? "text-yellow-400" : "text-gray-300") { text("★") }
                    end
                  end
                  
                  link("234 reviews", destination: "#reviews", class: "text-sm text-blue-600 hover:text-blue-800")
                  span(class: "text-gray-400") { text("•") }
                  span(class: "text-sm text-green-600") { text("In Stock") }
                end.mt(2)
                
                # Price
                hstack(spacing: 3) do
                  span(class: "text-3xl font-bold text-gray-900") { text("$249.99") }
                  span(class: "text-xl text-gray-500 line-through") { text("$299.99") }
                  span(class: "px-2 py-1 bg-red-100 text-red-800 text-sm font-semibold rounded") do
                    text("Save $50")
                  end
                end.mt(6)
                
                # Product options
                vstack(spacing: 6) do
                  # Color selector
                  div do
                    p(class: "text-sm font-medium text-gray-700 mb-2") { text("Color") }
                    hstack(spacing: 2) do
                      colors = [
                        { name: "Space Gray", hex: "bg-gray-800" },
                        { name: "Silver", hex: "bg-gray-300" },
                        { name: "Blue", hex: "bg-blue-600" },
                        { name: "Red", hex: "bg-red-600" }
                      ]
                      
                      colors.each_with_index do |color, idx|
                        ring_class = idx == 0 ? 'ring-blue-500' : 'ring-transparent'
                        button(
                          class: "w-8 h-8 rounded-full " + color[:hex] + " ring-2 ring-offset-2 " + ring_class
                        )
                      end
                    end
                  end
                  
                  # Size selector
                  div do
                    p(class: "text-sm font-medium text-gray-700 mb-2") { text("Size") }
                    select(class: "w-full px-3 py-2 border rounded-md") do
                      option(value: "standard") { text("Standard") }
                      option(value: "large") { text("Large (+$20)") }
                    end
                  end
                  
                  # Quantity
                  div do
                    p(class: "text-sm font-medium text-gray-700 mb-2") { text("Quantity") }
                    hstack(spacing: 3) do
                      button(class: "w-10 h-10 border rounded-md") { text("-") }
                      input(type: "number", value: "1", min: "1", class: "w-20 text-center border rounded-md")
                      button(class: "w-10 h-10 border rounded-md") { text("+") }
                    end
                  end
                end.mt(8)
                
                # Add to cart and wishlist
                hstack(spacing: 3) do
                  button { text("Add to Cart") }
                    .flex_1
                    .py(3)
                    .bg("blue-600")
                    .text_color("white")
                    .rounded("lg")
                    .font_weight("semibold")
                    .hover("bg-blue-700")
                  
                  button(class: "p-3 border rounded-lg hover:bg-gray-50") do
                    span(class: "text-xl") { text("♡") }
                  end
                end.mt(8)
                
                # Product highlights
                div(class: "mt-8 p-4 bg-gray-50 rounded-lg") do
                  vstack(spacing: 3) do
                    h3(class: "font-semibold text-gray-900") { text("Product Highlights") }
                    highlights = [
                      "Active noise cancellation",
                      "30-hour battery life", 
                      "Premium comfort padding",
                      "Bluetooth 5.0",
                      "Foldable design"
                    ]
                    
                    highlights.each do |feature|
                      hstack(spacing: 2) do
                        span(class: "text-green-500") { text("✓") }
                        text(feature).text_sm.text_color("gray-700")
                      end
                    end
                  end
                end
                
                # Shipping info
                div(class: "mt-6 border-t pt-6") do
                  vstack(spacing: 3) do
                    hstack(spacing: 3) do
                      span(class: "text-blue-600") { text("🚚") }
                      div do
                        p(class: "font-medium text-gray-900") { text("Free Shipping") }
                        p(class: "text-sm text-gray-600") { text("Delivery in 2-3 business days") }
                      end
                    end
                    
                    hstack(spacing: 3) do
                      span(class: "text-green-600") { text("↩️") }
                      div do
                        p(class: "font-medium text-gray-900") { text("Free Returns") }
                        p(class: "text-sm text-gray-600") { text("30-day return policy") }
                      end
                    end
                  end
                end
              end
            end
            
            # Product tabs
            div(class: "mt-16") do
              # Tab navigation
              div(class: "border-b") do
                hstack(spacing: 8) do
                  ["Description", "Specifications", "Reviews (234)"].each_with_index do |tab, idx|
                    tab_class = idx == 0 ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-500'
                    button(class: "pb-4 " + tab_class) do
                      text(tab)
                    end
                  end
                end
              end
              
              # Tab content - Description
              div(class: "py-8") do
                div(class: "prose max-w-none") do
                  p(class: "text-gray-700") do
                    text("Experience premium audio quality with our Wireless Headphones Pro. Featuring industry-leading noise cancellation technology, these headphones deliver crystal-clear sound in any environment. The ergonomic design ensures all-day comfort, while the 30-hour battery life keeps you connected to your music longer.")
                  end
                  
                  h3(class: "text-lg font-semibold text-gray-900 mt-6 mb-3") { text("Key Features") }
                  
                  vstack(spacing: 4) do
                    features = [
                      {
                        title: "Active Noise Cancellation",
                        desc: "Block out unwanted noise with our advanced ANC technology"
                      },
                      {
                        title: "Premium Sound Quality",
                        desc: "40mm drivers deliver rich, detailed audio across all frequencies"
                      },
                      {
                        title: "All-Day Battery",
                        desc: "30 hours of playback on a single charge, with quick charge support"
                      }
                    ]
                    
                    features.each do |feature|
                      div do
                        h4(class: "font-medium text-gray-900") { text(feature[:title]) }
                        p(class: "text-sm text-gray-600 mt-1") { text(feature[:desc]) }
                      end
                    end
                  end
                end
              end
            end
            
            # Related products
            div(class: "mt-16") do
              h2(class: "text-2xl font-bold text-gray-900 mb-6") { text("You Might Also Like") }
              
              grid(columns: 4, spacing: 6) do
                related = [
                  { name: "Wireless Earbuds", price: "$149", rating: 4.3, image: "🎵" },
                  { name: "Headphone Stand", price: "$39", rating: 4.7, image: "🎧" },
                  { name: "Audio Cable", price: "$19", rating: 4.5, image: "🔌" },
                  { name: "Carrying Case", price: "$29", rating: 4.8, image: "💼" }
                ]
                
                related.each do |product|
                  card(elevation: 1) do
                    div(class: "h-32 bg-gray-100 rounded-t flex items-center justify-center") do
                      span(class: "text-3xl") { text(product[:image]) }
                    end
                    
                    div(class: "p-4") do
                      h4(class: "font-medium text-gray-900") { text(product[:name]) }
                      
                      hstack(spacing: 1) do
                        full_stars = product[:rating].floor
                        full_stars.times { span(class: "text-yellow-400 text-sm") { text("★") } }
                        (5 - full_stars).times { span(class: "text-gray-300 text-sm") { text("★") } }
                      end
                      
                      p(class: "font-bold text-gray-900 mt-2") { text(product[:price]) }
                    end
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has product title" => -> { assert_text "Wireless Headphones Pro" },
        "has price" => -> { assert_text "$249.99" ; assert_text "$299.99" },
        "has rating" => -> { assert_text "234 reviews" },
        "has color options" => -> { assert_text "Color" },
        "has add to cart" => -> { assert_text "Add to Cart" },
        "has product highlights" => -> { assert_text "Product Highlights" ; assert_text "Active noise cancellation" },
        "has shipping info" => -> { assert_text "Free Shipping" ; assert_text "Free Returns" },
        "has tabs" => -> { assert_text "Description" ; assert_text "Specifications" ; assert_text "Reviews" },
        "has related products" => -> { assert_text "You Might Also Like" }
      }
    )
  end

  test "creates checkout form with validation" do
    test_component(
      name: "Checkout Form",
      category: "E-commerce",
      code: <<~'RUBY',
        swift_ui do
          div(class: "max-w-7xl mx-auto p-6") do
            h1(class: "text-3xl font-bold text-gray-900 mb-8") { text("Checkout") }
            
            grid(columns: { base: 1, lg: 3 }, column_gap: 8) do
              # Main form
              div(class: "lg:col-span-2") do
                form do
                  vstack(spacing: 8) do
                    # Contact information
                    card(elevation: 1) do
                      h2(class: "text-xl font-semibold text-gray-900 mb-6") { text("Contact Information") }
                      
                      vstack(spacing: 4) do
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Email Address") }
                          textfield(
                            type: "email",
                            name: "email",
                            placeholder: "john@example.com",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        label(class: "flex items-center") do
                          input(type: "checkbox", class: "rounded text-blue-600 mr-2")
                          span(class: "text-sm text-gray-700") { text("Email me with news and offers") }
                        end
                      end
                    end.p(6)
                    
                    # Shipping address
                    card(elevation: 1) do
                      h2(class: "text-xl font-semibold text-gray-900 mb-6") { text("Shipping Address") }
                      
                      grid(columns: 2, spacing: 4) do
                        # First name
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("First Name") }
                          textfield(
                            type: "text",
                            name: "first_name",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        # Last name
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Last Name") }
                          textfield(
                            type: "text",
                            name: "last_name",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        # Address
                        div(class: "col-span-2") do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Address") }
                          textfield(
                            type: "text",
                            name: "address",
                            placeholder: "123 Main St",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        # Apartment
                        div(class: "col-span-2") do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") do
                            text("Apartment, suite, etc. ")
                            span(class: "text-gray-500") { text("(optional)") }
                          end
                          textfield(
                            type: "text",
                            name: "apartment",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        # City
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("City") }
                          textfield(
                            type: "text",
                            name: "city",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        # State
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("State") }
                          select(name: "state", class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500") do
                            option(value: "") { text("Select state") }
                            ["CA", "NY", "TX", "FL", "IL"].each do |state|
                              option(value: state) { text(state) }
                            end
                          end
                        end
                        
                        # ZIP
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("ZIP Code") }
                          textfield(
                            type: "text",
                            name: "zip",
                            placeholder: "12345",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        # Phone
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Phone") }
                          textfield(
                            type: "tel",
                            name: "phone",
                            placeholder: "(555) 123-4567",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                      end
                    end.p(6)
                    
                    # Shipping method
                    card(elevation: 1) do
                      h2(class: "text-xl font-semibold text-gray-900 mb-6") { text("Shipping Method") }
                      
                      vstack(spacing: 3) do
                        shipping_options = [
                          { name: "Standard Shipping", time: "5-7 business days", price: "$0.00", default: true },
                          { name: "Express Shipping", time: "2-3 business days", price: "$15.00", default: false },
                          { name: "Next Day Shipping", time: "1 business day", price: "$35.00", default: false }
                        ]
                        
                        shipping_options.each do |option|
                          label(class: "flex items-center p-4 border rounded-lg cursor-pointer hover:bg-gray-50") do
                            input(
                              type: "radio",
                              name: "shipping",
                              value: option[:name].downcase.gsub(" ", "_"),
                              checked: option[:default],
                              class: "text-blue-600"
                            )
                            div(class: "ml-3 flex-1") do
                              hstack(justify: :between) do
                                div do
                                  p(class: "font-medium text-gray-900") { text(option[:name]) }
                                  p(class: "text-sm text-gray-500") { text(option[:time]) }
                                end
                                p(class: "font-medium text-gray-900") { text(option[:price]) }
                              end
                            end
                          end
                        end
                      end
                    end.p(6)
                    
                    # Payment
                    card(elevation: 1) do
                      h2(class: "text-xl font-semibold text-gray-900 mb-6") { text("Payment") }
                      
                      vstack(spacing: 4) do
                        # Card number
                        div do
                          label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Card Number") }
                          textfield(
                            type: "text",
                            name: "card_number",
                            placeholder: "1234 5678 9012 3456",
                            class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                          )
                        end
                        
                        grid(columns: 3, spacing: 4) do
                          # Expiry
                          div(class: "col-span-2") do
                            label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Expiry Date") }
                            textfield(
                              type: "text",
                              name: "expiry",
                              placeholder: "MM/YY",
                              class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                            )
                          end
                          
                          # CVV
                          div do
                            label(class: "block text-sm font-medium text-gray-700 mb-1") { text("CVV") }
                            textfield(
                              type: "text",
                              name: "cvv",
                              placeholder: "123",
                              class: "w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                            )
                          end
                        end
                        
                        # Save card
                        label(class: "flex items-center") do
                          input(type: "checkbox", class: "rounded text-blue-600 mr-2")
                          span(class: "text-sm text-gray-700") { text("Save this card for future purchases") }
                        end
                      end
                    end.p(6)
                  end
                end
              end
              
              # Order summary sidebar
              div(class: "lg:col-span-1") do
                card(elevation: 2) do
                  h2(class: "text-xl font-semibold text-gray-900 mb-6") { text("Order Summary") }
                  
                  # Items
                  vstack(spacing: 4) do
                    order_items = [
                      { name: "Wireless Headphones Pro", qty: 1, price: 249.99 },
                      { name: "Smart Watch Series 7", qty: 2, price: 799.98 },
                      { name: "USB-C Hub", qty: 1, price: 59.99 }
                    ]
                    
                    order_items.each do |item|
                      hstack(justify: :between) do
                        div do
                          p(class: "font-medium text-gray-900") { text(item[:name]) }
                          p(class: "text-sm text-gray-500") { text("Qty: " + item[:qty].to_s) }
                        end
                        p(class: "font-medium text-gray-900") { text("$" + item[:price].to_s) }
                      end
                    end
                  end
                  
                  # Totals
                  div(class: "mt-6 pt-6 border-t space-y-2") do
                    [
                      { label: "Subtotal", value: "$1,109.96" },
                      { label: "Shipping", value: "$0.00" },
                      { label: "Tax", value: "$88.80" }
                    ].each do |line|
                      hstack(justify: :between) do
                        text(line[:label]).text_sm.text_color("gray-600")
                        text(line[:value]).text_sm.font_weight("medium")
                      end
                    end
                    
                    # Total
                    hstack(justify: :between) do
                      text("Total").font_weight("semibold").text_gray("900")
                      text("$1,198.76").text_xl.font_weight("bold").text_color("gray-900")
                    end.mt(4).pt(4).border_t
                  end
                  
                  # Complete order button
                  button { text("Complete Order") }
                    .full_width
                    .mt(6)
                    .py(3)
                    .bg("blue-600")
                    .text_color("white")
                    .rounded("lg")
                    .font_weight("semibold")
                    .text_size("lg")
                    .hover("bg-blue-700")
                  
                  # Security note
                  p(class: "mt-4 text-xs text-center text-gray-500") do
                    text("🔒 Your payment information is encrypted and secure")
                  end
                end.p(6).bg("white").sticky.top(6)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has checkout title" => -> { assert_text "Checkout" },
        "has contact section" => -> { assert_text "Contact Information" ; assert_text "Email Address" },
        "has shipping address" => -> { assert_text "Shipping Address" ; assert_text "First Name" ; assert_text "ZIP Code" },
        "has shipping methods" => -> { assert_text "Shipping Method" ; assert_text "Standard Shipping" ; assert_text "Express Shipping" },
        "has payment section" => -> { assert_text "Payment" ; assert_text "Card Number" ; assert_text "CVV" },
        "has order summary" => -> { assert_text "Order Summary" ; assert_text "Total" },
        "has complete button" => -> { assert_text "Complete Order" }
      }
    )
  end
end