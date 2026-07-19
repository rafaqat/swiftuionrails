# frozen_string_literal: true

require "test_helper"

class SwiftUIRails::NavigationPresentationTest < ActiveSupport::TestCase
  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "navigation is route backed and exposes current-page semantics" do
    html = render_dsl do
      navigation_stack(label: "Account") do
        navigation_link("Profile", destination: "/account", current: true)
        navigation_link(
          "Help",
          destination: "https://example.test/help",
          target: "_blank",
          replace: true
        )
      end
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css("nav.swift-ui-navigation-stack[aria-label='Account']")
    assert fragment.at_css("a[href='/account'][aria-current='page'][data-turbo-action='advance']")
    external = fragment.at_css("a[href='https://example.test/help']")
    assert_equal "replace", external["data-turbo-action"]
    assert_includes external["rel"].split, "noopener"
    assert_includes external["rel"].split, "noreferrer"
  end

  test "automatic current-page matching ignores fragments and external network paths" do
    request = Struct.new(:path).new("/account")
    @view.define_singleton_method(:request) { request }

    html = render_dsl do
      navigation_stack(label: "Account") do
        navigation_link("Account", destination: "/account?section=profile")
        navigation_link("Filtered account", destination: "?section=security")
        navigation_link("Section", destination: "#security")
        navigation_link("External lookalike", destination: "//example.test/account")
      end
    end
    links = Nokogiri::HTML.fragment(html).css("a")

    assert_equal "page", links[0]["aria-current"]
    assert_equal "page", links[1]["aria-current"]
    assert_nil links[2]["aria-current"]
    assert_nil links[3]["aria-current"]
  end

  test "tab view renders linked tabs and readable panels before enhancement" do
    html = render_dsl do
      tab_view(id: "account-tabs", label: "Account sections", selection: :activity) do
        tab("Overview", value: :overview) { text("Overview panel") }
        tab("Activity", value: :activity) { text("Activity panel") }
        tab("Billing", value: :billing, destination: "/billing") { text("Billing panel") }
      end
    end
    fragment = Nokogiri::HTML.fragment(html)

    root = fragment.at_css("#account-tabs[data-sui-tabs]")
    tabs = JSON.parse(root["data-sui-tabs"])
    assert_equal "activity", tabs.fetch("selection")
    assert_equal "activity", tabs.fetch("initialSelection")
    assert_equal "Account sections", root.at_css("[role='tablist']")["aria-label"]
    assert_equal "true", root.at_css("#account-tabs-tab-activity")["aria-selected"]
    assert_equal "#account-tabs-panel-overview", root.at_css("#account-tabs-tab-overview")["href"]
    assert_equal "false", root.at_css("#account-tabs-tab-overview")["data-turbo"]
    assert_equal "/billing", root.at_css("#account-tabs-tab-billing")["href"]
    assert_nil root.at_css("#account-tabs-tab-billing")["data-turbo"]
    billing = JSON.parse(root.at_css("#account-tabs-tab-billing")["data-sui-tab"])
    assert_equal false, billing.fetch("local")

    panels = root.css("[role='tabpanel']")
    assert_equal 3, panels.length
    assert panels.none? { |panel| panel.key?("hidden") }, "server fallback should leave every panel readable"
    assert_equal "Activity panel", root.at_css("#account-tabs-panel-activity").text
  end

  test "sheet and item-bound presentations emit native dialogs" do
    html = render_dsl do
      presentation_trigger("Edit project", target: "project-sheet", fallback: "/projects/1?sheet=edit")
      sheet("Edit project", id: "project-sheet", presented: false) { text("Project form") }
      sheet("Member", id: "member-sheet", item: { name: "Ari" }) do |member|
        text(member.fetch(:name))
      end
      sheet("Absent member", id: "absent-member-sheet", item: nil) { text("Must not render") }
      alert("Saved", id: "saved-alert", message: "Your changes are live", presented: true)
      confirmation_dialog("Delete project?", id: "delete-dialog", presented: true) do
        navigation_link("Delete", destination: "/projects/1/delete")
      end
    end
    fragment = Nokogiri::HTML.fragment(html)

    trigger = fragment.at_css("a.swift-ui-presentation-trigger")
    assert_equal "/projects/1?sheet=edit", trigger["href"]
    assert_equal "project-sheet", trigger["aria-controls"]
    assert_nil fragment.at_css("#project-sheet")["open"]
    assert_equal "Project form", fragment.at_css("#project-sheet .swift-ui-dialog-body").text.strip
    assert_nil fragment.at_css("#project-sheet .swift-ui-dialog-actions")

    assert fragment.at_css("#member-sheet[open][role='dialog']")
    assert_equal "false", fragment.at_css("#member-sheet")["aria-modal"]
    assert_includes fragment.at_css("#member-sheet").text, "Ari"
    assert_nil fragment.at_css("#absent-member-sheet")
    assert fragment.at_css("#saved-alert[open][role='alertdialog'][aria-describedby='saved-alert-description']")
    assert_equal "Your changes are live", fragment.at_css("#saved-alert-description").text
    assert_equal 1, fragment.css("#saved-alert .swift-ui-dialog-dismiss").length
    assert fragment.at_css("#delete-dialog .swift-ui-dialog-actions a[href='/projects/1/delete']")
    assert_equal "Cancel", fragment.at_css("#delete-dialog .swift-ui-dialog-dismiss").text
  end

  test "presentation fallbacks and dismissals remain unambiguous Rails routes" do
    html = render_dsl do
      presentation_trigger("Edit", target: "edit-sheet", fallback: "/projects/1/edit?sheet=true")
      sheet("Edit", id: "edit-sheet", dismiss_path: "/projects/1") { text("Editor") }
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal "/projects/1/edit?sheet=true", fragment.at_css(".swift-ui-presentation-trigger")["href"]
    assert_equal "/projects/1", fragment.at_css("#edit-sheet .swift-ui-dialog-close")["href"]
  end

  test "popover and toolbar preserve native and ARIA semantics" do
    html = render_dsl do
      popover("Quick actions", id: "quick-actions", expanded: true) do
        navigation_link("Archive", destination: "/archive")
      end
      toolbar(label: "Editing tools") do
        toolbar_item(placement: :primary_action, priority: :pinned) { button("Bold", type: "button") }
        toolbar_item(placement: :secondary_action) { button("Italic", type: "button") }
      end
    end
    fragment = Nokogiri::HTML.fragment(html)

    popover = fragment.at_css("details#quick-actions[open]")
    assert_equal "dialog", popover.at_css("summary")["aria-haspopup"]
    assert_equal "Quick actions", popover.at_css("summary").text
    assert_equal "dialog", popover.at_css("#quick-actions-content")["role"]

    toolbar = fragment.at_css("[role='toolbar'][aria-label='Editing tools']")
    assert_equal "horizontal", toolbar["aria-orientation"]
    assert_equal "primary_action", toolbar.at_css(".swift-ui-toolbar-item")["data-sui-toolbar-placement"]
    assert_equal "pinned", toolbar.at_css(".swift-ui-toolbar-item")["data-sui-toolbar-priority"]
    assert_equal "automatic", toolbar.at_css(".swift-ui-toolbar-item")["data-sui-toolbar-visibility"]
    assert_equal %w[Bold Italic], toolbar.css("button").map(&:text)
    assert toolbar.css("button").none? { |control| control.key?("tabindex") },
      "all toolbar controls should remain tabbable before enhancement"
    assert_equal 2, toolbar.at_css(".swift-ui-toolbar-items").css(".swift-ui-toolbar-item").length
    assert_empty toolbar.at_css(".swift-ui-toolbar-overflow-items").css(".swift-ui-toolbar-item")
    assert toolbar.at_css("details.swift-ui-toolbar-overflow").key?("hidden")
  end

  test "adaptive toolbar declares overflow pinning visibility and scroll minimization without weakening fallback" do
    html = render_dsl do
      toolbar(
        label: "Document actions",
        overflow_label: "More document actions",
        minimize_on_scroll: true,
        minimize_threshold: 36
      ) do
        toolbar_item(priority: :pinned) { button("Save", type: "button") }
        toolbar_item(priority: :high) { button("Preview", type: "button") }
        toolbar_item(priority: :low) { button("Export", type: "button") }
        toolbar_item(visibility: :visible) { button("Status", type: "button") }
        toolbar_item(visibility: :overflow) { button("Advanced", type: "button") }
      end
    end
    toolbar = Nokogiri::HTML.fragment(html).at_css("[role='toolbar']")
    primary = toolbar.at_css("[data-sui-toolbar-role='items']")
    disclosure = toolbar.at_css("[data-sui-toolbar-role='overflow']")
    descriptor = JSON.parse(toolbar["data-sui-toolbar"])

    assert_equal true, descriptor.fetch("overflow")
    assert_equal true, descriptor.fetch("minimizeOnScroll")
    assert_equal 36, descriptor.fetch("minimizeThreshold")
    assert_equal "More document actions", disclosure.at_css("summary").text
    assert_equal disclosure["id"] + "-items", disclosure.at_css("summary")["aria-controls"]
    assert_equal "group", disclosure.at_css(".swift-ui-toolbar-overflow-items")["role"]
    assert_equal %w[Save Preview Export Status Advanced], primary.css("button").map(&:text)
    assert_empty disclosure.at_css(".swift-ui-toolbar-overflow-items").css("button")
    assert toolbar.css("button").none? { |control| control.key?("tabindex") },
      "server output must leave every action in the normal tab order"

    items = toolbar.css(".swift-ui-toolbar-item")
    assert_equal %w[pinned high low automatic automatic], items.map { |item| item["data-sui-toolbar-priority"] }
    assert_equal %w[automatic automatic automatic visible overflow],
      items.map { |item| item["data-sui-toolbar-visibility"] }
  end

  test "invalid declarations fail closed" do
    assert_raises(ArgumentError) { render_dsl { navigation_stack(label: "") {} } }
    assert_raises(ArgumentError) { render_dsl { navigation_link("Bad", destination: "javascript:alert(1)") } }
    assert_raises(ArgumentError) do
      render_dsl { presentation_trigger("Bad", target: "dialog", fallback: "https://example.test/dialog") }
    end
    assert_raises(ArgumentError) do
      render_dsl { presentation_trigger("Bad", target: "dialog", fallback: "relative/dialog") }
    end
    assert_raises(ArgumentError) { render_dsl { sheet("Bad", dismiss_path: "//example.test/back") {} } }
    assert_raises(ArgumentError) { render_dsl { alert("Bad", dismiss_path: "/\\example.test/back") } }
    assert_raises(ArgumentError) { render_dsl { tab("Orphan", value: :orphan) { text("No") } } }
    assert_raises(ArgumentError) { render_dsl { tab_view(label: "Empty") {} } }
    assert_raises(ArgumentError) do
      render_dsl do
        tab_view(label: "Duplicate") do
          tab("One", value: :same) { text("One") }
          tab("Two", value: :same) { text("Two") }
        end
      end
    end
    assert_raises(ArgumentError) { render_dsl { sheet("Bad", id: "bad id") {} } }
    assert_raises(ArgumentError) { render_dsl { alert("Bad", presented: "yes") } }
    assert_raises(ArgumentError) do
      render_dsl { confirmation_dialog("Bad", presented: true, item: {}) }
    end
    assert_raises(ArgumentError) { render_dsl { toolbar(label: "Tools", orientation: :diagonal) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar_item(placement: :magic) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar_item(priority: :urgent) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar_item(visibility: :sometimes) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar_item(priority: :pinned, visibility: :overflow) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar(label: "Tools", overflow: "yes") {} } }
    assert_raises(ArgumentError) do
      render_dsl { toolbar(label: "Tools", overflow: false, minimize_on_scroll: true) {} }
    end
    assert_raises(ArgumentError) { render_dsl { toolbar(label: "Tools", minimize_threshold: -1) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar(label: "Tools", minimize_threshold: 1_001) {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar(label: "Tools", minimize_threshold: "24") {} } }
    assert_raises(ArgumentError) { render_dsl { toolbar(label: "Tools", overflow_label: " ") {} } }
  end

  test "generated presentation identifiers remain unique across nested contexts" do
    html = render_dsl do
      div { sheet("First", presented: false) { text("First body") } }
      div { sheet("Second", presented: false) { text("Second body") } }
      div { popover("Third") { text("Third body") } }
    end
    ids = Nokogiri::HTML.fragment(html).css("dialog[id], details[id]").map { |node| node["id"] }

    assert_equal 3, ids.length
    assert_equal ids, ids.uniq
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end
end
