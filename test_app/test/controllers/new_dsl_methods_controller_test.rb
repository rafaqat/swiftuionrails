# Copyright 2025
require "test_helper"

class NewDslMethodsControllerTest < ActionDispatch::IntegrationTest
  test "new DSL methods work in views" do
    # Create a temporary route and action to test the DSL
    Rails.application.routes.draw do
      get "/test_new_dsl", to: "application#test_new_dsl"
    end

    # Add the test action to ApplicationController
    ApplicationController.class_eval do
      include SwiftUIRails::Helpers

      def test_new_dsl
        render inline: <<~ERB
          <%= swift_ui do
            vstack do
              label("Test Label", for_input: "test-select")
              select(name: "test", selected: "2") do
                option("1", "Option 1")
                option("2", "Option 2", selected: true)
              end.ring_hover(2, "blue-500")
          #{'    '}
              div.break_inside("avoid").group_hover_opacity(50) do
                text("Test content")
              end
          #{'    '}
              button("Test Button")
                .flex_shrink(0)
                .title("Test tooltip")
                .style("color: red")
            end
          end %>
        ERB
      end
    end

    get "/test_new_dsl"
    assert_response :success

    # Verify the HTML includes our new DSL elements
    assert_select "label[for='test-select']", "Test Label"
    assert_select "select[name='test']" do
      assert_select "option[value='1']", "Option 1"
      assert_select "option[value='2'][selected='selected']", "Option 2"
    end
    assert_select ".hover\\:ring-2"
    assert_select ".hover\\:ring-blue-500"
    assert_select ".break-inside-avoid"
    assert_select ".group-hover\\:opacity-50"
    assert_select ".flex-shrink-0"
    assert_select "[title='Test tooltip']"
    assert_select "[style*='color: red']"
  end
end
# Copyright 2025
