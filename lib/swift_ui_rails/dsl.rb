# frozen_string_literal: true

require_relative "dsl/element"
require_relative "dsl/safe_element"
require_relative "dsl/context"

module SwiftUIRails
  module DSL
    extend ActiveSupport::Concern

    # Layout Components
    def vstack(alignment: :center, spacing: 8, **attrs, &block)
      attrs[:class] = class_names("flex flex-col", attrs[:class])
      attrs[:class] += " items-#{alignment_class(alignment)}"
      attrs[:class] += " space-y-#{spacing}" if spacing > 0
      create_element(:div, nil, **attrs, &block)
    end

    def hstack(alignment: :center, spacing: 8, **attrs, &block)
      attrs[:class] = class_names("flex flex-row", attrs[:class])
      attrs[:class] += " items-#{alignment_class(alignment)}"
      attrs[:class] += " space-x-#{spacing}" if spacing > 0
      create_element(:div, nil, **attrs, &block)
    end

    def zstack(**attrs, &block)
      attrs[:class] = class_names("relative", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def grid(columns: 2, spacing: 8, **attrs, &block)
      attrs[:class] = class_names("grid", attrs[:class])
      attrs[:class] += " grid-cols-#{columns} gap-#{spacing}"
      create_element(:div, nil, **attrs, &block)
    end

    # Text Components
    def text(content, **attrs)
      create_element(:span, content, **attrs)
    end

    def label(text_content = nil, for_input: nil, **attrs, &block)
      attrs[:for] = for_input if for_input
      if block_given?
        create_element(:label, nil, **attrs, &block)
      elsif text_content
        create_element(:label, text_content, **attrs)
      else
        create_element(:label, nil, **attrs)
      end
    end

    # Control Components
    def button(title = nil, **attrs, &block)
      # Pure structure - no behavior. Behavior is handled by Stimulus
      element = if block_given?
        create_element(:button, nil, **attrs, &block)
      else
        create_element(:button, title, **attrs)
      end
      # Ensure we always return an Element instance for powerful chaining
      element
    end

    def link(title = nil, destination: "#", **attrs, &block)
      attrs[:href] = destination
      if block_given?
        create_element(:a, nil, **attrs, &block)
      else
        create_element(:a, title, **attrs)
      end
    end

    def textfield(placeholder: "", value: "", **attrs)
      attrs[:type] ||= "text"
      attrs[:placeholder] = placeholder
      attrs[:value] = value
      create_element(:input, nil, **attrs)
    end

    def toggle(label_text, is_on: false, **attrs)
      create_element(:label, nil, **attrs) do
        concat(tag(:input, type: "checkbox", checked: is_on))
        concat(content_tag(:span, label_text))
      end
    end

    def slider(value: 50, min: 0, max: 100, step: 1, **attrs)
      attrs[:type] = "range"
      attrs[:value] = value
      attrs[:min] = min
      attrs[:max] = max
      attrs[:step] = step
      create_element(:input, nil, **attrs)
    end

    def select(name: nil, selected: nil, **attrs, &block)
      attrs[:name] = name if name
      attrs[:value] = selected if selected
      create_element(:select, nil, **attrs, &block)
    end

    def option(value, text_content = nil, selected: false, **attrs)
      attrs[:value] = value
      attrs[:selected] = selected if selected
      content = text_content || value
      create_element(:option, content, **attrs)
    end

    # E-commerce Components with ViewComponent 2.0 Collection Optimization
    # Generic list method - composition-based approach
    def list(items:, **attrs, &block)
      # Pure structure for listing items - behavior comes from the block
      attrs[:class] = class_names("space-y-4", attrs[:class])
      
      create_element(:div, nil, **attrs) do
        items.each_with_index do |item, index|
          # Pass both item and index to the block for maximum flexibility
          if block_given?
            instance_exec(item, index, &block)
          else
            # Default rendering if no block provided
            text(item.to_s)
          end
        end
      end
    end
    
    # Grid variant of list for grid layouts
    def grid_list(items:, columns: 3, **attrs, &block)
      attrs[:class] = class_names("grid gap-4", attrs[:class])
      attrs[:class] += " grid-cols-#{columns}"
      
      create_element(:div, nil, **attrs) do
        items.each_with_index do |item, index|
          if block_given?
            instance_exec(item, index, &block)
          else
            text(item.to_s)
          end
        end
      end
    end
    
    # ViewComponent 2.0 Collection-optimized rendering methods
    def card_collection(items:, **attrs, &block)
      # Use ViewComponent 2.0 collection rendering for 10x performance
      CardComponent.card_collection(cards: items, **attrs, &block)
    end
    
    def button_collection(items:, **attrs, &block)
      # Use ViewComponent 2.0 collection rendering for 10x performance  
      SimpleButtonComponent.button_collection(buttons: items, **attrs, &block)
    end
    
    # Layout collection optimizations
    def vstack_collection(items:, spacing: 8, **attrs, &block)
      # Render collection in vertical stack with ViewComponent 2.0 performance
      vstack(spacing: spacing, **attrs) do
        if block_given?
          items.each_with_index do |item, index|
            block.call(item, index)
          end
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end
    
    def hstack_collection(items:, spacing: 8, **attrs, &block)
      # Render collection in horizontal stack with ViewComponent 2.0 performance
      hstack(spacing: spacing, **attrs) do
        if block_given?
          items.each_with_index do |item, index|
            block.call(item, index)
          end
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end
    
    def grid_collection(items:, columns: 3, spacing: 8, **attrs, &block)
      # Render collection in grid with ViewComponent 2.0 performance
      grid(columns: columns, spacing: spacing, **attrs) do
        if block_given?
          items.each_with_index do |item, index|
            block.call(item, index)
          end
        else
          items.each { |item| text(item.to_s) }
        end
      end
    end

    # Container Components - Simplified for composition
    def card(**attrs, &block)
      # Simple card container - just structure and styling
      attrs[:class] = class_names("rounded-lg shadow-md", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_header(**attrs, &block)
      # A helper for a styled header region
      attrs[:class] = class_names("p-4 border-b", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_content(**attrs, &block)
      # A helper for the main content area
      attrs[:class] = class_names("p-4", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_footer(**attrs, &block)
      # A helper for a styled footer region
      attrs[:class] = class_names("p-4 border-t", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end
    
    def card_section(**attrs, &block)
      # A helper for additional card sections
      attrs[:class] = class_names("p-4", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    def list(**attrs, &block)
      create_element(:ul, nil, **attrs, &block)
    end

    def list_item(**attrs, &block)
      create_element(:li, nil, **attrs, &block)
    end

    def scroll_view(**attrs, &block)
      attrs[:class] = class_names("overflow-auto", attrs[:class])
      create_element(:div, nil, **attrs, &block)
    end

    # Media Components
    def image(src: nil, alt: "", **attrs)
      raise ArgumentError, "image requires src attribute" unless src
      attrs[:src] = src
      attrs[:alt] = alt
      create_element(:img, nil, **attrs)
    end

    def icon(name, size: 16, **attrs)
      # For now, just return a placeholder span
      # In a real implementation, this would render an SVG icon
      attrs[:class] = class_names("inline-block", attrs[:class])
      attrs[:style] = "width: #{size}px; height: #{size}px;"
      create_element(:span, "", **attrs)
    end

    # Layout Helpers
    def spacer(min_length: nil)
      attrs = { class: "flex-1" }
      attrs[:style] = "min-height: #{min_length}px" if min_length
      create_element(:div, "", **attrs)
    end

    def divider(**attrs)
      attrs[:class] = class_names("border-t", attrs[:class])
      create_element(:hr, nil, **attrs)
    end

    def div(**attrs, &block)
      Rails.logger.debug "DSL.div called with block: #{block_given?}"
      create_element(:div, nil, **attrs, &block)
    end
    
    def span(**attrs, &block)
      create_element(:span, nil, **attrs, &block)
    end
    
    def section(**attrs, &block)
      create_element(:section, nil, **attrs, &block)
    end
    
    def article(**attrs, &block)
      create_element(:article, nil, **attrs, &block)
    end
    
    def header(**attrs, &block)
      create_element(:header, nil, **attrs, &block)
    end
    
    def footer(**attrs, &block)
      create_element(:footer, nil, **attrs, &block)
    end
    
    def nav(**attrs, &block)
      create_element(:nav, nil, **attrs, &block)
    end
    
    def a(**attrs, &block)
      create_element(:a, nil, **attrs, &block)
    end
    
    def h3(**attrs, &block)
      create_element(:h3, nil, **attrs, &block)
    end
    
    def p(**attrs, &block)
      create_element(:p, nil, **attrs, &block)
    end
    
    # Loading Components
    def spinner(size: :md, border_color: nil, spinner_color: nil)
      size_classes = {
        xs: "h-3 w-3",
        sm: "h-4 w-4",
        md: "h-5 w-5",
        lg: "h-6 w-6",
        xl: "h-8 w-8"
      }
      
      border_class = border_color ? "border-#{border_color}" : ""
      spinner_class = spinner_color ? "border-t-#{spinner_color}" : ""
      
      create_element(:div, nil, class: "inline-flex items-center") do
        content_tag(:div, "", class: "animate-spin rounded-full border-2 #{border_class} #{spinner_class} #{size_classes[size]}")
      end
    end

    private

    def alignment_class(alignment)
      case alignment
      when :top, :start then "start"
      when :center then "center"
      when :bottom, :end then "end"
      else "center"
      end
    end

    # Override concat to handle Element instances
    def concat(content)
      if defined?(Element) && content.is_a?(Element)
        super(content.to_s.html_safe)
      else
        super(content)
      end
    end
    
    private
    
    # Create a chainable element
    def create_element(tag_name, content = nil, options = {}, &block)
      # Create a DSL context for capturing nested elements
      if block_given? && !self.is_a?(SwiftUIRails::DSLContext)
        # Create a temporary DSL context to capture child elements
        dsl_context = DSLContext.new(self)
        element = Element.new(tag_name, content, options, dsl_context, &block)
      else
        dsl_context = self.is_a?(SwiftUIRails::DSLContext) ? self : nil
        element = Element.new(tag_name, content, options, dsl_context, &block)
      end
      
      element.view_context = self
      
      # If self is a component, store it directly on the element
      if self.respond_to?(:component_id)
        Rails.logger.debug "Storing component on element: #{self.class.name}, component_id=#{self.component_id}"
        element.instance_variable_set(:@component, self)
      elsif self.is_a?(DSLContext) && self.instance_variable_get(:@component)
        comp = self.instance_variable_get(:@component)
        Rails.logger.debug "Storing component from context: #{comp.class.name}, component_id=#{comp.component_id if comp}"
        element.instance_variable_set(:@component, comp)
      else
        Rails.logger.debug "No component to store. self=#{self.class.name}"
      end
      
      # Register the element for later rendering instead of immediate buffer append
      if dsl_context && self.is_a?(SwiftUIRails::DSLContext)
        dsl_context.register_element(element)
      end
      
      Rails.logger.debug "Created element: #{tag_name}, has_block: #{block_given?}, dsl_context: #{dsl_context.class.name if dsl_context}"
      
      element
    end
  end
end