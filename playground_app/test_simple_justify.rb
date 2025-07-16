#!/usr/bin/env ruby

# Simple test to verify justify-between works in browser

require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'

# Configure Capybara
Capybara.configure do |config|
  config.default_driver = :selenium_chrome_headless
  config.app_host = 'http://localhost:3000'
end

# Setup Chrome driver
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,720')
  
  Selenium::WebDriver::Chrome::Service.driver_path = '/usr/local/bin/chromedriver'
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Start the test
include Capybara::DSL

puts "=== TESTING JUSTIFY-BETWEEN IN BROWSER ==="

# Visit the playground
visit '/playground_v2'

# Wait for page to load
sleep 3

# Click on Layout Demo
find('button', text: 'Layout Demo').click

# Wait for preview to load
sleep 3

# Take screenshot
save_screenshot('justify_between_test.png')

# Find the justify-between element
within('#preview-container-v2') do
  justify_between_element = find('div.justify-between')
  puts "Found justify-between element: #{justify_between_element.present?}"
  
  if justify_between_element.present?
    puts "Classes: #{justify_between_element[:class]}"
    
    # Get computed styles
    computed_styles = page.evaluate_script("
      var element = document.querySelector('div.justify-between');
      var styles = window.getComputedStyle(element);
      return {
        display: styles.display,
        flexDirection: styles.flexDirection,
        justifyContent: styles.justifyContent,
        width: styles.width,
        alignItems: styles.alignItems
      };
    ")
    
    puts "=== COMPUTED STYLES ==="
    puts "Display: #{computed_styles['display']}"
    puts "Flex Direction: #{computed_styles['flexDirection']}"
    puts "Justify Content: #{computed_styles['justifyContent']}"
    puts "Width: #{computed_styles['width']}"
    puts "Align Items: #{computed_styles['alignItems']}"
    puts "=== END COMPUTED STYLES ==="
    
    # Get element positions
    positions = page.evaluate_script("
      var container = document.querySelector('div.justify-between');
      var children = container.children;
      var containerRect = container.getBoundingClientRect();
      var childPositions = [];
      
      for (var i = 0; i < children.length; i++) {
        var rect = children[i].getBoundingClientRect();
        childPositions.push({
          index: i,
          left: rect.left,
          right: rect.right,
          width: rect.width,
          text: children[i].textContent.trim()
        });
      }
      
      return {
        container: {
          left: containerRect.left,
          right: containerRect.right,
          width: containerRect.width
        },
        children: childPositions
      };
    ")
    
    puts "=== ELEMENT POSITIONS ==="
    puts "Container: #{positions['container']}"
    puts "Children:"
    positions['children'].each do |child|
      puts "  #{child['text']}: left=#{child['left']}, right=#{child['right']}, width=#{child['width']}"
    end
    
    # Check if justify-between is working
    if positions['children'].length >= 2
      first_child = positions['children'][0]
      last_child = positions['children'][-1]
      gap = last_child['left'] - first_child['right']
      
      puts "Gap between first and last child: #{gap}px"
      
      if gap > 50
        puts "✅ justify-between is working correctly!"
      else
        puts "❌ justify-between is NOT working - elements are too close together"
      end
    end
    
    puts "=== END ELEMENT POSITIONS ==="
  else
    puts "❌ Could not find justify-between element"
  end
end

puts "=== END TEST ==="