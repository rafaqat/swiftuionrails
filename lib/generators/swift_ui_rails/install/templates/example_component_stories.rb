# frozen_string_literal: true

# Copyright 2025

class ExampleComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Storybook::Layouts
  include SwiftUIRails::Storybook::Previews
  include SwiftUIRails::Storybook::Documentation

  # Default story
  story :default do
    component ExampleComponent

    controls do
      swift_text :title, default: 'Hello from SwiftUI Rails!'
      swift_text :description, default: 'This is an example component showing state management and interactions.'
    end
  end

  # Playground story with all features
  story :playground do
    component ExampleComponent

    controls do
      swift_text :title, default: 'SwiftUI Rails Playground'
      swift_text :description, default: 'Try out different props and see how the component responds!'
    end

    layout :playground
  end

  # Documentation story
  story :docs do
    component ExampleComponent

    controls do
      swift_text :title, default: 'Component Documentation'
      swift_text :description, default: "This story shows the component's props and usage examples."
    end

    layout :documentation
  end

  # Interactive story
  story :interactive do
    component ExampleComponent

    controls do
      swift_text :title, default: 'Interactive Example'
      swift_text :description, default: 'Click the buttons to see state management in action!'
    end

    layout :interactive_demo
  end
end
# Copyright 2025
