# frozen_string_literal: true

require "application_system_test_case"

class SidebarComponentsValidationTest < ApplicationSystemTestCase
  # Test each sidebar component to ensure they work properly
  
  def test_all_sidebar_components_render_correctly
    visit root_path
    
    # Wait for page to load
    assert_selector "[data-controller='playground']", wait: 10
    
    # Test each component from the sidebar
    test_text_component
    test_button_component
    test_image_component
    test_vstack_component
    test_hstack_component
    test_card_component
    test_list_component
    test_grid_component
    test_form_component
    test_textfield_component
    test_table_components
  end
  
  private
  
  def test_text_component
    code = 'text("Your text here")
  .font_size("xl")
  .font_weight("semibold")
  .text_color("gray-800")
  .text_align("left")
  .leading("relaxed")'
    
    test_component_code("Text", code)
  end
  
  def test_button_component
    code = 'button("Click Me")
  .bg("blue-500")
  .text_color("white")
  .px(4).py(2)
  .rounded("lg")
  .data(action: "click->controller#method")'
    
    test_component_code("Button", code)
  end
  
  def test_image_component
    code = 'image(src: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop", alt: "Beautiful sunflower")'
    
    test_component_code("Image", code)
  end
  
  def test_vstack_component
    code = 'vstack(spacing: 16) do
  text("Item 1")
  text("Item 2")
  text("Item 3")
end'
    
    test_component_code("VStack", code)
  end
  
  def test_hstack_component
    code = 'hstack(justify: :between) do
  text("Left")
  text("Right")
end'
    
    test_component_code("HStack", code)
  end
  
  def test_card_component
    code = 'card(elevation: 2) do
  text("Card content")
  text("More content")
end'
    
    test_component_code("Card", code)
  end
  
  def test_list_component
    code = 'list do
  (1..5).each do |i|
    list_item { text("Item #{i}") }
  end
end'
    
    test_component_code("List", code)
  end
  
  def test_grid_component
    # Test the WRONG syntax first to see if it fails
    wrong_code = 'grid(cols: 3, gap: 16) do
  # Add grid items here
end'
    
    puts "Testing WRONG grid syntax..."
    test_component_code_expect_error("Grid (Wrong)", wrong_code)
    
    # Now test the CORRECT syntax
    correct_code = 'grid(columns: 3, spacing: 16) do
  (1..6).each do |i|
    card(elevation: 1) do
      text("Grid Item #{i}")
    end
  end
end'
    
    puts "Testing CORRECT grid syntax..."
    test_component_code("Grid (Correct)", correct_code)
  end
  
  def test_form_component
    code = 'form(action: "#", method: :post) do
  textfield(name: "email", placeholder: "Enter email")
  button("Submit", type: "submit")
end'
    
    test_component_code("Form", code)
  end
  
  def test_textfield_component
    code = 'textfield(name: "email", placeholder: "Enter email")'
    
    test_component_code("TextField", code)
  end
  
  def test_table_components
    simple_table_code = 'simple_table(
  headers: ["Name", "Role", "Status"],
  rows: [
    ["John Doe", "Admin", "Active"],
    ["Jane Smith", "User", "Inactive"]
  ]
)'
    
    test_component_code("Simple Table", simple_table_code)
    
    data_table_code = 'data_table(
  title: "Users",
  data: [
    { name: "John", role: "Admin", status: "Active" },
    { name: "Jane", role: "User", status: "Inactive" }
  ],
  columns: [
    { key: :name, label: "Name" },
    { key: :role, label: "Role", format: :badge },
    { key: :status, label: "Status", format: :badge }
  ]
)'
    
    test_component_code("Data Table", data_table_code)
  end
  
  def test_component_code(component_name, code)
    puts "Testing #{component_name} component..."
    
    # Send POST request to preview endpoint
    page.driver.post("/playground/preview", { code: code })
    
    if page.status_code == 200
      response_body = page.body
      
      # Check for error indicators
      if response_body.include?("error") || response_body.include?("Error") || response_body.include?("undefined")
        puts "❌ #{component_name} FAILED - Error in response"
        puts "Response: #{response_body[0..200]}..."
        assert false, "#{component_name} component failed to render"
      else
        puts "✅ #{component_name} rendered successfully"
        # Should contain HTML elements
        assert response_body.include?("<"), "#{component_name} should generate HTML"
      end
    else
      puts "❌ #{component_name} FAILED - HTTP #{page.status_code}"
      assert false, "#{component_name} component failed with status #{page.status_code}"
    end
  end
  
  def test_component_code_expect_error(component_name, code)
    puts "Testing #{component_name} component (expecting error)..."
    
    # Send POST request to preview endpoint
    page.driver.post("/playground/preview", { code: code })
    
    if page.status_code == 200
      response_body = page.body
      
      # Check for error indicators - we EXPECT an error
      if response_body.include?("error") || response_body.include?("Error") || response_body.include?("undefined")
        puts "✅ #{component_name} correctly failed as expected"
      else
        puts "⚠️ #{component_name} unexpectedly succeeded - response: #{response_body[0..200]}..."
      end
    else
      puts "✅ #{component_name} correctly failed with HTTP #{page.status_code}"
    end
  end
end