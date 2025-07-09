# Copyright 2025
require "test_helper"

class DataAttributeTest < ActiveSupport::TestCase
  include ActionView::Helpers::TagHelper

  test "Rails content_tag properly handles data attributes with arrows" do
    # Test how Rails handles data attributes
    result = content_tag(:button, "Click", data: { action: "click->test#method" })
    puts "Rails content_tag result: #{result}"
    assert_match(/data-action="click->test#method"/, result)
  end

  test "Manual attribute setting" do
    # Test manual attribute approach
    attrs = { "data-action" => "click->test#method" }
    result = content_tag(:button, "Click", attrs)
    puts "Manual attrs result: #{result}"
    assert_match(/data-action="click->test#method"/, result)
  end
end
# Copyright 2025
