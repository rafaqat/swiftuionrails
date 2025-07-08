# Copyright 2025
require "test_helper"

class CardMethodTest < ActiveSupport::TestCase
  test "debug card method behavior" do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.extend(SwiftUIRails::Helpers)

    dsl_context = SwiftUIRails::DSLContext.new(view)

    # Test 1: card without block
    puts "=== Test 1: card without block ==="
    card1 = dsl_context.card(elevation: 2)
    puts "card1 class: #{card1.class}"
    puts "card1 has block?: #{card1.instance_variable_get(:@block).nil? ? 'no' : 'yes'}"

    # Test 2: card with block
    puts "\n=== Test 2: card with block ==="
    card2 = dsl_context.card(elevation: 2) { dsl_context.text("Inside") }
    puts "card2 class: #{card2.class}"
    puts "card2 has block?: #{card2.instance_variable_get(:@block).nil? ? 'no' : 'yes'}"
    puts "card2 HTML: #{card2}"

    # Test 3: card with chained method
    puts "\n=== Test 3: card(elevation: 2).p(6) ==="
    card3 = dsl_context.card(elevation: 2).p(6)
    puts "card3 class: #{card3.class}"
    puts "card3 has block?: #{card3.instance_variable_get(:@block).nil? ? 'no' : 'yes'}"

    # Test 4: card with chained method and block
    puts "\n=== Test 4: card(elevation: 2).p(6) { block } ==="
    card4 = dsl_context.card(elevation: 2).p(6) { dsl_context.text("With padding") }
    puts "card4 class: #{card4.class}"
    puts "card4 has block?: #{card4.instance_variable_get(:@block).nil? ? 'no' : 'yes'}"
    puts "card4 HTML: #{card4}"

    # Test 5: Check if it's the same element instance
    puts "\n=== Test 5: Object identity ==="
    card5a = dsl_context.card(elevation: 2)
    card5b = card5a.p(6)
    puts "Same object? #{card5a.object_id == card5b.object_id}"
  end
end
# Copyright 2025
