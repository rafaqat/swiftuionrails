# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class DslProductCardDebugTest < ActiveSupport::TestCase
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  test "content_tag works with two arguments" do
    # Test that content_tag works properly
    result = content_tag(:div, "Hello", class: "test")
    assert_equal '<div class="test">Hello</div>', result
  end

  test "content_tag works with block" do
    # Test that content_tag works with a block
    result = content_tag(:div, class: "test") do
      "Hello from block"
    end
    assert_equal '<div class="test">Hello from block</div>', result
  end

  test "swift_ui DSL works" do
    # Test that swift_ui works
    result = swift_ui do
      div do
        text("Hello DSL")
      end
    end
    assert result.include?("Hello DSL")
  end

  test "combined content_tag and swift_ui works" do
    # Test the combination
    result = content_tag(:div, class: "wrapper") do
      swift_ui do
        div do
          text("Hello Combined")
        end
      end
    end
    assert result.include?("wrapper")
    assert result.include?("Hello Combined")
  end
end
# Copyright 2025
