# frozen_string_literal: true

require "test_helper"

class PlaygroundIntellisenseTest < ActionDispatch::IntegrationTest
  test "completions endpoint returns suggestions for button methods" do
    post playground_completions_path, params: {
      context: 'button("Test").',
      position: { lineNumber: 1, column: 15 }
    }, as: :json
    
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["suggestions"].is_a?(Array)
    assert data["suggestions"].length > 0
    
    # Check for expected method suggestions
    method_labels = data["suggestions"].map { |s| s["label"] }
    assert_includes method_labels, "bg"
    assert_includes method_labels, "text_color"
    assert_includes method_labels, "padding"
    assert_includes method_labels, "rounded"
  end
  
  test "completions endpoint returns color suggestions for bg method" do
    post playground_completions_path, params: {
      context: 'button("Test").bg(',
      position: { lineNumber: 1, column: 18 }
    }, as: :json
    
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["suggestions"].is_a?(Array)
    assert data["suggestions"].length > 0
    
    # Check for color suggestions
    color_labels = data["suggestions"].map { |s| s["label"] }
    assert_includes color_labels, "blue"
    assert_includes color_labels, "red"
    assert_includes color_labels, "green"
    # Also check for some specific shades
    assert color_labels.any? { |label| label.include?("blue") || label.include?("500") }
  end
  
  test "signatures endpoint returns signature for vstack" do
    get playground_signatures_path, params: {
      method: "vstack",
      active_parameter: 0
    }, as: :json
    
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["signatures"].is_a?(Array)
    
    if data["signatures"].length > 0
      signature = data["signatures"].first
      assert signature["label"].include?("vstack")
      assert signature["parameters"].is_a?(Array)
    end
  end
end