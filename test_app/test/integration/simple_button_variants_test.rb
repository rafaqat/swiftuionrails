# Copyright 2025
require "test_helper"

class SimpleButtonVariantsTest < ActionDispatch::IntegrationTest
  test "storybook loads simple button component with default variant" do
    get "/storybook/show", params: { story: "simple_button_component" }
    assert_response :success
    
    # Check that the controls panel exists
    assert_select "h2", { text: /Live Controls/ }
    assert_select "h2", { text: /Live Preview/ }
    
    # Check that story variants section exists
    assert_select "h3", "Story Variants"
  end
  
  test "default story variant shows single button in preview area" do
    get "/storybook/show", params: { 
      story: "simple_button_component", 
      story_variant: "default" 
    }
    assert_response :success
    
    # Should show a single button in the component preview area (excluding UI chrome buttons)
    # Look specifically for SimpleButtonComponent buttons which have "rounded-md" class
    assert_select "turbo-frame#component-preview button.rounded-md", count: 1
    assert_select "turbo-frame#component-preview button.rounded-md", text: "Click Me"
  end
  
  test "all_variants story shows multiple buttons with different variants" do
    get "/storybook/show", params: { 
      story: "simple_button_component", 
      story_variant: "all_variants" 
    }
    assert_response :success
    
    # Should show multiple buttons in the preview area (primary, secondary, danger)
    assert_select "turbo-frame#component-preview button.rounded-md", count: 3
    
    # Should show variant labels
    assert_match "Primary", response.body
    assert_match "Secondary", response.body  
    assert_match "Danger", response.body
  end
  
  test "all_sizes story shows multiple buttons with different sizes" do
    get "/storybook/show", params: { 
      story: "simple_button_component", 
      story_variant: "all_sizes" 
    }
    assert_response :success
    
    # Should show multiple buttons in the preview area (small, medium, large)
    assert_select "turbo-frame#component-preview button.rounded-md", count: 3
    
    # Should show size labels (sm, md, lg)
    assert_match ">sm<", response.body
    assert_match ">md<", response.body
    assert_match ">lg<", response.body
  end
  
  test "controls change button properties" do
    get "/storybook/show", params: { 
      story: "simple_button_component",
      story_variant: "default",
      title: "Custom Text",
      variant: "secondary",
      size: "lg",
      disabled: "true"
    }
    assert_response :success
    
    # Button should have the custom text in the preview area
    assert_select "turbo-frame#component-preview button.rounded-md", text: "Custom Text"
    
    # Check that the usage example shows the custom props (HTML encoded)
    assert_match 'title: &quot;Custom Text&quot;', response.body
    assert_match 'variant: :secondary', response.body
    assert_match 'size: :lg', response.body
    assert_match 'disabled: true', response.body
  end
  
  test "with_variants story respects control parameters" do
    get "/storybook/show", params: { 
      story: "simple_button_component",
      story_variant: "with_variants",
      title: "Test Button",
      variant: "danger",
      size: "sm"
    }
    assert_response :success
    
    # Should show the button with custom properties in the preview area
    assert_select "turbo-frame#component-preview button.rounded-md", text: "Test Button"
  end
end
# Copyright 2025
