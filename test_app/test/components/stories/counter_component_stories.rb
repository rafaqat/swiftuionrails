# frozen_string_literal: true

# Copyright 2025

class CounterComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  # Define interactive controls
  control :initial_count, as: :number, default: 0, min: -100, max: 100
  control :step, as: :number, default: 1, min: 1, max: 10
  control :counter_label, as: :text, default: "Counter"

  def default(initial_count: 0, step: 1, counter_label: "Counter")
    # Return the counter component directly
    CounterComponent.new(
      initial_count: initial_count,
      step: step,
      counter_label: counter_label
    )
  end
end
# Copyright 2025
