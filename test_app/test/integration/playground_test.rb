require "test_helper"

class PlaygroundTest < ActionDispatch::IntegrationTest
  test "playground index loads successfully" do
    get playground_root_path
    assert_response :success
    assert_select "h1", "SwiftUI Rails Playground"
    assert_select "textarea[data-playground-target='codeInput']"
    assert_select "#playground-preview"
  end

  test "playground execute endpoint processes DSL code" do
    post playground_execute_path, params: {
      code: 'swift_ui { text("Hello from test!") }',
      session_id: "test-session"
    }, as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.content_type
    assert_match "playground-preview", response.body
    assert_match "Hello from test!", response.body
  end

  test "playground execute handles errors gracefully" do
    post playground_execute_path, params: {
      code: "swift_ui { invalid syntax here }",
      session_id: "test-session"
    }, as: :turbo_stream

    assert_response :success
    assert_match "playground-errors", response.body
    assert_match "Error", response.body
    assert_match "undefined local variable or method", response.body
  end

  test "playground prevents dangerous operations" do
    post playground_execute_path, params: {
      code: 'system("rm -rf /")',
      session_id: "test-session"
    }, as: :turbo_stream

    assert_response :success
    assert_match "playground-errors", response.body
    assert_match "Unsafe operation detected", response.body
  end
end
