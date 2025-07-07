# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Reactive
    # @ObservedObject equivalent for shared state management
    module ObservedObject
      extend ActiveSupport::Concern

      included do
        class_attribute :observed_object_definitions, default: {}

        # Temporarily disabled to debug rendering issue
      end

      class_methods do
        # Define an observed object property
        # @observed_object :user_store
        ##
        # Defines an observed object property with reactive store access and update methods.
        # Registers the property for observation, creates getter and updater methods, and links it to an observable store.
        # @param [Symbol] name - The name of the observed object property.
        # @param [Class, nil] type - The expected type of the observed object, if specified.
        # @param [Symbol, nil] store - The store identifier to use; defaults to the property name.
        def observed_object(name, type: nil, store: nil)
          observed_object_definitions[name] = {
            type: type,
            store: store || name
          }

          # Define getter that returns the observed store
          define_method(name) do
            @observed_objects ||= {}
            @observed_objects[name] ||= begin
              store_name = self.class.observed_object_definitions[name][:store]
              ObservableStore.find_or_create(store_name)
            end
          end

          # Define convenience methods for accessing store data
          define_method("#{name}_data") do
            send(name).data
          end

          # Define method to update store
          define_method("update_#{name}") do |&block|
            send(name).update(&block)
          end
        end
      end

      private

      ##
      # Subscribes the instance to all defined observed object stores, registering callbacks to handle changes.
      # Stores the resulting subscription handles for later management.
      def subscribe_to_observed_objects
        @observation_subscriptions = []

        self.class.observed_object_definitions.each_key do |name|
          store = send(name)

          # Subscribe to changes
          subscription = store.subscribe(self) do |changes|
            handle_observed_changes(name, changes)
          end

          @observation_subscriptions << subscription
        end
      end

      ##
      # Records changes from an observed store for later processing.
      # Stores the changes associated with the given store name in the @observed_changes hash.
      # @param [String, Symbol] store_name - The name of the observed store.
      # @param [Hash] changes - The changes detected in the observed store.
      def handle_observed_changes(store_name, changes)
        # This will be called when the observed object changes
        # In a real implementation, this would trigger a re-render
        @observed_changes ||= {}
        @observed_changes[store_name] = changes
      end

      ##
      # Embeds observed changes as a `data-observed-changes` attribute in the root HTML element of the content.
      #
      # If no root element exists, wraps the content in a `<div>` with the attribute.
      # Uses Nokogiri for safe HTML manipulation to prevent XSS vulnerabilities.
      def add_observation_metadata
        return unless @observed_changes&.any?

        # SECURITY: Use proper HTML parsing to prevent XSS
        require 'nokogiri'
        doc = Nokogiri::HTML::DocumentFragment.parse(@_content.to_s)

        # Find the root element or create a wrapper if needed
        root = doc.children.first
        if root&.element?
          # Safely add the data attribute with proper escaping
          root.set_attribute('data-observed-changes', @observed_changes.to_json)
          @_content = doc.to_html.html_safe
        elsif doc.children.any?
          # Wrap content in a div if there's no root element
          wrapper = Nokogiri::XML::Node.new('div', doc)
          wrapper.set_attribute('data-observed-changes', @observed_changes.to_json)
          doc.children.each { |child| wrapper.add_child(child) }
          doc.add_child(wrapper)
          @_content = doc.to_html.html_safe
        end
      end
    end

    # Observable store that multiple components can share
    # SECURITY: Thread-safe implementation using Concurrent::Map
    class ObservableStore
      include ActiveSupport::Callbacks

      define_callbacks :change

      attr_reader :id, :data

      # SECURITY: Use thread-safe Concurrent::Map instead of class variable
      require 'concurrent-ruby'
      @stores = Concurrent::Map.new
      @mutex = Mutex.new

      class << self
        ##
        # Retrieves the observable store with the given ID, creating it if it does not exist.
        # Ensures thread safety during retrieval and creation.
        # @param [Object] id - The identifier for the store.
        # @return [ObservableStore] The store instance associated with the given ID.
        def find_or_create(id)
          @stores.compute_if_absent(id) { new(id) }
        end

        ##
        # Retrieves the observable store instance for the given ID in a thread-safe manner.
        # @param [Object] id - The identifier of the store to retrieve.
        # @return [ObservableStore, nil] The store instance if found, or nil if it does not exist.
        def find(id)
          @stores[id]
        end

        ##
        # Removes all observable stores in a thread-safe manner.
        def clear_all
          @mutex.synchronize do
            @stores.clear
          end
        end

        ##
        # Returns the number of observable stores currently managed.
        # @return [Integer] The total count of active stores.
        def store_count
          @stores.size
        end

        ##
        # Returns an array of all observable store IDs.
        # @return [Array] The list of store identifiers.
        def all_store_ids
          @stores.keys
        end
      end

      ##
      # Initializes a new observable store with the given ID and optional initial data.
      # Sets up thread-safe data storage and observer management.
      # @param [String, Symbol] id - The unique identifier for the store.
      # @param [Hash] initial_data - The initial data for the store (default: empty hash).
      def initialize(id, initial_data = {})
        @id = id
        @data = initial_data.with_indifferent_access
        @data_mutex = Mutex.new
        # SECURITY: Use thread-safe Set and Hash
        @observers = Concurrent::Set.new
        @subscriptions = Concurrent::Hash.new
      end

      ##
      # Atomically updates the store's data using the provided block and notifies observers of any changes.
      # The block can either receive the mutable data hash or execute in the store's context for dynamic access.
      # @return [Hash] The updated data hash.
      def update(&block)
        changes = nil

        @data_mutex.synchronize do
          old_data = @data.deep_dup

          if block.arity == 1
            # Pass mutable data to block
            yield(@data)
          else
            # Execute in context where data methods are available
            instance_exec(&block)
          end

          # Track what changed
          changes = compute_changes(old_data, @data)
        end

        # Notify observers outside the mutex to prevent deadlocks
        notify_observers(changes) if changes&.any?

        @data
      end

      ##
      # Sets a specific key-value pair in the store's data.
      # @param key The key to set.
      # @param value The value to assign to the key.
      def set(key, value)
        update { |data| data[key] = value }
      end

      ##
      # Retrieves the value associated with the given key from the store in a thread-safe manner.
      # @param key The key to look up in the store's data.
      # @return The value corresponding to the key, or nil if the key does not exist.
      def get(key)
        @data_mutex.synchronize { @data[key] }
      end

      ##
      # Returns a thread-safe deep copy of the store's current data.
      # @return [Hash] A deep duplicate of the store's data at the time of invocation.
      def data_snapshot
        @data_mutex.synchronize { @data.deep_dup }
      end

      ##
      # Subscribes an observer to store changes with a callback.
      # Returns a lambda that can be called to unsubscribe.
      # @param observer The object subscribing to changes.
      # @yield [changes] Block to be called when the store changes, receiving the changes hash.
      # @return [Proc] A lambda that unsubscribes the observer when called.
      def subscribe(observer, &callback)
        subscription_id = SecureRandom.hex(8)
        @subscriptions[subscription_id] = {
          observer: observer,
          callback: callback
        }
        @observers << observer

        # Return unsubscribe function
        -> { unsubscribe(subscription_id) }
      end

      ##
      # Removes a subscription by its ID, stopping further notifications to the associated observer.
      # @param [Object] subscription_id - The identifier of the subscription to remove.
      def unsubscribe(subscription_id)
        if (sub = @subscriptions.delete(subscription_id))
          @observers.delete(sub[:observer])
        end
      end

      ##
      # Notifies all subscribed observers of changes to the store.
      # @param [Hash] changes - A hash describing the changes to the store's data.
      def notify_observers(changes)
        run_callbacks :change do
          @subscriptions.each_value do |subscription|
            subscription[:callback].call(changes)
          end
        end
      end

      ##
      # Resets the store's data to the provided initial state.
      # @param [Hash] initial_data The data to reset the store with. Defaults to an empty hash.
      def reset(initial_data = {})
        update { @data = initial_data.with_indifferent_access }
      end

      private

      ##
      # Computes the differences between two data hashes, identifying added, modified, and removed keys.
      # @param [Hash] old_data The original data hash.
      # @param [Hash] new_data The updated data hash.
      # @return [Hash] A hash describing changes, where each key maps to a hash with :old, :new, and optionally :removed fields.
      def compute_changes(old_data, new_data)
        changes = {}

        # Find added/modified keys
        new_data.each do |key, value|
          next unless !old_data.key?(key) || old_data[key] != value

          changes[key] = {
            old: old_data[key],
            new: value
          }
        end

        # Find removed keys
        old_data.each do |key, value|
          next if new_data.key?(key)

          changes[key] = {
            old: value,
            new: nil,
            removed: true
          }
        end

        changes
      end

      ##
      # Provides dynamic getter and setter methods for store data keys with thread safety.
      # If the method name ends with '=', sets the corresponding key; otherwise, retrieves the value if the key exists.
      # Falls back to the default behavior if the key is not present.
      def method_missing(method, *args)
        if method.to_s.end_with?('=')
          # Setter method - use thread-safe update
          key = method.to_s.chomp('=')
          set(key, args.first)
        elsif @data_mutex.synchronize { @data.key?(method) }
          # Getter method - thread-safe access
          get(method)
        else
          super
        end
      end

      ##
      # Determines if the store responds to a dynamic getter or setter method for a data key.
      # @param [Symbol, String] method - The method name being checked.
      # @param [Boolean] include_private - Whether to include private methods.
      # @return [Boolean] True if the method is a dynamic getter/setter for a data key or handled by the superclass.
      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?('=') || @data_mutex.synchronize { @data.key?(method) } || super
      end
    end

    # Publisher protocol for custom observable objects
    module Publisher
      extend ActiveSupport::Concern

      included do
        attr_reader :object_will_change_callbacks
      end

      ##
      # Initializes the publisher and sets up the callbacks array for change notifications.
      def initialize(*)
        super
        @object_will_change_callbacks = []
      end

      ##
      # Invokes all registered callbacks to signal that the object is about to change.
      def object_will_change
        @object_will_change_callbacks.each(&:call)
      end

      ##
      # Registers a callback to be invoked when the object is about to change.
      # @yield The block to be called before changes occur.
      # @return [Proc] An unsubscribe lambda that removes the registered callback.
      def on_change(&block)
        @object_will_change_callbacks << block
        # Return unsubscribe function
        -> { @object_will_change_callbacks.delete(block) }
      end
    end
  end
end
# Copyright 2025
