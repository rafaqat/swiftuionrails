require "test_helper"

class NewDslMethodsTest < ActionView::TestCase
  include SwiftUIRails::Helpers
  
  test "select and option DSL methods work correctly" do
    html = swift_ui do
      select(name: "color", selected: "blue") do
        option("red", "Red")
        option("blue", "Blue", selected: true)
        option("green", "Green")
      end
    end
    
    assert_includes html, '<select name="color"'
    assert_includes html, '<option value="red">Red</option>'
    assert_includes html, '<option value="blue" selected="selected">Blue</option>'
    assert_includes html, '<option value="green">Green</option>'
  end
  
  test "label DSL method works with different signatures" do
    # Label with text only
    label_text = swift_ui { label("Name") }
    assert_includes label_text, '<label>Name</label>'
    
    # Label with for attribute
    label_for = swift_ui { label("Email", for_input: "email-field") }
    assert_includes label_for, '<label for="email-field">Email</label>'
    
    # Label with block
    label_block = swift_ui do
      label do
        text("Custom content")
      end
    end
    assert_includes label_block, '<label>'
    assert_includes label_block, '<span>Custom content</span>'
  end
  
  test "chainable modifiers work correctly" do
    # Test break_inside
    element = swift_ui { div.break_inside("avoid") }
    assert_includes element, 'class="break-inside-avoid"'
    
    # Test ring_hover
    button_ring = swift_ui { button("Click me").ring_hover(4, "blue-500") }
    assert_includes button_ring, 'class="hover:ring-4 hover:ring-blue-500"'
    
    # Test group_hover_opacity
    div_opacity = swift_ui { div.group_hover_opacity(75) }
    assert_includes div_opacity, 'class="group-hover:opacity-75"'
    
    # Test flex_shrink with value
    flex_div = swift_ui { div.flex_shrink(0) }
    assert_includes flex_div, 'class="flex-shrink-0"'
    
    # Test title attribute
    titled_span = swift_ui { text("Hover me").title("This is a tooltip") }
    assert_includes titled_span, 'title="This is a tooltip"'
    
    # Test style method
    styled_div = swift_ui { div.style("color: red; font-size: 16px") }
    assert_includes styled_div, 'style="color: red; font-size: 16px"'
  end
  
  test "chained modifiers work together" do
    complex_element = swift_ui do
      div
        .bg("gray-100")
        .p(4)
        .rounded("lg")
        .shadow("md")
        .break_inside("avoid")
        .ring_hover(2, "indigo-500")
        .title("Complex element")
        .style("min-height: 100px")
    end
    
    html = complex_element
    assert_includes html, 'bg-gray-100'
    assert_includes html, 'p-4'
    assert_includes html, 'rounded-lg'
    assert_includes html, 'shadow-md'
    assert_includes html, 'break-inside-avoid'
    assert_includes html, 'hover:ring-2'
    assert_includes html, 'hover:ring-indigo-500'
    assert_includes html, 'title="Complex element"'
    assert_includes html, 'style="min-height: 100px"'
  end
end