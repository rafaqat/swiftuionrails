# frozen_string_literal: true

# Copyright 2025

# LiveStories extends ViewComponent::Storybook::Stories with interactive capabilities
module LiveStories
  extend ActiveSupport::Concern

  included do
    class_attribute :_live_story_definitions, default: {}
    class_attribute :_story_session_config, default: {}
  end

  class_methods do
    # Define a live, interactive story
    def live_story(name, &block)
      story_config = LiveStoryDefinition.new(name)
      story_config.instance_eval(&block) if block_given?

      _live_story_definitions[name] = story_config

      # Create the story method that supports both static and live modes
      define_method(name) do |**props|
        if @live_mode && @story_session
          # Live mode: return component with session management
          render_live_component(name, **props)
        else
          # Static mode: traditional story rendering
          render_static_component(name, **props)
        end
      end
    end

    # Configure session behavior for all stories
    def session_config(&block)
      config = SessionConfig.new
      config.instance_eval(&block) if block_given?
      self._story_session_config = config
    end

    # Check if a story is live-enabled
    def live_story?(name)
      _live_story_definitions.key?(name.to_sym)
    end

    # Get live story configuration
    def live_story_config(name)
      _live_story_definitions[name.to_sym]
    end
  end

  # Enable live mode for this story instance
  def enable_live_mode!(story_session)
    @live_mode = true
    @story_session = story_session
  end

  # Render component in live mode with session management
  def render_live_component(story_name, **props)
    config = self.class.live_story_config(story_name)
    return render_static_component(story_name, **props) unless config

    # Update session props
    @story_session.update_props!(props) if props.any?

    # Create component instance
    component_class = config.component_class
    component = component_class.new(**@story_session.props.symbolize_keys)

    # Enable stateful features if component supports it
    if component.respond_to?(:story_session_id=)
      component.story_session_id = @story_session.session_id

      # Store session lookup for component callbacks
      Rails.cache.write(
        "story_session_lookup:#{@story_session.session_id}",
        {
          story_name: @story_session.story_name,
          variant: @story_session.variant
        },
        expires_in: 30.minutes
      )
    end

    # Restore component state
    component.restore_state!(@story_session.state) if component.respond_to?(:restore_state!)

    component
  end

  # Render component in static mode (traditional)
  def render_static_component(story_name, **props)
    config = self.class.live_story_config(story_name)

    if config
      component_class = config.component_class
      component_class.new(**props)
    else
      # Fallback to traditional component rendering
      # This assumes the story method exists and returns a component
      super(**props) if defined?(super)
    end
  end

  # Configuration class for live stories
  class LiveStoryDefinition
    attr_reader :name, :component_class, :controls_config, :session_config

    def initialize(name)
      @name = name
      @controls_config = {}
      @session_config = {}
    end

    def component(klass)
      @component_class = klass
    end

    def controls(&block)
      controls_builder = ControlsBuilder.new
      controls_builder.instance_eval(&block) if block_given?
      @controls_config = controls_builder.controls
    end

    def session_state(&block)
      session_builder = SessionStateBuilder.new
      session_builder.instance_eval(&block) if block_given?
      @session_config = session_builder.config
    end

    def live_updates(enabled: true)
      @session_config[:live_updates] = enabled
    end

    def stimulus_controller(name)
      @session_config[:stimulus_controller] = name
    end
  end

  # Builder for control definitions
  class ControlsBuilder
    attr_reader :controls

    def initialize
      @controls = {}
    end

    def text(name, default: nil, **options)
      @controls[name] = { type: :text, default: default, **options }
    end

    def select(name, options:, default: nil, **opts)
      @controls[name] = { type: :select, options: options, default: default, **opts }
    end

    def boolean(name, default: false, **options)
      @controls[name] = { type: :boolean, default: default, **options }
    end

    def number(name, default: 0, min: nil, max: nil, step: 1, **options)
      @controls[name] = {
        type: :number,
        default: default,
        min: min,
        max: max,
        step: step,
        **options
      }
    end
  end

  # Builder for session state configuration
  class SessionStateBuilder
    attr_reader :config

    def initialize
      @config = {}
    end

    def initial_state(**state)
      @config[:initial_state] = state
    end

    def persist_for(duration)
      @config[:persist_for] = duration
    end

    def auto_save(enabled = true)
      @config[:auto_save] = enabled
    end
  end

  # Configuration for session behavior
  class SessionConfig
    attr_accessor :default_persist_duration, :auto_save_enabled, :live_updates_enabled

    def initialize
      @default_persist_duration = 30.minutes
      @auto_save_enabled = true
      @live_updates_enabled = true
    end

    def persist_for(duration)
      @default_persist_duration = duration
    end

    def auto_save(enabled = true)
      @auto_save_enabled = enabled
    end

    def live_updates(enabled = true)
      @live_updates_enabled = enabled
    end
  end
end
# Copyright 2025
