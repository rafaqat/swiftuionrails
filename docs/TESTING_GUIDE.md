# Testing Guide

## Component Testing with RSpec

### Basic Component Test
```ruby
# spec/components/button_component_spec.rb
require "rails_helper"

RSpec.describe ButtonComponent, type: :component do
  it "renders with default props" do
    component = described_class.new(text: "Click me")
    
    render_inline(component)
    
    expect(page).to have_css("button", text: "Click me")
    expect(page).to have_css(".bg-blue-500")
    expect(page).to have_css(".text-white")
  end
  
  it "accepts custom styling" do
    component = described_class.new(
      text: "Custom",
      variant: :secondary
    )
    
    render_inline(component)
    
    expect(page).to have_css(".bg-gray-500")
  end
  
  it "includes Stimulus data attributes" do
    component = described_class.new(
      text: "Action",
      action: "click->form#submit"
    )
    
    render_inline(component)
    
    expect(page).to have_css('[data-action="click->form#submit"]')
  end
end
```

### Testing Components with Slots
```ruby
RSpec.describe CardComponent, type: :component do
  it "renders with header and content slots" do
    render_inline(described_class.new(title: "Card")) do |card|
      card.with_header { "Custom Header" }
      card.with_content { "Card body content" }
    end
    
    expect(page).to have_text("Custom Header")
    expect(page).to have_text("Card body content")
  end
  
  it "uses title prop when no header slot provided" do
    render_inline(described_class.new(title: "Default Title")) do |card|
      card.with_content { "Content" }
    end
    
    expect(page).to have_text("Default Title")
  end
end
```

### Testing Collections with ViewComponent 2.0
```ruby
RSpec.describe ProductCardComponent, type: :component do
  let(:products) do
    [
      { name: "Product 1", price: 10.00 },
      { name: "Product 2", price: 20.00 }
    ]
  end
  
  it "renders collection efficiently" do
    # Use with_collection for performance
    components = described_class.with_collection(products)
    
    render_inline(components)
    
    expect(page).to have_text("Product 1")
    expect(page).to have_text("Product 2")
    expect(page).to have_text("$10.00")
    expect(page).to have_text("$20.00")
  end
end
```

## System Testing with Capybara

### Testing Stimulus Interactions
```ruby
# test/system/counter_test.rb
class CounterTest < ApplicationSystemTestCase
  test "counter increments and decrements" do
    visit root_path
    
    # Initial state
    within "[data-controller='counter']" do
      assert_text "0"
    end
    
    # Increment
    click_button "+"
    within "[data-counter-target='count']" do
      assert_text "1"
    end
    
    # Decrement
    click_button "-"
    within "[data-counter-target='count']" do
      assert_text "0"
    end
  end
  
  test "counter respects step value" do
    visit counter_path(step: 5)
    
    click_button "+"
    assert_text "5"
    
    click_button "+"
    assert_text "10"
  end
end
```

### Testing Turbo Interactions
```ruby
class ProductsTest < ApplicationSystemTestCase
  test "filters update via Turbo without page reload" do
    visit products_path
    
    # Apply filter
    select "Electronics", from: "Category"
    
    # Turbo Frame updates without page reload
    within "#products" do
      assert_text "iPhone"
      assert_no_text "Book"
    end
    
    # URL updates for bookmarkability
    assert_equal "/products?category=electronics", current_path
  end
  
  test "pagination works with Turbo morphing" do
    visit products_path
    
    # Click next page
    within ".pagination" do
      click_link "2"
    end
    
    # Content updates smoothly
    assert_text "Page 2"
    assert_no_text "Page 1"
  end
end
```

## Testing Best Practices

1. **Test the DSL Output, Not Implementation**
   ```ruby
   # Good
   expect(page).to have_css(".bg-blue-500")
   expect(page).to have_css("[data-controller='toggle']")
   
   # Avoid
   expect(component.instance_variable_get(:@color)).to eq("blue-500")
   ```

2. **Use Factories for Complex Props**
   ```ruby
   let(:product_props) do
     {
       name: "Test Product",
       price: 99.99,
       image_url: "/test.jpg",
       in_stock: true
     }
   end
   
   it "renders product correctly" do
     render_inline(ProductCardComponent.new(**product_props))
     # assertions...
   end
   ```

3. **Test Stimulus Controllers Separately**
   ```javascript
   // test/javascript/controllers/counter_controller_test.js
   import { Application } from "@hotwired/stimulus"
   import CounterController from "counter_controller"
   
   describe("CounterController", () => {
     beforeEach(() => {
       document.body.innerHTML = `
         <div data-controller="counter"
              data-counter-count-value="0"
              data-counter-step-value="1">
           <span data-counter-target="count"></span>
           <button data-action="click->counter#increment">+</button>
         </div>
       `
       
       const application = Application.start()
       application.register("counter", CounterController)
     })
     
     it("increments count", () => {
       const button = document.querySelector("button")
       const count = document.querySelector("[data-counter-target='count']")
       
       button.click()
       
       expect(count.textContent).toBe("1")
     })
   })
   ```