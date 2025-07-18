# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class SimpleReactiveTest < ViewComponent::TestCase
  class SimpleComponent < SwiftUIRails::Component::Base
    prop :title, type: String, default: "Hello"

    swift_ui do
      text(title)
    end
  end

  def test_simple_component_renders
    render_inline(SimpleComponent.new(title: "Test"))
    puts page.native.to_html # Debug output
    assert_text "Test"
  end
end
# Copyright 2025
