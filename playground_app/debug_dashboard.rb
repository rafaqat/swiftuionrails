#!/usr/bin/env ruby

# Debug script to isolate the Dashboard Stats error
require_relative 'config/environment'

# Test the exact code that's failing
test_code = <<~'RUBY'
swift_ui do
  grid(columns: 4, spacing: 16) do
    [
      { label: "Total Revenue", value: "$45,678", change: "+12.5%", trend: "up", color: "green" }
    ].each do |stat|
      card(elevation: 1) do
        vstack(spacing: 4, alignment: :start) do
          hstack(justify: :between) do
            text(stat[:label])
              .text_sm
              .text_color("gray-600")
              .font_weight("medium")
            
            div
              .w(8).h(8)
              .rounded("full")
              .bg("#{stat[:color]}-100")
              .flex.items_center.justify_center do
              text(stat[:trend] == "up" ? "↑" : "↓")
                .text_color("#{stat[:color]}-600")
                .font_weight("bold")
            end
          end
        end
      end
    end
  end
end
RUBY

begin
  # Create a minimal component to test
  component = Class.new(SwiftUIRails::Component::Base) do
    def initialize
      super
    end
    
    def call
      swift_ui do
        grid(columns: 4, spacing: 16) do
          [
            { label: "Total Revenue", value: "$45,678", change: "+12.5%", trend: "up", color: "green" }
          ].each do |stat|
            card(elevation: 1) do
              vstack(spacing: 4, alignment: :start) do
                hstack(justify: :between) do
                  text(stat[:label])
                    .text_sm
                    .text_color("gray-600")
                    .font_weight("medium")
                  
                  div
                    .w(8).h(8)
                    .rounded("full")
                    .bg("#{stat[:color]}-100")
                    .flex.items_center.justify_center do
                    text(stat[:trend] == "up" ? "↑" : "↓")
                      .text_color("#{stat[:color]}-600")
                      .font_weight("bold")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  result = component.new.call
  puts "✅ Dashboard Stats code executed successfully"
  puts result.inspect
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace[0..10].join("\n")
end