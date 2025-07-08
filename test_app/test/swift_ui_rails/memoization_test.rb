# frozen_string_literal: true

require "test_helper"

class MemoizationTest < ActiveSupport::TestCase
  def setup
    @test_component_class =
    Class.new(SwiftUIRails::Component::Base) do
      prop :title, type: String, required: true
      prop :count, type: Integer, default: 0

      state :clicks, 0

      swift_ui do
        vstack do
          text(title)
          text("Count: #{count}")
          text("Clicks: #{clicks}")
          # Add a unique identifier to track renders
          text("Render ID: #{SecureRandom.hex(4)}")
        end
      end
    end
  end

  def component
    @component ||= @test_component_class.new(title: "Test", count: 5)
  end

  test "memoization is enabled by default" do
    assert @test_component_class.swift_ui_memoization_enabled
  end

  test "memoization can be disabled" do
    @test_component_class.enable_memoization(false)
    assert_not @test_component_class.swift_ui_memoization_enabled
    @test_component_class.enable_memoization(true) # Reset
  end

  test "returns the same content for identical props" do
    first_render = component.call
    second_render = component.call

    # Extract render IDs to verify memoization
    first_id = first_render.match(/Render ID: ([a-f0-9]+)/)[1]
    second_id = second_render.match(/Render ID: ([a-f0-9]+)/)[1]

    assert_equal first_id, second_id # Same ID means memoized content
  end

  test "generates new content when props change" do
    first_render = component.call

    # Create new component with different props
    new_component = @test_component_class.new(title: "Changed", count: 5)
    second_render = new_component.call

    # Extract render IDs
    first_id = first_render.match(/Render ID: ([a-f0-9]+)/)[1]
    second_id = second_render.match(/Render ID: ([a-f0-9]+)/)[1]

    assert_not_equal first_id, second_id # Different IDs means new render
  end

  test "generates new content when state changes" do
    first_render = component.call
    first_id = first_render.match(/Render ID: ([a-f0-9]+)/)[1]

    # Change state
    component.clicks = 1

    second_render = component.call
    second_id = second_render.match(/Render ID: ([a-f0-9]+)/)[1]

    assert_not_equal first_id, second_id # Different IDs means new render
  end

  test "respects memoization when disabled" do
    @test_component_class.enable_memoization(false)

    no_memo_component = @test_component_class.new(title: "No Memo", count: 1)
    first_render = no_memo_component.call
    second_render = no_memo_component.call

    # Extract render IDs
    first_id = first_render.match(/Render ID: ([a-f0-9]+)/)[1]
    second_id = second_render.match(/Render ID: ([a-f0-9]+)/)[1]

    assert_not_equal first_id, second_id # Different IDs when memoization disabled

    @test_component_class.enable_memoization(true) # Reset
  end

  test "creates consistent keys for same props" do
    key1 = component.send(:calculate_memoization_key)
    key2 = component.send(:calculate_memoization_key)

    assert_equal key1, key2
  end

  test "creates different keys for different props" do
    component1 = @test_component_class.new(title: "Test1", count: 1)
    component2 = @test_component_class.new(title: "Test2", count: 1)

    key1 = component1.send(:calculate_memoization_key)
    key2 = component2.send(:calculate_memoization_key)

    assert_not_equal key1, key2
  end

  test "handles various prop types correctly" do
    complex_component_class = Class.new(SwiftUIRails::Component::Base) do
      prop :string_prop, type: String
      prop :number_prop, type: Integer
      prop :bool_prop, type: [ TrueClass, FalseClass ]
      prop :array_prop, type: Array
      prop :hash_prop, type: Hash
      prop :time_prop, type: Time
      prop :nil_prop

      swift_ui { text("Complex") }
    end

    time_now = Time.now
    component = complex_component_class.new(
      string_prop: "test",
      number_prop: 42,
      bool_prop: true,
      array_prop: [ 1, 2, 3 ],
      hash_prop: { a: 1, b: 2 },
      time_prop: time_now,
      nil_prop: nil
    )

    assert_nothing_raised { component.send(:calculate_memoization_key) }
  end

  test "clear_memoization! clears cached content" do
    first_render = component.call
    first_id = first_render.match(/Render ID: ([a-f0-9]+)/)[1]

    component.send(:clear_memoization!)

    second_render = component.call
    second_id = second_render.match(/Render ID: ([a-f0-9]+)/)[1]

    assert_not_equal first_id, second_id # New render after clearing cache
  end

  test "improves performance for repeated renders" do
    # Create a more complex component
    heavy_component_class = Class.new(SwiftUIRails::Component::Base) do
      prop :items, type: Array, default: -> { (1..100).to_a }

      swift_ui do
        vstack do
          items.each do |item|
            hstack do
              text("Item #{item}")
              spacer
              button("Action #{item}")
            end
          end
        end
      end
    end

    component = heavy_component_class.new

    # Measure first render time
    start_time = Time.now
    component.call
    first_render_time = Time.now - start_time

    # Measure memoized render time
    start_time = Time.now
    10.times { component.call }
    memoized_render_time = (Time.now - start_time) / 10

    # Memoized renders should be significantly faster
    assert memoized_render_time < (first_render_time / 2)
  end
end
