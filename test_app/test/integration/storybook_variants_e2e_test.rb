require "test_helper"

class StorybookVariantsE2eTest < ActionDispatch::IntegrationTest
  
  # Helper method to check if response contains certain content
  def assert_response_includes(content, message = nil)
    assert response.body.include?(content), message || "Response should include #{content}"
  end
  # This test ensures all story variants work across all components
  
  def setup
    @story_files = Dir[Rails.root.join("test/components/stories/*_stories.rb")]
    @story_classes = @story_files.map do |file|
      story_name = File.basename(file, "_stories.rb")
      story_class_name = "#{story_name.camelize}Stories"
      
      # Load the story file
      load file
      
      # Get the class
      story_class = story_class_name.safe_constantize
      
      {
        file: file,
        name: story_name,
        class_name: story_class_name,
        story_class: story_class
      }
    end.compact.reject { |story| story[:story_class].nil? }
  end
  
  test "all story files can be loaded without errors" do
    @story_classes.each do |story_info|
      assert story_info[:story_class], "Story class #{story_info[:class_name]} should be defined"
      assert story_info[:story_class] < ViewComponent::Storybook::Stories, 
             "#{story_info[:class_name]} should inherit from ViewComponent::Storybook::Stories"
    end
  end
  
  test "all story variants load successfully in storybook" do
    @story_classes.each do |story_info|
      story_name = story_info[:name]
      story_class = story_info[:story_class]
      
      # Skip base story which is just a helper
      next if story_name == "base_story"
      
      # Get all story methods (variants) - filter out internal methods
      story_instance = story_class.new
      parent_methods = ViewComponent::Storybook::Stories.instance_methods
      live_stories_methods = LiveStories.instance_methods
      
      all_public_methods = story_instance.public_methods(false) - parent_methods - live_stories_methods
      
      # Filter out class attribute accessors and other non-story methods
      available_stories = all_public_methods.reject do |method_name|
        method_name.to_s.end_with?('?', '=') || 
        method_name.to_s.start_with?('_') ||
        method_name.to_s.include?('_definitions')
      end
      
      # Test that the story index loads
      get "/storybook/show", params: { story: story_name }
      assert_response :success, "Story #{story_name} should load successfully"
      
      # Test each variant
      available_stories.each do |variant|
        get "/storybook/show", params: { story: story_name, story_variant: variant.to_s }
        
        # Check response is successful
        assert_response :success, 
          "Story #{story_name} with variant #{variant} should load successfully. " +
          "Response: #{response.status} #{response.body[0..200]}"
        
        # Check that the preview area exists
        assert_response_includes 'id="component-preview"', 
          "Story #{story_name} with variant #{variant} should have component preview area"
        
        # Check that no error messages appear in the preview
        assert_select "#component-preview .text-red-600", { count: 0 }, 
          "Story #{story_name} with variant #{variant} should not show error messages"
        
        # Verify the page contains expected elements  
        # The story name is processed as base_name.titleize (e.g. "example_component" -> "Example")
        story_display_name = story_name.gsub(/_component$/, "").titleize
        assert_select "h1", { text: /#{story_display_name}/ }, 
          "Story #{story_name} should have component title showing '#{story_display_name}'"
        assert_select "h2", { text: /Live Controls/ }, 
          "Story #{story_name} should have controls section"
        assert_select "h2", { text: /Live Preview/ }, 
          "Story #{story_name} should have preview section"
      end
    end
  end
  
  test "all stories have at least one working variant" do
    @story_classes.each do |story_info|
      story_name = story_info[:name]
      story_class = story_info[:story_class]
      
      # Skip base story which is just a helper
      next if story_name == "base_story"
      
      # Get all story methods (variants) - filter out internal methods
      story_instance = story_class.new
      parent_methods = ViewComponent::Storybook::Stories.instance_methods
      live_stories_methods = LiveStories.instance_methods
      
      all_public_methods = story_instance.public_methods(false) - parent_methods - live_stories_methods
      
      # Filter out class attribute accessors and other non-story methods
      available_stories = all_public_methods.reject do |method_name|
        method_name.to_s.end_with?('?', '=') || 
        method_name.to_s.start_with?('_') ||
        method_name.to_s.include?('_definitions')
      end
      
      assert available_stories.length > 0, 
        "Story #{story_name} should have at least one story method/variant"
      
      # Test default variant specifically
      if available_stories.include?(:default)
        get "/storybook/show", params: { story: story_name, story_variant: "default" }
        assert_response :success, "Story #{story_name} default variant should work"
        assert_response_includes 'id="component-preview"', "Default variant should have preview element"
      end
    end
  end
  
  test "story controls are properly defined and functional" do
    @story_classes.each do |story_info|
      story_name = story_info[:name]
      story_class = story_info[:story_class]
      
      # Skip base story which is just a helper
      next if story_name == "base_story"
      
      # Load the story page
      get "/storybook/show", params: { story: story_name }
      assert_response :success
      
      # Check that controls section exists
      assert_select "h2", { text: /Live Controls/ }, "Story #{story_name} should have controls section"
      
      # Check that form exists for controls
      assert_response_includes "data-live-story-target=\"form\"",
        "Story #{story_name} should have controls form"
        
      # Check for story variants section if multiple variants exist
      story_instance = story_class.new
      parent_methods = ViewComponent::Storybook::Stories.instance_methods
      available_stories = story_instance.public_methods(false) - parent_methods
      
      if available_stories.length > 1
        assert_select "h3", { text: "Story Variants" }, 
          "Story #{story_name} with multiple variants should show Story Variants section"
        
        # Check that each variant has a clickable link
        available_stories.each do |variant|
          assert_response_includes "data-variant=\"#{variant}\"", 
            "Story #{story_name} should have clickable link for variant #{variant}"
        end
      end
    end
  end
  
  test "story variants don't crash when switching between them" do
    # Focus on stories we know should work
    working_stories = ["simple_button_component"]
    
    working_stories.each do |story_name|
      # Get the story class
      story_class_name = "#{story_name.camelize}Stories"
      story_class = story_class_name.safe_constantize
      next unless story_class
      
      # Get all variants
      story_instance = story_class.new
      parent_methods = ViewComponent::Storybook::Stories.instance_methods
      available_stories = story_instance.public_methods(false) - parent_methods
      
      # Test switching between each variant
      available_stories.each do |variant|
        get "/storybook/show", params: { story: story_name, story_variant: variant.to_s }
        assert_response :success, 
          "Should be able to switch to variant #{variant} for story #{story_name}"
        
        # Test that TURBO_STREAM requests also work (for live updates)
        get "/storybook/show", params: { story: story_name, story_variant: variant.to_s }, 
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
        assert_response :success, 
          "TURBO_STREAM request for variant #{variant} should work for story #{story_name}"
      end
    end
  end
end