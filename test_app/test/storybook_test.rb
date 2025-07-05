require "test_helper"

class StorybookTest < ActionDispatch::IntegrationTest
  test "storybook index page loads" do
    get "/storybook/index"
    assert_response :success
    assert_select "h1", "SwiftUI Rails Component Storybook"
  end
  
  test "component stories are listed" do
    get "/storybook/index"
    assert_response :success
    
    # Check that our SwiftUI Rails stories are listed
    assert_match "Simple Button", response.body
    assert_match "Simple Card", response.body
    assert_match "Example", response.body
  end
  
  test "button component story loads" do
    get "/storybook/show", params: { story: "simple_button" }
    assert_response :success
    
    # Check for the controls panel
    assert_select "h2", "Controls"
    assert_select "h2", "Preview"
    assert_select "h2", "Usage Example"
  end
  
  test "story variants are shown" do
    get "/storybook/show", params: { story: "simple_button" }
    assert_response :success
    
    # Check for story variants if they exist
    assert_select "h3", "Story Variants"
    assert_match "Default", response.body
    assert_match "With variants", response.body
  end
  
  test "controls update component preview" do
    get "/storybook/show", params: { 
      story: "simple_button",
      title: "Custom Button",
      variant: "primary"
    }
    assert_response :success
    
    # Check that the usage example shows the custom props (HTML encoded)
    assert_match 'title: &quot;Custom Button&quot;', response.body
    assert_match 'variant: :primary', response.body
  end
end