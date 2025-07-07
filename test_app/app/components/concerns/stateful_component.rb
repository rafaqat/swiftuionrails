# frozen_string_literal: true

# Copyright 2025

# StatefulComponent adds enhanced state management for interactive storybook
module StatefulComponent
  extend ActiveSupport::Concern

  included do
    attr_accessor :story_session_id
    # rubocop:disable ThreadSafety/ClassAndModuleAttributes
    # State and effect definitions are set at class definition time and are read-only during requests
    class_attribute :_state_definitions, default: {}
    class_attribute :_effect_definitions, default: {}
    # rubocop:enable ThreadSafety/ClassAndModuleAttributes
  end

  class_methods do
    # Enhanced state definition with story session support
    def state(name, default_value = nil)
      _state_definitions[name] = default_value

      # Create getter that checks story session first
      define_method(name) do
        if story_session_id && (session = current_story_session)
          session.state[name.to_s] || default_value
        else
          # Fallback to instance variable for normal component usage
          instance_variable_get("@#{name}") || default_value
        end
      end

      # Create setter with session persistence and effect triggering
      define_method("#{name}=") do |new_value|
        old_value = send(name)

        if story_session_id && (session = current_story_session)
          # Update session state
          session.update_state!(name.to_s => new_value)
        else
          # Normal component usage
          instance_variable_set("@#{name}", new_value)
        end

        # Trigger effects if value changed
        if old_value != new_value && _effect_definitions[name]
          trigger_effect(name, new_value, old_value)
        end

        new_value
      end
    end

    # Enhanced effect definition
    def effect(state_name, &block)
      _effect_definitions[state_name] = block
    end

    # Define computed properties that depend on state
    def computed(name, &block)
      define_method(name) do
        instance_eval(&block)
      end
    end
  end

  # Restore state from story session
  def restore_state!(state_hash)
    state_hash.each do |key, value|
      if respond_to?("#{key}=")
        # Set without triggering session update (avoid infinite loop)
        if story_session_id
          instance_variable_set("@_restoring_state", true)
          send("#{key}=", value)
          instance_variable_set("@_restoring_state", false)
        else
          send("#{key}=", value)
        end
      end
    end
  end

  # Get current state as hash
  def current_state
    state_hash = {}
    self.class._state_definitions.keys.each do |key|
      state_hash[key.to_s] = send(key)
    end
    state_hash
  end

  # Get list of state variable names
  def state_variables
    self.class._state_definitions.keys
  end

  # Define action methods for interactive stories
  def handle_increment(field = :counter)
    current_value = send(field) || 0
    send("#{field}=", current_value + 1)
  end

  def handle_decrement(field = :counter)
    current_value = send(field) || 0
    send("#{field}=", [ current_value - 1, 0 ].max)
  end

  def handle_toggle(field)
    send("#{field}=", !send(field))
  end

  def handle_reset
    self.class._state_definitions.each do |name, default_value|
      send("#{name}=", default_value)
    end
  end

  private

  def current_story_session
    return nil unless story_session_id
    return @current_story_session if @current_story_session

    # Try to find session from session ID
    # We need story_name and variant, but we can extract from the session
    session_data = Rails.cache.read("story_session_lookup:#{story_session_id}")
    if session_data
      @current_story_session = StorySession.find(
        session_data[:story_name],
        session_data[:variant],
        story_session_id
      )
    end

    @current_story_session
  end

  def trigger_effect(state_name, new_value, old_value)
    effect_block = self.class._effect_definitions[state_name]
    return unless effect_block

    # Execute effect in component context
    instance_exec(new_value, old_value, &effect_block)
  end

  def restoring_state?
    instance_variable_get("@_restoring_state") == true
  end
end
# Copyright 2025
