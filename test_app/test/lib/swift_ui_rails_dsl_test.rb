require "test_helper"

class SwiftUIRailsDSLTest < ActiveSupport::TestCase
  def setup
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "vstack renders a vertical stack with its block content" do
    stack = render_dsl do
      vstack(spacing: 4) { "Content" }
    end.at_css("div.flex.flex-col.items-center")

    assert stack
    assert_equal "gap: 4px", stack["style"]
    assert_equal "Content", stack.text
  end

  test "hstack renders a horizontal stack with its block content" do
    stack = render_dsl do
      hstack(spacing: 2) { "Content" }
    end.at_css("div.flex.flex-row.items-center")

    assert stack
    assert_equal "gap: 2px", stack["style"]
    assert_equal "Content", stack.text
  end

  test "button renders text and attributes" do
    button = render_dsl do
      button("Click Me", class: "custom-class", type: "submit")
    end.at_css("button.custom-class")

    assert button
    assert_equal "submit", button["type"]
    assert_equal "Click Me", button.text
  end

  test "button is form-safe by default and preserves explicit form intents" do
    fragment = render_dsl do
      form do
        button("Action")
        button("Submit", type: :submit)
        button("Reset", **{ "type" => "reset" })
        button("Invalid", type: "not-a-button-type")
      end
    end

    assert_equal "button", fragment.at_css("button:nth-of-type(1)")["type"]
    assert_equal "submit", fragment.at_css("button:nth-of-type(2)")["type"]
    assert_equal "reset", fragment.at_css("button:nth-of-type(3)")["type"]
    assert_equal "button", fragment.at_css("button:nth-of-type(4)")["type"]
  end

  test "text renders a span with escaped text content" do
    span = render_dsl do
      text("Hello <strong>World</strong>")
    end.at_css("span")

    assert span
    assert_equal "Hello <strong>World</strong>", span.text
    assert_nil span.at_css("strong")
  end

  test "card renders its container and nested content" do
    card = render_dsl do
      card { text("Card Content") }
    end.at_css("div.bg-white.rounded-lg")

    assert card
    assert_equal "Card Content", card.at_css("span")&.text
  end

  test "modifiers are reflected in rendered HTML" do
    span = render_dsl do
      text("Status").font_weight("bold").text_color("blue-600").padding(2)
    end.at_css("span.font-bold.text-blue-600.p-2")

    assert span
    assert_equal "Status", span.text
  end

  private

  def render_dsl(&block)
    Nokogiri::HTML.fragment(@view.swift_ui(&block))
  end
end
