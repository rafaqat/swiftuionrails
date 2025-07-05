# frozen_string_literal: true

require "test_helper"

class StorybookViewDebugTest < ActionDispatch::IntegrationTest
  test "debug view variables for card component" do
    # Monkey patch the controller to capture variables
    StorybookController.class_eval do
      alias_method :original_show, :show
      
      def show
        original_show
        
        # Debug the instance variables
        Rails.logger.info "=== VIEW VARIABLES DEBUG ==="
        Rails.logger.info "@story_config: #{@story_config}"
        Rails.logger.info "@story_config[:controls]: #{@story_config[:controls] if @story_config}"
        Rails.logger.info "@component_props: #{@component_props}"
        Rails.logger.info "=== END DEBUG ==="
      end
    end
    
    get "/storybook/show", params: { story: "card_component" }
    assert_response :success
    
    # Check if the form section exists in the response
    assert response.body.include?("controls-form"), "Should include controls-form"
    assert response.body.include?("@story_config"), "Should include @story_config reference"
    
    # Clean up the monkey patch
    StorybookController.class_eval do
      alias_method :show, :original_show
      remove_method :original_show
    end
  end
end
# Copyright 2025
