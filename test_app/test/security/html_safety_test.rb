require "test_helper"

class HtmlSafetyTest < ActiveSupport::TestCase
  include SwiftUIRails::Reactive
  
  class TestComponent
    include SwiftUIRails::Reactive::ObservedObject
    
    def initialize
      @_content = "<div>Test Content</div>"
      @observed_changes = { store1: { field: { old: "old", new: "new" } } }
    end
    
    attr_accessor :_content, :observed_changes
  end
  
  test "add_observation_metadata safely escapes JSON in HTML attributes" do
    component = TestComponent.new
    component.send(:add_observation_metadata)
    
    # Verify the content has been properly wrapped with data attribute
    assert_match /data-observed-changes/, component._content
    assert component._content.html_safe?
    
    # Verify no raw JSON injection is possible
    refute_match /<script/, component._content
  end
  
  test "add_observation_metadata handles malicious JSON content" do
    component = TestComponent.new
    # Try to inject script tag via JSON
    component.observed_changes = { 
      xss: "</div><script>alert('XSS')</script><div>" 
    }
    
    component.send(:add_observation_metadata)
    
    # Verify the script tag has been properly escaped (using Unicode escapes)
    refute_match /<script>alert/, component._content
    # Check for either HTML entity escaping or Unicode escaping
    assert(component._content.match(/&lt;script&gt;/) || component._content.match(/\\u003cscript\\u003e/),
           "Script tags should be escaped")
  end
  
  test "add_observation_metadata wraps content without root element" do
    component = TestComponent.new
    component._content = "Just text without wrapper"
    component.send(:add_observation_metadata)
    
    # Verify content is wrapped in a div
    assert_match /^<div data-observed-changes=/, component._content
    assert_match /Just text without wrapper/, component._content
  end
  
  test "add_observation_metadata handles empty content" do
    component = TestComponent.new
    component._content = ""
    
    # Should not error on empty content
    assert_nothing_raised do
      component.send(:add_observation_metadata)
    end
    
    assert_equal "", component._content
  end
  
  test "add_observation_metadata skips when no observed changes" do
    component = TestComponent.new
    component.observed_changes = nil
    original_content = component._content.dup
    
    component.send(:add_observation_metadata)
    
    # Content should remain unchanged
    assert_equal original_content, component._content
  end
end
# Copyright 2025
