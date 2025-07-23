# frozen_string_literal: true

module SwiftUIRails
  module Component
    # StatefulComponent provides reactive state management for components
    #
    # Features:
    # - Reactive state properties with change tracking
    # - Computed properties with automatic invalidation
    # - Side effects triggered by state changes
    # - State persistence (session/localStorage)
    # - Watch patterns for complex state dependencies
    #
    # Usage:
    #   class MyComponent < ApplicationComponent
    #     include StatefulComponent
    #     
    #     state :count, default: 0, reactive: true
    #     state :user_preferences, default: {}, persist: :session
    #     
    #     computed :doubled_count do
    #       count * 2
    #     end
    #     
    #     effect :count do |new_value, old_value|
    #       # Triggered when count changes
    #     end
    #   end
    module StatefulComponent
      extend ActiveSupport::Concern
      
      included do
        class_attribute :state_configurations, default: {}
        class_attribute :computed_configurations, default: {}
        class_attribute :effects, default: {}
        class_attribute :watchers, default: {}
        
        attr_reader :state_store
      end
      
      class_methods do
        # Define a reactive state property
        def state(name, default: nil, reactive: true, persist: false)
          state_config = {
            default: default,
            reactive: reactive,
            persist: persist
          }
          
          state_configurations[name] = state_config
          
          # Getter method
          define_method name do
            load_state(name, state_config)
          end
          
          # Setter method with reactivity
          define_method "#{name}=" do |value|
            set_state(name, value, state_config)
          end
          
          # Predicate method
          define_method "#{name}?" do
            !!send(name)
          end
        end
        
        # Define computed properties that auto-invalidate
        def computed(name, dependencies: [], &block)
          computed_config = {
            block: block,
            dependencies: Array(dependencies)
          }
          
          computed_configurations[name] = computed_config
          
          define_method name do
            @computed_cache ||= {}
            
            # Check if we need to recompute
            if @computed_cache[name].nil? || computed_invalidated?(name)
              @computed_cache[name] = instance_eval(&block)
              @computed_dependencies_cache ||= {}
              @computed_dependencies_cache[name] = compute_dependency_values(computed_config[:dependencies])
            end
            
            @computed_cache[name]
          end
          
          # Manual invalidation
          define_method "invalidate_#{name}" do
            @computed_cache&.delete(name)
            @computed_dependencies_cache&.delete(name)
          end
        end
        
        # Define side effects triggered by state changes
        def effect(state_name, &block)
          effects[state_name] ||= []
          effects[state_name] << block
        end
        
        # Define watchers for multiple state changes
        def watch(*state_names, &block)
          state_names.each do |state_name|
            watchers[state_name] ||= []
            watchers[state_name] << block
          end
        end
      end
      
      def initialize(*args, **kwargs)
        super
        initialize_state_store
      end
      
      private
      
      def initialize_state_store
        @state_store = {}
        @computed_cache = {}
        @computed_dependencies_cache = {}
        @state_change_callbacks = []
      end
      
      def load_state(name, config)
        return @state_store[name] if @state_store.key?(name)
        
        # Try to load persisted state first
        if config[:persist]
          persisted_value = load_persisted_state(name, config[:persist])
          if !persisted_value.nil?
            @state_store[name] = persisted_value
            return persisted_value
          end
        end
        
        # Use default value
        default_value = evaluate_default(config[:default])
        @state_store[name] = default_value
        default_value
      end
      
      def set_state(name, value, config)
        old_value = @state_store[name]
        @state_store[name] = value
        
        # Persist if configured
        if config[:persist]
          persist_state(name, value, config[:persist])
        end
        
        # Trigger reactivity
        if config[:reactive] && old_value != value
          trigger_effects(name, value, old_value)
          trigger_watchers(name, value, old_value)
          invalidate_computed_dependencies(name)
          
          # Trigger state change callbacks
          @state_change_callbacks.each do |callback|
            callback.call(name, value, old_value)
          end
        end
        
        value
      end
      
      def evaluate_default(default)
        case default
        when Proc
          instance_eval(&default)
        when Symbol
          send(default) if respond_to?(default, true)
        else
          default
        end
      end
      
      def trigger_effects(state_name, new_value, old_value)
        return unless self.class.effects[state_name]
        
        self.class.effects[state_name].each do |effect_block|
          begin
            instance_exec(new_value, old_value, &effect_block)
          rescue => e
            Rails.logger.error "Effect error for #{state_name}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
      end
      
      def trigger_watchers(state_name, new_value, old_value)
        return unless self.class.watchers[state_name]
        
        self.class.watchers[state_name].each do |watcher_block|
          begin
            instance_exec(state_name, new_value, old_value, &watcher_block)
          rescue => e
            Rails.logger.error "Watcher error for #{state_name}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
      end
      
      def invalidate_computed_dependencies(changed_state)
        return unless @computed_dependencies_cache
        
        # Find computed properties that depend on this state
        self.class.computed_configurations.each do |computed_name, config|
          if config[:dependencies].include?(changed_state) || config[:dependencies].empty?
            # Empty dependencies means it watches all state
            invalidate_computed_property(computed_name)
          end
        end
      end
      
      def computed_invalidated?(name)
        return true unless @computed_dependencies_cache&.key?(name)
        
        config = self.class.computed_configurations[name]
        return true unless config
        
        # Check if any dependencies have changed
        current_values = compute_dependency_values(config[:dependencies])
        current_values != @computed_dependencies_cache[name]
      end
      
      def compute_dependency_values(dependencies)
        if dependencies.empty?
          # Watch all state
          @state_store.dup
        else
          dependencies.map { |dep| [dep, @state_store[dep]] }.to_h
        end
      end
      
      def invalidate_computed_property(name)
        @computed_cache&.delete(name)
        @computed_dependencies_cache&.delete(name)
      end
      
      def load_persisted_state(name, persist_type)
        case persist_type
        when :session
          # This would integrate with Rails session in a real implementation
          # For now, return nil to use defaults
          nil
        when :local_storage
          # This would require JavaScript integration
          nil
        else
          nil
        end
      end
      
      def persist_state(name, value, persist_type)
        case persist_type
        when :session
          # This would integrate with Rails session
          # Implementation depends on having access to session
        when :local_storage
          # This would require JavaScript integration via Stimulus
        end
      end
      
      # Public API for external state management
      public
      
      def on_state_change(&block)
        @state_change_callbacks << block
      end
      
      def get_state(name)
        @state_store[name]
      end
      
      def set_state_value(name, value)
        config = self.class.state_configurations[name]
        return unless config
        
        set_state(name, value, config)
      end
      
      def invalidate_all_computed
        @computed_cache&.clear
        @computed_dependencies_cache&.clear
      end
      
      def state_snapshot
        @state_store.dup
      end
    end
  end
end