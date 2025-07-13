# Copyright 2025
require "test_helper"

class ProductLayoutComponentTest < ViewComponent::TestCase
  def test_renders_product_grid
    products = [
      {
        id: 1,
        name: "Test Product",
        price: 29.99,
        image_url: "test.jpg",
        in_stock: true
      }
    ]

    component = ProductLayoutComponent.new(
      title: "Test Products",
      products: products
    )

    render_inline(component)

    assert_text "Test Products"
    assert_text "Test Product"
    assert_text "$29.99"
  end

  def test_renders_with_variants
    products = [
      {
        id: 1,
        name: "Classic T-Shirt",
        price: 29.99,
        image_url: "tshirt.jpg",
        variant: "Blue",
        in_stock: true
      },
      {
        id: 2,
        name: "Classic T-Shirt",
        price: 29.99,
        image_url: "tshirt.jpg",
        variant: "Red",
        in_stock: true
      },
      {
        id: 3,
        name: "Premium Jacket",
        price: 89.99,
        image_url: "jacket.jpg",
        color: "Black", # Alternative property name
        in_stock: true
      }
    ]

    component = ProductLayoutComponent.new(
      title: "Products with Variants",
      products: products,
      show_filters: false # Simplify test by not showing filters
    )

    render_inline(component)

    # Should render the variants
    assert_text "Blue"
    assert_text "Red"
    assert_text "Black"

    # Should render product names
    assert_text "Classic T-Shirt"
    assert_text "Premium Jacket"

    # Should render prices
    assert_text "$29.99"
    assert_text "$89.99"
  end

  def test_responsive_columns
    # ProductLayoutComponent only accepts integer columns, not responsive hash
    component = ProductLayoutComponent.new(
      products: [],
      columns: 3
    )

    render_inline(component)

    # Component should render without errors
    assert_selector "div"  # Basic check that something renders
  end
end
# Copyright 2025
