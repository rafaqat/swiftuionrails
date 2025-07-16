# frozen_string_literal: true

require "test_helper"

class HeaderComponentTest < ViewComponent::TestCase
  test "header component renders without error" do
    component = Playground::HeaderComponent.new(
      title: "Test Title",
      badge_text: "Test Badge"
    )
    
    # This should not raise an error
    rendered = render_inline(component)
    
    assert_selector "header"
    assert_text "Test Title"
    assert_text "Test Badge"
  end
  
  test "header DSL method returns an element" do
    component = Playground::HeaderComponent.new
    
    # Test if the DSL methods are available
    assert component.respond_to?(:header)
    assert component.respond_to?(:div)
    assert component.respond_to?(:create_element)
  end
end