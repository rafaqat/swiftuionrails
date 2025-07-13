# Copyright 2025
require "test_helper"

class ERBRenderingTest < ActionDispatch::IntegrationTest
  test "simple ERB with swift_ui" do
    # Create a simple test view
    erb_content = <<~ERB
      <div>
        <%= swift_ui do
          vstack(spacing: 24).p(8) do
            text("Test content")
          end
        end %>
      </div>
    ERB

    # Get the home page
    get "/"

    puts "=== Response body ==="
    puts response.body

    # Check for errors
    if response.body.include?("Error")
      puts "=== Error found ==="
      error_match = response.body.match(/Error.*?<\/p>/m)
      puts error_match[0] if error_match
    end
    
    # Add assertions
    assert_response :success, "Should render successfully"
    refute_match(/Error/, response.body, "Should not contain errors")
    assert_match(/SwiftUI Rails DSL Components/, response.body, "Should contain page content")
  end

end
# Copyright 2025
