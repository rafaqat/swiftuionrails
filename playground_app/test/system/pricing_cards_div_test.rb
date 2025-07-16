require "application_system_test_case"

class PricingCardsDivTest < ApplicationSystemTestCase
  test "test div.relative syntax" do
    visit "/"
    
    # Wait for page to load
    sleep 2
    
    # Test div.relative syntax
    div_test_code = <<~RUBY
      swift_ui do
        card(elevation: 2) do
          div.relative do
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
        puts "SUCCESS: div.relative syntax works"
      else
        puts "FAIL: div.relative syntax doesn't work"
        puts "HTML: #{page.evaluate_script("document.getElementById('preview-container').innerHTML")}"
      end
    end
  end
end