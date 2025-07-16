# frozen_string_literal: true

require "test_helper"

class PlaygroundControllerTest < ActionDispatch::IntegrationTest
  test "should get index without errors" do
    get "/playground"
    assert_response :success
    assert_select "div[data-controller='playground']"
    assert_no_match /undefined method.*for nil/, response.body
  end

  test "should render playground component" do
    get "/playground"
    assert_response :success
    # Should contain playground content
    assert_match(/SwiftUI Rails Playground/, response.body)
  end
end