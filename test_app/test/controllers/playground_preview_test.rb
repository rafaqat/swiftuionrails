# frozen_string_literal: true

require 'test_helper'

class PlaygroundPreviewTest < ActionDispatch::IntegrationTest
  test "renders button with proper classes" do
    button_code = <<~RUBY
      button("Hello World")
        .bg("teal")
        .text_color("yellow")
        .px(16).py(8)
        .rounded("lg")
    RUBY
    
    post preview_playground_path, params: { code: button_code }, as: :turbo_stream
    
    assert_response :success
    
    # Extract the rendered HTML
    html = response.body
    puts "\n=== RENDERED HTML ==="
    puts html
    puts "=== END HTML ===\n"
    
    # Check if button is in the response
    assert_match /<button/, html, "Response should contain a button element"
    assert_match /Hello World/, html, "Button should contain 'Hello World' text"
    
    # Check for Tailwind classes
    assert_match /bg-teal/, html, "Button should have teal background class"
    assert_match /text-yellow/, html, "Button should have yellow text class"
  end
  
  test "renders button without swift_ui wrapper" do
    button_code = 'button("Test").bg("blue")'
    
    post preview_playground_path, params: { code: button_code }, as: :turbo_stream
    
    assert_response :success
    html = response.body
    
    assert_match /<button/, html
    assert_match /Test/, html
    assert_match /bg-blue/, html
  end
  
  test "button method signature variations" do
    # Test 1: Simple button
    post preview_playground_path, params: { code: 'button("Simple")' }, as: :turbo_stream
    assert_response :success
    assert_match /<button[^>]*>Simple<\/button>/, response.body
    
    # Test 2: Button with single modifier
    post preview_playground_path, params: { code: 'button("Styled").bg("red")' }, as: :turbo_stream
    assert_response :success
    assert_match /bg-red/, response.body
    
    # Test 3: Button with multiple modifiers
    code = 'button("Multi").bg("green").text_color("white").px(4)'
    post preview_playground_path, params: { code: code }, as: :turbo_stream
    assert_response :success
    html = response.body
    assert_match /bg-green/, html
    assert_match /text-white/, html
    assert_match /px-4/, html
  end
end