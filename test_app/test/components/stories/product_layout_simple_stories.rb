# frozen_string_literal: true

class ProductLayoutSimpleStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Helpers
  
  # Simple story that renders ProductLayoutComponent with sample data
  def default
    products = [
      { name: "Basic Tee", variant: "Black", price: 35, image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg" },
      { name: "Basic Tee", variant: "White", price: 35, image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-01.jpg" },
      { name: "Nomad Tumbler", variant: "White", price: 35, image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-02.jpg" },
      { name: "Travel Mug", variant: "Black", price: 25, image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-03.jpg" }
    ]
    
    render ProductLayoutComponent.new(
      products: products,
      title: "Product Catalog",
      columns: 2,
      show_filters: false
    )
  end
  
  def with_filters
    products = generate_sample_products
    
    render ProductLayoutComponent.new(
      products: products,
      title: "Filtered Products",
      columns: 3,
      show_filters: true,
      filter_position: "top"
    )
  end
  
  def four_column_grid
    products = generate_sample_products
    
    render ProductLayoutComponent.new(
      products: products,
      title: "Four Column Layout",
      columns: 4,
      show_filters: false,
      show_sort: true
    )
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
end