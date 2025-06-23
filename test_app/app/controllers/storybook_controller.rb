class StorybookController < ApplicationController
  protect_from_forgery except: [:update_preview, :component_action] # Allow AJAX requests
  helper_method :generate_chainable_example, :tailwind_color_to_css
  def index
    @stories = Dir[Rails.root.join("test/components/stories/*_stories.rb")].map do |file|
      story_name = File.basename(file, "_stories.rb")
      component_name = story_name.gsub("_component", "").titleize
      { 
        name: component_name,
        path: story_name,
        file: file
      }
    end
  end

  def show
    story_name = params[:story]
    story_file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")
    
    unless File.exist?(story_file)
      flash[:alert] = "Story not found: #{story_name}"
      redirect_to storybook_index_path
      return
    end
    
    # Load the story file
    load story_file
    
    @story_class_name = "#{story_name.camelize}Stories"
    @story_class = @story_class_name.safe_constantize
    
    unless @story_class
      flash[:alert] = "Story not found: #{story_name}"
      redirect_to storybook_index_path
      return
    end
    
    # Handle both story formats: "simple_button" and "simple_button_component"
    # Always resolve to component class name: "SimpleButtonComponent"
    base_name = story_name.gsub(/_component(_stories)?$/, "")
    @component_name = "#{base_name}_component"
    @component_class = @component_name.camelize.safe_constantize
    
    unless @component_class
      flash[:alert] = "Component not found for story: #{story_name}"
      redirect_to storybook_index_path
      return
    end
    
    @story_name = base_name.titleize
    
    # Get all story methods (public instance methods that aren't from parent classes)
    @story_instance = @story_class.new
    parent_methods = ViewComponent::Storybook::Stories.instance_methods
    @available_stories = @story_instance.public_methods(false) - parent_methods
    
    # Get the requested story variant
    @story_variant = (params[:story_variant] || :default).to_sym
    
    # Extract story configuration
    @story_config = extract_story_config(@story_class)
    @component_props = build_component_props(@story_config)
    
    
    # Handle AJAX and Turbo Stream requests for live updates
    if request.xhr? || request.headers["Accept"]&.include?("turbo-stream")
      render turbo_stream: turbo_stream.update(
        "component-preview",
        partial: "storybook/component_preview",
        locals: {
          component_class: @component_class,
          component_props: @component_props,
          story_instance: @story_instance,
          story_variant: @story_variant,
          available_stories: @available_stories
        }
      )
    end
  end

  # Real-time preview updates for interactive mode
  def update_preview
    story_name = params[:story]
    variant_name = params[:story_variant] || 'default'
    session_id = params[:session_id]
    mode = params[:mode] || 'static'

    # Load story and component classes
    story_file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")
    return render json: { error: "Story not found" }, status: 404 unless File.exist?(story_file)

    load story_file
    story_class_name = "#{story_name.camelize}Stories"
    story_class = story_class_name.safe_constantize
    return render json: { error: "Story class not found" }, status: 404 unless story_class

    # Get component class
    base_name = story_name.gsub(/_component(_stories)?$/, "")
    component_name = "#{base_name}_component"
    component_class = component_name.camelize.safe_constantize
    return render json: { error: "Component not found" }, status: 404 unless component_class

    # Build props from form parameters
    story_config = extract_story_config(story_class)
    component_props = build_component_props(story_config)

    # For interactive mode, use session-aware component
    if mode == 'interactive' && session_id.present?
      story_session = StorySession.find_or_create(story_name, variant_name, session_id)
      
      # Update session state with new props
      story_session.update_props(component_props)
      
      # Get component instance with session context
      component_instance = story_session.component_instance
    else
      # Static mode - create normal component instance
      component_instance = component_class.new(**component_props)
    end

    # Use update with custom smooth transition attributes
    render turbo_stream: turbo_stream.update(
      "component-preview",
      partial: "storybook/live_component_preview",
      locals: {
        component_instance: component_instance,
        story_name: story_name,
        variant_name: variant_name,
        session_id: session_id,
        mode: mode
      }
    )
  rescue => e
    Rails.logger.error "Preview update failed: #{e.message}"
    render json: { error: e.message }, status: 500
  end

  # Handle component actions in interactive mode
  def component_action
    story_name = params[:story]
    variant_name = params[:story_variant] || 'default'
    session_id = params[:session_id]
    action = params[:action]
    component_id = params[:component_id]

    return render json: { error: "Missing required parameters" }, status: 400 unless session_id.present?

    begin
      # Get story session
      story_session = StorySession.find_or_create(story_name, variant_name, session_id)
      component_instance = story_session.component_instance

      # Execute the action if the component responds to it
      action_method = "handle_#{action}"
      if component_instance.respond_to?(action_method)
        component_instance.public_send(action_method)
        
        # Save updated state back to session
        story_session.save_component_state(component_instance)
      end

      render turbo_stream: turbo_stream.update(
        "component-preview",
        partial: "storybook/live_component_preview",
        locals: {
          component_instance: component_instance,
          story_name: story_name,
          variant_name: variant_name,
          session_id: session_id,
          mode: 'interactive'
        }
      )
    rescue => e
      Rails.logger.error "Component action failed: #{e.message}"
      render json: { error: e.message }, status: 500
    end
  end

  # State inspector endpoint for debugging
  def state_inspector
    story_name = params[:story]
    variant_name = params[:story_variant] || 'default'
    session_id = params[:session_id]

    return render json: {} unless session_id.present?

    begin
      story_session = StorySession.find_or_create(story_name, variant_name, session_id)
      component_instance = story_session.component_instance

      # Extract component state
      state_data = {}
      
      # Get state variables if component has state management
      if component_instance.respond_to?(:state_variables)
        component_instance.state_variables.each do |var_name|
          state_data[var_name] = component_instance.public_send(var_name)
        end
      end
      
      # Get props
      if component_instance.respond_to?(:props)
        component_instance.props.each do |prop_name, prop_value|
          state_data["prop_#{prop_name}"] = prop_value
        end
      end

      render json: state_data
    rescue => e
      Rails.logger.error "State inspector failed: #{e.message}"
      render json: { error: e.message }
    end
  end
  
  private
  
  def extract_story_config(story_class)
    # Extract configuration from story class
    controls_collection = story_class.send(:controls)
    controls_hash = {}
    
    # Access the @controls instance variable of the collection
    controls_data = controls_collection.instance_variable_get(:@controls) || []
    
    controls_data.each do |control_data|
      control_hash = control_data.except(:only, :except)
      control_hash[:type] = control_hash.delete(:as)
      controls_hash[control_data[:param]] = control_hash
    end
    
    {
      component: @component_class,
      controls: controls_hash,
      layout: nil
    }
  end
  
  def build_component_props(story_config)
    props = {}
    story_config[:controls].each do |key, control|
      # Use params if provided, otherwise use default
      props[key] = params[key] || control[:default]
      
      # Convert to appropriate type
      case control[:type]
      when :boolean
        props[key] = ActiveModel::Type::Boolean.new.cast(props[key])
      when :select
        # Check if options are integers to determine if we should convert
        if control[:options] && control[:options].all? { |opt| opt.is_a?(Integer) }
          props[key] = props[key].to_i if props[key].is_a?(String)
        else
          # Only convert to symbol for specific symbol-based props like variant, size, and columns
          # String-based select props like corner_radius, font_weight, image_aspect should stay as strings
          symbol_props = [:variant, :size, :columns]
          if symbol_props.include?(key.to_sym) && props[key].is_a?(String)
            props[key] = props[key].to_sym
          end
        end
      end
    end
    props
  end
  
  # Generate chainable SwiftUI-style DSL example
  def generate_chainable_example(base_method, props)
    # Start with the base DSL method
    example = "#{base_method}(\"#{props[:title] || 'Click Me'}\")"
    
    # Add chainable modifiers based on props
    modifiers = []
    
    # Handle variant with button_style
    if props[:variant] && props[:variant] != :primary
      modifiers << ".button_style(:#{props[:variant]})"
    end
    
    # Handle size with button_size  
    if props[:size] && props[:size] != :md
      modifiers << ".button_size(:#{props[:size]})"
    end
    
    # Handle custom background color
    if props[:background_color].present?
      modifiers << ".background(\"#{props[:background_color]}\")"
    end
    
    # Handle custom text color
    if props[:text_color].present?
      modifiers << ".foreground_color(\"#{props[:text_color]}\")"
    end
    
    # Handle corner radius
    if props[:corner_radius] && props[:corner_radius] != "md"
      modifiers << ".corner_radius(\"#{props[:corner_radius]}\")"
    end
    
    # Handle custom padding
    if props[:padding_x].present? || props[:padding_y].present?
      if props[:padding_x].present?
        modifiers << ".padding_horizontal(#{props[:padding_x]})"
      end
      if props[:padding_y].present?
        modifiers << ".padding_vertical(#{props[:padding_y]})"
      end
    end
    
    # Handle font weight
    if props[:font_weight] && props[:font_weight] != "medium"
      case props[:font_weight]
      when "bold"
        modifiers << ".font_bold"
      when "semibold"
        modifiers << ".font_semibold"
      when "light"
        modifiers << ".font_light"
      else
        modifiers << ".font_weight(\"#{props[:font_weight]}\")"
      end
    end
    
    # Handle font size
    if props[:font_size].present?
      modifiers << ".font_size(\"#{props[:font_size]}\")"
    end
    
    # Handle disabled state
    if props[:disabled]
      modifiers << ".disabled"
    end
    
    # Add default modifiers for better styling
    if modifiers.empty? || !modifiers.any? { |m| m.include?("animation") }
      modifiers << ".animation"
      modifiers << ".focus_ring"
    end
    
    # Join everything together with proper formatting
    if modifiers.any?
      example + "\n      " + modifiers.join("\n      ")
    else
      example + "\n      .animation\n      .focus_ring"
    end
  end
  
  # Convert Tailwind color names to CSS color values for color swatches
  def tailwind_color_to_css(color_name)
    # Tailwind CSS color palette mapping
    color_map = {
      # Basic colors
      'white' => '#ffffff',
      'black' => '#000000',
      
      # Gray scale
      'gray-50' => '#f9fafb', 'gray-100' => '#f3f4f6', 'gray-200' => '#e5e7eb', 'gray-300' => '#d1d5db',
      'gray-400' => '#9ca3af', 'gray-500' => '#6b7280', 'gray-600' => '#4b5563', 'gray-700' => '#374151',
      'gray-800' => '#1f2937', 'gray-900' => '#111827',
      
      # Red
      'red-50' => '#fef2f2', 'red-100' => '#fee2e2', 'red-200' => '#fecaca', 'red-300' => '#fca5a5',
      'red-400' => '#f87171', 'red-500' => '#ef4444', 'red-600' => '#dc2626', 'red-700' => '#b91c1c',
      'red-800' => '#991b1b', 'red-900' => '#7f1d1d',
      
      # Orange
      'orange-50' => '#fff7ed', 'orange-100' => '#ffedd5', 'orange-200' => '#fed7aa', 'orange-300' => '#fdba74',
      'orange-400' => '#fb923c', 'orange-500' => '#f97316', 'orange-600' => '#ea580c', 'orange-700' => '#c2410c',
      'orange-800' => '#9a3412', 'orange-900' => '#7c2d12',
      
      # Yellow
      'yellow-50' => '#fefce8', 'yellow-100' => '#fef3c7', 'yellow-200' => '#fde68a', 'yellow-300' => '#fcd34d',
      'yellow-400' => '#fbbf24', 'yellow-500' => '#f59e0b', 'yellow-600' => '#d97706', 'yellow-700' => '#b45309',
      'yellow-800' => '#92400e', 'yellow-900' => '#78350f',
      
      # Green
      'green-50' => '#f0fdf4', 'green-100' => '#dcfce7', 'green-200' => '#bbf7d0', 'green-300' => '#86efac',
      'green-400' => '#4ade80', 'green-500' => '#22c55e', 'green-600' => '#16a34a', 'green-700' => '#15803d',
      'green-800' => '#166534', 'green-900' => '#14532d',
      
      # Blue
      'blue-50' => '#eff6ff', 'blue-100' => '#dbeafe', 'blue-200' => '#bfdbfe', 'blue-300' => '#93c5fd',
      'blue-400' => '#60a5fa', 'blue-500' => '#3b82f6', 'blue-600' => '#2563eb', 'blue-700' => '#1d4ed8',
      'blue-800' => '#1e40af', 'blue-900' => '#1e3a8a',
      
      # Indigo
      'indigo-50' => '#eef2ff', 'indigo-100' => '#e0e7ff', 'indigo-200' => '#c7d2fe', 'indigo-300' => '#a5b4fc',
      'indigo-400' => '#818cf8', 'indigo-500' => '#6366f1', 'indigo-600' => '#4f46e5', 'indigo-700' => '#4338ca',
      'indigo-800' => '#3730a3', 'indigo-900' => '#312e81',
      
      # Purple
      'purple-50' => '#faf5ff', 'purple-100' => '#f3e8ff', 'purple-200' => '#e9d5ff', 'purple-300' => '#d8b4fe',
      'purple-400' => '#c084fc', 'purple-500' => '#a855f7', 'purple-600' => '#9333ea', 'purple-700' => '#7c3aed',
      'purple-800' => '#6b21a8', 'purple-900' => '#581c87',
      
      # Pink
      'pink-50' => '#fdf2f8', 'pink-100' => '#fce7f3', 'pink-200' => '#fbcfe8', 'pink-300' => '#f9a8d4',
      'pink-400' => '#f472b6', 'pink-500' => '#ec4899', 'pink-600' => '#db2777', 'pink-700' => '#be185d',
      'pink-800' => '#9d174d', 'pink-900' => '#831843'
    }
    
    color_map[color_name] || '#6b7280' # Default to gray-500 if color not found
  end
end