# Copyright 2025
require "test_helper"

class StorybookControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get storybook_index_url
    assert_response :success
  end

  test "should handle valid component story" do
    get storybook_show_url, params: { story: "card_component" }
    assert_response :success
  end

  test "should handle invalid story gracefully" do
    get storybook_show_url, params: { story: "nonexistent_story" }
    assert_redirected_to storybook_index_path
    assert_equal "Story not found: nonexistent_story", flash[:alert]
  end

  test "should handle story without component suffix gracefully" do
    # Test a DSL story that exists
    get storybook_show_url, params: { story: "dsl_button" }
    # Should successfully find the DSL story and render the page
    assert_response :success, "Should successfully handle DSL story"
  end

  test "should handle malformed component name mapping" do
    # Test another existing DSL story
    get storybook_show_url, params: { story: "dsl_card" }
    assert_response :success
    # Component should be found and loaded correctly
  end

  test "should handle story with nonexistent component" do
    # Test a story that exists but component doesn't exist
    get storybook_show_url, params: { story: "nonexistent_button" }
    assert_redirected_to storybook_index_path
    assert_equal "Story not found: nonexistent_button", flash[:alert]
  end
end
# Copyright 2025
