# frozen_string_literal: true

require "view_component/storybook/stories"
require_relative "storybook/stories"

module SwiftUIRails
  # A SwiftUI-like base class for component stories that uses the DSL directly
  class Storybook < ViewComponent::Storybook::Stories
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Context
    include SwiftUIRails::DSL
    include SwiftUIRails::Helpers
    
    class << self
      # The main entry point for the SwiftUI-like preview DSL
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
      
      def define_scenario_method(scenario_name, scenario_block)
        # Create a unique method name for this scenario
        method_name = scenario_name.parameterize.underscore
        
        # Define the method that Storybook will call
        define_method(method_name) do |**args|
          # Execute the scenario in the context of DSL
          swift_ui(&scenario_block)
        end
      end
    end
    
    # Context for evaluating preview blocks
    class PreviewContext
      attr_reader :scenarios
      
      def initialize
        @scenarios = {}
      end
      
      def scenario(name, &block)
        @scenarios[name] = block
      end
    end
  end
end