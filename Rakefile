# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

# Security tasks
namespace :security do
  desc "Run all security checks"
  task all: [:rubocop, :brakeman, :audit]
  
  desc "Run RuboCop security linting"
  task :rubocop do
    begin
      sh "bundle exec rubocop"
    rescue StandardError => e
      puts "RuboCop check failed: #{e.message}"
      exit 1
    end
  end
  
  desc "Run Brakeman security scanner"
  task :brakeman do
    begin
      sh "bundle exec brakeman -q --no-pager"
    rescue StandardError => e
      puts "Brakeman security scan failed: #{e.message}"
      puts "Ensure brakeman is installed: gem install brakeman"
      exit 1
    end
  end
  
  desc "Run bundler-audit dependency scanner"
  task :audit do
    begin
      sh "bundle exec bundle-audit check --update"
    rescue StandardError => e
      puts "Bundle audit failed: #{e.message}"
      puts "Ensure bundler-audit is installed: gem install bundler-audit"
      exit 1
    end
  end
  
  desc "Run thread safety analysis"
  task :thread_safety do
    begin
      sh "bundle exec rubocop --only ThreadSafety"
    rescue StandardError => e
      puts "Thread safety analysis failed: #{e.message}"
      exit 1
    end
  end
end

task default: %i[spec standard security:all]

desc "Open an IRB console with SwiftUIRails loaded"
task :console do
  begin
    require "irb"
    require "swift_ui_rails"
    
    # Load Rails environment if available
    if File.exist?("test_app/config/environment.rb")
      puts "Loading Rails test app environment..."
      require_relative "test_app/config/environment"
    end
    
    # Clear ARGV to prevent IRB from trying to parse rake args
    ARGV.clear
    
    # Start IRB session
    puts "Starting SwiftUIRails console..."
    puts "SwiftUIRails version: #{SwiftUIRails::VERSION}"
    
    IRB.start
  rescue LoadError => e
    puts "Error loading required libraries: #{e.message}"
    puts "Please ensure all dependencies are installed with: bundle install"
    exit 1
  rescue StandardError => e
    puts "Error starting console: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    exit 1
  end
end