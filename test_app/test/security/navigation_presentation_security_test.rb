# frozen_string_literal: true

require "test_helper"

class NavigationPresentationSecurityTest < ActiveSupport::TestCase
  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "navigation and dismissal URLs reject executable schemes" do
    dangerous_urls = [
      "javascript:alert(document.domain)",
      "data:text/html,<script>alert(1)</script>",
      "vbscript:msgbox(1)",
      "file:///etc/passwd"
    ]

    dangerous_urls.each do |url|
      assert_raises(ArgumentError) do
        render_dsl { navigation_link("Unsafe", destination: url) }
      end

      assert_raises(ArgumentError) do
        render_dsl { alert("Unsafe", dismiss_path: url) }
      end
    end
  end

  test "presentation route fallbacks cannot redirect off origin or depend on the current base path" do
    invalid_routes = [
      "https://attacker.test/dialog",
      "//attacker.test/dialog",
      "relative/dialog",
      "../dialog",
      "/\\attacker.test/dialog"
    ]

    invalid_routes.each do |route|
      assert_raises(ArgumentError) do
        render_dsl { presentation_trigger("Open", target: "safe-dialog", fallback: route) }
      end

      assert_raises(ArgumentError) do
        render_dsl { sheet("Close", dismiss_path: route) { text("Content") } }
      end
    end
  end

  test "DOM identifiers cannot escape semantic descriptors or ARIA references" do
    dangerous_ids = [
      'dialog" data-action="click->evil#run',
      "dialog<script>",
      "../../dialog",
      "dialog id",
      "1dialog"
    ]

    dangerous_ids.each do |identifier|
      assert_raises(ArgumentError) do
        render_dsl { presentation_trigger("Open", target: identifier) }
      end

      assert_raises(ArgumentError) do
        render_dsl { popover("Open", id: identifier) { text("Content") } }
      end
    end
  end

  test "labels messages and custom content remain escaped" do
    attack = '<img src=x onerror="alert(1)">'
    html = render_dsl do
      navigation_stack(label: attack) do
        navigation_link(attack, destination: "/safe")
      end
      alert(attack, message: attack, id: "safe-alert") do
        text(attack)
      end
    end

    fragment = Nokogiri::HTML.fragment(html)
    assert_empty fragment.css("img")
    assert_equal attack, fragment.at_css("nav")["aria-label"]
    assert_equal attack, fragment.at_css("a[href='/safe']").text
    assert_equal attack, fragment.at_css("#safe-alert-title").text
    assert_equal attack, fragment.at_css("#safe-alert-description").text
    assert_equal attack, fragment.at_css("#safe-alert .swift-ui-dialog-actions span").text
  end

  test "application JavaScript metadata is rejected and presentation descriptors cannot be displaced" do
    assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      render_dsl do
        sheet("Settings", id: "legacy-sheet", data: { controller: "legacy" }) { text("Settings form") }
      end
    end

    html = render_dsl do
      sheet(
        "Settings",
        id: "settings-sheet",
        data: {
          analytics: "settings",
          sui_dialog: JSON.generate(kind: "script", presented: false, dismissible: false)
        }
      ) { text("Settings form") }
    end
    dialog = Nokogiri::HTML.fragment(html).at_css("#settings-sheet")
    descriptor = JSON.parse(dialog["data-sui-dialog"])

    assert_nil dialog["data-controller"]
    assert_nil dialog["data-action"]
    assert_equal "settings", dialog["data-analytics"]
    assert_equal "sheet", descriptor.fetch("kind")
    assert_equal true, descriptor.fetch("presented")
    assert_equal true, descriptor.fetch("dismissible")
  end

  test "toolbar overflow labels are escaped and required adaptive metadata wins" do
    attack = '<img src=x onerror="alert(1)">'
    html = render_dsl do
      toolbar(
        label: "Safe tools",
        overflow_label: attack,
        minimize_on_scroll: true,
        data: {
          sui_toolbar: JSON.generate(
            orientation: "diagonal",
            overflow: false,
            minimizeOnScroll: false,
            minimizeThreshold: 999_999
          )
        }
      ) do
        toolbar_item(
          priority: :pinned,
          data: {
            sui_toolbar_priority: "low",
            sui_toolbar_visibility: "overflow"
          }
        ) { button("Save", type: "button") }
      end
    end
    toolbar = Nokogiri::HTML.fragment(html).at_css("[role='toolbar']")
    item = toolbar.at_css(".swift-ui-toolbar-item")
    descriptor = JSON.parse(toolbar["data-sui-toolbar"])

    assert_empty toolbar.css("img")
    assert_equal attack, toolbar.at_css(".swift-ui-toolbar-overflow-trigger").text
    assert_nil toolbar["data-controller"]
    assert_nil toolbar["data-action"]
    assert_equal "horizontal", descriptor.fetch("orientation")
    assert_equal true, descriptor.fetch("overflow")
    assert_equal true, descriptor.fetch("minimizeOnScroll")
    assert_equal 24, descriptor.fetch("minimizeThreshold")
    assert_equal "pinned", item["data-sui-toolbar-priority"]
    assert_equal "automatic", item["data-sui-toolbar-visibility"]
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end
end
