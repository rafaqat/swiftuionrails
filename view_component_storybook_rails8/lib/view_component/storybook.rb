# frozen_string_literal: true

# Copyright 2025

require 'active_model'
require 'active_support/dependencies/autoload'

module ViewComponent
  module Storybook
    extend ActiveSupport::Autoload

    autoload :Controls
    autoload :Collections
    autoload :Stories
    autoload :StoriesParser

    autoload :Story
    autoload :Slots

    include ActiveSupport::Configurable
    # Set the location of component previews through app configuration:
    #
    #     config.view_component_storybook.stories_path = Rails.root.join("lib/component_stories")
    #
    # rubocop:disable ThreadSafety/ClassAndModuleAttributes
    # Configuration is set once at boot time and never changes during requests
    mattr_accessor :stories_paths, instance_writer: false
    # rubocop:enable ThreadSafety/ClassAndModuleAttributes

    # Enable or disable component previews through app configuration:
    #
    #     config.view_component_storybook.show_stories = true
    #
    # Defaults to +true+ for development environment
    #
    # rubocop:disable ThreadSafety/ClassAndModuleAttributes
    # Configuration is set once at boot time
    mattr_accessor :show_stories, instance_writer: false
    # rubocop:enable ThreadSafety/ClassAndModuleAttributes

    # Set the entry route for component stories:
    #
    #     config.view_component_storybook.stories_route = "/stories"
    #
    # Defaults to `/rails/stories` when `show_stories` is enabled.
    #
    # rubocop:disable ThreadSafety/ClassAndModuleAttributes
    # Configuration is set once at boot time
    mattr_accessor :stories_route, instance_writer: false
    # rubocop:enable ThreadSafety/ClassAndModuleAttributes

    # :nocov:
    if defined?(ViewComponent::Storybook::Engine)
      ActiveSupport::Deprecation.warn(
        'This manually engine loading is deprecated and will be removed in v1.0.0. ' \
        'Remove `require "view_component/storybook/engine"`.'
      )
    elsif defined?(Rails::Engine)
      require 'view_component/storybook/engine'
    end
    # :nocov:

    # Define how component stories titles are generated:
    #
    #     config.view_component_storybook.stories_title_generator = lambda { |stories|
    #       stories.stories_name.humanize.upcase
    #     }
    #
    # rubocop:disable ThreadSafety/ClassAndModuleAttributes
    # Configuration is set once at boot time
    mattr_accessor :stories_title_generator, instance_writer: false,
                                             default: ->(stories) { stories.stories_name.humanize.titlecase }
    # rubocop:enable ThreadSafety/ClassAndModuleAttributes

    ActiveSupport.run_load_hooks(:view_component_storybook, self)
  end
end
# Copyright 2025
