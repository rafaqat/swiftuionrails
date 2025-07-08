# frozen_string_literal: true

# Copyright 2025

class SimpleTestComponentStories < ViewComponent::Storybook::Stories
  control :message, as: :text, default: "Hello from Test Component"

  def default(message: "Hello from Test Component")
    SimpleTestComponent.new(message: message)
  end
end
# Copyright 2025
