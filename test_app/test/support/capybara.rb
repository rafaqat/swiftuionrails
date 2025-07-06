# Copyright 2025
require 'capybara/rails'
require 'capybara/minitest'

# Configure Capybara
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  
  # Enable browser logging
  options.add_option('goog:loggingPrefs', { browser: 'ALL' })
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 5

# For debugging, you can use this to see the browser
Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_option('goog:loggingPrefs', { browser: 'ALL' })
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
# Copyright 2025
