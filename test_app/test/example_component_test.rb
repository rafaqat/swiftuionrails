# Copyright 2025
require "test_helper"

class ExampleComponentTest < ViewComponent::TestCase
  test "renders with default props" do
    result = render_inline(ExampleComponent.new)

    puts "\n=== ExampleComponent render result ==="
    puts result.to_html

    # The component renders a card div
    assert_selector "div.bg-white.rounded-lg.shadow-md.p-6"
  end

  test "renders with custom props" do
    result = render_inline(ExampleComponent.new(
      title: "Custom Title",
      description: "Custom Description"
    ))

    puts "\n=== ExampleComponent with custom props ==="
    puts result.to_html

    # The component should render the same structure regardless of props
    assert_selector "div.bg-white.rounded-lg.shadow-md.p-6"
  end

  test "check component structure" do
    component = ExampleComponent.new(title: "Test")

    puts "\n=== Component internals ==="
    puts "Component class: #{component.class}"
    puts "Has swift_ui_block? #{component.class.instance_variable_get(:@swift_ui_block).nil? ? 'no' : 'yes'}"

    # Try to call the component directly
    result = component.call
    puts "Direct call result: #{result}"
    
    # Add assertions
    assert_not_nil component.class.instance_variable_get(:@swift_ui_block), "Component should have swift_ui_block"
    assert_kind_of String, result, "Component call should return a String"
    assert result.include?("Test"), "Result should include the title"
  end
end
# Copyright 2025
