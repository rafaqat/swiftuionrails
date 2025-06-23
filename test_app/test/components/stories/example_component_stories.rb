# frozen_string_literal: true

class ExampleComponentStories < ViewComponent::Storybook::Stories
  include LiveStories
  
  # Define controls for traditional stories
  control :title, as: :text, default: "Hello from SwiftUI Rails!"
  control :description, as: :text, default: "This is an example component showing state management and interactions."
  
  # Session configuration for live stories
  session_config do
    persist_for 1.hour
    auto_save true
    live_updates true
  end
  
  # Traditional static story
  def default(title: "Hello from SwiftUI Rails!", description: "This is an example component showing state management and interactions.")
    render ExampleComponent.new(title: title, description: description)
  end
  
  # Enhanced live story with full interactivity
  live_story :interactive_playground do
    component ExampleComponent
    
    controls do
      text :title, default: "🚀 Interactive Playground"
      text :description, default: "Click buttons to see real-time state changes!"
    end
    
    session_state do
      initial_state counter: 0, show_details: false
      persist_for 30.minutes
      auto_save true
    end
    
    live_updates enabled: true
    stimulus_controller "interactive-story"
  end
  
  # Live story focusing on counter functionality
  live_story :counter_demo do
    component ExampleComponent
    
    controls do
      text :title, default: "Counter Demo"
      text :description, default: "Test the counter increment/decrement functionality"
    end
    
    session_state do
      initial_state counter: 10, show_details: true
    end
    
    live_updates enabled: true
  end
  
  # Live story for testing effects
  live_story :effects_demo do
    component ExampleComponent
    
    controls do
      text :title, default: "Effects Demo"
      text :description, default: "Watch the console for effect logging"
    end
    
    session_state do
      initial_state counter: 0, show_details: false
    end
    
    live_updates enabled: true
  end
  
  # Traditional playground story (static)
  def playground(title: "SwiftUI Rails Playground", description: "Try out different props and see how the component responds!")
    render ExampleComponent.new(title: title, description: description)
  end
  
  # Documentation story
  def docs(title: "Component Documentation", description: "This story shows the component's props and usage examples.")
    render ExampleComponent.new(title: title, description: description)
  end
end