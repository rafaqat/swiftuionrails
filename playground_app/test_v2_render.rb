# Load Rails environment
require_relative "config/environment"

puts "Attempting to render PlaygroundV2Component..."

begin
  component = PlaygroundV2Component.new(
    default_code: "puts 'hello'",
    components: [],
    examples: []
  )
  
  output = ApplicationController.render(component, layout: false)
  
  puts "--- Rendered Output Start ---"
  puts output
  puts "--- Rendered Output End ---"

  if output.include?("SwiftUI Rails Playground")
    puts "✅ Component rendered successfully!"
  else
    puts "❌ Component rendered but missing expected content."
  end
rescue => e
  puts "❌ Error rendering component: #{e.class} - #{e.message}"
  puts e.backtrace.take(10)
end