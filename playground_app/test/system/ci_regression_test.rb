require "application_system_test_case"

# CI Regression Test Suite for SwiftUI Rails Playground
# This test ensures all sidebar components render without errors
# and can be run in CI/CD pipelines for regression detection

class CiRegressionTest < ApplicationSystemTestCase
  # Configure for headless CI environments
  def setup
    # Use headless Chrome for CI
    if ENV['CI'] || ENV['HEADLESS']
      Capybara.current_driver = :selenium_chrome_headless
    end
    
    # Set stable timeouts for CI
    Capybara.default_max_wait_time = 10
    
    visit "/"
    sleep 2 # Allow initial page load
  end

  # Test that all sidebar components render without syntax errors
  test "all sidebar components render without errors" do
    # Components to test (name => [expected_text_content])
    components = {
      "Text" => ["Hello World"],
      "Button" => ["Click Me"],
      "VStack" => ["Item 1", "Item 2", "Item 3"],
      "HStack" => ["Left", "Center", "Right"],
      "Grid" => ["Grid Item 1", "Grid Item 2"],
      "Card" => ["Card Title", "Card content"],
      "Dashboard Stats" => ["Total Revenue", "$45,678"],
      "Pricing Cards" => ["Starter", "Professional", "Enterprise"],
      "Layout Demo" => ["HStack Justification Examples"],
      "Simple Table" => ["John Doe", "jane@example.com"],
      "Data Table" => ["User Management", "John Doe"],
      "Sales Report" => ["iPhone 15", "MacBook Pro"],
      "Employee Directory" => ["Sarah Connor", "John Matrix"]
    }
    
    failed_components = []
    
    components.each do |component_name, expected_texts|
      begin
        # Click component button
        click_button component_name
        sleep 1
        
        # Check for error messages
        if page.has_css?("#preview-container .playground-error")
          error_msg = find("#preview-container .playground-error").text
          failed_components << "#{component_name}: #{error_msg}"
          next
        end
        
        # Verify expected content renders
        within "#preview-container" do
          expected_texts.each do |expected_text|
            assert_text expected_text, wait: 5
          end
        end
        
      rescue => e
        failed_components << "#{component_name}: #{e.message}"
      end
    end
    
    # Report results
    if failed_components.any?
      puts "\n❌ CI Regression Test Failed:"
      failed_components.each { |failure| puts "  - #{failure}" }
      flunk "#{failed_components.length} components failed regression test"
    else
      puts "\n✅ All components passed CI regression test"
    end
  end
  
  # Test that critical DSL syntax fixes work
  test "critical DSL syntax fixes work" do
    critical_syntax_tests = [
      {
        name: "div.relative with block",
        code: <<~'RUBY',
          swift_ui do
            div.relative do
              text("Relative content")
            end
          end
        RUBY
        expected: "Relative content"
      },
      {
        name: "div.absolute with block", 
        code: <<~'RUBY',
          swift_ui do
            div.absolute do
              text("Absolute content")
            end
          end
        RUBY
        expected: "Absolute content"
      },
      {
        name: "div.fixed with block",
        code: <<~'RUBY',
          swift_ui do
            div.fixed do
              text("Fixed content")
            end
          end
        RUBY
        expected: "Fixed content"
      },
      {
        name: "span with block (not positional args)",
        code: <<~'RUBY',
          swift_ui do
            span do
              text("Span content")
            end
          end
        RUBY
        expected: "Span content"
      }
    ]
    
    failed_syntax = []
    
    critical_syntax_tests.each do |test|
      begin
        # Set code in Monaco editor
        page.execute_script("window.monacoEditorInstance.setValue(#{test[:code].inspect})")
        sleep 1
        
        # Check if it renders without error
        if page.has_css?("#preview-container .playground-error")
          error_msg = find("#preview-container .playground-error").text
          failed_syntax << "#{test[:name]}: #{error_msg}"
          next
        end
        
        # Verify expected content
        within "#preview-container" do
          assert_text test[:expected], wait: 5
        end
        
      rescue => e
        failed_syntax << "#{test[:name]}: #{e.message}"
      end
    end
    
    # Report results
    if failed_syntax.any?
      puts "\n❌ Critical DSL syntax tests failed:"
      failed_syntax.each { |failure| puts "  - #{failure}" }
      flunk "#{failed_syntax.length} critical syntax tests failed"
    else
      puts "\n✅ All critical DSL syntax tests passed"
    end
  end
  
  # Test that table DSL components work (user requested focus)
  test "table DSL components showcase correctly" do
    table_tests = [
      {
        name: "Simple Table",
        expected: ["Name", "Role", "Email", "John Doe", "Jane Smith"]
      },
      {
        name: "Data Table", 
        expected: ["User Management", "Name", "Role", "John Doe", "Admin"]
      },
      {
        name: "Sales Report",
        expected: ["Q1 2024 Sales Report", "iPhone 15", "MacBook Pro", "AirPods Pro"]
      },
      {
        name: "Employee Directory",
        expected: ["Company Directory", "Sarah Connor", "Engineering", "Senior Developer"]
      }
    ]
    
    failed_tables = []
    
    table_tests.each do |test|
      begin
        # Click table component (use first to avoid ambiguity)
        first(:button, test[:name]).click
        sleep 2 # Tables may take longer to render
        
        # Check for errors
        if page.has_css?("#preview-container .playground-error")
          error_msg = find("#preview-container .playground-error").text
          failed_tables << "#{test[:name]}: #{error_msg}"
          next
        end
        
        # Verify table content
        within "#preview-container" do
          test[:expected].each do |expected_text|
            assert_text expected_text, wait: 5
          end
        end
        
      rescue => e
        failed_tables << "#{test[:name]}: #{e.message}"
      end
    end
    
    if failed_tables.any?
      puts "\n❌ Table DSL tests failed:"
      failed_tables.each { |failure| puts "  - #{failure}" }
      flunk "#{failed_tables.length} table DSL tests failed"
    else
      puts "\n✅ All table DSL components work correctly"
    end
  end
end