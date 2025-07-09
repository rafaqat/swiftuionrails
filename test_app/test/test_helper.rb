# Copyright 2025
ENV["RAILS_ENV"] ||= "test"
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
    # Disabled for CI compatibility - tests must run serially
    parallelize(workers: 1)

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
