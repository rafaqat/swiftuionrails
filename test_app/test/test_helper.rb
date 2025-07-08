# Copyright 2025
ENV["RAILS_ENV"] ||= "test"

# Configure SimpleCov for code coverage - must be first!
require "simplecov"
SimpleCov.start "rails" do
  track_files "{app,lib}/**/*.rb"

  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"
  add_filter "/.bundle/"
  add_filter "/spec/"

  add_group "Components", "app/components"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Models", "app/models"

  minimum_coverage 0 # Set to 0 for security tests only
  enable_coverage :branch
end
require_relative "../config/environment"
require "rails/test_help"
require "view_component/test_helpers"
require "view_component/system_test_helpers"
require "capybara/rails"
require "capybara/minitest"

# Load support files
Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ViewComponent::TestCase
  include ViewComponent::TestHelpers
  include Capybara::Minitest::Assertions

  def page
    @page ||= Capybara::Node::Simple.new(rendered_content)
  end
end
# Copyright 2025
