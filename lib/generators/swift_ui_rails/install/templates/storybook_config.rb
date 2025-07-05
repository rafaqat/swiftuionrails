# frozen_string_literal: true

if defined?(ViewComponent::Storybook)
  ViewComponent::Storybook.configure do |config|
    # Where to find component stories
    config.stories_paths = [Rails.root.join("test/components/stories")]
    
    # Story titles use component names
    config.stories_title_generator = lambda do |story_class|
      story_class.name.chomp("Stories").titleize
    end
  end
  
  # Add SwiftUI Rails storybook helpers to all stories
  ViewComponent::Storybook::Stories.class_eval do
    include SwiftUIRails::Storybook if defined?(SwiftUIRails::Storybook)
  end
  
  # Configure preview layouts
  Rails.application.config.to_prepare do
    ViewComponent::Storybook.stories_layout = "storybook"
  end
end