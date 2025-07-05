require "test_helper"

class ProductCardComponentTest < ViewComponent::TestCase
  def test_renders_basic_product
    product = {
      id: 1,
      name: "Test Product",
      price: 29.99,
      image_url: "test.jpg",
      in_stock: true
    }
    
    component = ProductCardComponent.new(product: product)
    render_inline(component)
    
    assert_text "Test Product"
    assert_text "$29.99"
  end
  
  def test_renders_out_of_stock
    product = {
      id: 1,
      name: "Test Product",
      price: 29.99,
      in_stock: false
    }
    
    component = ProductCardComponent.new(product: product)
    render_inline(component)
    
    assert_text "Out of Stock"
  end
end
# Copyright 2025
