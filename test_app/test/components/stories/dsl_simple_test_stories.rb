# frozen_string_literal: true

class DslSimpleTestStories < ViewComponent::Storybook::Stories
  def default
    # Test 1: Simple HTML string
    "<div>Simple HTML Test</div>"
  end
  
  def with_dsl
    # Test 2: Using swift_ui DSL
    swift_ui do
      div do
        text("Swift UI DSL Test")
      end
    end
  end
end