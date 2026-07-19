# frozen_string_literal: true

require "test_helper"

class EnvironmentInteractionSecurityTest < ActiveSupport::TestCase
  def setup
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "environment keys and declarations cannot inject or replace component methods" do
    assert_raises(ArgumentError) { SwiftUIRails::Environment.normalize_key("theme<script>") }
    assert_raises(ArgumentError) { SwiftUIRails::Environment.normalize_key("__send__") }

    assert_raises(ArgumentError) do
      Class.new(SwiftUIRails::Component::Base) do
        environment :render_in
      end
    end
  end

  test "task only accepts bounded same-origin paths and fixed methods" do
    unsafe_urls = [
      "https://evil.example/task",
      "//evil.example/task",
      "javascript:alert(1)",
      "/\\evil.example/task",
      "/task\nX-Injected: true",
      "/#{'a' * 2050}"
    ]

    unsafe_urls.each do |url|
      assert_raises(ArgumentError, url) do
        @view.swift_ui { div("Fallback").task(url: url) }
      end
    end

    assert_raises(ArgumentError) do
      @view.swift_ui { div("Fallback").task(url: "/safe", method: :delete) }
    end
    assert_raises(ArgumentError) do
      @view.swift_ui { div("Fallback").task(url: "/safe", method: :post) }
    end

    manual_post = @view.swift_ui do
      div("Fallback").refreshable(url: "/safe", method: :post)
    end
    descriptor = JSON.parse(Nokogiri::HTML.fragment(manual_post).at_css("[data-sui-task]")["data-sui-task"])
    assert_equal "POST", descriptor.fetch("method")
    assert_equal "manual", descriptor.fetch("trigger")
  end

  test "gesture numeric inputs and keyboard filters are allowlisted" do
    assert_raises(ArgumentError) do
      @view.swift_ui { div.on_long_press(minimum_duration: "0.5;alert(1)") {} }
    end
    assert_raises(ArgumentError) do
      @view.swift_ui { div.on_drag(axis: "both; background:url(javascript:alert(1))") {} }
    end
    assert_raises(ArgumentError) do
      @view.swift_ui { div.on_key_press(keys: "Enter<script>") {} }
    end
    assert_raises(ArgumentError) do
      @view.swift_ui { div.on_key_press(keys: :enter, modifiers: :command) {} }
    end
  end

  test "raw server action event names are validated before reaching data attributes" do
    element = @view.swift_ui do
      div("Safe")
    end

    assert_includes element, "Safe"
    unsafe_element = SwiftUIRails::DSL::Element.new(:button, "Unsafe", {}, nil)
    assert_raises(ArgumentError) do
      unsafe_element.add_server_action("click x->evil#run") {}
    end
  end

  test "focus values reject objects, control characters, and oversized values" do
    assert_raises(TypeError) { SwiftUIRails::FocusState.serialize_value(Object.new) }
    assert_raises(ArgumentError) { SwiftUIRails::FocusState.serialize_value("line\nbreak") }
    assert_raises(ArgumentError) { SwiftUIRails::FocusState.serialize_value("a" * 129) }
  end
end
