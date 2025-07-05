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
    
    # Create a test controller that renders this ERB
    get "/home/index"
    
    puts "=== Response body ==="
    puts response.body
    
    # Check for errors
    if response.body.include?("Error")
      puts "=== Error found ==="
      error_match = response.body.match(/Error.*?<\/p>/m)
      puts error_match[0] if error_match
    end
  end
  
  test "render ERB directly" do
    # Test ERB rendering directly
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)
    
    erb_content = <<~ERB
      <%= swift_ui do
        vstack(spacing: 24).p(8) do
          text("Test content")
        end
      end %>
    ERB
    
    begin
      result = ERB.new(erb_content).result(view.send(:binding))
      puts "=== Direct ERB result ==="
      puts result
    rescue => e
      puts "=== ERB rendering failed ==="
      puts "#{e.class}: #{e.message}"
      puts e.backtrace[0..5].join("\n")
    end
  end
end
# Copyright 2025
