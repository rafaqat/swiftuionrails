# frozen_string_literal: true

require_relative 'context_locator'
require_relative 'dsl_registry'

module Playground
  class CompletionService
    include SwiftUIRails::DSL
    include SwiftUIRails::Tailwind::Modifiers
    
    # Cache for performance
    CACHE_TTL = 5.minutes
    
    def initialize(context, position)
      @context = context
      @position = position
      @line = position["lineNumber"] || 1
      @column = position["column"] || 1
    end
    
    def generate_completions
      # Use cached results if available
      cache_key = "completions:#{Digest::MD5.hexdigest(@context)}:#{@line}:#{@column}"
      
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        # Extract text up to cursor for parsing
        text_before_cursor = extract_text_before_cursor
        
        # Use AST parser for accurate context
        locator = ContextLocator.new(text_before_cursor)
        context = locator.completion_context
        
        Rails.logger.debug "Completion context: #{context.inspect}"
        Rails.logger.debug "Text before cursor: #{text_before_cursor.inspect}"
        
        case context[:type]
        when :method_completion
          generate_method_completions(context[:receiver], context[:partial])
        when :parameter_completion
          generate_parameter_completions(context[:method], context[:receiver])
        when :top_level
          generate_top_level_completions(context[:partial])
        else
          []
        end
      end
    end
    
    private
    
    def extract_text_before_cursor
      lines = @context.split("\n")
      before_lines = lines[0...(@line - 1)]
      current_line = lines[@line - 1] || ""
      current_line_before = current_line[0...@column]
      
      (before_lines + [current_line_before]).join("\n")
    end
    
    def generate_top_level_completions(partial = "")
      registry = DslRegistry.instance
      
      Rails.logger.debug "Registry has #{registry.all.size} elements"
      Rails.logger.debug "Looking for completions starting with: #{partial.inspect}"
      
      results = registry.all.map do |name, metadata|
        name_str = name.to_s
        Rails.logger.debug "Checking #{name_str} against #{partial}"
        next unless name_str.start_with?(partial)
        
        {
          label: name_str,
          kind: "Function",
          detail: format_parameters(metadata[:parameters]),
          documentation: build_documentation(metadata),
          insertText: build_insert_text(name_str, metadata[:parameters]),
          insertTextFormat: 2 # Snippet format
        }
      end.compact
      
      Rails.logger.debug "Found #{results.size} completions"
      results
    end
    
    def generate_method_completions(receiver_chain, partial = "")
      return [] unless receiver_chain && receiver_chain.any?
      
      Rails.logger.debug "Method completion - receiver: #{receiver_chain.inspect}, partial: #{partial.inspect}"
      
      # Get the last element type
      last_element = receiver_chain.last
      element_meta = DslRegistry.instance[last_element]
      
      # Get available modifiers for this element
      modifiers = element_meta ? (element_meta[:modifiers] || []) : []
      base_modifiers = get_base_modifiers
      
      # Always include base modifiers for any DSL element
      all_modifiers = (modifiers + base_modifiers.keys).uniq
      
      Rails.logger.debug "Available modifiers: #{all_modifiers.inspect}"
      
      results = all_modifiers.map do |modifier|
        # Filter by partial if provided
        next unless partial.empty? || modifier.start_with?(partial)
        
        modifier_meta = base_modifiers[modifier] || {}
        
        {
          label: modifier,
          kind: "Method",
          detail: modifier_meta[:parameters] ? "(#{modifier_meta[:parameters]})" : "",
          documentation: modifier_meta[:description] || "Modifier: #{modifier}",
          insertText: build_modifier_insert_text(modifier, modifier_meta),
          insertTextFormat: 2
        }
      end.compact
      
      Rails.logger.debug "Method completions found: #{results.size}"
      results
    end
    
    def generate_parameter_completions(method_name, receiver_chain)
      # Check modifier registry first
      modifier_meta = get_modifier_metadata(method_name)
      return [] unless modifier_meta
      
      case modifier_meta[:values]
      when :tailwind_colors
        generate_tailwind_color_completions
      when :spacing_values
        generate_spacing_completions
      when :size_values
        generate_size_completions
      when :font_sizes
        generate_font_size_completions
      when Array
        modifier_meta[:values].map do |value|
          {
            label: value,
            kind: "Value",
            detail: "Option",
            documentation: "#{method_name}: #{value}",
            insertText: value,
            insertTextFormat: 1
          }
        end
      else
        []
      end
    end
    
    def get_base_modifiers
      {
        # Spacing
        "padding" => { parameters: "value", description: "Add padding" },
        "p" => { parameters: "value", description: "Padding shorthand" },
        "px" => { parameters: "value", description: "Horizontal padding" },
        "py" => { parameters: "value", description: "Vertical padding" },
        "margin" => { parameters: "value", description: "Add margin" },
        "m" => { parameters: "value", description: "Margin shorthand" },
        
        # Colors
        "bg" => { parameters: "color", description: "Background color" },
        "background" => { parameters: "color", description: "Background color" },
        "text_color" => { parameters: "color", description: "Text color" },
        "border_color" => { parameters: "color", description: "Border color" },
        
        # Typography
        "font_size" => { parameters: "size", description: "Font size" },
        "font_weight" => { parameters: "weight", description: "Font weight" },
        "text_align" => { parameters: "alignment", description: "Text alignment" },
        
        # Layout
        "w" => { parameters: "value", description: "Width" },
        "h" => { parameters: "value", description: "Height" },
        "flex" => { description: "Make element flex container" },
        "hidden" => { description: "Hide element" },
        
        # Effects
        "rounded" => { parameters: "size", description: "Border radius" },
        "shadow" => { parameters: "size", description: "Box shadow" },
        "opacity" => { parameters: "value", description: "Opacity (0-100)" },
        
        # Interactivity
        "hover" => { parameters: "classes", description: "Hover state styling" },
        "data" => { parameters: "attributes", description: "Data attributes" }
      }
    end
    
    def get_modifier_metadata(method_name)
      # This would be loaded from the registry
      modifiers = {
        "bg" => { values: :tailwind_colors },
        "background" => { values: :tailwind_colors },
        "text_color" => { values: :tailwind_colors },
        "border_color" => { values: :tailwind_colors },
        "font_size" => { values: :font_sizes },
        "text_size" => { values: :font_sizes },
        "font_weight" => { values: %w[thin light normal medium semibold bold] },
        "padding" => { values: :spacing_values },
        "p" => { values: :spacing_values },
        "px" => { values: :spacing_values },
        "py" => { values: :spacing_values },
        "pt" => { values: :spacing_values },
        "pb" => { values: :spacing_values },
        "pl" => { values: :spacing_values },
        "pr" => { values: :spacing_values },
        "margin" => { values: :spacing_values },
        "m" => { values: :spacing_values },
        "mx" => { values: :spacing_values },
        "my" => { values: :spacing_values },
        "mt" => { values: :spacing_values },
        "mb" => { values: :spacing_values },
        "ml" => { values: :spacing_values },
        "mr" => { values: :spacing_values },
        "spacing" => { values: :spacing_values },
        "gap" => { values: :spacing_values },
        "space_x" => { values: :spacing_values },
        "space_y" => { values: :spacing_values },
        "rounded" => { values: %w[none sm md lg xl 2xl 3xl full] },
        "corner_radius" => { values: %w[none sm md lg xl 2xl 3xl full] },
        "shadow" => { values: %w[none sm md lg xl 2xl inner] },
        "elevation" => { values: %w[0 1 2 3 4 5] },
        "w" => { values: :size_values },
        "h" => { values: :size_values },
        "width" => { values: :size_values },
        "height" => { values: :size_values }
      }
      
      modifiers[method_name]
    end
    
    def generate_tailwind_color_completions
      # Load from pre-generated file
      load_tailwind_colors.map do |color|
        {
          label: color[:label],
          kind: "Color", 
          detail: color[:category] == "base-color" ? "Base color" : "Tailwind color",
          insertText: color[:value],
          insertTextFormat: 1
        }
      end.first(50) # Limit for performance
    end
    
    def generate_spacing_completions
      load_spacing_values.map do |spacing|
        {
          label: spacing[:label],
          kind: "Value",
          detail: spacing[:description] || "Spacing value",
          insertText: spacing[:value],
          insertTextFormat: 1
        }
      end
    end
    
    def generate_size_completions
      values = %w[0 1 2 4 8 16 24 32 48 64 96 full screen auto min max fit]
      
      values.map do |value|
        detail = case value
        when /^\d+$/
          "#{value} × 0.25rem"
        else
          value.capitalize
        end
        
        {
          label: value,
          kind: "Value",
          detail: detail,
          insertText: value,
          insertTextFormat: 1
        }
      end
    end
    
    def generate_font_size_completions
      load_font_sizes.map do |size|
        {
          label: size[:label],
          kind: "Value",
          detail: size[:description] || "Font size",
          insertText: size[:value],
          insertTextFormat: 1
        }
      end
    end
    
    def load_tailwind_colors
      @tailwind_colors ||= Rails.cache.fetch("playground:tailwind_colors", expires_in: 1.hour) do
        path = Rails.root.join("public/playground/data/tailwind_colors.json")
        if File.exist?(path)
          JSON.parse(File.read(path), symbolize_names: true)
        else
          # Fallback to basic colors
          %w[red-500 blue-500 green-500 yellow-500 gray-100 white black transparent].map do |color|
            { value: color, label: color, category: "color" }
          end
        end
      end
    end
    
    def load_spacing_values
      @spacing_values ||= Rails.cache.fetch("playground:spacing_values", expires_in: 1.hour) do
        path = Rails.root.join("public/playground/data/spacing_values.json")
        if File.exist?(path)
          JSON.parse(File.read(path), symbolize_names: true)
        else
          # Fallback
          %w[0 1 2 3 4 5 6 8 10 12 16 20 24 32].map do |spacing|
            { value: spacing, label: spacing, description: "#{spacing} × 0.25rem" }
          end
        end
      end
    end
    
    def load_font_sizes
      @font_sizes ||= Rails.cache.fetch("playground:font_sizes", expires_in: 1.hour) do
        path = Rails.root.join("public/playground/data/font_sizes.json")
        if File.exist?(path)
          JSON.parse(File.read(path), symbolize_names: true)
        else
          # Fallback
          %w[xs sm base lg xl 2xl 3xl 4xl 5xl 6xl].map do |size|
            { value: size, label: size }
          end
        end
      end
    end
    
    def format_parameters(params)
      return "()" if params.nil? || params.empty?
      
      param_strings = params.map do |name, type|
        "#{name}: #{type}"
      end
      
      "(#{param_strings.join(', ')})"
    end
    
    def build_documentation(metadata)
      parts = [metadata[:description]]
      
      if metadata[:examples]&.any?
        parts << "\n\nExamples:"
        parts.concat(metadata[:examples].map { |ex| "  #{ex}" })
      end
      
      parts.join("\n")
    end
    
    def build_insert_text(name, parameters)
      return name if parameters.nil? || parameters.empty?
      
      # Build snippet with tab stops
      params = parameters.map.with_index do |(param_name, param_type), index|
        default = case param_type
        when "String" then '""'
        when /^:/ then param_type
        else param_type
        end
        
        "#{param_name}: ${#{index + 1}:#{default}}"
      end
      
      "#{name}(#{params.join(', ')})"
    end
    
    def build_modifier_insert_text(modifier, metadata)
      if metadata[:parameters]
        "#{modifier}(${1})"
      else
        modifier
      end
    end
  end
end