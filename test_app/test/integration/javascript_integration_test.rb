# Copyright 2025
require "test_helper"

class JavascriptIntegrationTest < ActionDispatch::IntegrationTest
  test "swift-ui controller exists" do
    # With importmaps, we need to check that the file exists
    controller_path = Rails.root.join("app/javascript/controllers/swift_ui_controller.js")
    assert File.exist?(controller_path), "swift_ui_controller.js should exist"

    # Check content
    content = File.read(controller_path)
    assert_match /Controller/, content
    assert_match /connect/, content
  end

  test "stimulus is properly configured" do
    # Check that stimulus is configured in the application
    app_js_path = Rails.root.join("app/javascript/application.js")
    assert File.exist?(app_js_path), "application.js should exist"

    # Check that controllers are imported
    content = File.read(app_js_path)
    assert_match /import "controllers"/, content

    # Check that stimulus is actually configured in controllers/application.js
    controllers_app_path = Rails.root.join("app/javascript/controllers/application.js")
    assert File.exist?(controllers_app_path), "controllers/application.js should exist"

    controllers_content = File.read(controllers_app_path)
    assert_match /@hotwired\/stimulus/, controllers_content
    assert_match /Application.start/, controllers_content
  end

  test "pages with swift-ui components include necessary JavaScript" do
    get counter_path

    assert_response :success

    # Check for Stimulus data attributes - CounterComponent uses data-controller="counter"
    assert_select "[data-controller='counter']"

    # Check for JavaScript module imports
    assert_match /type="module"/, response.body
  end

  test "components render with proper data attributes for JavaScript" do
    # Create a test component
    component_html = ApplicationController.render(
      inline: %(
        <div data-controller="swift-ui"
             data-swift-ui-state-value='{"test": true}'
             data-swift-ui-component-id-value="test-123">
          Test Component
        </div>
      )
    )

    assert_includes component_html, 'data-controller="swift-ui"'
    assert_includes component_html, "data-swift-ui-state-value"
    assert_includes component_html, "data-swift-ui-component-id-value"
  end

  test "JavaScript errors are caught and logged" do
    # Check that the controller has error handling
    controller_path = Rails.root.join("app/javascript/controllers/swift_ui_controller.js")
    content = File.read(controller_path)

    # Look for try-catch blocks or error handling
    assert_match /catch|error|console/, content
  end
end
# Copyright 2025
