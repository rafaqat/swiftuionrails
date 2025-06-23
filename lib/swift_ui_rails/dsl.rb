# frozen_string_literal: true

require_relative "dsl/element"
require_relative "dsl/safe_element"

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

    def label(text_content, system_image: nil, **attrs, &block)
      create_element(:label, nil, **attrs) do
        concat(icon(system_image).to_s) if system_image
        concat(text(text_content).to_s)
        concat(capture(&block)) if block_given?
      end
    end

    # Control Components
    def button(title = nil, action: "#", **attrs, &block)
      attrs[:onclick] = action unless action == "#"
      element = if block_given?
        create_element(:button, nil, **attrs, &block)
      else
        create_element(:button, title, **attrs)
      end
      # Ensure we always return an Element instance
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

    # E-commerce Components
    def product_list(products:, **attrs)
      # Create a wrapper that can render the ProductListComponent
      attrs[:products] = products
      create_component_element(:product_list, attrs)
    end

    def enhanced_product_list(products:, **attrs, &block)
      # Create enhanced product list with slots support
      attrs[:products] = products
      create_component_element(:enhanced_product_list, attrs, &block)
    end

    # Container Components
    def card(elevation: 1, **attrs, &block)
      attrs[:class] = class_names("bg-white rounded-lg", attrs[:class])
      attrs[:class] += " shadow" if elevation == 1
      attrs[:class] += " shadow-md" if elevation == 2
      attrs[:class] += " shadow-lg" if elevation == 3
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
    def image(src, alt: "", **attrs)
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
      attrs[:class] = class_names("border-t border-gray-300", attrs[:class])
      create_element(:hr, nil, **attrs)
    end

    def div(**attrs, &block)
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
    
    # Loading Components
    def spinner(size: :md)
      size_classes = {
        xs: "h-3 w-3",
        sm: "h-4 w-4",
        md: "h-5 w-5",
        lg: "h-6 w-6",
        xl: "h-8 w-8"
      }
      
      create_element(:div, nil, class: "inline-flex items-center") do
        content_tag(:div, "", class: "animate-spin rounded-full border-2 border-gray-300 border-t-blue-600 #{size_classes[size]}")
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
      # Pass self as the DSL context if we're a DSLContext instance
      dsl_context = self.is_a?(SwiftUIRails::DSLContext) ? self : nil
      element = Element.new(tag_name, content, options, dsl_context, &block)
      element.send(:view_context=, self)
      
      # Register the element for later rendering instead of immediate buffer append
      if dsl_context
        dsl_context.register_element(element)
      end
      
      element
    end
  end
end