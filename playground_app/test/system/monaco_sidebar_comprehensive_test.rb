# frozen_string_literal: true

require "application_system_test_case"

class MonacoSidebarComprehensiveTest < ApplicationSystemTestCase
  # Test every single sidebar component by sending code to Monaco and checking render
  
  def test_all_sidebar_components_monaco_to_render
    visit root_path
    
    # Wait for playground to load
    assert_selector "[data-controller='playground']", wait: 10
    
    # Wait for Monaco editor to be ready
    wait_for_monaco_editor
    
    # Get all sidebar components and test each one
    test_all_basic_components
    test_all_layout_components
    test_all_form_components
    test_all_table_components
    test_all_example_components
    
    puts "\n🎯 All sidebar components tested successfully!"
  end
  
  private
  
  def wait_for_monaco_editor
    puts "⏳ Waiting for Monaco editor to load..."
    # Wait for Monaco container to be present
    assert_selector "#monaco-editor", wait: 15
    
    # Wait a bit for Monaco to initialize
    sleep 5
    
    # Check if Monaco is ready
    monaco_ready = page.evaluate_script("
      typeof window.monacoEditorInstance !== 'undefined' && 
      window.monacoEditorInstance !== null
    ")
    
    if monaco_ready
      puts "✅ Monaco editor is ready"
    else
      puts "⚠️ Monaco editor may not be fully loaded, but continuing..."
      sleep 3  # Give it more time
    end
  end
  
  def test_all_basic_components
    puts "\n🔍 Testing Basic Components..."
    
    # Test Text component
    test_component_with_monaco(
      "Text",
      'text("Your text here")
  .font_size("xl")
  .font_weight("semibold")
  .text_color("gray-800")
  .text_align("left")
  .leading("relaxed")',
      ["Your text here"]
    )
    
    # Test Button component
    test_component_with_monaco(
      "Button",
      'button("Click Me")
  .bg("blue-500")
  .text_color("white")
  .px(4).py(2)
  .rounded("lg")
  .data(action: "click->controller#method")',
      ["Click Me", "button"]
    )
    
    # Test Image component
    test_component_with_monaco(
      "Image",
      'image(src: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop", alt: "Beautiful sunflower")',
      ["img", "Beautiful sunflower"]
    )
  end
  
  def test_all_layout_components
    puts "\n🔍 Testing Layout Components..."
    
    # Test VStack component
    test_component_with_monaco(
      "VStack",
      'vstack(spacing: 16) do
  text("First Item")
  text("Second Item")
  text("Third Item")
end',
      ["First Item", "Second Item", "Third Item"]
    )
    
    # Test HStack component
    test_component_with_monaco(
      "HStack",
      'hstack(justify: :between) do
  text("Left")
  text("Right")
end',
      ["Left", "Right"]
    )
    
    # Test Grid component - the CORRECTED one
    test_component_with_monaco(
      "Grid",
      'grid(columns: 3, spacing: 16) do
  (1..6).each do |i|
    card(elevation: 1) do
      text("Grid Item #{i}")
    end
  end
end',
      ["Grid Item 1", "Grid Item 2", "Grid Item 3", "Grid Item 4", "Grid Item 5", "Grid Item 6"]
    )
  end
  
  def test_all_form_components
    puts "\n🔍 Testing Form Components..."
    
    # Test Form component
    test_component_with_monaco(
      "Form",
      'form(action: "#", method: :post) do
  textfield(name: "email", placeholder: "Enter email")
    .w("full")
    .mb(4)
  button("Submit", type: "submit")
    .bg("blue-500")
    .text_color("white")
    .px(4).py(2)
    .rounded("lg")
end',
      ["form", "Enter email", "Submit"]
    )
    
    # Test TextField component
    test_component_with_monaco(
      "TextField",
      'textfield(name: "email", placeholder: "Enter email")',
      ["input", "Enter email"]
    )
  end
  
  def test_all_table_components
    puts "\n🔍 Testing Table Components..."
    
    # Test Simple Table component
    test_component_with_monaco(
      "Simple Table",
      'simple_table(
  headers: ["Name", "Role", "Status"],
  rows: [
    ["John Doe", "Admin", "Active"],
    ["Jane Smith", "User", "Inactive"]
  ]
)',
      ["table", "Name", "Role", "Status", "John Doe", "Admin", "Active", "Jane Smith", "User", "Inactive"]
    )
    
    # Test Data Table component
    test_component_with_monaco(
      "Data Table",
      'data_table(
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
)',
      ["table", "Users", "Name", "Role", "Status", "John", "Admin", "Active", "Jane", "User", "Inactive"]
    )
    
    # Test raw Table component
    test_component_with_monaco(
      "Table",
      'table do
  thead do
    tr do
      th { text("Header") }
    end
  end
  tbody do
    tr do
      td { text("Data") }
    end
  end
end',
      ["table", "thead", "tbody", "Header", "Data"]
    )
  end
  
  def test_all_example_components
    puts "\n🔍 Testing Example Components..."
    
    # Test Layout Demo
    test_example_with_monaco(
      "Layout Demo",
      ["HStack Justification Examples", "justify: :start", "justify: :center", "justify: :between", "justify: :around", "justify: :evenly"]
    )
    
    # Test Product Grid
    test_example_with_monaco(
      "Product Grid",
      ["Premium Product", "grid", "Quick View"]
    )
    
    # Test Dashboard Stats
    test_example_with_monaco(
      "Dashboard Stats",
      ["Total Revenue", "Active Users", "$45,678", "grid"]
    )
    
    # Test Pricing Cards
    test_example_with_monaco(
      "Pricing Cards",
      ["Starter", "Professional", "Enterprise", "Most Popular", "Get Started"]
    )
    
    # Test Todo List
    test_example_with_monaco(
      "Todo List",
      ["My Tasks", "What needs to be done?"]
    )
    
    # Test Navigation Bar
    test_example_with_monaco(
      "Navigation Bar",
      ["SwiftUI Rails", "Home", "Components", "Documentation"]
    )
    
    # Test NEW Table Examples
    test_example_with_monaco(
      "Simple Table",
      ["Simple Table Example", "Name", "Role", "Email", "Status", "John Doe"]
    )
    
    test_example_with_monaco(
      "Data Table",
      ["Advanced Data Table", "User Management", "Add User", "Search users..."]
    )
    
    test_example_with_monaco(
      "Sales Report",
      ["Sales Report Table", "Q1 2024 Sales Report", "iPhone 15", "Revenue", "Growth %"]
    )
    
    test_example_with_monaco(
      "Employee Directory",
      ["Employee Directory", "Company Directory", "Sarah Connor", "Engineering", "Salary"]
    )
  end
  
  def test_component_with_monaco(component_name, code, expected_content)
    puts "  🧪 Testing #{component_name}..."
    
    # Clear Monaco editor
    clear_monaco_editor
    
    # Send code to Monaco
    set_monaco_code(code)
    
    # Wait for preview to update
    wait_for_preview_update
    
    # Check if content renders correctly
    expected_content.each do |content|
      assert_preview_contains(content, component_name)
    end
    
    puts "    ✅ #{component_name} rendered successfully"
  end
  
  def test_example_with_monaco(example_name, expected_content)
    puts "  🧪 Testing #{example_name} example..."
    
    # Click on the example in the sidebar
    click_on_example(example_name)
    
    # Wait for Monaco to be updated with example code
    wait_for_monaco_update
    
    # Wait for preview to update
    wait_for_preview_update
    
    # Check if content renders correctly
    expected_content.each do |content|
      assert_preview_contains(content, example_name)
    end
    
    puts "    ✅ #{example_name} example rendered successfully"
  end
  
  def clear_monaco_editor
    # Clear Monaco editor content
    page.evaluate_script("
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue('');
      }
    ")
    sleep 0.5
  end
  
  def set_monaco_code(code)
    # Set Monaco editor content
    escaped_code = code.gsub("'", "\\'").gsub("\n", "\\n")
    page.evaluate_script("
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue('#{escaped_code}');
        window.monacoEditorInstance.trigger('editor', 'editor.action.formatDocument');
      }
    ")
    sleep 1
  end
  
  def click_on_example(example_name)
    # Find and click on the example in the sidebar
    begin
      within("[data-playground-target='examplesContainer']") do
        click_on example_name
      end
    rescue Capybara::ElementNotFound
      # If not found in examples, try in components
      begin
        within("[data-playground-target='componentsContainer']") do
          click_on example_name
        end
      rescue Capybara::ElementNotFound
        # Try to find it anywhere in the sidebar
        within(".playground-sidebar") do
          click_on example_name
        end
      end
    end
    sleep 1
  end
  
  def wait_for_monaco_update
    # Wait for Monaco to update with new content
    sleep 2
  end
  
  def wait_for_preview_update
    # Wait for preview to update
    sleep 2
  end
  
  def assert_preview_contains(content, component_name)
    # Check if preview contains expected content
    within("#preview-container") do
      begin
        assert_text content, wait: 5
      rescue Capybara::ElementNotFound
        # If text not found, try checking HTML structure
        begin
          assert_selector "*", text: content, wait: 2
        rescue Capybara::ElementNotFound
          # Check if it's an HTML element we're looking for
          if ["table", "form", "input", "button", "img", "thead", "tbody", "grid"].include?(content)
            assert_selector content, wait: 2
          else
            # Final fallback: check HTML content
            preview_html = find("#preview-container").native.inner_html
            assert_includes preview_html, content, "#{component_name}: Expected preview to contain '#{content}'"
          end
        end
      end
    end
  end
end