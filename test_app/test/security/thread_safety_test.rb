require "test_helper"
require "concurrent"

class ThreadSafetyTest < ActiveSupport::TestCase
  include SwiftUIRails::Reactive
  
  def setup
    # Clear any existing stores
    ObservableStore.clear_all
  end
  
  def teardown
    ObservableStore.clear_all
  end
  
  test "ObservableStore.find_or_create is thread-safe" do
    store_ids = []
    threads = []
    
    # Create multiple threads trying to create the same store
    10.times do |i|
      threads << Thread.new do
        store = ObservableStore.find_or_create("shared_store")
        Thread.current[:store_id] = store.object_id
      end
    end
    
    # Wait for all threads
    threads.each(&:join)
    
    # Collect all store IDs
    threads.each { |t| store_ids << t[:store_id] }
    
    # All threads should get the same store instance
    assert_equal 1, store_ids.uniq.size,
      "All threads should receive the same store instance"
  end
  
  test "concurrent updates to store data are thread-safe" do
    store = ObservableStore.find_or_create("counter_store")
    store.set(:counter, 0)
    
    threads = []
    increments_per_thread = 100
    thread_count = 10
    
    # Create threads that increment the counter
    thread_count.times do |i|
      threads << Thread.new do
        increments_per_thread.times do
          store.update do |data|
            data[:counter] += 1
          end
        end
      end
    end
    
    # Wait for all threads
    threads.each(&:join)
    
    # Check final value
    expected = thread_count * increments_per_thread
    actual = store.get(:counter)
    
    assert_equal expected, actual,
      "Counter should equal total increments (#{expected}), but was #{actual}"
  end
  
  test "concurrent reads and writes don't cause race conditions" do
    store = ObservableStore.find_or_create("rw_store")
    errors = Concurrent::Array.new
    
    # Initialize data
    store.update do |data|
      data[:values] = Array.new(100, 0)
    end
    
    reader_threads = []
    writer_threads = []
    
    # Create reader threads
    5.times do |i|
      reader_threads << Thread.new do
        100.times do
          begin
            values = store.get(:values)
            # Verify data consistency
            if values && !values.all? { |v| v >= 0 }
              errors << "Found negative value"
            end
          rescue => e
            errors << "Reader error: #{e.message}"
          end
        end
      end
    end
    
    # Create writer threads
    5.times do |i|
      writer_threads << Thread.new do
        100.times do |j|
          begin
            store.update do |data|
              idx = rand(100)
              data[:values][idx] += 1
            end
          rescue => e
            errors << "Writer error: #{e.message}"
          end
        end
      end
    end
    
    # Wait for all threads
    (reader_threads + writer_threads).each(&:join)
    
    # Check for errors
    assert_empty errors, "Should have no race condition errors: #{errors.join(', ')}"
  end
  
  test "store subscriptions are thread-safe" do
    store = ObservableStore.find_or_create("subscription_store")
    notifications = Concurrent::Array.new
    unsubscribers = Concurrent::Array.new
    
    # Add subscribers from multiple threads
    threads = []
    5.times do |i|
      threads << Thread.new do
        unsubscriber = store.subscribe(self) do |changes|
          notifications << { thread: i, changes: changes }
        end
        unsubscribers << unsubscriber
      end
    end
    
    threads.each(&:join)
    
    # Trigger an update
    store.set(:value, "test")
    
    # All subscribers should be notified
    sleep 0.1 # Give time for notifications
    assert_equal 5, notifications.size,
      "All 5 subscribers should be notified"
    
    # Unsubscribe from multiple threads
    unsubscribe_threads = []
    unsubscribers.each do |unsubscriber|
      unsubscribe_threads << Thread.new { unsubscriber.call }
    end
    
    unsubscribe_threads.each(&:join)
    
    # Clear notifications
    notifications.clear
    
    # Trigger another update
    store.set(:value, "test2")
    
    # No subscribers should be notified
    sleep 0.1
    assert_empty notifications,
      "No subscribers should be notified after unsubscribing"
  end
  
  test "store clear_all is thread-safe" do
    stores = []
    
    # Create stores from multiple threads
    threads = []
    10.times do |i|
      threads << Thread.new do
        store = ObservableStore.find_or_create("store_#{i}")
        stores << store
      end
    end
    
    threads.each(&:join)
    
    # Verify stores were created
    assert_equal 10, ObservableStore.store_count
    
    # Clear from multiple threads simultaneously
    clear_threads = []
    5.times do
      clear_threads << Thread.new { ObservableStore.clear_all }
    end
    
    clear_threads.each(&:join)
    
    # All stores should be cleared
    assert_equal 0, ObservableStore.store_count
  end
  
  test "DSL methods are thread-safe" do
    store = ObservableStore.find_or_create("dsl_store")
    errors = Concurrent::Array.new
    
    threads = []
    
    # Test dynamic setter methods
    10.times do |i|
      threads << Thread.new do
        begin
          store.send("field_#{i}=", "value_#{i}")
        rescue => e
          errors << "Setter error: #{e.message}"
        end
      end
    end
    
    # Test dynamic getter methods
    10.times do |i|
      threads << Thread.new do
        begin
          # Wait a bit to ensure setters have run
          sleep 0.01
          value = store.send("field_#{i}")
        rescue => e
          errors << "Getter error: #{e.message}"
        end
      end
    end
    
    threads.each(&:join)
    
    assert_empty errors, "DSL methods should be thread-safe: #{errors.join(', ')}"
  end
  
  test "compute_if_absent prevents duplicate store creation" do
    creation_count = Concurrent::AtomicFixnum.new(0)
    
    # Monkey-patch to count creations
    original_new = ObservableStore.singleton_class.instance_method(:new)
    ObservableStore.singleton_class.define_method(:new) do |*args|
      creation_count.increment
      original_new.bind(self).call(*args)
    end
    
    threads = []
    100.times do
      threads << Thread.new do
        ObservableStore.find_or_create("singleton_store")
      end
    end
    
    threads.each(&:join)
    
    # Despite 100 threads, only one store should be created
    assert_equal 1, creation_count.value,
      "Only one store instance should be created"
  ensure
    # Restore original method
    ObservableStore.singleton_class.define_method(:new, original_new)
  end
end
# Copyright 2025
