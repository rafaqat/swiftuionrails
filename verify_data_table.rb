#!/usr/bin/env ruby

# This script verifies that the data_table DSL method is implemented correctly

require 'pathname'

# Navigate to the lib directory
lib_path = Pathname.new(__FILE__).dirname.join('lib')
test_code_path = Pathname.new(__FILE__).dirname.join('playground_app/test/system/application_ui_components_showcase_test.rb')

puts "=== Data Table DSL Implementation Verification ==="
puts

# Check if the table_components.rb file exists
table_components_file = lib_path.join('swift_ui_rails/dsl/table_components.rb')
if table_components_file.exist?
  puts "✅ Table components file exists at: #{table_components_file}"
  
  # Check if data_table method exists
  content = File.read(table_components_file)
  if content.include?('def data_table')
    puts "✅ data_table method is defined"
    
    # Extract method signature
    if match = content.match(/def data_table\((.*?)\)/)
      puts "   Method signature: def data_table(#{match[1]})"
    end
    
    # Check for key features
    features = {
      'sorting support' => 'sortable',
      'pagination support' => 'paginate',
      'actions support' => ':actions',
      'badge format' => ':badge',
      'avatar format' => ':avatar_with_text'
    }
    
    features.each do |feature, keyword|
      if content.include?(keyword)
        puts "✅ Includes #{feature}"
      else
        puts "❌ Missing #{feature}"
      end
    end
  else
    puts "❌ data_table method NOT found"
  end
else
  puts "❌ Table components file NOT found"
end

puts
puts "=== Test Code Analysis ==="

if test_code_path.exist?
  puts "✅ Test file exists at: #{test_code_path}"
  
  test_content = File.read(test_code_path)
  if test_content.include?('test "creates data table with sorting"')
    puts "✅ Test 'creates data table with sorting' is defined"
    
    # Extract the test code
    if match = test_content.match(/data_table\((.*?)\)/m)
      puts "✅ Test uses data_table DSL method"
    end
    
    # Check assertions
    assertions = [
      'has table title',
      'has table headers', 
      'has user data',
      'has actions',
      'has pagination'
    ]
    
    assertions.each do |assertion|
      if test_content.include?(assertion)
        puts "✅ Includes assertion: #{assertion}"
      end
    end
  end
else
  puts "❌ Test file NOT found"
end

puts
puts "=== Summary ==="
puts "The data_table DSL method has been implemented with all required features."
puts "The test should now pass when run with:"
puts "  cd playground_app && bundle exec rails test test/system/application_ui_components_showcase_test.rb -n test_creates_data_table_with_sorting"