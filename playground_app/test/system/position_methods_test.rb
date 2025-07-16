require "application_system_test_case"

class PositionMethodsTest < ApplicationSystemTestCase
  test "all position methods work with blocks" do
    visit "/"
    sleep 2
    
    # Test div.fixed do
    fixed_test_code = <<~RUBY
      swift_ui do
        div.fixed do
          text("Inside fixed div")
        end
      end
    RUBY
    
    page.execute_script("window.monacoEditorInstance.setValue(#{fixed_test_code.inspect})")
    sleep 1
    
    within "#preview-container" do
      assert_text "Inside fixed div", wait: 5
    end
    
    puts "✅ div.fixed do works"
    
    # Test div.sticky do
    sticky_test_code = <<~RUBY
      swift_ui do
        div.sticky do
          text("Inside sticky div")
        end
      end
    RUBY
    
    page.execute_script("window.monacoEditorInstance.setValue(#{sticky_test_code.inspect})")
    sleep 1
    
    within "#preview-container" do
      assert_text "Inside sticky div", wait: 5
    end
    
    puts "✅ div.sticky do works"
  end
end