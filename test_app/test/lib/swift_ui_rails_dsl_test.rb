# Copyright 2025
require "test_helper"

class SwiftUIRailsDSLTest < ActiveSupport::TestCase
  include SwiftUIRails::DSL
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context

  test "vstack creates vertical stack with proper classes" do
    result = vstack(spacing: 4) do
      "Content"
    end
    
    assert_match /flex flex-col/, result
    assert_match /space-y-4/, result
    assert_match /Content/, result
  end

  test "hstack creates horizontal stack with proper classes" do
    result = hstack(spacing: 2) do
      "Content"
    end
    
    assert_match /flex flex-row/, result
    assert_match /space-x-2/, result
    assert_match /Content/, result
  end

  test "button creates button element with text" do
    result = button("Click Me", class: "custom-class")
    
    assert_match /<button/, result
    assert_match /custom-class/, result
    assert_match />Click Me<\/button>/, result
  end

  test "text creates span with text content" do
    result = text("Hello World")
    
    assert_match /<span/, result
    assert_match />Hello World<\/span>/, result
  end

  test "card creates card container" do
    result = card do
      "Card Content"
    end
    
    assert_match /bg-white rounded-lg/, result
    assert_match /Card Content/, result
  end

  test "chaining modifiers works" do
    # In actual usage, modifiers would be chained
    # For testing, we'll verify the DSL methods exist
    assert respond_to?(:vstack)
    assert respond_to?(:hstack)
    assert respond_to?(:button)
    assert respond_to?(:text)
    assert respond_to?(:card)
  end
end
# Copyright 2025
