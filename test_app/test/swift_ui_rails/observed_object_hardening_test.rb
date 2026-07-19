# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class SwiftUIRails::ObservedObjectHardeningTest < ViewComponent::TestCase
  ExplicitStore = SwiftUIRails::Reactive::ObservableStore.new(
    "inventory.actual",
    count: 1
  )

  class SnapshotComponent < SwiftUIRails::Component::Base
    class_attribute :loader_calls, default: 0

    observed_resource :inventory, stream: :inventory_snapshot do
      self.class.loader_calls += 1
      { revision: self.class.loader_calls, items: ["item-#{self.class.loader_calls}"] }
    end

    swift_ui do
      first = @component.inventory.data
      first[:items] << "local-only"
      second = @component.inventory.data

      text("#{first.fetch(:revision)}:#{second.fetch(:revision)}:#{second.fetch(:items).join(',')}")
    end
  end

  class ExplicitStoreComponent < SwiftUIRails::Component::Base
    observed_object :inventory, store: ExplicitStore

    swift_ui do
      text("Explicit store")
    end
  end

  class DynamicStoreComponent < SwiftUIRails::Component::Base
    observed_object :inventory,
      store: -> { SwiftUIRails::Reactive::ObservableStore.new("inventory.dynamic", count: 1) }

    swift_ui do
      text("Dynamic store")
    end
  end

  setup do
    SnapshotComponent.loader_calls = 0
  end

  test "observed resource loads once per render and every read uses an isolated copy of that snapshot" do
    component = SnapshotComponent.new
    render_inline(component)

    assert_text "1:1:item-1"
    assert_equal 1, SnapshotComponent.loader_calls

    render_inline(component)

    assert_text "2:2:item-2"
    assert_equal 2, SnapshotComponent.loader_calls
    assert_equal 3, component.inventory.data.fetch(:revision)
    assert_equal 3, SnapshotComponent.loader_calls
  end

  test "observable store update rolls back atomically without callbacks or broadcasts when mutation raises" do
    store = SwiftUIRails::Reactive::ObservableStore.new(
      "atomic.inventory",
      count: 1,
      nested: { status: "ready" }
    )
    observed_changes = []
    broadcasts = []
    server = Object.new
    server.define_singleton_method(:broadcast) do |stream, payload|
      broadcasts << [stream, payload]
    end
    store.subscribe(self) { |changes| observed_changes << changes }

    error = assert_raises(RuntimeError) do
      ActionCable.stub(:server, server) do
        store.update do |data|
          data[:count] = 2
          data[:nested][:status] = "mutated"
          raise "transaction failed"
        end
      end
    end

    assert_equal "transaction failed", error.message
    assert_equal({ "count" => 1, "nested" => { "status" => "ready" } }, store.data)
    assert_empty observed_changes
    assert_empty broadcasts
  end

  test "explicit and dynamic stores publish their normalized actual stream ids" do
    render_inline(ExplicitStoreComponent.new)
    assert_selector "[data-sui-observed-stores='[\"inventory.actual\"]']"

    render_inline(DynamicStoreComponent.new)
    assert_selector "[data-sui-observed-stores='[\"inventory.dynamic\"]']"
  end
end
