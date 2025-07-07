# frozen_string_literal: true

# Copyright 2025

require 'view_component/storybook/stories'
require_relative 'storybook/stories'

module SwiftUIRails
  # A SwiftUI-like base class for component stories that uses the DSL directly
  class StorybookStories < ViewComponent::Storybook::Stories
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Context
    include SwiftUIRails::DSL
    include SwiftUIRails::Helpers

    class << self
      ##
      # Defines a set of preview scenarios for a component using a SwiftUI-like DSL.
      # If no title is provided, the component's name is used as the default title.
      # Each scenario defined within the block becomes an instance method for previewing that scenario.
      # @param [String, nil] title Optional title for the preview group.
      def preview(title = nil, &block)
        # If no title provided, use the component name
        title ||= name.gsub(/Stories$/, '').underscore.humanize

        # Create a preview context and evaluate the block
        preview_context = PreviewContext.new
        preview_context.instance_eval(&block)

        # Define methods for each scenario
        preview_context.scenarios.each do |scenario_name, scenario_block|
          define_scenario_method(scenario_name, scenario_block)
        end
      end

      private

      ##
      # Dynamically defines an instance method for a scenario, allowing it to be invoked by name.
      # The defined method executes the scenario block within the SwiftUI DSL context.
      def define_scenario_method(scenario_name, scenario_block)
        # Create a unique method name for this scenario
        method_name = scenario_name.parameterize.underscore

        # Define the method that Storybook will call
        define_method(method_name) do |**_args|
          # Execute the scenario in the context of DSL
          swift_ui(&scenario_block)
        end
      end
    end

    # Context for evaluating preview blocks
    class PreviewContext
      attr_reader :scenarios

      ##
      # Initializes a new PreviewContext with an empty set of scenarios.
      def initialize
        @scenarios = {}
      end

      ##
      # Registers a scenario with the given name and associated block in the preview context.
      # @param [String] name - The name of the scenario.
      def scenario(name, &block)
        @scenarios[name] = block
      end
    end
  end
end
# Copyright 2025
