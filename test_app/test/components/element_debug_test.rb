# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class ElementDebugTest < ViewComponent::TestCase
  # Super simple component
  class TextOnlyComponent < SwiftUIRails::Component::Base
    swift_ui do
      text("Hello World")
    end
  end

  # Component with vstack
  class VStackComponent < SwiftUIRails::Component::Base
    swift_ui do
      vstack do
        text("Inside vstack")
      end
    end
  end

  def test_text_only_component
    render_inline(TextOnlyComponent.new)
    puts "Text only HTML: #{page.native.to_html}"
    assert_text "Hello World"
  end

  def test_vstack_component
    render_inline(VStackComponent.new)
    puts "VStack HTML: #{page.native.to_html}"
    assert_text "Inside vstack"
  end

  def test_manual_element_rendering
    component = TextOnlyComponent.new

    # Get the swift_ui block
    block = component.class.instance_variable_get(:@swift_ui_block)

    # Execute it
    element = component.instance_eval(&block)
    puts "Element class: #{element.class}"
    puts "Element tag: #{element.tag_name}"
    puts "Element content: #{element.content.inspect}"

    # Set view context and render
    element.view_context = component
    html = element.to_s
    puts "Rendered HTML: #{html}"

    # Add assertions
    assert_equal :span, element.tag_name, "Element should have span tag"
    assert_equal "Hello World", element.content, "Element should have correct content"
    assert_match /<span>Hello World<\/span>/, html, "HTML should be properly rendered"
  end
end
# Copyright 2025
