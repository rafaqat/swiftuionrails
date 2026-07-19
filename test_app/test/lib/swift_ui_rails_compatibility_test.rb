# frozen_string_literal: true

require "test_helper"

class SwiftUIRailsCompatibilityTest < ActiveSupport::TestCase
  Compatibility = SwiftUIRails::Compatibility
  DOCUMENT_PATH = Rails.root.join("..", "docs", "swiftui_compatibility.md").expand_path

  test "registry is internally valid and uses the WWDC26 baseline" do
    assert Compatibility.validate!
    assert_equal "SwiftUI 2027 releases", Compatibility::BASELINE[:release]
    assert_equal "WWDC26", Compatibility::BASELINE[:announced_at]
    assert_equal "Xcode 27", Compatibility::BASELINE[:toolchain]
  end

  test "registry exposes every compatibility and delivery classification" do
    summary = Compatibility.summary

    assert_equal Compatibility.features.length, summary[:total]
    assert_equal Compatibility::STATUS_DEFINITIONS.keys.sort, summary[:by_status].keys.sort
    assert_equal Compatibility::DELIVERY_DEFINITIONS.keys.sort, summary[:by_delivery].keys.sort
    assert_equal Compatibility::CATEGORIES.keys.sort, summary[:by_category].keys.sort
  end

  test "feature data is queryable and deeply immutable" do
    bindings = Compatibility.fetch("bindings")

    assert_equal :partial, bindings[:status]
    assert_equal :available, bindings[:delivery]
    assert_includes bindings[:apis], "binding"
    assert_same bindings, Compatibility.feature(:bindings)
    assert_raises(KeyError) { Compatibility.fetch(:does_not_exist) }
    assert_raises(FrozenError) { bindings[:apis] << "unsafe mutation" }
  end

  test "delivery filters do not present planned APIs as available" do
    planned = Compatibility.select(delivery: :planned)
    available = Compatibility.select(delivery: :available)

    assert planned.any?
    assert available.any?
    assert planned.all? { |feature| feature[:gap].present? }
    assert_empty planned.map { |feature| feature[:id] } & available.map { |feature| feature[:id] }
  end

  test "implemented parity families are no longer described as planned or prototype" do
    implemented = %i[
      semantic_text_styles custom_view_appearances
      local_state bindings observation environment_values reactive_rendering
      navigation_stack presentation alerts_and_dialogs gestures focus toolbars
      charts maps canvas rich_text web_view arbitrary_container_reordering
      swipe_actions_container toolbar_visibility_and_overflow document_api
      async_image_caching item_bound_presentations
    ]

    implemented.each do |id|
      assert_equal :available, Compatibility.fetch(id)[:delivery], id.to_s
    end
    assert_equal %w[ appearance visually_hidden ], Compatibility.fetch(:custom_view_appearances)[:apis]
    assert_equal :prototype, Compatibility.fetch(:lazy_containers)[:delivery]
    assert_equal :planned, Compatibility.fetch(:drag_and_drop)[:delivery]
    assert_equal :not_applicable, Compatibility.fetch(:scenes_and_windows)[:delivery]
  end

  test "current WWDC26 feature families are explicit and sourced to Apple" do
    expected = %i[
      content_builder
      state_macro
      arbitrary_container_reordering
      swipe_actions_container
      toolbar_visibility_and_overflow
      document_api
      async_image_caching
      item_bound_presentations
      liquid_glass_refresh
    ]

    assert_equal expected.sort, Compatibility.select(category: :wwdc26).map { |feature| feature[:id] }.sort
    Compatibility.select(category: :wwdc26).each do |feature|
      assert feature[:sources].any? { |source| source.to_s.start_with?("wwdc26") || source == :swiftui_updates || source == :tn3211 }, feature[:id].to_s
    end
  end

  test "human matrix stays synchronized with the executable registry" do
    rows = File.read(DOCUMENT_PATH).scan(
      /^\| `(?<id>[a-z0-9_]+)` \| `(?<category>[a-z0-9_]+)` \| .*? \| `(?<status>[a-z_]+)` \| `(?<delivery>[a-z_]+)` \|/
    ).to_h do |id, category, status, delivery|
      [id.to_sym, {category: category.to_sym, status: status.to_sym, delivery: delivery.to_sym}]
    end

    assert_equal Compatibility.features.length, rows.length
    Compatibility.features.each do |feature|
      assert_equal feature.slice(:category, :status, :delivery), rows[feature[:id]], feature[:id].to_s
    end
  end
end
