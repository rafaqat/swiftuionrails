# frozen_string_literal: true
# Copyright 2025

# Updated to use our Rails 8 compatible fork
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
  if defined?(ViewComponent::Storybook::Stories) && defined?(SwiftUIRails::Storybook)
    # ViewComponent::Storybook::Stories is a module, so we need to prepend to it
    ViewComponent::Storybook::Stories.module_eval do
      def self.included(base)
        super
        base.include SwiftUIRails::Storybook if defined?(SwiftUIRails::Storybook)
      end
    end
  end
  
  # Configure preview layouts
  Rails.application.config.to_prepare do
    # ViewComponent::Storybook doesn't have stories_layout method
    # Instead, we'll handle layout in the controller or views
  end
end
# Copyright 2025
