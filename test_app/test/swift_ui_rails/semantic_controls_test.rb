# frozen_string_literal: true

require "test_helper"

class SwiftUIRails::SemanticControlsTest < ActiveSupport::TestCase
  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "badge owns its semantic styling and rejects unknown tones" do
    html = render_dsl { badge("In Stock", tone: :success, announce: true) }
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal "In Stock", fragment.at_css("span[role='status']").text
    assert_includes fragment.at_css("span")["class"], "bg-green-50"
    assert_raises(ArgumentError) { render_dsl { badge("Nope", tone: :script) } }
  end

  test "progress and gauge expose bounded native semantics" do
    html = render_dsl do
      progress_view(value: 150, total: 100, label: "Upload")
      gauge(value: -4, range: 0..10, label: "Signal")
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal "100.0", fragment.at_css("progress")["value"]
    assert_equal "100.0", fragment.at_css("progress")["max"]
    assert_equal "Upload", fragment.at_css("progress")["aria-label"]
    assert_equal "0.0", fragment.at_css("meter")["value"]
    assert_equal "Signal", fragment.at_css("meter")["aria-label"]
  end

  test "disclosure and menu remain useful without JavaScript" do
    html = render_dsl do
      disclosure_group("Details", expanded: true) { text("More information") }
      menu("Actions") { button("Archive") }
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css("details.swift-ui-disclosure[open]")
    assert_equal "Details", fragment.at_css("details.swift-ui-disclosure > summary").text
    assert_equal "More information", fragment.at_css("details.swift-ui-disclosure span").text
    assert_equal "Actions", fragment.at_css("details.swift-ui-menu > summary").text
    assert_equal "Archive", fragment.at_css("[role='menu'] button").text
  end

  test "control group, date picker, color picker, and stepper use native controls" do
    html = render_dsl do
      control_group(label: "Filters") do
        date_picker(name: "starts_on", value: Date.new(2026, 7, 17))
        color_picker(name: "accent", value: "#12AbEF")
        stepper(name: "quantity", value: 12, range: 1..10, step: 2)
      end
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal "Filters", fragment.at_css("fieldset[role='group'] legend").text
    assert_equal "2026-07-17", fragment.at_css("input[type='date']")["value"]
    assert_equal "#12AbEF", fragment.at_css("input[type='color']")["value"]
    assert_equal "10.0", fragment.at_css("input[type='number']")["value"]
    assert_equal "2.0", fragment.at_css("input[type='number']")["step"]
  end

  test "semantic controls reject malformed ranges and values" do
    assert_raises(ArgumentError) { render_dsl { progress_view(total: 0) } }
    assert_raises(ArgumentError) { render_dsl { gauge(value: 1, range: 2..1) } }
    assert_raises(ArgumentError) { render_dsl { color_picker(name: "color", value: "red; background:url(x)") } }
    assert_raises(ArgumentError) { render_dsl { stepper(name: "count", value: 1, step: 0) } }
    assert_raises(ArgumentError) { render_dsl { date_picker(name: "date", value: "not-a-date") } }
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end
end
