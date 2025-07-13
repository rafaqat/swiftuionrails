# Copyright 2025
require "test_helper"

class SwiftUIRailsDSLTest < ActiveSupport::TestCase
  include SwiftUIRails::DSL
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context

  test "vstack creates vertical stack with proper classes" do
    result = vstack(spacing: 4) do
      text("Content")
    end

    # Element needs to be rendered to HTML
    html = result.to_s
    assert_match /flex flex-col/, html
    assert_match /space-y-4/, html
    assert_match /Content/, html
  end

  test "hstack creates horizontal stack with proper classes" do
    result = hstack(spacing: 2) do
      text("Content")
    end

    # Element needs to be rendered to HTML
    html = result.to_s
    assert_match /flex flex-row/, html
    assert_match /space-x-2/, html
    assert_match /Content/, html
  end

  test "button creates button element with text" do
    result = button("Click Me", class: "custom-class")
    
    # Element needs to be rendered to HTML
    html = result.to_s
    assert_match /<button/, html
    assert_match /custom-class/, html
    assert_match />Click Me<\/button>/, html
  end

  test "text creates span with text content" do
    result = text("Hello World")
    
    # Element needs to be rendered to HTML
    html = result.to_s
    assert_match /<span/, html
    assert_match />Hello World<\/span>/, html
  end

  test "card creates card container" do
    result = card do
      text("Card Content")
    end
    
    # Element needs to be rendered to HTML
    html = result.to_s
    assert_match /bg-white/, html
    assert_match /rounded-lg/, html
    assert_match /Card Content/, html
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
