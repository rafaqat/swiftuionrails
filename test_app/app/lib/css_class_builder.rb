# frozen_string_literal: true
# Copyright 2025

# Utility class to build CSS classes while avoiding conflicts
# Specifically handles text-prefix conflicts (text-color vs text-size)
class CssClassBuilder
  attr_reader :classes

  def initialize
    @classes = []
    @text_color = nil
    @text_size = nil
  end

  # Add a regular CSS class
  def add(css_class)
    return self if css_class.blank?
    
    css_class_str = css_class.to_s.strip
    return self if css_class_str.empty?
    
    # Check if this is a text-color or text-size class
    if css_class_str.match(/^text-(\w+)-(\d+)$/) # text-red-500, text-blue-600, etc.
      @text_color = css_class_str
    elsif css_class_str.match(/^text-(xs|sm|base|lg|xl|\d*xl)$/) # text-sm, text-lg, etc.
      @text_size = css_class_str
    else
      @classes << css_class_str
    end
    
    self
  end

  # Add multiple classes at once
  def add_multiple(*css_classes)
    css_classes.flatten.each { |css_class| add(css_class) }
    self
  end

  # Set text color specifically (overrides any previous text color)
  def text_color(color)
    return self if color.blank?
    @text_color = "text-#{color}"
    self
  end

  # Set text size specifically (overrides any previous text size)
  def text_size(size)
    return self if size.blank?
    @text_size = "text-#{size}"
    self
  end

  # Build the final CSS class string with proper ordering
  def build
    final_classes = @classes.dup
    
    # Add text size first, then text color to ensure color takes precedence
    final_classes << @text_size if @text_size.present?
    final_classes << @text_color if @text_color.present?
    
    final_classes.compact.uniq.join(" ")
  end

  # Convenience method to build CSS classes for components
  def self.build
    builder = new
    yield(builder) if block_given?
    builder.build
  end

  # Helper method to safely combine text color and size
  def self.safe_text_classes(color: nil, size: nil)
    classes = []
    classes << "text-#{size}" if size.present?
    classes << "text-#{color}" if color.present?
    classes.join(" ")
  end
end
# Copyright 2025
