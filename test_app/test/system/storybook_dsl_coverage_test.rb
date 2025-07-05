# frozen_string_literal: true
# Copyright 2025

require "application_system_test_case"

class StorybookDslCoverageTest < ApplicationSystemTestCase
  def setup
    # Start server on port 3030 as configured
    Capybara.server_port = 3030
    visit "/"
  end

  test "all storybook components render without DSL method errors" do
    # Navigate to storybook index
    visit "/storybook"
    
    # Get all available story components
    story_links = all('[data-testid="story-link"], a[href*="/storybook/show"]', wait: 5)
    story_names = story_links.map { |link| link[:href].split("story=").last&.split("&")&.first }.compact.uniq
    
    puts "\n🧪 Testing #{story_names.length} story components for DSL method coverage..."
    
    missing_methods = []
    failed_components = []
    
    story_names.each do |story_name|
      puts "  Testing #{story_name}..."
      
      begin
        # Visit the story page
        visit "/storybook/show?story=#{story_name}"
        
        # Wait for the page to load
        sleep 1
        
        # Check for error messages
        error_elements = all(".text-red-600, [class*='error'], [class*='alert-danger']", wait: 2)
        
        if error_elements.any?
          error_messages = error_elements.map(&:text)
          
          # Look for undefined method errors specifically
          dsl_method_errors = error_messages.select do |message|
            message.include?("undefined method") && 
            message.include?("SwiftUIRails::DSL::Element")
          end
          
          if dsl_method_errors.any?
            # Extract method names from error messages
            dsl_method_errors.each do |error|
              if match = error.match(/undefined method `([^']+)'/)
                method_name = match[1]
                missing_methods << {
                  component: story_name,
                  method: method_name,
                  error: error
                }
                puts "    ❌ Missing DSL method: #{method_name}"
              end
            end
            failed_components << story_name
          else
            # Other types of errors
            puts "    ⚠️  Other error: #{error_messages.first}"
            failed_components << story_name
          end
        else
          puts "    ✅ Rendered successfully"
        end
        
        # Test variant stories if they exist
        variant_links = all('[data-variant]', wait: 1)
        variant_links.each do |variant_link|
          variant_name = variant_link["data-variant"]
          next if variant_name == "default"
          
          puts "    Testing variant: #{variant_name}"
          variant_link.click
          sleep 0.5
          
          variant_errors = all(".text-red-600", wait: 1)
          if variant_errors.any?
            puts "      ❌ Variant #{variant_name} has errors"
          else
            puts "      ✅ Variant #{variant_name} OK"
          end
        end
        
      rescue => e
        puts "    💥 Exception: #{e.message}"
        failed_components << story_name
      end
    end
    
    # Generate detailed report
    puts "\n📊 DSL Coverage Test Results:"
    puts "=" * 50
    puts "✅ Successful components: #{story_names.length - failed_components.length}"
    puts "❌ Failed components: #{failed_components.length}"
    puts "🔧 Missing DSL methods: #{missing_methods.length}"
    
    if missing_methods.any?
      puts "\n🚨 Missing DSL Methods Report:"
      puts "-" * 30
      
      # Group by method name
      methods_by_name = missing_methods.group_by { |m| m[:method] }
      methods_by_name.each do |method_name, occurrences|
        components = occurrences.map { |o| o[:component] }.uniq
        puts "📍 #{method_name} (used in: #{components.join(', ')})"
      end
      
      puts "\n🛠️  Auto-generated DSL methods to add:"
      puts "-" * 35
      methods_by_name.each do |method_name, _|
        puts generate_dsl_method_template(method_name)
        puts ""
      end
    end
    
    if failed_components.any?
      puts "\n❌ Failed Components:"
      failed_components.each { |name| puts "  - #{name}" }
    end
    
    # Fail the test if there are missing methods
    assert missing_methods.empty?, 
      "Missing DSL methods found: #{missing_methods.map { |m| m[:method] }.uniq.join(', ')}"
  end
  
  test "DSL method usage analysis across all stories" do
    puts "\n🔍 Analyzing DSL method usage patterns..."
    
    # Scan all story files for method calls
    story_files = Dir[Rails.root.join("test/components/stories/*_stories.rb")]
    method_usage = Hash.new(0)
    
    story_files.each do |file|
      content = File.read(file)
      
      # Find method calls like .method_name(
      method_calls = content.scan(/\.([a-z_]+)\(/i)
      method_calls.each do |match|
        method_name = match[0]
        # Skip obvious Rails/Ruby methods
        next if %w[present? blank? empty? to_s to_i camelize humanize].include?(method_name)
        method_usage[method_name] += 1
      end
    end
    
    puts "\n📈 Most used DSL methods:"
    method_usage.sort_by { |_, count| -count }.first(20).each do |method, count|
      puts "  #{method}: #{count} times"
    end
    
    # Check if these methods exist in Element class
    element_file = File.read(Rails.root.join("../lib/swift_ui_rails/dsl/element.rb"))
    
    puts "\n🔧 Potentially missing methods:"
    method_usage.each do |method, count|
      unless element_file.include?("def #{method}")
        puts "  #{method} (used #{count} times) - MISSING"
      end
    end
  end
  
  private
  
  def generate_dsl_method_template(method_name)
    # Generate smart method templates based on common patterns
    case method_name
    when /^(.+)_(\d+)$/
      # Methods like w_1_2, h_full, etc.
      base = $1
      value = $2
      "def #{method_name}(&block)\n  tw(\"#{base.tr('_', '-')}-#{value}\", &block)\nend"
    when /^(.+)_color$/
      # Color methods like text_color, bg_color
      "def #{method_name}(color, &block)\n  tw(\"#{$1}-\#{color}\", &block)\nend"
    when /^hover_(.+)$/
      # Hover methods
      "def #{method_name}(value = nil, &block)\n  tw(\"hover:#{$1}\#{value ? \"-\#{value}\" : \"\"}\", &block)\nend"
    when /^(.+)_(.+)$/
      # Compound methods like items_center, justify_between
      "def #{method_name}(&block)\n  tw(\"#{method_name.tr('_', '-')}\", &block)\nend"
    else
      # Generic method
      "def #{method_name}(value = nil, &block)\n  tw(value ? \"#{method_name}-\#{value}\" : \"#{method_name}\", &block)\nend"
    end
  end
end
# Copyright 2025
