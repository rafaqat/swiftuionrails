require "application_system_test_case"

class ComprehensiveSidebarCiTest < ApplicationSystemTestCase
  # This test suite is designed to run in CI/CD pipelines
  # It tests all sidebar components and examples to ensure they render properly
  # and don't break with DSL changes
  
  SIDEBAR_COMPONENTS = [
    # Basic Components
    { name: "Text", expected_content: ["Hello World"] },
    { name: "Button", expected_content: ["Click me"] },
    { name: "Image", expected_content: [], check_selector: "img[src*='placeholder']" },
    
    # Layout Components
    { name: "VStack", expected_content: ["Item 1", "Item 2", "Item 3"] },
    { name: "HStack", expected_content: ["Left", "Center", "Right"] },
    { name: "Grid", expected_content: ["Grid Item 1", "Grid Item 2", "Grid Item 3"] },
    { name: "Card", expected_content: ["Card Title", "Card content"] },
    
    # Form Components
    { name: "Form", expected_content: ["Submit"] },
    { name: "TextField", expected_content: ["Name"] },
    
    # Table Components
    { name: "Simple Table", expected_content: ["Name", "Email", "Role"] },
    { name: "Data Table", expected_content: ["User Management", "Name", "Email"] },
    { name: "Table", expected_content: ["Header 1", "Header 2", "Header 3"] }
  ]
  
  EXAMPLE_COMPONENTS = [
    { name: "Layout Demo", expected_content: ["HStack Justification Examples", "justify: :start"] },
    { name: "Product Grid", expected_content: ["Product 1", "Product 2", "Quick View"] },
    { name: "Dashboard Stats", expected_content: ["Total Revenue", "$45,678", "+12.5%"] },
    { name: "Pricing Cards", expected_content: ["Starter", "Professional", "Enterprise", "Most Popular"] },
    { name: "Todo List", expected_content: ["My Tasks", "What needs to be done?"] },
    { name: "Navbar", expected_content: ["SwiftUI Rails", "Home", "Components"] },
    { name: "Simple Table", expected_content: ["Simple Table Example", "John Doe", "jane@example.com"] },
    { name: "Data Table", expected_content: ["Advanced Data Table", "User Management", "John Doe"] },
    { name: "Sales Report", expected_content: ["Sales Report Table", "iPhone 15", "MacBook Pro"] },
    { name: "Employee Directory", expected_content: ["Employee Directory", "Sarah Connor", "John Matrix"] }
  ]
  
  def setup
    # Use headless browser for CI
    Capybara.current_driver = :selenium_chrome_headless
    
    # Set longer wait times for CI stability
    Capybara.default_max_wait_time = 10
    
    # Visit the playground once
    visit "/"
    sleep 2 # Wait for initial load
  end
  
  test "all sidebar components render without errors" do
    puts "\n🔍 Testing all sidebar components for CI..."
    
    failed_components = []
    
    SIDEBAR_COMPONENTS.each do |component|
      print "Testing #{component[:name]}... "
      
      begin
        # Click the component
        click_button component[:name]
        sleep 1
        
        # Check for errors
        if page.has_css?("#preview-container .playground-error")
          error_text = find("#preview-container .playground-error").text
          failed_components << "#{component[:name]}: #{error_text}"
          puts "❌ ERROR"
          next
        end
        
        # Check expected content
        within "#preview-container" do
          if component[:check_selector]
            # Check for specific selector
            assert_selector component[:check_selector], wait: 5
          else
            # Check for expected text content
            component[:expected_content].each do |expected|
              assert_text expected, wait: 5
            end
          end
        end
        
        puts "✅ PASS"
        
      rescue => e
        failed_components << "#{component[:name]}: #{e.message}"
        puts "❌ FAIL"
      end
    end
    
    # Check examples
    EXAMPLE_COMPONENTS.each do |component|
      print "Testing #{component[:name]}... "
      
      begin
        # Click the component
        click_button component[:name]
        sleep 1
        
        # Check for errors
        if page.has_css?("#preview-container .playground-error")
          error_text = find("#preview-container .playground-error").text
          failed_components << "#{component[:name]}: #{error_text}"
          puts "❌ ERROR"
          next
        end
        
        # Check expected content
        within "#preview-container" do
          component[:expected_content].each do |expected|
            assert_text expected, wait: 5
          end
        end
        
        puts "✅ PASS"
        
      rescue => e
        failed_components << "#{component[:name]}: #{e.message}"
        puts "❌ FAIL"
      end
    end
    
    # Report results
    total_components = SIDEBAR_COMPONENTS.length + EXAMPLE_COMPONENTS.length
    passed_components = total_components - failed_components.length
    
    puts "\n📊 CI Test Results:"
    puts "✅ Passed: #{passed_components}/#{total_components}"
    puts "❌ Failed: #{failed_components.length}/#{total_components}"
    
    if failed_components.any?
      puts "\n💥 Failed Components:"
      failed_components.each { |failure| puts "   - #{failure}" }
    end
    
    # Fail the test if any components failed
    assert failed_components.empty?, "#{failed_components.length} components failed CI tests"
  end
  
  test "div.relative block syntax works correctly" do
    puts "\n🔍 Testing div.relative block syntax fix..."
    
    # Test the div.relative syntax that was broken
    div_relative_code = <<~RUBY
      swift_ui do
        div.relative do
          text("Content inside relative div")
          
          div.absolute.top(2).right(2) do
            text("Absolute positioned")
          end
        end
      end
    RUBY
    
    # Set the code in Monaco
    page.execute_script("window.monacoEditorInstance.setValue(#{div_relative_code.inspect})")
    
    # Wait for preview to update
    sleep 2
    
    # Check if it renders correctly
    within "#preview-container" do
      assert_text "Content inside relative div", wait: 5
      assert_text "Absolute positioned", wait: 5
    end
    
    puts "✅ div.relative block syntax works correctly"
  end
  
  test "method chaining with blocks works for all position methods" do
    puts "\n🔍 Testing method chaining with blocks..."
    
    # Test all position methods that should support blocks
    position_methods = %w[relative absolute fixed sticky]
    
    position_methods.each do |method|
      print "Testing div.#{method} do... "
      
      test_code = <<~RUBY
        swift_ui do
          div.#{method} do
            text("Inside #{method} div")
          end
        end
      RUBY
      
      # Set the code in Monaco
      page.execute_script("window.monacoEditorInstance.setValue(#{test_code.inspect})")
      
      # Wait for preview to update
      sleep 1
      
      # Check if it renders correctly
      within "#preview-container" do
        assert_text "Inside #{method} div", wait: 5
      end
      
      puts "✅"
    end
  end
  
  private
  
  def wait_for_stable_page
    # Wait for any pending JS to complete
    sleep 0.5
    
    # Wait for any animations/transitions
    page.execute_script("return new Promise(resolve => setTimeout(resolve, 100))")
  end
end