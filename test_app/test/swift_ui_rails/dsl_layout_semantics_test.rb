# frozen_string_literal: true

require "test_helper"

class SwiftUIRails::DSLLayoutSemanticsTest < ViewComponent::TestCase
  class SiblingActionsComponent < SwiftUIRails::Component::Base
    swift_ui do
      button("First").on_click { |_event| }
      button("Second").on_click { |_event| }
    end
  end

  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "stack spacing uses point-like pixel values instead of Tailwind scale values" do
    html = render_dsl do
      vstack(spacing: 8) { text("Vertical") }
      hstack(spacing: 12.5) { text("Horizontal") }
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal "gap: 8px", fragment.css("[data-swift-ui-layout-axis]")[0]["style"]
    assert_equal "gap: 12.5px", fragment.css("[data-swift-ui-layout-axis]")[1]["style"]
    refute_includes html, "space-y-8"
    refute_includes html, "space-x-12.5"
  end

  test "zstack overlays direct children in one grid cell and honors alignment" do
    html = render_dsl do
      zstack(alignment: :top_trailing) do
        div("Background")
        text("Overlay")
      end
    end
    fragment = Nokogiri::HTML.fragment(html)
    stack = fragment.at_css("[data-swift-ui-layout-axis='overlay']")

    assert_includes stack["class"], "grid"
    assert_includes stack["class"], "items-start"
    assert_includes stack["class"], "justify-items-end"
    assert_equal 2, stack.element_children.length
    stack.element_children.each do |child|
      assert_includes child["class"], "col-start-1"
      assert_includes child["class"], "row-start-1"
    end
  end

  test "spacer minimum length follows its parent stack axis" do
    html = render_dsl do
      hstack { spacer(min_length: 24) }
      vstack { spacer(min_length: 32) }
    end
    fragment = Nokogiri::HTML.fragment(html)
    horizontal = fragment.at_css("[data-spacer-axis='horizontal']")
    vertical = fragment.at_css("[data-spacer-axis='vertical']")

    assert_equal "min-width: 24px", horizontal["style"]
    assert_includes horizontal["class"], "min-w-0"
    assert_equal "min-height: 32px", vertical["style"]
    assert_includes vertical["class"], "min-h-0"
  end

  test "divider is perpendicular to its parent stack axis" do
    html = render_dsl do
      hstack { divider }
      vstack { divider }
    end
    fragment = Nokogiri::HTML.fragment(html)
    horizontal_stack_divider = fragment.at_css("[data-swift-ui-layout-axis='horizontal'] [role='separator']")
    vertical_stack_divider = fragment.at_css("[data-swift-ui-layout-axis='vertical'] hr")

    assert_equal "div", horizontal_stack_divider.name
    assert_equal "vertical", horizontal_stack_divider["aria-orientation"]
    assert_includes horizontal_stack_divider["class"], "border-l"
    assert_equal "horizontal", vertical_stack_divider["aria-orientation"]
    assert_includes vertical_stack_divider["class"], "border-t"
  end

  test "grid items produce exact fixed flexible and adaptive CSS tracks" do
    fixed_and_flexible = render_dsl do
      vgrid(
        columns: [grid_item(:fixed, size: 80), grid_item(:flexible, min: 120, max: 240)],
        spacing: 10
      ) { text("Cell") }
    end
    adaptive = render_dsl do
      lazy_vgrid(columns: [grid_item(:adaptive, min: 150)], spacing: 6) { text("Cell") }
    end

    fixed_grid = Nokogiri::HTML.fragment(fixed_and_flexible).at_css(".swift-ui-grid > .grid")
    lazy_wrapper = Nokogiri::HTML.fragment(adaptive).at_css(".swift-ui-grid")
    adaptive_grid = lazy_wrapper.element_children.find { |child| child["class"].to_s.split.include?("grid") }

    assert_includes fixed_grid["style"], "grid-template-columns: 80px minmax(120px, 240px)"
    assert_includes fixed_grid["style"], "gap: 10px"
    assert_includes adaptive_grid["style"], "repeat(auto-fit, minmax(min(100%, 150px), 1fr))"
    assert_equal "content-visibility", lazy_wrapper["data-lazy-strategy"]
    assert_includes lazy_wrapper["style"], "content-visibility: auto"
  end

  test "grid auto rows normalize CSS whitespace without splitting the class token" do
    html = render_dsl do
      grid(columns: 2, auto_rows: "minmax(350px, auto)") { text("Cell") }
    end
    grid = Nokogiri::HTML.fragment(html).at_css(".grid")

    assert_includes grid["class"], "auto-rows-[minmax(350px,_auto)]"
    refute_includes grid["class"].split, "auto)]"
    assert_raises(ArgumentError) do
      render_dsl { grid(auto_rows: "minmax(1px, auto); color: red") { text("Nope") } }
    end
  end

  test "semantic button styles and sizes apply classes and reject typos" do
    html = render_dsl { button("Save").button_style(:bordered_prominent).button_size(:large) }
    button_node = Nokogiri::HTML.fragment(html).at_css("button")

    assert_includes button_node["class"], "bg-blue-600"
    assert_includes button_node["class"], "px-5"
    assert_includes button_node["class"], "py-2.5"
    assert_raises(ArgumentError) { render_dsl { button("Nope").button_style(:typo) } }
    assert_raises(ArgumentError) { render_dsl { button("Nope").button_size(:huge) } }
  end

  test "hidden and disabled modifiers can be reversed" do
    html = render_dsl do
      div("Reserved space").hidden
      div("Visible").hidden(true).hidden(false)
      button("Enabled").disabled(true).disabled(false)
    end
    fragment = Nokogiri::HTML.fragment(html)
    reserved = fragment.css("div").find { |node| node.text == "Reserved space" }
    visible = fragment.css("div").find { |node| node.text == "Visible" }
    enabled = fragment.at_css("button")

    assert_includes reserved["class"], "invisible"
    assert_equal "true", reserved["aria-hidden"]
    assert_nil visible["class"]
    assert_nil visible["aria-hidden"]
    assert_nil enabled["disabled"]
    assert_nil enabled["aria-disabled"]
    refute_includes enabled["class"].to_s, "opacity-50"
  end

  test "sibling event handlers receive unique and deterministic action IDs" do
    first_component = SiblingActionsComponent.new
    render_inline(first_component)
    first_ids = first_component.registered_actions

    second_component = SiblingActionsComponent.new
    render_inline(second_component)
    second_ids = second_component.registered_actions

    assert_equal 2, first_ids.length
    assert_equal first_ids.uniq, first_ids
    assert_equal first_ids, second_ids
  end

  test "unsafe layout values and malformed grid definitions fail closed" do
    assert_raises(ArgumentError) { render_dsl { vstack(spacing: "8; color: red") { text("Nope") } } }
    assert_raises(ArgumentError) { render_dsl { grid_item(:flexible, min: 20, max: 10) } }
    assert_raises(ArgumentError) { render_dsl { grid_item(:unknown) } }
    assert_raises(ArgumentError) { render_dsl { lazy_vgrid(columns: []) { text("Nope") } } }
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end
end
