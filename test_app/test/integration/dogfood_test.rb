require "test_helper"

class DogfoodTest < ActionDispatch::IntegrationTest
  test "dogfood index page loads successfully" do
    get dogfood_path
    assert_response :success
    assert_select "h1", "SwiftUI Rails Playground"
  end

  test "component library page loads" do
    get dogfood_component_library_path
    assert_response :success
    assert_select "h1", "SwiftUI Rails Component Library"
  end

  test "patterns page loads" do
    get dogfood_patterns_path
    assert_response :success
    assert_select "h1", "SwiftUI Rails Patterns & Best Practices"
  end

  test "all dogfood examples render without errors" do
    require Rails.root.join("examples/playground_dogfood_examples.rb")
    
    PlaygroundDogfoodExamples.all_examples.each do |name, code|
      # Create a temporary component to test each example
      component_class = Class.new(ApplicationComponent) do
        include SwiftUIRails::DSL
        include SwiftUIRails::Helpers
        
        class_eval <<-RUBY
          def call
            #{code}
          end
        RUBY
      end
      
      # Ensure it renders without errors
      html = component_class.new.call.to_s
      assert html.present?, "Example #{name} should render HTML"
      assert_not html.include?("Error"), "Example #{name} should not contain errors"
    end
  end

  test "playground loads with new examples" do
    get playground_path
    assert_response :success
    
    # Check that new examples are included
    assert_match "Product Grid", response.body
    assert_match "Dashboard Stats", response.body
    assert_match "Pricing Cards", response.body
    assert_match "Todo List", response.body
    assert_match "Navigation Bar", response.body
  end
end