require "application_system_test_case"

class PricingCardsChainingTest < ApplicationSystemTestCase
  test "test div chaining with block" do
    visit "/"
    
    # Wait for page to load
    sleep 2
    
    # Test different div syntax
    div_test_code = <<~RUBY
      swift_ui do
        card(elevation: 2) do
          div(class: "relative") do
            text("Inside relative div")
          end
        end
      end
    RUBY
    
    # Set the code in Monaco
    page.execute_script("window.monacoEditorInstance.setValue(#{div_test_code.inspect})")
    
    # Wait for preview to update
    sleep 2
    
    # Check if it renders
    within "#preview-container" do
      puts "Preview content: #{page.text}"
      
      if page.has_text?("Inside relative div")
        puts "SUCCESS: div(class: 'relative') syntax works"
      else
        puts "FAIL: div(class: 'relative') syntax doesn't work"
        puts "HTML: #{page.evaluate_script("document.getElementById('preview-container').innerHTML")}"
      end
    end
  end
end