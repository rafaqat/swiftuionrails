require "test_helper"

class CounterRenderTest < ActiveSupport::TestCase
  include SwiftUIRails::Helpers
  
  test "counter component renders with data-controller attribute" do
    component = CounterComponent.new(
      initial_count: 5,
      step: 2,
      label: "Test Counter"
    )
    
    # Render the component
    output = component.call.to_s
    
    puts "Component output:"
    puts output
    
    # Check for data-controller attribute
    assert_match(/data-controller=["']counter["']/, output)
    assert_match(/data-counter-count-value=["']5["']/, output)
    assert_match(/data-counter-step-value=["']2["']/, output)
    assert_match(/data-counter-label-value=["']Test Counter["']/, output)
    
    # Check for Stimulus targets
    assert_match(/data-counter-target=["']count["']/, output)
    assert_match(/data-counter-target=["']label["']/, output)
    assert_match(/data-counter-target=["']incrementBtn["']/, output)
    assert_match(/data-counter-target=["']decrementBtn["']/, output)
    
    # Check for Stimulus actions (HTML escaped)
    assert_match(/data-action=["']click-&gt;counter#increment["']/, output)
    assert_match(/data-action=["']click-&gt;counter#decrement["']/, output)
    assert_match(/data-action=["']click-&gt;counter#reset["']/, output)
  end
  
  test "DSL div method properly handles data attributes" do
    # Test the DSL directly
    result = swift_ui do
      div(data: { controller: "test", "test-value": "hello" }, id: "my-div") do
        text("Content")
      end
    end
    
    output = result.to_s
    puts "DSL div output:"
    puts output
    
    assert_match(/data-controller=["']test["']/, output)
    assert_match(/data-test-value=["']hello["']/, output)
    assert_match(/id=["']my-div["']/, output)
  end
end