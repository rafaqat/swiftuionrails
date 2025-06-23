# frozen_string_literal: true

class SimpleButtonComponent < SwiftUIRails::Component::Base
  prop :title, type: String, required: true
  prop :variant, type: Symbol, default: :primary
  prop :size, type: Symbol, default: :md
  prop :disabled, type: [TrueClass, FalseClass], default: false
  
  # SwiftUI-style customizable properties
  prop :background_color, type: String, default: nil
  prop :text_color, type: String, default: nil
  prop :corner_radius, type: String, default: "md"
  prop :padding_x, type: String, default: nil
  prop :padding_y, type: String, default: nil
  prop :font_weight, type: String, default: "medium"
  prop :font_size, type: String, default: nil
  
  VARIANT_CLASSES = {
    primary: { bg: "blue-600", hover_bg: "blue-700", text: "white" },
    secondary: { bg: "gray-200", hover_bg: "gray-300", text: "gray-900" },
    danger: { bg: "red-600", hover_bg: "red-700", text: "white" },
    success: { bg: "green-600", hover_bg: "green-700", text: "white" },
    warning: { bg: "yellow-500", hover_bg: "yellow-600", text: "white" }
  }.freeze
  
  SIZE_PRESETS = {
    sm: { px: "3", py: "2", text: "sm" },
    md: { px: "4", py: "2", text: "sm" },
    lg: { px: "6", py: "3", text: "base" },
    xl: { px: "8", py: "4", text: "lg" }
  }.freeze
  
  CORNER_RADIUS_OPTIONS = {
    none: "rounded-none",
    sm: "rounded-sm", 
    md: "rounded-md",
    lg: "rounded-lg",
    xl: "rounded-xl",
    full: "rounded-full"
  }.freeze
  
  swift_ui do
    button(
      title,
      class: button_classes,
      disabled: disabled,
      style: inline_styles
    )
  end
  
  private
  
  def button_classes
    classes = []
    
    # Base classes
    classes << "inline-flex items-center transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2"
    
    # Background and text colors (from variant or custom)
    if background_color.present? || text_color.present?
      # Custom colors override variant
      if background_color.blank?
        # Use variant background if no custom background
        variant_config = VARIANT_CLASSES[variant] || VARIANT_CLASSES[:primary]
        classes << "bg-#{variant_config[:bg]} hover:bg-#{variant_config[:hover_bg]}"
      else
        classes << "hover:opacity-90"
      end
      
      if text_color.present?
        classes << "text-#{text_color}"
      else
        # Use variant text color if no custom text color
        variant_config = VARIANT_CLASSES[variant] || VARIANT_CLASSES[:primary]
        classes << "text-#{variant_config[:text]}"
      end
    else
      # Use variant preset
      variant_config = VARIANT_CLASSES[variant] || VARIANT_CLASSES[:primary]
      classes << "bg-#{variant_config[:bg]} hover:bg-#{variant_config[:hover_bg]} text-#{variant_config[:text]}"
      classes << "focus:ring-#{variant_config[:bg].split('-').first}-500"
    end
    
    # Corner radius
    radius_key = corner_radius.is_a?(String) ? corner_radius.to_sym : corner_radius
    classes << (CORNER_RADIUS_OPTIONS[radius_key] || CORNER_RADIUS_OPTIONS[:md])
    
    # Size and padding
    if padding_x.present? || padding_y.present?
      # Custom padding
      classes << "px-#{padding_x || '4'} py-#{padding_y || '2'}"
    else
      # Use size preset
      size_config = SIZE_PRESETS[size] || SIZE_PRESETS[:md]
      classes << "px-#{size_config[:px]} py-#{size_config[:py]}"
    end
    
    # Font styling
    classes << "font-#{font_weight}"
    if font_size.present?
      classes << "text-#{font_size}"
    else
      size_config = SIZE_PRESETS[size] || SIZE_PRESETS[:md]
      classes << "text-#{size_config[:text]}"
    end
    
    # Disabled state
    classes << "opacity-50 cursor-not-allowed" if disabled
    
    classes.join(" ")
  end
  
  def inline_styles
    styles = []
    
    if background_color.present?
      # Support hex colors, CSS color names, or Tailwind color references
      if background_color.start_with?('#')
        styles << "background-color: #{background_color}"
      elsif background_color.include?('-')
        # Tailwind color like "blue-500" - handled in CSS classes
      else
        styles << "background-color: #{background_color}"
      end
    end
    
    if text_color.present?
      if text_color.start_with?('#')
        styles << "color: #{text_color}"
      elsif text_color.include?('-')
        # Tailwind color - handled in CSS classes
      else
        styles << "color: #{text_color}"
      end
    end
    
    styles.empty? ? nil : styles.join("; ")
  end
end