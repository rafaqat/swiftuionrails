#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to run all component showcase tests
# Usage: ruby test/system/run_all_showcase_tests.rb

require 'fileutils'
require 'time'

# Run tests
puts "🚀 Running SwiftUI Rails Component Showcase Tests..."
puts "=" * 60

test_files = [
  "test/system/marketing_components_showcase_test.rb",
  "test/system/application_ui_components_showcase_test.rb", 
  "test/system/ecommerce_components_showcase_test.rb"
]

start_time = Time.now
results = []

test_files.each do |test_file|
  puts "\n📋 Running #{File.basename(test_file)}..."
  
  # Run the test and capture output
  output = `bundle exec rails test #{test_file} 2>&1`
  success = $?.success?
  
  # Extract test counts from output
  if output =~ /(\d+) runs?, (\d+) assertions?, (\d+) failures?, (\d+) errors?/
    runs, assertions, failures, errors = $1.to_i, $2.to_i, $3.to_i, $4.to_i
    
    results << {
      file: test_file,
      runs: runs,
      assertions: assertions,
      failures: failures,
      errors: errors,
      success: success
    }
    
    status = success ? "✅ PASSED" : "❌ FAILED"
    puts "   #{status}: #{runs} tests, #{assertions} assertions, #{failures} failures, #{errors} errors"
  else
    puts "   ⚠️  Could not parse test results"
  end
end

end_time = Time.now
duration = (end_time - start_time).round(2)

# Summary
puts "\n" + "=" * 60
puts "📊 SUMMARY"
puts "=" * 60

total_runs = results.sum { |r| r[:runs] }
total_assertions = results.sum { |r| r[:assertions] }
total_failures = results.sum { |r| r[:failures] }
total_errors = results.sum { |r| r[:errors] }
all_passed = results.all? { |r| r[:success] }

puts "Total tests: #{total_runs}"
puts "Total assertions: #{total_assertions}"
puts "Total failures: #{total_failures}"
puts "Total errors: #{total_errors}"
puts "Duration: #{duration} seconds"
puts "\nOverall: #{all_passed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}"

# Find the latest screenshot directory
screenshot_dirs = Dir.glob("tmp/component_showcase/*").select { |f| File.directory?(f) }
if screenshot_dirs.any?
  latest_dir = screenshot_dirs.max_by { |d| File.mtime(d) }
  puts "\n📸 Screenshots saved to: #{latest_dir}"
  
  # Open the directory in Finder (macOS)
  if RUBY_PLATFORM =~ /darwin/
    puts "Opening screenshots folder..."
    system("open #{latest_dir}")
  end
  
  # Check for test report
  report_file = File.join(latest_dir, "test_report.html")
  if File.exist?(report_file)
    puts "📄 Test report: #{report_file}"
    
    # Open the report in browser
    if RUBY_PLATFORM =~ /darwin/
      system("open #{report_file}")
    end
  end
end

exit(all_passed ? 0 : 1)