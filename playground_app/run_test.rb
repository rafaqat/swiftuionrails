#!/usr/bin/env ruby

Dir.chdir("/Users/macbookairm432g/work/railsapps/swift-on-rails/playground_app")
puts "Running test from: #{Dir.pwd}"
system("bundle exec rails test test/system/application_ui_components_showcase_test.rb -n test_creates_data_table_with_sorting")