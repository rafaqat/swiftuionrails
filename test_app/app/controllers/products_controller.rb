# frozen_string_literal: true
# Copyright 2025

class ProductsController < ApplicationController
  def index
    # Sample product data - in a real app this would come from the database
    @products = [
      {
        id: 1,
        name: "MacBook Pro 16\"",
        description: "Apple M3 Max chip with 16-core CPU and 40-core GPU",
        price: 3999.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp16-m3-max-202311-gallery-1?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1699048547510",
        category: "Laptops",
        color: "Space Gray",
        in_stock: true
      },
      {
        id: 2,
        name: "iPhone 15 Pro",
        description: "Titanium design with A17 Pro chip",
        price: 999.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-finish-select-202309-6-1inch-titanium?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1692858839538",
        category: "Phones",
        color: "Titanium",
        in_stock: true
      },
      {
        id: 3,
        name: "iPad Pro 12.9\"",
        description: "M2 chip, Liquid Retina XDR display",
        price: 1299.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/ipad-pro-13-select-wifi-spacegray-202405?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1713808374457",
        category: "Tablets",
        color: "Silver",
        in_stock: true
      },
      {
        id: 4,
        name: "Apple Watch Ultra 2",
        description: "Rugged titanium case with precision GPS",
        price: 799.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MT5J3ref_VW_34FR+watch-49-titanium-ultra2_VW_34FR+watch-face-49-alpine-ultra2_VW_34FR?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1694861343622",
        category: "Wearables",
        color: "Orange",
        in_stock: true
      },
      {
        id: 5,
        name: "AirPods Pro",
        description: "Active Noise Cancellation and Adaptive Audio",
        price: 249.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MQD83?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1678916533447",
        category: "Audio",
        color: "White",
        in_stock: true
      },
      {
        id: 6,
        name: "Studio Display",
        description: "27-inch 5K Retina display",
        price: 1599.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/studio-display-tilt-1?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1645034298834",
        category: "Displays",
        color: "Silver",
        in_stock: false
      },
      {
        id: 7,
        name: "Mac mini",
        description: "M2 Pro chip in a compact design",
        price: 1299.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mac-mini-hero-202301?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1670034116538",
        category: "Desktops",
        color: "Silver",
        in_stock: true
      },
      {
        id: 8,
        name: "Magic Keyboard",
        description: "Wireless keyboard with Touch ID",
        price: 199.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MMMR3?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1645719947833",
        category: "Accessories",
        color: "White",
        in_stock: true
      }
    ]
    
    # Simulate categories for filters
    @categories = [
      { id: 1, name: "Laptops" },
      { id: 2, name: "Phones" },
      { id: 3, name: "Tablets" },
      { id: 4, name: "Wearables" },
      { id: 5, name: "Audio" },
      { id: 6, name: "Displays" },
      { id: 7, name: "Desktops" },
      { id: 8, name: "Accessories" }
    ]
    
    @total_count = @products.count
  end
  
  def catalog
    # Same products but demonstrating different layout
    @products = index_products
    @featured_products = @products.first(3)
    @sale_products = @products.last(3)
  end
  
  private
  
  def index_products
    [
      {
        id: 1,
        name: "MacBook Pro 16\"",
        description: "Apple M3 Max chip with 16-core CPU and 40-core GPU",
        price: 3999.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp16-m3-max-202311-gallery-1?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1699048547510",
        category: "Laptops",
        color: "Space Gray",
        in_stock: true,
        featured: true
      },
      {
        id: 2,
        name: "iPhone 15 Pro",
        description: "Titanium design with A17 Pro chip",
        price: 999.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-finish-select-202309-6-1inch-titanium?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1692858839538",
        category: "Phones",
        color: "Titanium",
        in_stock: true,
        featured: true
      },
      {
        id: 3,
        name: "iPad Pro 12.9\"",
        description: "M2 chip, Liquid Retina XDR display",
        price: 1299.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/ipad-pro-13-select-wifi-spacegray-202405?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1713808374457",
        category: "Tablets",
        color: "Silver",
        in_stock: true,
        featured: true
      },
      {
        id: 4,
        name: "Apple Watch Ultra 2",
        description: "Rugged titanium case with precision GPS",
        price: 799.00,
        original_price: 899.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MT5J3ref_VW_34FR+watch-49-titanium-ultra2_VW_34FR+watch-face-49-alpine-ultra2_VW_34FR?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1694861343622",
        category: "Wearables",
        color: "Orange",
        in_stock: true,
        on_sale: true
      },
      {
        id: 5,
        name: "AirPods Pro",
        description: "Active Noise Cancellation and Adaptive Audio",
        price: 199.00,
        original_price: 249.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MQD83?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1678916533447",
        category: "Audio",
        color: "White",
        in_stock: true,
        on_sale: true
      },
      {
        id: 6,
        name: "Studio Display",
        description: "27-inch 5K Retina display",
        price: 1399.00,
        original_price: 1599.00,
        image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/studio-display-tilt-1?wid=600&hei=600&fmt=jpeg&qlt=95&.v=1645034298834",
        category: "Displays",
        color: "Silver",
        in_stock: false,
        on_sale: true
      }
    ]
  end
end
# Copyright 2025
