# frozen_string_literal: true

module StorybookDebugHelper
  # Capture the DSL structure from a story
  def capture_story_structure(story_instance, story_variant, component_props)
    return nil unless story_instance.respond_to?(story_variant)

    Rails.logger.info "[StorybookDebugHelper] Starting capture for #{story_variant}"

    # Create a new story instance for capture
    capture_instance = story_instance.class.new
    Rails.logger.info "[StorybookDebugHelper] Created capture instance: #{capture_instance.class.name}"

    # Set up capturing mode - store on instance variable
    capture_instance.instance_variable_set(:@_captured_root, nil)

    # Override swift_ui on the capture instance
    capture_instance.define_singleton_method(:swift_ui) do |&block|
      Rails.logger.info "[StorybookDebugHelper] swift_ui called in capture mode"

      # Create a capturing context
      capturing_context = StorybookDebugHelper::CapturingDSLContext.new(self)

      # Execute block in capturing context
      if block
        Rails.logger.debug "[StorybookDebugHelper] Executing DSL block in capturing context..."
        capturing_context.instance_eval(&block)
      end

      # Get all captured elements
      Rails.logger.info "[StorybookDebugHelper] Captured #{capturing_context.captured_elements.length} elements"
      capturing_context.captured_elements.each_with_index do |elem, i|
        classes = elem.instance_variable_get(:@css_classes) || []
        Rails.logger.info "[StorybookDebugHelper]   [#{i}] #{elem.tag_name} classes: #{classes.join(' ')}"
      end

      # Store the tree structure
      instance_variable_set(:@_captured_tree, capturing_context.element_tree)

      # Return empty string to prevent rendering
      ""
    end

    begin
      # Execute the story method on the capture instance
      Rails.logger.debug "[StorybookDebugHelper] Executing story method: #{story_variant}"
      capture_instance.send(story_variant, **component_props)

      # Get the captured tree
      captured_tree = capture_instance.instance_variable_get(:@_captured_tree) || []
      Rails.logger.info "[StorybookDebugHelper] Captured tree with #{captured_tree.length} root elements"

      # Return the tree structure
      captured_tree
    rescue => e
      Rails.logger.error "[StorybookDebugHelper] Error capturing structure: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

  # Render debug tree for a DSL element
  def render_dsl_element_tree(element, depth = 0)
    return "" unless element.is_a?(SwiftUIRails::DSL::Element)

    tree_lines = []
    indent = "  " * depth
    connector = depth == 0 ? "" : "└── "

    # Determine the DSL method based on element properties
    options = element.instance_variable_get(:@options) || {}
    class_attr = options[:class] || ""
    css_classes = element.instance_variable_get(:@css_classes) || []
    content = element.instance_variable_get(:@content)

    # Try to infer the DSL method from classes
    dsl_method = case
    when class_attr.include?("flex flex-col")
      "vstack"
    when class_attr.include?("flex flex-row")
      "hstack"
    when element.tag_name == :button
      "button"
    when element.tag_name == :span && content.present?
      "text"
    when element.tag_name == :div && class_attr.include?("grid")
      "grid"
    else
      element.tag_name.to_s
    end

    # Element info
    element_info = dsl_method

    # Add text content if present
    if content.is_a?(String) && !content.empty?
      element_info += "(\"#{truncate(content, length: 30)}\")"
    end

    # Add spacing info for stacks
    if dsl_method == "vstack" && class_attr =~ /space-y-(\d+)/
      element_info += " spacing: #{$1}"
    elsif dsl_method == "hstack" && class_attr =~ /space-x-(\d+)/
      element_info += " spacing: #{$1}"
    end

    # Add additional CSS classes
    if css_classes.any?
      element_info += " .#{css_classes.first(3).join('.')}"
      element_info += "..." if css_classes.length > 3
    end

    tree_lines << "#{indent}#{connector}#{element_info}"

    # Check if element has captured children
    captured_children = element.instance_variable_get(:@captured_children)
    Rails.logger.info "[DEBUG TREE] Element #{element.tag_name} has #{captured_children&.length || 0} captured children"
    if captured_children && captured_children.any?
      Rails.logger.info "[DEBUG TREE] Rendering #{captured_children.length} children"
      captured_children.each_with_index do |child, index|
        Rails.logger.info "[DEBUG TREE] Rendering child #{index}: #{child.tag_name}"
        is_last = index == captured_children.length - 1
        child_indent = indent + (depth == 0 ? "" : "    ")
        child_connector = is_last ? "└── " : "├── "

        # Recursively render child
        child_tree = render_dsl_element_tree(child, depth + 1)
        Rails.logger.info "[DEBUG TREE] Child tree for #{child.tag_name}: #{child_tree}"
        if child_tree.present?
          lines = child_tree.split("\n")
          lines.each_with_index do |line, i|
            if i == 0
              tree_lines << "#{child_indent}#{child_connector}#{line.strip}"
            else
              line_indent = child_indent + (is_last ? "    " : "│   ")
              tree_lines << "#{line_indent}#{line.strip}"
            end
          end
        end
      end
    elsif element.instance_variable_get(:@block)
      # Has a block but no captured children
      tree_lines << "#{indent}  (has uncaptured block content)"
    end

    tree_lines.join("\n")
  end

  # Capturing DSL Context
  class CapturingDSLContext < SwiftUIRails::DSLContext
    include SwiftUIRails::DSL

    attr_accessor :captured_elements, :element_tree

    def initialize(view_context)
      super(view_context, 0)
      @captured_elements = []
      @element_tree = []
      @element_stack = []
      @seen_elements = Set.new  # Track element object IDs to prevent duplicates
    end

    def register_element(element)
      # Skip if we've already seen this element
      element_id = element.object_id
      if @seen_elements.include?(element_id)
        Rails.logger.info "[CapturingDSLContext] Skipping duplicate element: #{element.tag_name} (id: #{element_id})"
        return
      end
      @seen_elements.add(element_id)

      # Get some context about what's being registered
      content = element.instance_variable_get(:@content)
      content_preview = content.is_a?(String) ? content[0..30] : "no content"
      Rails.logger.info "[CapturingDSLContext] Registering element: #{element.tag_name} - content: #{content_preview} (id: #{element_id})"

      @captured_elements << element

      # Build tree structure
      if @element_stack.empty?
        # Top-level element
        @element_tree << element
      else
        # Child element - add to parent's children
        parent = @element_stack.last
        parent.instance_variable_set(:@captured_children, []) unless parent.instance_variable_defined?(:@captured_children)
        parent.instance_variable_get(:@captured_children) << element
      end

      # If element has a block, we need to capture its children
      if element.instance_variable_get(:@block)
        Rails.logger.info "[CapturingDSLContext] Element #{element.tag_name} has a block, capturing children..."
        @element_stack.push(element)
        begin
          # Execute the block to capture children
          block = element.instance_variable_get(:@block)
          # Execute block in this context (not instance_eval)
          # This ensures DSL methods are called on this capturing context
          result = instance_exec(&block) if block

          # If the block returns an element, it might be a duplicate
          # (already registered by the DSL method that created it)
          if result.is_a?(SwiftUIRails::DSL::Element)
            Rails.logger.info "[CapturingDSLContext] Block returned element #{result.tag_name}, checking if already registered"
          end
        ensure
          @element_stack.pop
        end
        children_count = element.instance_variable_get(:@captured_children)&.length || 0
        Rails.logger.info "[CapturingDSLContext] Captured #{children_count} children for #{element.tag_name}"
      end

      # Don't call super - we don't want to flush elements
    end

    # Override flush_elements to prevent rendering
    def flush_elements
      # Do nothing - we just want to capture structure
      ""
    end
  end
end
