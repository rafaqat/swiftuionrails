# frozen_string_literal: true

class SimpleTestComponentStories < ViewComponent::Storybook::Stories
  control :message, as: :text, default: "Hello from Test Component"
  
  def default(message: "Hello from Test Component")
    SimpleTestComponent.new(message: message)
  end
end
# Copyright 2025
