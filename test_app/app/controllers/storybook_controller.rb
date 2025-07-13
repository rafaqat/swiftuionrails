# frozen_string_literal: true

# Copyright 2025

class StorybookController < ApplicationController
  # SECURITY: This controller is for development/test environments only
  # Use proper CSRF tokens in AJAX requests instead of disabling protection
  # Add csrf_meta_tags to layout and include token in AJAX headers
  helper_method :tailwind_color_to_css
  helper StorybookDebugHelper
  def index
    # Show both DSL stories and component stories needed for tests
    dsl_stories = [ 
      "dsl_button", 
      "dsl_card", 
      "dsl_product_card", 
      "product_layout_simple", 
      "enhanced_grid", 
      "auth_form", 
      "simple_auth", 
      "card_component", 
      "enhanced_product_list_component",
      "button_preview",
      "counter_component",
      "counter_debug",
      "dsl_composition",
      "dsl_simple_test",
      "enhanced_auth",
      "new_dsl_methods",
      "responsive_card_component",
      "simple_test_component",
      "swiftui_preview_demo",
      "test_grid"
    ]

    @stories = dsl_stories.map do |story_name|
      file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")
      next unless File.exist?(file)

      display_name = case story_name
      when "dsl_button" then "DSL Button"
      when "dsl_card" then "DSL Card"
      when "dsl_product_card" then "DSL Product Card"
      when "product_layout_simple" then "DSL Product List"
      when "enhanced_grid" then "Enhanced Grid Layouts"
      when "auth_form" then "Authentication Forms"
      when "simple_auth" then "Simple Auth Forms"
      when "card_component" then "Card Component"
      when "enhanced_product_list_component" then "Enhanced Product List"
      when "button_preview" then "Button Preview"
      when "counter_component" then "Counter Component"
      when "counter_debug" then "Counter Debug"
      when "dsl_composition" then "DSL Composition"
      when "dsl_simple_test" then "DSL Simple Test"
      when "enhanced_auth" then "Enhanced Auth"
      when "new_dsl_methods" then "New DSL Methods"
      when "responsive_card_component" then "Responsive Card Component"
      when "simple_test_component" then "Simple Test Component"
      when "swiftui_preview_demo" then "SwiftUI Preview Demo"
      when "test_grid" then "Test Grid"
      else story_name.titleize
      end

      {
        name: display_name,
        path: story_name,
        file: file
      }
    end.compact
  end

  def show
    story_name = sanitize_story_name(params[:story])
    unless story_name
      flash[:alert] = "Invalid story name"
      redirect_to storybook_index_path
      return
    end

    story_file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")

    Rails.logger.info "Looking for story file: #{story_file}"
    Rails.logger.info "File exists? #{File.exist?(story_file)}"

    unless File.exist?(story_file)
      flash[:alert] = "Story not found: #{story_name}"
      redirect_to storybook_index_path
      return
    end

    # Load the story file
    load story_file

    @story_class_name = "#{story_name.camelize}Stories"
    Rails.logger.info "Looking for story class: #{@story_class_name}"

    # Validate class name before constantize
    unless allowed_story_class?(@story_class_name)
      Rails.logger.error "[SECURITY] Attempted to load unauthorized story class: #{@story_class_name}"
      flash[:alert] = "Unauthorized story class"
      redirect_to storybook_index_path
      return
    end

    @story_class = @story_class_name.safe_constantize
    Rails.logger.info "Story class found? #{@story_class.present?}"

    unless @story_class
      flash[:alert] = "Story class not found: #{@story_class_name}"
      redirect_to storybook_index_path
      return
    end

    # Handle both story formats: "simple_button" and "simple_button_component"
    # Always resolve to component class name: "SimpleButtonComponent"
    base_name = story_name.gsub(/_component(_stories)?$/, "")
    @component_name = "#{base_name}_component"
    component_class_name = @component_name.camelize

    # Validate component class name before constantize
    if component_class_name.present? && allowed_component_class?(component_class_name)
      @component_class = component_class_name.safe_constantize
    else
      @component_class = nil
    end

    # For DSL stories (like dsl_button), a backing component is not required
    # DSL stories create elements directly using the DSL, not components
    unless @component_class
      if story_name.start_with?("dsl_") || story_name.include?("product_layout") || 
         story_name == "enhanced_grid" || story_name == "auth_form" || story_name == "simple_auth" ||
         story_name == "button_preview" || story_name == "counter_debug" || story_name == "enhanced_auth" ||
         story_name == "new_dsl_methods" || story_name == "swiftui_preview_demo" || story_name == "test_grid"
        # DSL stories don't need backing components - they use pure DSL elements
        @component_class = nil
        @component_name = story_name
      else
        flash[:alert] = "Component not found for story: #{story_name}"
        redirect_to storybook_index_path
        return
      end
    end

    @story_name = base_name.titleize

    # Get all story methods (public instance methods that aren't from parent classes)
    @story_instance = @story_class.new
    parent_methods = ViewComponent::Storybook::Stories.instance_methods
    @available_stories = @story_instance.public_methods(false) - parent_methods

    # Get the requested story variant (support both :variant and :story_variant params)
    @story_variant = (params[:variant] || params[:story_variant] || :default).to_sym

    # Extract story configuration
    @story_config = extract_story_config(@story_class)
    @component_props = build_component_props(@story_config)

    # Read actual story source code for DSL stories
    is_dsl_story = story_name.start_with?("dsl_") || story_name.include?("product_layout") || 
                   story_name == "enhanced_grid" || story_name == "auth_form" || story_name == "simple_auth" ||
                   story_name == "button_preview" || story_name == "counter_debug" || story_name == "enhanced_auth" ||
                   story_name == "new_dsl_methods" || story_name == "swiftui_preview_demo" || story_name == "test_grid"
    if is_dsl_story && @story_class
      story_file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")
      if File.exist?(story_file)
        @story_source_code = extract_story_method_source(story_file, @story_variant.to_s)
      end
    end


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
    story_name = sanitize_story_name(params[:story])
    unless story_name
      return render json: { error: "Invalid story name" }, status: 400
    end

    variant_name = params[:story_variant] || "default"
    session_id = params[:session_id]
    mode = params[:mode] || "static"

    # Load story and component classes
    story_file = Rails.root.join("test/components/stories/#{story_name}_stories.rb")
    return render json: { error: "Story not found" }, status: 404 unless File.exist?(story_file)

    load story_file
    story_class_name = "#{story_name.camelize}Stories"

    # Validate story class before constantize
    unless allowed_story_class?(story_class_name)
      Rails.logger.error "[SECURITY] Attempted to load unauthorized story class: #{story_class_name}"
      return render json: { error: "Unauthorized story class" }, status: 403
    end

    story_class = story_class_name.safe_constantize
    return render json: { error: "Story class not found" }, status: 404 unless story_class

    # Get component class (optional for DSL stories)
    base_name = story_name.gsub(/_component(_stories)?$/, "")
    component_name = "#{base_name}_component"
    component_class_name = component_name.camelize

    # Validate component class before constantize
    if component_class_name.present? && allowed_component_class?(component_class_name)
      component_class = component_class_name.safe_constantize
    else
      component_class = nil
    end

    # For DSL stories (like dsl_button), a backing component is not required
    unless component_class
      if story_name.start_with?("dsl_") || story_name.include?("product_layout") || story_name == "enhanced_grid" || story_name == "auth_form" || story_name == "simple_auth"
        # DSL stories don't need backing components - they use pure DSL elements
        component_class = nil
      else
        return render json: { error: "Component not found" }, status: 404
      end
    end

    # Build props from form parameters
    story_config = extract_story_config(story_class)
    component_props = build_component_props(story_config)

    # Debug: Log the actual props being passed
    Rails.logger.info "Component props: #{component_props.inspect}"

    # For DSL stories, we don't create component instances - we render the story directly
    if component_class.nil?
      # DSL story - render the story method directly with props
      story_instance = story_class.new
      component_instance = nil
    else
      # Component story - create component instance
      if mode == "interactive" && session_id.present?
        story_session = StorySession.find_or_create(story_name, variant_name, session_id)

        # Update session state with new props
        story_session.update_props(component_props)

        # Get component instance with session context
        component_instance = story_session.component_instance
      else
        # Static mode - create normal component instance
        component_instance = component_class.new(**component_props)
      end
    end

    # Get current state for the inspector
    state_data = {}
    if mode == "interactive" && session_id.present? && defined?(story_session) && story_session
      state_data = story_session.current_state || {}
    end

    # Use update with custom smooth transition attributes and state data
    render turbo_stream: turbo_stream.update(
      "component-preview",
      partial: "storybook/component_preview",
      locals: {
        component_class: component_class,
        component_props: component_props,
        story_instance: story_instance || story_class.new,
        story_variant: variant_name,
        available_stories: [ variant_name ],
        state_data: state_data
      }
    )
  rescue => e
    Rails.logger.error "Preview update failed: #{e.message}"
    render json: { error: e.message }, status: 500
  end

  # Handle component actions in interactive mode
  def component_action
    story_name = sanitize_story_name(params[:story])
    unless story_name
      return render json: { error: "Invalid story name" }, status: 400
    end

    variant_name = params[:story_variant] || "default"
    session_id = params[:session_id]
    action = sanitize_action_name(params[:action])
    component_id = params[:component_id]

    return render json: { error: "Missing required parameters" }, status: 400 unless session_id.present? && action.present?

    begin
      # Get story session
      story_session = StorySession.find_or_create(story_name, variant_name, session_id)
      component_instance = story_session.component_instance

      # Define allowed actions whitelist
      allowed_actions = %w[increment decrement reset click submit toggle select]

      # Validate action is in whitelist
      unless allowed_actions.include?(action)
        Rails.logger.error "[SECURITY] Attempted to execute unauthorized action: #{action}"
        return render json: { error: "Unauthorized action" }, status: 403
      end

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
          mode: "interactive"
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
    variant_name = params[:story_variant] || "default"
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
      param_value = params[key]

      # Handle empty strings properly for optional props
      if param_value == ""
        # For color props and optional props, nil means "not set" which allows smart defaults
        optional_props = [ :background_color, :text_color, :padding_x, :padding_y, :font_size,
                         :custom_background, :custom_text_color ]
        if optional_props.include?(key.to_sym)
          props[key] = nil
        else
          props[key] = control[:default]
        end
      else
        props[key] = param_value || control[:default]
      end

      # Convert to appropriate type
      case control[:type]
      when :boolean
        props[key] = ActiveModel::Type::Boolean.new.cast(props[key])
      when :number
        # Convert string to integer or float
        props[key] = props[key].to_i if props[key].present?
      when :select
        # Check if options are integers to determine if we should convert
        if control[:options] && control[:options].all? { |opt| opt.is_a?(Integer) }
          props[key] = props[key].to_i if props[key].is_a?(String)
        else
          # Only convert to symbol for specific symbol-based props like variant, size, and columns
          # String-based select props like corner_radius, font_weight, image_aspect should stay as strings
          symbol_props = [ :variant, :size, :columns ]
          if symbol_props.include?(key.to_sym) && props[key].is_a?(String)
            props[key] = props[key].to_sym
          end
        end
      end
    end
    props
  end


  # Extract source code for a specific story method
  def extract_story_method_source(file_path, method_name)
    begin
      content = File.read(file_path)
      lines = content.split("\n")
    rescue Errno::ENOENT => e
      Rails.logger.error "Story file not found: #{file_path} - #{e.message}"
      return nil
    rescue => e
      Rails.logger.error "Error reading story file: #{file_path} - #{e.message}"
      return nil
    end

    # Find the method definition
    method_start = nil
    indent_level = nil

    lines.each_with_index do |line, index|
      if line.match(/^\s*def\s+#{Regexp.escape(method_name)}(\s|\(|$)/)
        method_start = index
        indent_level = line[/^\s*/].length
        break
      end
    end

    return nil unless method_start

    # Find the method end
    method_end = nil
    current_indent = indent_level

    (method_start + 1...lines.length).each do |index|
      line = lines[index]
      next if line.strip.empty?

      line_indent = line[/^\s*/].length

      if line.strip == "end" && line_indent == indent_level
        method_end = index
        break
      end
    end

    return nil unless method_end

    # Extract and return the method source
    method_lines = lines[method_start..method_end]
    method_lines.join("\n")
  end

  # Security helper methods
  def sanitize_story_name(name)
    return nil unless name.is_a?(String)
    # Only allow alphanumeric, underscores, and hyphens
    return nil unless name.match?(/\A[a-zA-Z0-9_-]+\z/)
    # Prevent directory traversal
    return nil if name.include?("..") || name.include?("/") || name.include?("\\")
    name
  end

  def sanitize_action_name(name)
    return nil unless name.is_a?(String)
    # Only allow lowercase letters and underscores
    return nil unless name.match?(/\A[a-z_]+\z/)
    name
  end

  def allowed_story_class?(class_name)
    # Whitelist of allowed story classes
    allowed_stories = Dir[Rails.root.join("test/components/stories/*_stories.rb")].map do |file|
      File.basename(file, ".rb").camelize
    end

    allowed_stories.include?(class_name)
  end

  def allowed_component_class?(class_name)
    # Whitelist of allowed component classes
    allowed_components = Dir[Rails.root.join("app/components/*_component.rb")].map do |file|
      File.basename(file, ".rb").camelize
    end

    # Also allow known framework components
    allowed_components += %w[
      ApplicationComponent
      ViewComponent::Base
    ]

    allowed_components.include?(class_name)
  end

  # Convert Tailwind color names to CSS color values for color swatches
  def tailwind_color_to_css(color_name)
    # Tailwind CSS color palette mapping
    color_map = {
      # Basic colors
      "white" => "#ffffff",
      "black" => "#000000",

      # Gray scale
      "gray-50" => "#f9fafb", "gray-100" => "#f3f4f6", "gray-200" => "#e5e7eb", "gray-300" => "#d1d5db",
      "gray-400" => "#9ca3af", "gray-500" => "#6b7280", "gray-600" => "#4b5563", "gray-700" => "#374151",
      "gray-800" => "#1f2937", "gray-900" => "#111827",

      # Red
      "red-50" => "#fef2f2", "red-100" => "#fee2e2", "red-200" => "#fecaca", "red-300" => "#fca5a5",
      "red-400" => "#f87171", "red-500" => "#ef4444", "red-600" => "#dc2626", "red-700" => "#b91c1c",
      "red-800" => "#991b1b", "red-900" => "#7f1d1d",

      # Orange
      "orange-50" => "#fff7ed", "orange-100" => "#ffedd5", "orange-200" => "#fed7aa", "orange-300" => "#fdba74",
      "orange-400" => "#fb923c", "orange-500" => "#f97316", "orange-600" => "#ea580c", "orange-700" => "#c2410c",
      "orange-800" => "#9a3412", "orange-900" => "#7c2d12",

      # Yellow
      "yellow-50" => "#fefce8", "yellow-100" => "#fef3c7", "yellow-200" => "#fde68a", "yellow-300" => "#fcd34d",
      "yellow-400" => "#fbbf24", "yellow-500" => "#f59e0b", "yellow-600" => "#d97706", "yellow-700" => "#b45309",
      "yellow-800" => "#92400e", "yellow-900" => "#78350f",

      # Green
      "green-50" => "#f0fdf4", "green-100" => "#dcfce7", "green-200" => "#bbf7d0", "green-300" => "#86efac",
      "green-400" => "#4ade80", "green-500" => "#22c55e", "green-600" => "#16a34a", "green-700" => "#15803d",
      "green-800" => "#166534", "green-900" => "#14532d",

      # Blue
      "blue-50" => "#eff6ff", "blue-100" => "#dbeafe", "blue-200" => "#bfdbfe", "blue-300" => "#93c5fd",
      "blue-400" => "#60a5fa", "blue-500" => "#3b82f6", "blue-600" => "#2563eb", "blue-700" => "#1d4ed8",
      "blue-800" => "#1e40af", "blue-900" => "#1e3a8a",

      # Indigo
      "indigo-50" => "#eef2ff", "indigo-100" => "#e0e7ff", "indigo-200" => "#c7d2fe", "indigo-300" => "#a5b4fc",
      "indigo-400" => "#818cf8", "indigo-500" => "#6366f1", "indigo-600" => "#4f46e5", "indigo-700" => "#4338ca",
      "indigo-800" => "#3730a3", "indigo-900" => "#312e81",

      # Purple
      "purple-50" => "#faf5ff", "purple-100" => "#f3e8ff", "purple-200" => "#e9d5ff", "purple-300" => "#d8b4fe",
      "purple-400" => "#c084fc", "purple-500" => "#a855f7", "purple-600" => "#9333ea", "purple-700" => "#7c3aed",
      "purple-800" => "#6b21a8", "purple-900" => "#581c87",

      # Pink
      "pink-50" => "#fdf2f8", "pink-100" => "#fce7f3", "pink-200" => "#fbcfe8", "pink-300" => "#f9a8d4",
      "pink-400" => "#f472b6", "pink-500" => "#ec4899", "pink-600" => "#db2777", "pink-700" => "#be185d",
      "pink-800" => "#9d174d", "pink-900" => "#831843"
    }

    color_map[color_name] || "#6b7280" # Default to gray-500 if color not found
  end
end
# Copyright 2025
