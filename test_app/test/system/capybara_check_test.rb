require "application_system_test_case"

class CapybaraCheckTest < ApplicationSystemTestCase
  test "verify capybara is working" do
    # First, let's check what we have access to
    puts "\n=== Capybara Check ==="
    puts "Test class: #{self.class}"
    puts "Responds to visit?: #{respond_to?(:visit)}"
    puts "Page class: #{page.class if respond_to?(:page)}"
    
    # Try to visit a simple path
    begin
      visit root_path
      puts "Visit succeeded!"
      puts "Current path: #{current_path}"
      assert true
    rescue => e
      puts "Visit failed: #{e.class} - #{e.message}"
      puts e.backtrace[0..5].join("\n")
      flunk "Capybara visit is not working"
    end
  end
end
# Copyright 2025
