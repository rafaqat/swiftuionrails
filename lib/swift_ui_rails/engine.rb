# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  class Engine < ::Rails::Engine
    isolate_namespace SwiftUIRails

    config.eager_load_namespaces << SwiftUIRails

    initializer 'swift_ui_rails.assets' do |app|
      app.config.assets.precompile += %w[swift_ui_rails.js swift_ui_rails.css]
    end

    initializer 'swift_ui_rails.helpers' do
      ActiveSupport.on_load(:action_controller_base) do
        helper SwiftUIRails::Helpers
      end
    end

    initializer 'swift_ui_rails.view_component' do
      require 'view_component'
    end

    config.after_initialize do
      # Include Tailwind modifiers if enabled
      if SwiftUIRails.configuration.tailwind_enabled
        SwiftUIRails::Component::Base.include(SwiftUIRails::Tailwind::Modifiers)
        # Element class was removed in our refactor
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # Explicitly load generators in the initializer
    initializer 'swift_ui_rails.generators' do
      Rails.application.config.generators.templates.unshift File.expand_path('../generators/swift_ui_rails/templates', __dir__)
    end
  end
end
# Copyright 2025
