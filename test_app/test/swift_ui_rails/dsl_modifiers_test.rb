# Copyright 2025
require "test_helper"

class SwiftUIRails::DSLModifiersTest < ActiveSupport::TestCase
  def setup
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  # Test Spacing Modifiers

  test "margin modifiers add correct classes" do
    result = @view.swift_ui do
      div.m(4).mt(2).mb(3).ml(5).mr(6).mx(7).my(8)
    end

    assert_includes result, "m-4"
    assert_includes result, "mt-2"
    assert_includes result, "mb-3"
    assert_includes result, "ml-5"
    assert_includes result, "mr-6"
    assert_includes result, "mx-7"
    assert_includes result, "my-8"
  end

  test "padding modifiers add correct classes" do
    result = @view.swift_ui do
      div.p(4).pt(2).pb(3).pl(5).pr(6).px(7).py(8)
    end

    assert_includes result, "p-4"
    assert_includes result, "pt-2"
    assert_includes result, "pb-3"
    assert_includes result, "pl-5"
    assert_includes result, "pr-6"
    assert_includes result, "px-7"
    assert_includes result, "py-8"
  end

  test "space modifiers handle different values" do
    result = @view.swift_ui do
      vstack do
        div.p(0)     # Zero padding
        div.m("px")  # Pixel value
        div.p(2.5)   # Decimal value
      end
    end

    assert_includes result, "p-0"
    assert_includes result, "m-px"
    assert_includes result, "p-2.5"
  end

  # Test Sizing Modifiers

  test "width modifiers" do
    result = @view.swift_ui do
      div.w(64).min_w(32).max_w("xl")
    end

    assert_includes result, "w-64"
    assert_includes result, "min-w-32"
    assert_includes result, "max-w-xl"
  end

  test "height modifiers" do
    result = @view.swift_ui do
      div.h(64).min_h(32).max_h("screen")
    end

    assert_includes result, "h-64"
    assert_includes result, "min-h-32"
    assert_includes result, "max-h-screen"
  end

  test "full width and height" do
    result = @view.swift_ui do
      div.w("full").h("full")
    end

    assert_includes result, "w-full"
    assert_includes result, "h-full"
  end

  # Test Text Modifiers

  test "text size modifier" do
    sizes = %w[xs sm base lg xl 2xl 3xl]
    sizes.each do |size|
      result = @view.swift_ui do
        text("Test").text_size(size)
      end
      assert_includes result, "text-#{size}"
    end
  end

  test "text color modifier" do
    result = @view.swift_ui do
      text("Colored").text_color("blue-600")
    end

    assert_includes result, "text-blue-600"
  end

  test "font weight modifier" do
    weights = %w[thin light normal medium semibold bold extrabold black]
    weights.each do |weight|
      result = @view.swift_ui do
        text("Test").font_weight(weight)
      end
      assert_includes result, "font-#{weight}"
    end
  end

  # Test Visual Modifiers

  test "background color modifier" do
    result = @view.swift_ui do
      div.bg("red-500")
    end

    assert_includes result, "bg-red-500"
  end

  test "border modifiers" do
    result = @view.swift_ui do
      div.border.border(2)
    end

    assert_includes result, "border"
    assert_includes result, "border-2"
  end

  test "rounded modifier" do
    result = @view.swift_ui do
      vstack do
        div.rounded        # Default
        div.rounded("md")  # Size
        div.rounded("full") # Full
      end
    end

    assert_includes result, 'class="rounded"'
    assert_includes result, 'class="rounded-md"'
    assert_includes result, 'class="rounded-full"'
  end

  test "shadow modifier" do
    shadows = %w[sm md lg xl 2xl none]
    shadows.each do |shadow|
      result = @view.swift_ui do
        div.shadow(shadow)
      end
      assert_includes result, "shadow-#{shadow}"
    end
  end

  # Test Display Modifiers

  test "display type modifiers" do
    result = @view.swift_ui do
      vstack do
        div.flex
        div.block
        div.inline
        div.hidden
      end
    end

    assert_includes result, 'class="flex"'
    assert_includes result, 'class="block"'
    assert_includes result, 'class="inline"'
    assert_includes result, 'class="hidden"'
  end

  test "flex modifier with tw for additional classes" do
    result = @view.swift_ui do
      div.flex.tw("flex-row items-center justify-between")
    end

    assert_includes result, "flex"
    assert_includes result, "flex-row"
    assert_includes result, "items-center"
    assert_includes result, "justify-between"
  end

  # Test Method Chaining

  test "modifiers are chainable" do
    result = @view.swift_ui do
      text("Chained")
        .text_size("lg")
        .text_color("blue-600")
        .font_weight("bold")
        .p(4)
        .bg("gray-100")
        .rounded("md")
        .shadow
    end

    # All modifiers should be applied
    assert_includes result, "text-lg"
    assert_includes result, "text-blue-600"
    assert_includes result, "font-bold"
    assert_includes result, "p-4"
    assert_includes result, "bg-gray-100"
    assert_includes result, "rounded-md"
    assert_includes result, "shadow"
  end

  test "chaining works with blocks" do
    result = @view.swift_ui do
      div.p(4).bg("white").rounded("lg") do
        text("Inside styled div")
      end
    end

    assert_includes result, "p-4"
    assert_includes result, "bg-white"
    assert_includes result, "rounded-lg"
    assert_includes result, "Inside styled div"
  end

  # Test tw() Method

  test "tw method adds custom classes" do
    result = @view.swift_ui do
      div.tw("custom-class another-class")
    end

    assert_includes result, "custom-class"
    assert_includes result, "another-class"
  end

  test "tw method combines with other modifiers" do
    result = @view.swift_ui do
      div.p(4).tw("hover:bg-gray-100 focus:outline-none").rounded
    end

    assert_includes result, "p-4"
    assert_includes result, "hover:bg-gray-100"
    assert_includes result, "focus:outline-none"
    assert_includes result, "rounded"
  end

  # Test Attribute Setting

  test "attr method sets HTML attributes" do
    result = @view.swift_ui do
      div
        .attr(:id, "my-div")
        .attr("data-value", "123")
        .attr(:onclick, "handleClick()")
    end

    assert_includes result, 'id="my-div"'
    assert_includes result, 'data-value="123"'
    assert_includes result, 'onclick="handleClick()"'
  end

  test "disabled modifier" do
    result = @view.swift_ui do
      button("Disabled").disabled(true)
    end

    assert_includes result, 'disabled="disabled"'
  end

  # Test Responsive with tw()

  test "responsive classes via tw method" do
    result = @view.swift_ui do
      div.tw("p-2 sm:p-4 md:p-6 lg:p-8")
    end

    assert_includes result, "sm:p-4"
    assert_includes result, "md:p-6"
    assert_includes result, "lg:p-8"
  end

  # Test State Classes with tw()

  test "hover and focus classes via tw method" do
    result = @view.swift_ui do
      button("Hover me").tw("hover:bg-blue-700 focus:ring-2")
    end

    assert_includes result, "hover:bg-blue-700"
    assert_includes result, "focus:ring-2"
  end

  # Test Complex Chaining Scenarios

  test "complex modifier chain maintains order" do
    result = @view.swift_ui do
      div
        .p(4)
        .m(2)
        .bg("white")
        .rounded("lg")
        .shadow("md")
        .border
        .tw("hover:bg-gray-50 border-gray-200 transition-all duration-200")
        .attr(:id, "complex-div")
    end

    # Check all classes are present
    expected_classes = %w[p-4 m-2 bg-white rounded-lg shadow-md border hover:bg-gray-50 border-gray-200 transition-all duration-200]
    expected_classes.each do |klass|
      assert_includes result, klass
    end

    # Check attribute
    assert_includes result, 'id="complex-div"'
  end
end
# Copyright 2025
