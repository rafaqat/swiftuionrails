require "application_system_test_case"

class PricingCardsMinimalTest < ApplicationSystemTestCase
  test "test minimal pricing card" do
    visit "/"
    
    # Wait for page to load
    sleep 2
    
    # Inject a minimal pricing card test
    minimal_code = <<~RUBY
      swift_ui do
        card(elevation: 2) do
          text("Test Card")
        end
      end
    RUBY
    
    # Set the code in Monaco
    page.execute_script("window.monacoEditorInstance.setValue(#{minimal_code.inspect})")
    
    # Wait for preview to update
    sleep 2
    
    # Check if it renders
    within "#preview-container" do
      puts "Preview content: #{page.text}"
      
      if page.has_text?("Test Card")
        puts "SUCCESS: Minimal card works"
      else
        puts "FAIL: Minimal card doesn't work"
        puts "HTML: #{page.evaluate_script("document.getElementById('preview-container').innerHTML")}"
      end
    end
  end
end