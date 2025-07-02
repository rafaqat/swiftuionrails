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
        
        # Add data attributes for Stimulus to handle updates
        @_content = @_content.to_s.gsub(
          /(<[^>]+)(>)/,
          "\\1 data-observed-changes='#{@observed_changes.to_json}'\\2"
        ).html_safe
      end
    end
    
    # Observable store that multiple components can share
    class ObservableStore
      include ActiveSupport::Callbacks
      
      define_callbacks :change
      
      attr_reader :id, :data
      
      @@stores = {}
      
      def self.find_or_create(id)
        @@stores[id] ||= new(id)
      end
      
      def self.find(id)
        @@stores[id]
      end
      
      def self.clear_all
        @@stores.clear
      end
      
      def initialize(id, initial_data = {})
        @id = id
        @data = initial_data.with_indifferent_access
        @observers = Set.new
        @subscriptions = {}
      end
      
      # Update store data
      def update(&block)
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
        
        if changes.any?
          notify_observers(changes)
        end
        
        @data
      end
      
      # Set a specific value
      def set(key, value)
        update { |data| data[key] = value }
      end
      
      # Get a specific value
      def get(key)
        @data[key]
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
      
      # DSL for updating data
      def method_missing(method, *args)
        if method.to_s.end_with?('=')
          # Setter method
          key = method.to_s.chomp('=')
          @data[key] = args.first
        elsif @data.key?(method)
          # Getter method
          @data[method]
        else
          super
        end
      end
      
      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?('=') || @data.key?(method) || super
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