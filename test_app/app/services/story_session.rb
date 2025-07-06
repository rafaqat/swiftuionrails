# frozen_string_literal: true
# Copyright 2025

# StorySession manages persistent state for interactive component stories
# Enables real-time component state management in storybook
class StorySession
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  # SECURITY: Whitelist of allowed story classes to prevent RCE
  ALLOWED_STORIES = %w[
    ButtonComponentStories
    CardComponentStories
    ModalComponentStories
    CounterComponentStories
    ProductCardComponentStories
    ProductListComponentStories
    AuthFormStories
    AuthFormComponentStories
    EnhancedLoginComponentStories
    EnhancedRegisterComponentStories
    VstackComponentStories
    HstackComponentStories
    TextComponentStories
    GridComponentStories
    ImageComponentStories
    ListComponentStories
    SimpleButtonComponentStories
    DslButtonStories
    DslCardStories
    DslCompositionStories
    DslProductCardStories
    DslSimpleTestStories
    ButtonPreviewStories
    CounterDebugStories
    EnhancedAuthStories
    EnhancedGridStories
    NewDslMethodsStories
    ProductLayoutSimpleStories
    SimpleAuthStories
    SimpleTestComponentStories
    SwiftuiPreviewDemoStories
    TestGridStories
  ].freeze
  
  attribute :story_name, :string
  attribute :variant, :string
  attribute :session_id, :string
  attribute :state, default: -> { {} }
  attribute :props, default: -> { {} }
  attribute :created_at, :datetime, default: -> { Time.current }
  
  validates :story_name, :variant, :session_id, presence: true
  
  def self.find_or_create(story_name, variant, session_id)
    key = cache_key(story_name, variant, session_id)
    data = Rails.cache.read(key)
    
    if data
      new(data.symbolize_keys)
    else
      session = new(
        story_name: story_name,
        variant: variant,
        session_id: session_id
      )
      session.save!
      session
    end
  end
  
  def self.find(story_name, variant, session_id)
    key = cache_key(story_name, variant, session_id)
    data = Rails.cache.read(key)
    return nil unless data
    
    new(data.symbolize_keys)
  end
  
  def save!
    Rails.cache.write(cache_key, attributes, expires_in: 30.minutes)
    self
  end
  
  def component_instance
    # SECURITY: Validate story class name to prevent RCE
    story_class_name = "#{story_name.camelize}Stories"
    story_class = safe_constantize_story(story_class_name)
    story_instance = story_class.new
    
    # Get the story method parameters to filter props
    method_obj = story_instance.method(variant.to_sym)
    method_params = method_obj.parameters
    
    # Filter props to only include valid parameters
    accepted_params = method_params.select { |type, name| [:key, :keyreq].include?(type) }.map(&:last)
    filtered_props = props.symbolize_keys.slice(*accepted_params)
    
    # Create component using StoryRenderer for proper context
    renderer = StoryRenderer.new(ApplicationController.new)
    component = renderer.render_story(story_instance, variant.to_sym, **filtered_props)
    
    # If component responds to state management, restore its state
    if component.is_a?(ViewComponent::Base) && component.respond_to?(:restore_state!)
      component.story_session_id = session_id
      component.restore_state!(state)
    end
    
    component
  rescue NameError, NoMethodError => e
    Rails.logger.error "Error creating component instance: #{e.message}"
    nil
  end
  
  def update_state!(new_state)
    self.state = state.merge(new_state)
    save!
    broadcast_state_change
  end
  
  def update_props(new_props)
    self.props = props.merge(new_props)
    save!
  end
  
  def update_props!(new_props)
    self.props = props.merge(new_props)
    save!
    broadcast_prop_change
  end
  
  def save_component_state(component_instance)
    return unless component_instance.respond_to?(:state_variables)
    
    # Extract current state from component
    current_state = {}
    component_instance.state_variables.each do |var_name|
      current_state[var_name.to_s] = component_instance.public_send(var_name)
    end
    
    update_state!(current_state)
  end
  
  # Alias for accessing current state - used by storybook controller
  def current_state
    state
  end
  
  def reset_state!
    self.state = {}
    save!
    broadcast_state_change
  end
  
  private
  
  def cache_key
    self.class.cache_key(story_name, variant, session_id)
  end
  
  def self.cache_key(story_name, variant, session_id)
    "story_session:#{story_name}:#{variant}:#{session_id}"
  end
  
  def broadcast_state_change
    # Broadcast to Turbo streams for real-time updates
    Turbo::StreamsChannel.broadcast_update_to(
      "story_session_#{session_id}",
      target: "component-preview",
      partial: "storybook/live_component",
      locals: { 
        component: component_instance,
        story_session: self
      }
    )
  rescue => e
    Rails.logger.error "Error broadcasting state change: #{e.message}"
  end
  
  def broadcast_prop_change
    # Broadcast prop updates for real-time control updates
    # SECURITY: Validate story class name to prevent RCE
    story_class_name = "#{story_name.camelize}Stories"
    story_class = safe_constantize_story(story_class_name)
    
    Turbo::StreamsChannel.broadcast_update_to(
      "story_session_#{session_id}",
      target: "controls-panel", 
      partial: "storybook/live_controls",
      locals: {
        story_session: self,
        story_class: story_class
      }
    )
  rescue => e
    Rails.logger.error "Error broadcasting prop change: #{e.message}"
  end
  
  private
  
  def safe_constantize_story(story_class_name)
    unless ALLOWED_STORIES.include?(story_class_name)
      Rails.logger.error "[SECURITY] Attempted to instantiate unauthorized story class: #{story_class_name}"
      raise SecurityError, "Unauthorized story class: #{story_class_name}"
    end
    
    begin
      story_class = story_class_name.constantize
      
      # Verify it's actually a ViewComponent Storybook Stories class
      unless defined?(ViewComponent::Storybook::Stories) && story_class < ViewComponent::Storybook::Stories
        Rails.logger.error "[SECURITY] Class #{story_class_name} is not a valid Stories class"
        raise SecurityError, "#{story_class_name} is not a valid Stories class"
      end
      
      Rails.logger.info "[AUDIT] StorySession instantiated story: #{story_class_name}"
      story_class
    rescue NameError => e
      Rails.logger.error "[ERROR] Story class not found: #{story_class_name} - #{e.message}"
      raise ArgumentError, "Story class #{story_class_name} not found"
    end
  end
end
# Copyright 2025
