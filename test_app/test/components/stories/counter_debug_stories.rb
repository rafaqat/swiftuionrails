# frozen_string_literal: true

class CounterDebugStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  def default
    # Simple debug output
    swift_ui do
      vstack(spacing: 4) do
        text("Debug: Counter Story")
          .font_size("xl")
          .font_weight("bold")
        
        text("This is a test to see if anything renders")
          .text_color("gray-600")
        
        # Try to render the counter component directly
        div do
          "Counter component should appear below:"
        end
        
        # Try rendering without swift_ui wrapper
        render CounterComponent.new(
          initial_count: 0,
          step: 1,
          label: "Test Counter"
        )
      end
    end
  end
  
  def simple_test
    # Even simpler test
    "<div>Simple HTML test</div>".html_safe
  end
end