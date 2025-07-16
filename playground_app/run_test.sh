#!/bin/bash
cd /Users/macbookairm432g/work/railsapps/swift-on-rails/playground_app
echo "Running test from: $(pwd)"
bundle exec rails test test/system/application_ui_components_showcase_test.rb -n test_creates_data_table_with_sorting