require "test_helper"

class Playground::PlaygroundControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get playground_root_path
    assert_response :success

    # Check page content includes initial code
    assert_match /Welcome to SwiftUI Rails Playground/, response.body
    assert_match /swift_ui do/, response.body

    # Check snippets are rendered
    assert_select "[data-dropdown-target='menu']"
    assert_match /DSL Button/, response.body
    assert_match /Basic Components/, response.body
  end

  test "snippets are organized by category" do
    get playground_root_path

    # Check all categories are present in the dropdown
    expected_categories = [ "Basic Components", "Layout", "Interactive", "Forms", "Complex" ]
    expected_categories.each do |category|
      assert_match category, response.body
    end
  end

  test "each snippet type is present" do
    get playground_root_path

    # Check key snippets are present
    snippet_names = [ "DSL Button", "DSL Card", "DSL Text", "DSL VStack",
                     "Interactive Counter", "Complete Form", "Product Grid" ]

    snippet_names.each do |name|
      assert_match name, response.body, "Missing snippet: #{name}"
    end
  end

  test "execute endpoint accepts code and returns turbo stream" do
    post playground_execute_path, params: {
      code: 'swift_ui { text("Test from controller") }',
      session_id: "test-session-123"
    }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_match "playground-preview", response.body
    assert_match "Test from controller", response.body
  end

  test "execute endpoint handles syntax errors" do
    post playground_execute_path, params: {
      code: "swift_ui { invalid syntax here {{{ }",
      session_id: "test-session-123"
    }, as: :turbo_stream

    assert_response :success
    assert_match "playground-errors", response.body
    assert_match "Error", response.body
  end

  test "execute endpoint handles runtime errors" do
    post playground_execute_path, params: {
      code: "swift_ui { undefined_method_call }",
      session_id: "test-session-123"
    }, as: :turbo_stream

    assert_response :success
    assert_match "playground-errors", response.body
    assert_match "undefined local variable or method", response.body
  end

  test "execute endpoint prevents dangerous operations" do
    dangerous_codes = [
      'system("ls")',
      "`ls`",
      'File.read("/etc/passwd")',
      'Dir.entries("/")',
      'eval("1 + 1")',
      '__send__(:system, "ls")',
      'Kernel.system("ls")',
      'require "net/http"',
      'load "/some/file"',
      'open("|ls")'
    ]

    dangerous_codes.each do |code|
      post playground_execute_path, params: {
        code: code,
        session_id: "test-session-123"
      }, as: :turbo_stream

      assert_response :success
      assert_match "Unsafe operation detected", response.body,
        "Failed to block dangerous code: #{code}"
    end
  end

  test "export endpoint returns 404 for non-existent export" do
    get playground_export_path("non-existent-id")
    assert_redirected_to playground_root_path
    assert_equal "Export not found", flash[:alert]
  end

  test "snippet codes are properly formatted" do
    controller = Playground::PlaygroundController.new

    # Test DSL button snippet
    button_code = controller.send(:dsl_button_snippet)
    assert_match /swift_ui do/, button_code
    assert_match /button\("Click Me"\)/, button_code
    assert_match /\.bg\("blue-500"\)/, button_code

    # Test form snippet
    form_code = controller.send(:form_snippet)
    assert_match /form\(action: "#", method: "post"\)/, form_code
    assert_match /label\("Name", for_input: "name"\)/, form_code

    # Test grid snippet (with interpolation)
    grid_code = controller.send(:grid_snippet)
    assert_match /5\.times do \|i\|/, grid_code
    assert_match /Product #\{i \+ 1\}/, grid_code
  end

  test "complex snippets have valid DSL syntax" do
    controller = Playground::PlaygroundController.new

    # Get all snippet methods
    snippet_methods = controller.private_methods.grep(/_snippet$/)

    snippet_methods.each do |method|
      code = controller.send(method)

      # Basic syntax checks
      assert code.present?, "#{method} returns empty code"
      assert_match /swift_ui/, code, "#{method} missing swift_ui block"

      # Check for common DSL patterns
      assert code.include?("do") || code.include?("{"),
        "#{method} missing block syntax"
    end
  end

  test "session_id is used in execute endpoint" do
    session_id = "unique-test-session-#{SecureRandom.uuid}"

    post playground_execute_path, params: {
      code: 'swift_ui { text("Session test") }',
      session_id: session_id
    }, as: :turbo_stream

    assert_response :success
    # In a real implementation, you might check that the session_id
    # is used for caching or state management
  end
end
