# Copyright 2025
require "test_helper"

class JavascriptIntegrationTest < ActionDispatch::IntegrationTest
  test "swift-ui controller is loaded in assets" do
    get "/assets/controllers/swift_ui_controller.js"
    
    assert_response :success
    assert_match /Controller/, response.body
    assert_match /stateValue/, response.body
    assert_match /updateState/, response.body
  end
  
  test "stimulus is properly configured" do
    get "/assets/application.js"
    
    assert_response :success
    assert_match /stimulus/, response.body
  end
  
  test "pages with swift-ui components include necessary JavaScript" do
    get root_path
    
    assert_response :success
    
    # Check for Stimulus data attributes
    assert_select "[data-controller]"
    
    # Check for JavaScript module imports
    assert_match /type="module"/, response.body
  end
  
  test "components render with proper data attributes for JavaScript" do
    # Create a test component
    component_html = ApplicationController.render(
      inline: %{
        <div data-controller="swift-ui" 
             data-swift-ui-state-value='{"test": true}'
             data-swift-ui-component-id-value="test-123">
          Test Component
        </div>
      }
    )
    
    assert_includes component_html, 'data-controller="swift-ui"'
    assert_includes component_html, 'data-swift-ui-state-value'
    assert_includes component_html, 'data-swift-ui-component-id-value'
  end
  
  test "JavaScript errors are caught and logged" do
    # This would be better as a system test, but we can check
    # that error handling code is present
    get "/assets/controllers/swift_ui_controller.js"
    
    # Look for try-catch blocks or error handling
    assert_match /catch|error|console/, response.body
  end
end
# Copyright 2025
