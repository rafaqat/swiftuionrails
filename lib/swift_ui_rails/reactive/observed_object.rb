# frozen_string_literal: true

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
        # @observed_object :app_state, type: AppState
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
      
      def subscribe_to_observed_objects
        @observation_subscriptions = []
        
        self.class.observed_object_definitions.each do |name, definition|
          store = send(name)
          
          # Subscribe to changes
          subscription = store.subscribe(self) do |changes|
            handle_observed_changes(name, changes)
          end
          
          @observation_subscriptions << subscription
        end
      end
      
      def handle_observed_changes(store_name, changes)
        # This will be called when the observed object changes
        # In a real implementation, this would trigger a re-render
        @observed_changes ||= {}
        @observed_changes[store_name] = changes
      end
      
      def add_observation_metadata
        return unless @observed_changes&.any?
        
        # SECURITY: Use proper HTML parsing to prevent XSS
        require 'nokogiri'
        doc = Nokogiri::HTML::DocumentFragment.parse(@_content.to_s)
        
        # Find the root element or create a wrapper if needed
        root = doc.children.first
        if root && root.element?
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
        # SECURITY: Thread-safe find_or_create using compute_if_absent
        def find_or_create(id)
          @stores.compute_if_absent(id) { new(id) }
        end
        
        # SECURITY: Thread-safe find
        def find(id)
          @stores[id]
        end
        
        # SECURITY: Thread-safe clear with mutex protection
        def clear_all
          @mutex.synchronize do
            @stores.clear
          end
        end
        
        # SECURITY: Thread-safe store count for monitoring
        def store_count
          @stores.size
        end
        
        # SECURITY: Thread-safe store listing
        def all_store_ids
          @stores.keys
        end
      end
      
      def initialize(id, initial_data = {})
        @id = id
        @data = initial_data.with_indifferent_access
        @data_mutex = Mutex.new
        # SECURITY: Use thread-safe Set and Hash
        @observers = Concurrent::Set.new
        @subscriptions = Concurrent::Hash.new
      end
      
      # SECURITY: Thread-safe update method
      def update(&block)
        changes = nil
        
        @data_mutex.synchronize do
          old_data = @data.deep_dup
          
          if block.arity == 1
            # Pass mutable data to block
            block.call(@data)
          else
            # Execute in context where data methods are available
            instance_exec(&block)
          end
          
          # Track what changed
          changes = compute_changes(old_data, @data)
        end
        
        # Notify observers outside the mutex to prevent deadlocks
        if changes&.any?
          notify_observers(changes)
        end
        
        @data
      end
      
      # Set a specific value
      def set(key, value)
        update { |data| data[key] = value }
      end
      
      # SECURITY: Thread-safe getter
      def get(key)
        @data_mutex.synchronize { @data[key] }
      end
      
      # SECURITY: Thread-safe data snapshot
      def data_snapshot
        @data_mutex.synchronize { @data.deep_dup }
      end
      
      # Subscribe to changes
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
      
      # Unsubscribe from changes
      def unsubscribe(subscription_id)
        if sub = @subscriptions.delete(subscription_id)
          @observers.delete(sub[:observer])
        end
      end
      
      # Notify all observers of changes
      def notify_observers(changes)
        run_callbacks :change do
          @subscriptions.each do |_, subscription|
            subscription[:callback].call(changes)
          end
        end
      end
      
      # Reset store to initial state
      def reset(initial_data = {})
        update { @data = initial_data.with_indifferent_access }
      end
      
      private
      
      def compute_changes(old_data, new_data)
        changes = {}
        
        # Find added/modified keys
        new_data.each do |key, value|
          if !old_data.key?(key) || old_data[key] != value
            changes[key] = {
              old: old_data[key],
              new: value
            }
          end
        end
        
        # Find removed keys
        old_data.each do |key, value|
          unless new_data.key?(key)
            changes[key] = {
              old: value,
              new: nil,
              removed: true
            }
          end
        end
        
        changes
      end
      
      # SECURITY: Thread-safe DSL for updating data
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
      
      def initialize(*)
        super
        @object_will_change_callbacks = []
      end
      
      # Call this before making changes
      def object_will_change
        @object_will_change_callbacks.each(&:call)
      end
      
      # Subscribe to changes
      def on_change(&block)
        @object_will_change_callbacks << block
        # Return unsubscribe function
        -> { @object_will_change_callbacks.delete(block) }
      end
    end
  end
end
# Copyright 2025
