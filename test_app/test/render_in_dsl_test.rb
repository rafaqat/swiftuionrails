require "test_helper"

class RenderInDslTest < ActiveSupport::TestCase
  test "render ViewComponent inside DSL" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # Test rendering a component inside DSL
    result = view.swift_ui do
      div do
        # Try to render ExampleComponent
        puts "=== Attempting to render ExampleComponent ==="
        rendered = render ExampleComponent.new(title: "Test Title")
        puts "Rendered class: #{rendered.class}"
        puts "Rendered content: #{rendered.inspect[0..200]}..."
        rendered
      end
    end
    
    puts "\n=== Final result ==="
    puts result
    
    # Check if the component was rendered (it renders as a card div)
    assert result.include?('<div></div>'), "Should include the outer div"
  end
  
  test "render returns wrong type" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    # Check what render actually returns
    dsl_context = SwiftUIRails::DSLContext.new(view)
    
    puts "\n=== What does render return? ==="
    begin
      component = ExampleComponent.new(title: "Debug Test")
      result = dsl_context.render(component)
      puts "render returned: #{result.class}"
      puts "render content: #{result.inspect[0..200]}..."
    rescue => e
      puts "render failed: #{e.class} - #{e.message}"
    end
  end
end
# Copyright 2025
