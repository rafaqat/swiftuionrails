require "test_helper"

class SwiftUIRails::ErrorHandlingTest < ViewComponent::TestCase
  # Test invalid prop types
  
  class StrictPropsComponent < SwiftUIRails::Component::Base
    prop :name, type: String, required: true
    prop :age, type: Integer
    prop :active, type: [TrueClass, FalseClass]
    
    def call
      content_tag(:div) do
        "#{name}, #{age || 'unknown'}, #{active ? 'active' : 'inactive'}"
      end
    end
  end
  
  test "raises error for missing required prop" do
    assert_raises(ArgumentError, "Required prop 'name' is missing") do
      StrictPropsComponent.new
    end
  end
  
  test "raises error for invalid prop type" do
    assert_raises(TypeError) do
      StrictPropsComponent.new(name: "John", age: "not a number")
    end
  end
  
  test "accepts valid props" do
    component = StrictPropsComponent.new(name: "John", age: 30, active: true)
    assert_equal "John", component.name
    assert_equal 30, component.age
    assert_equal true, component.active
  end
  
  test "accepts array type props" do
    component = StrictPropsComponent.new(name: "John", active: false)
    assert_equal false, component.active
  end
  
  # Test invalid DSL usage
  
  test "DSL methods handle nil content gracefully" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    result = view.swift_ui do
      text(nil)
    end
    
    assert_includes result, "<span></span>"
  end
  
  test "DSL methods handle empty blocks" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    result = view.swift_ui do
      vstack do
        # Empty block
      end
    end
    
    assert_includes result, '<div class="flex flex-col items-center'
  end
  
  # Test edge cases with slots
  
  class EdgeCaseSlotComponent < SwiftUIRails::Component::Base
    renders_one :header
    renders_many :items
    
    def call
      content_tag(:div) do
        safe_join([
          header,
          items.any? ? content_tag(:ul) { safe_join(items.map { |item| content_tag(:li, item) }) } : nil
        ].compact)
      end
    end
  end
  
  test "component renders without any slots" do
    component = EdgeCaseSlotComponent.new
    html = render_inline(component)
    
    assert_equal "<div></div>", html.to_s.strip
  end
  
  test "renders_many handles empty collection" do
    component = EdgeCaseSlotComponent.new
    html = render_inline(component) do |c|
      c.with_header { "Header" }
      # No items added
    end
    
    assert_includes html.to_s, "Header"
    assert_not_includes html.to_s, "<ul"
  end
  
  # Test invalid component configurations
  
  class InvalidMethodComponent < SwiftUIRails::Component::Base
    def call
      content_tag(:div) do
        # This will raise an error
        undefined_method_call
      end
    end
  end
  
  test "component errors are raised properly" do
    component = InvalidMethodComponent.new
    
    assert_raises(NoMethodError) do
      render_inline(component)
    end
  end
  
  # Test prop defaults with nil
  
  class NilDefaultComponent < SwiftUIRails::Component::Base
    prop :value, default: nil
    prop :name, default: "Default"
    
    def call
      content_tag(:div) do
        "#{value.inspect}, #{name}"
      end
    end
  end
  
  test "handles nil default values" do
    component = NilDefaultComponent.new
    html = render_inline(component)
    
    assert_includes html.to_s, "nil, Default"
  end
  
  # Test computed properties with errors
  
  class ComputedErrorComponent < SwiftUIRails::Component::Base
    prop :divisor, type: Integer, default: 0
    
    computed :result do
      10 / divisor # Will raise ZeroDivisionError
    end
    
    def call
      content_tag(:div) do
        begin
          result.to_s
        rescue ZeroDivisionError
          "Error: Division by zero"
        end
      end
    end
  end
  
  test "computed properties can handle errors gracefully" do
    component = ComputedErrorComponent.new
    html = render_inline(component)
    
    assert_includes html.to_s, "Error: Division by zero"
  end
  
  # Test state changes with invalid values
  
  class StateValidationComponent < SwiftUIRails::Component::Base
    state :count, 0
    
    def call
      content_tag(:div) do
        # Try to set invalid state
        self.count = "invalid" if @attempt_invalid
        count.to_s
      end
    end
    
    def attempt_invalid!
      @attempt_invalid = true
    end
  end
  
  test "state accepts any value type" do
    component = StateValidationComponent.new
    component.attempt_invalid!
    html = render_inline(component)
    
    # State doesn't validate types, so it should accept the string
    assert_includes html.to_s, "invalid"
  end
  
  # Test deeply nested nil handling
  
  test "DSL handles deeply nested nil content" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    result = view.swift_ui do
      vstack do
        hstack do
          nil
        end
        nil
        div do
          nil
        end
      end
    end
    
    assert result.present?
    assert_includes result, "flex flex-col"
  end
  
  # Test invalid CSS classes
  
  test "modifiers handle invalid values gracefully" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    result = view.swift_ui do
      div.p(nil).m("").bg(false)
    end
    
    # Should still render, just with potentially invalid classes
    assert_includes result, "<div"
  end
  
  private
  
  def render_inline(component, &block)
    test_controller = ApplicationController.new
    test_controller.request = ActionDispatch::TestRequest.create
    
    view_context = test_controller.view_context
    component.render_in(view_context, &block)
  end
end
# Copyright 2025
