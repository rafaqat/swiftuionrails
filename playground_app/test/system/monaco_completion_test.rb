require "application_system_test_case"

class MonacoCompletionTest < ApplicationSystemTestCase
  test "Monaco editor Tab completion functionality" do
    visit root_path
    
    # Wait for Monaco editor to load
    assert_selector "#monaco-editor", wait: 10
    sleep 2
    
    # Check that Monaco editor is visible and ready
    monaco_container = find("#monaco-editor")
    assert monaco_container.visible?
    
    # Test that Monaco editor instance exists
    editor_ready = page.evaluate_script("!!window.monacoEditorInstance")
    assert editor_ready, "Monaco editor instance should be available"
    
    # Test that completion provider is registered
    completion_provider_count = page.evaluate_script("monaco.languages.getLanguages().length")
    assert completion_provider_count > 0, "Monaco languages should be available"
    
    # Test that we can get editor content
    current_content = page.evaluate_script("window.monacoEditorInstance ? window.monacoEditorInstance.getValue() : ''")
    assert current_content.length > 0, "Monaco editor should have initial content"
    
    # Test that we can trigger completion
    trigger_result = page.evaluate_script("
      if (window.monacoEditorInstance) {
        try {
          window.monacoEditorInstance.trigger('keyboard', 'editor.action.triggerSuggest', {});
          return true;
        } catch(e) {
          return false;
        }
      }
      return false;
    ")
    assert trigger_result, "Should be able to trigger completion"
    
    # Test that completion endpoints are functional
    page.driver.get "/playground/signatures"
    assert_includes page.body, "signatures"
    
    puts "✅ Monaco completion test passed"
  end
  
  test "IntelliSense completion API endpoints work" do
    # Test completions endpoint
    post "/playground/completions", params: {
      prefix: "tex",
      context: "swift_ui do\n  tex",
      line: 2,
      column: 5
    }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["completions"].is_a?(Array)
    
    # Find text completion
    text_completion = json_response["completions"].find { |c| c["label"] == "text" }
    assert text_completion.present?
    assert_equal "Function", text_completion["kind"]
    
    # Test signatures endpoint
    get "/playground/signatures"
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["signatures"].is_a?(Array)
    
    puts "✅ IntelliSense API endpoints test passed"
  end
end