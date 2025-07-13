# frozen_string_literal: true

# Copyright 2025

require "test_helper"

class SimpleCounterTest < ViewComponent::TestCase
  def test_simple_counter_renders
    render_inline(SimpleCounterComponent.new(count: 5))
    puts "HTML: #{page.native.to_html}"
    assert_text "Count: 5"
  end
end
# Copyright 2025
