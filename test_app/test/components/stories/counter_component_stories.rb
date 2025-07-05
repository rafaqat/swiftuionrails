# frozen_string_literal: true

class CounterComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers
  
  # Define interactive controls
  control :initial_count, as: :number, default: 0, min: -100, max: 100
  control :step, as: :number, default: 1, min: 1, max: 10
  control :label, as: :text, default: "Counter"
  
  def default(initial_count: 0, step: 1, label: "Counter")
    # Return the counter component directly
    CounterComponent.new(
      initial_count: initial_count,
      step: step,
      label: label
    )
  end
end
# Copyright 2025
