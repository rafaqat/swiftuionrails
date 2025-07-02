# frozen_string_literal: true

require "test_helper"

class StorybookRenderingTest < ActionDispatch::IntegrationTest
  def setup
    # Get all story files
    @story_files = Dir[Rails.root.join("test/components/stories/*_stories.rb")]
  end

  test "all storybook components render without DSL method errors" do
    story_results = []
    
    @story_files.each do |file|
      story_name = File.basename(file, "_stories.rb")
      next if story_name.include?("simple") # Skip legacy stories
      
      puts "Testing story: #{story_name}"
      
      # Visit the story page
      get "/storybook/show", params: { story: story_name }
      
      # Check if the response was successful
      if response.successful?
        # Look for error content in the response body
        if response.body.include?("undefined method") && 
           response.body.include?("SwiftUIRails::DSL::Element")
          
          # Extract method name from error
          error_match = response.body.match(/undefined method `([^']+)'.*SwiftUIRails::DSL::Element/m)
          if error_match
            method_name = error_match[1]
            story_results << {
              story: story_name,
              status: :missing_method,
              method: method_name,
              error: error_match[0]
            }
            puts "  ❌ Missing DSL method: #{method_name}"
          else
            story_results << {
              story: story_name, 
              status: :other_error,
              error: "DSL error but couldn't extract method name"
            }
            puts "  ❌ DSL error (unknown method)"
          end
        elsif response.body.include?("Error rendering component")
          story_results << {
            story: story_name,
            status: :render_error,
            error: "Component rendering error"
          }
          puts "  ⚠️  Render error"
        else
          story_results << { story: story_name, status: :success }
          puts "  ✅ Rendered successfully"
        end
      else
        story_results << {
          story: story_name,
          status: :http_error,
          error: "HTTP #{response.status}"
        }
        puts "  💥 HTTP Error: #{response.status}"
      end
    end
    
    # Generate report
    puts "\n📊 Storybook Rendering Test Results:"
    puts "=" * 50
    
    successful = story_results.count { |r| r[:status] == :success }
    total = story_results.length
    
    puts "✅ Successful: #{successful}/#{total} (#{(successful.to_f/total*100).round(1)}%)"
    
    # Group by error type
    by_status = story_results.group_by { |r| r[:status] }
    
    by_status.each do |status, results|
      next if status == :success
      
      puts "\n#{status_emoji(status)} #{status.to_s.humanize}: #{results.length}"
      results.each do |result|
        puts "  - #{result[:story]}"
        if result[:method]
          puts "    Missing method: #{result[:method]}"
        elsif result[:error]
          puts "    Error: #{result[:error]}"
        end
      end
    end
    
    # Extract missing methods for easy fixing
    missing_methods = story_results
      .select { |r| r[:status] == :missing_method }
      .map { |r| r[:method] }
      .uniq
    
    if missing_methods.any?
      puts "\n🚨 Missing DSL Methods to Add:"
      puts "-" * 30
      missing_methods.each do |method|
        puts generate_method_fix(method)
        puts ""
      end
    end
    
    # Fail if there are missing methods
    missing_method_stories = story_results.select { |r| r[:status] == :missing_method }
    assert missing_method_stories.empty?, 
      "#{missing_method_stories.length} stories have missing DSL methods: #{missing_methods.join(', ')}"
  end

  private

  def status_emoji(status)
    case status
    when :missing_method then "🔧"
    when :render_error then "⚠️"
    when :http_error then "💥"
    when :other_error then "❓"
    else "❌"
    end
  end

  def generate_method_fix(method_name)
    # Generate appropriate method based on common patterns
    case method_name
    when /^(.+)_(\d+)$/, /^([a-z]+)_([a-z]+)$/
      "def #{method_name}(&block)\n  tw(\"#{method_name.tr('_', '-')}\", &block)\nend"
    when /^(.+)_color$/, /^(.+)_size$/
      base = $1
      "def #{method_name}(value, &block)\n  tw(\"#{base}-\#{value}\", &block)\nend"
    else
      "def #{method_name}(value = nil, &block)\n  tw(value ? \"#{method_name.tr('_', '-')}-\#{value}\" : \"#{method_name.tr('_', '-')}\", &block)\nend"
    end
  end
end