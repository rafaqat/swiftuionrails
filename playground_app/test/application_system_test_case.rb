# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use headless Chrome for tests as requested
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end