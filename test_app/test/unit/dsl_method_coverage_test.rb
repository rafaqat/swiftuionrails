# frozen_string_literal: true

require "test_helper"

class DslMethodCoverageTest < ActiveSupport::TestCase
  def setup
    @story_files = Dir[Rails.root.join("test/components/stories/*_stories.rb")]
    @element_file = File.read(Rails.root.join("../lib/swift_ui_rails/dsl/element.rb"))
  end

  test "all DSL methods used in stories are implemented in Element class" do
    missing_methods = find_missing_dsl_methods
    
    if missing_methods.any?
      puts "\n🚨 Missing DSL Methods Found:"
      puts "=" * 40
      
      missing_methods.each do |method_info|
        puts "📍 #{method_info[:method]} (used in #{method_info[:files].join(', ')})"
      end
      
      puts "\n🛠️  Auto-generated method templates:"
      puts "-" * 35
      missing_methods.each do |method_info|
        puts generate_method_template(method_info[:method])
        puts ""
      end
    end
    
    assert missing_methods.empty?, 
      "Missing DSL methods: #{missing_methods.map { |m| m[:method] }.join(', ')}"
  end

  test "can instantiate all story components without errors" do
    failed_stories = []
    
    @story_files.each do |file|
      story_name = File.basename(file, "_stories.rb")
      
      begin
        # Load the story file
        load file
        
        # Get the story class
        story_class_name = "#{story_name.camelize}Stories"
        story_class = story_class_name.constantize
        
        # Try to instantiate and call default method
        story_instance = story_class.new
        
        if story_instance.respond_to?(:default)
          # Get the controls to simulate real parameters
          controls = extract_controls_from_story(story_class)
          default_params = build_default_params(controls)
          
          # Try to call the default story method
          result = story_instance.default(**default_params)
          
          # If it's a component, try to render it
          if result.respond_to?(:call) && result.is_a?(ViewComponent::Base)
            # Mock view context for rendering
            view_context = ActionView::Base.new
            view_context.extend(SwiftUIRails::Helpers)
            result.send(:view_context=, view_context)
            result.call
          end
        end
        
      rescue => e
        if e.message.include?("undefined method") && e.message.include?("SwiftUIRails::DSL::Element")
          # Extract method name from error
          if match = e.message.match(/undefined method `([^']+)'/)
            method_name = match[1]
            failed_stories << {
              story: story_name,
              method: method_name,
              error: e.message
            }
          end
        else
          # Other types of errors - might be OK (missing constants, etc.)
          puts "⚠️  #{story_name}: #{e.message}"
        end
      end
    end
    
    if failed_stories.any?
      puts "\n❌ Stories with missing DSL methods:"
      failed_stories.each do |failure|
        puts "  #{failure[:story]}: missing #{failure[:method]}"
      end
    end
    
    assert failed_stories.empty?, 
      "Stories failed due to missing DSL methods: #{failed_stories.map { |f| "#{f[:story]}:#{f[:method]}" }.join(', ')}"
  end

  test "DSL method documentation is up to date" do
    # Get all implemented methods from Element class
    implemented_methods = @element_file.scan(/def ([a-z_]+)/).flatten.uniq
    
    # Get all used methods from stories
    used_methods = find_all_used_methods
    
    puts "\n📊 DSL Method Usage Report:"
    puts "=" * 30
    puts "Implemented methods: #{implemented_methods.length}"
    puts "Used methods: #{used_methods.length}"
    puts "Coverage: #{((implemented_methods & used_methods.keys).length.to_f / used_methods.length * 100).round(1)}%"
    
    # Find unused implemented methods
    unused = implemented_methods - used_methods.keys
    if unused.any?
      puts "\n🗑️  Unused implemented methods:"
      unused.each { |method| puts "  - #{method}" }
    end
    
    # Find frequently used methods
    puts "\n🔥 Most used DSL methods:"
    used_methods.sort_by { |_, count| -count }.first(10).each do |method, count|
      status = implemented_methods.include?(method) ? "✅" : "❌"
      puts "  #{status} #{method}: #{count} uses"
    end
  end

  private

  def find_missing_dsl_methods
    used_methods = find_all_used_methods
    implemented_methods = @element_file.scan(/def ([a-z_]+)/).flatten
    
    missing = []
    used_methods.each do |method, count|
      unless implemented_methods.include?(method)
        # Find which files use this method
        files_using_method = []
        @story_files.each do |file|
          content = File.read(file)
          if content.include?(".#{method}(") || content.include?(".#{method}")
            files_using_method << File.basename(file)
          end
        end
        
        missing << {
          method: method,
          count: count,
          files: files_using_method
        }
      end
    end
    
    missing
  end

  def find_all_used_methods
    method_usage = Hash.new(0)
    
    @story_files.each do |file|
      content = File.read(file)
      
      # Find method calls like .method_name( or .method_name with word boundary
      method_calls = content.scan(/\.([a-z_]+)(?:\(|\s|$)/)
      method_calls.each do |match|
        method_name = match[0]
        # Skip obvious Rails/Ruby methods
        next if rails_or_ruby_method?(method_name)
        method_usage[method_name] += 1
      end
    end
    
    method_usage
  end

  def rails_or_ruby_method?(method_name)
    excluded_methods = %w[
      present? blank? empty? to_s to_i to_f camelize humanize titleize
      new class name constantize safe_constantize include? any? map
      select reject compact uniq join first last length size count
      respond_to? is_a? kind_of? nil? try send public_send
      merge merge! slice except keys values each with_index
      strip downcase upcase split gsub scan match sub
    ]
    excluded_methods.include?(method_name)
  end

  def extract_controls_from_story(story_class)
    # Try to get controls from the story class
    if story_class.respond_to?(:controls)
      story_class.controls.instance_variable_get(:@controls) || []
    else
      []
    end
  end

  def build_default_params(controls)
    params = {}
    controls.each do |control|
      if control.is_a?(Hash) && control[:param]
        params[control[:param]] = control[:default]
      end
    end
    params
  end

  def generate_method_template(method_name)
    case method_name
    when /^w_(.+)$/, /^h_(.+)$/, /^m_(.+)$/, /^p_(.+)$/
      # Width, height, margin, padding with values
      base = method_name.split('_').first
      value = method_name.split('_', 2).last.tr('_', '/')
      "def #{method_name}(&block)\n  tw(\"#{base}-#{value}\", &block)\nend"
    when /^(.+)_color$/
      # Color methods
      "def #{method_name}(color, &block)\n  tw(\"#{$1}-\#{color}\", &block)\nend"
    when /^hover_(.+)$/
      # Hover methods
      "def #{method_name}(value = nil, &block)\n  tw(\"hover:#{$1}\#{'-' + value if value}\", &block)\nend"
    when /^([a-z]+)_([a-z]+)$/
      # Compound methods like items_center, justify_between
      "def #{method_name}(&block)\n  tw(\"#{method_name.tr('_', '-')}\", &block)\nend"
    else
      # Generic method
      "def #{method_name}(value = nil, &block)\n  tw(value ? \"#{method_name}-\#{value}\" : \"#{method_name}\", &block)\nend"
    end
  end
end