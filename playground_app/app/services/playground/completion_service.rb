# frozen_string_literal: true

require_relative "context_locator"
require_relative "dsl_registry"

module Playground
  class CompletionService
    include SwiftUIRails::DSL
    include SwiftUIRails::Tailwind::Modifiers

    # Cache for performance
    CACHE_TTL = 5.minutes

    def initialize(context, position, cached_data = {})
      @context = context
      @position = position
      @line = position["lineNumber"] || 1
      @column = position["column"] || 1
      @cached_data = cached_data
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

      (before_lines + [ current_line_before ]).join("\n")
    end

    def generate_top_level_completions(partial = "")
      registry = DslRegistry.instance

      Rails.logger.debug "Registry has #{registry.all.size} elements"
      Rails.logger.debug "Looking for completions starting with: #{partial.inspect}"

      results = registry.all.map do |name, metadata|
        name_str = name.to_s
        Rails.logger.info "Checking #{name_str} against #{partial}"
        next unless name_str.start_with?(partial)

        # Debug the snippet generation
        insert_text = build_insert_text(name_str, metadata[:parameters])
        Rails.logger.info "Generated insert text for #{name_str}: #{insert_text}"
        
        # Extra debug for text specifically
        if name_str == "text"
          Rails.logger.debug "Text parameters: #{metadata[:parameters]}"
          Rails.logger.debug "Text metadata: #{metadata}"
        end
        
        {
          label: name_str,
          kind: "Function",
          detail: format_parameters(metadata[:parameters]),
          documentation: build_documentation(metadata),
          insertText: insert_text,
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

        modifier_meta = base_modifiers[modifier] || { parameters: true }

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
      # Use client-provided cached data if available
      if @cached_data["tailwind_colors"].present?
        return @cached_data["tailwind_colors"]
      end

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
      # Use client-provided cached data if available
      if @cached_data["spacing_values"].present?
        return @cached_data["spacing_values"]
      end

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
      # Use client-provided cached data if available
      if @cached_data["font_sizes"].present?
        return @cached_data["font_sizes"]
      end

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

      param_strings = params.map do |name, info|
        # Handle new parameter structure
        if info.is_a?(Hash)
          type_info = info[:type] || "String"
          required = info[:required] ? "" : "?"
          "#{name}#{required}: #{type_info}"
        else
          # Legacy format
          "#{name}: #{info}"
        end
      end

      "(#{param_strings.join(', ')})"
    end

    def build_documentation(metadata)
      parts = [ metadata[:description] ]

      if metadata[:examples]&.any?
        parts << "\n\nExamples:"
        parts.concat(metadata[:examples].map { |ex| "  #{ex}" })
      end

      parts.join("\n")
    end

    def build_insert_text(name, parameters)
      Rails.logger.debug "build_insert_text called with name: #{name}, parameters: #{parameters}"
      return name if parameters.nil? || parameters.empty?

      # Build snippet with tab stops and proper defaults
      tab_index = 1
      required_params = []
      optional_params = []
      
      parameters.each do |param_name, info|
        if info.is_a?(Hash)
          # New parameter structure
          param_info = info
          type = param_info[:type] || "String"
          required = param_info[:required] || false
          default = param_info[:default]
          options = param_info[:options]
          
          # Create placeholder with default value or type hint
          placeholder = if options && options.any?
            # For options, create a choice placeholder with proper quoting
            choices = options.map { |opt| 
              opt_str = opt.to_s.gsub('"', '')
              case type
              when "String"
                "\"#{opt_str}\""
              else
                opt_str
              end
            }.join(',')
            "${#{tab_index}|#{choices}|}"
          elsif default
            case type
            when "String"
              "${#{tab_index}:\"#{default}\"}"
            when "Integer"
              "${#{tab_index}:#{default}}"
            when "Symbol"
              "${#{tab_index}:#{default}}"
            else
              "${#{tab_index}:\"#{default}\"}"
            end
          else
            case type
            when "String"
              "${#{tab_index}:\"#{param_name}\"}"
            when "Integer"
              "${#{tab_index}:0}"
            when "Symbol"
              "${#{tab_index}::value}"
            else
              "${#{tab_index}:\"#{param_name}\"}"
            end
          end
          
          param_snippet = "#{param_name}: #{placeholder}"
          
          if required
            required_params << param_snippet
          else
            optional_params << param_snippet
          end
          
          tab_index += 1
        else
          # Legacy format
          default = case info
          when "String" then '""'
          when /^:/ then info
          else info
          end
          
          required_params << "#{param_name}: ${#{tab_index}:#{default}}"
          tab_index += 1
        end
      end
      
      # Combine required and optional parameters
      all_params = required_params + optional_params
      
      # Special cases with complex examples - check these FIRST
      case name
      when "button"
        Rails.logger.debug "Using complex button snippet"
        return "button(${1:\"Click Me\"})\n  .bg(${2:\"blue-500\"})\n  .text_color(${3:\"white\"})\n  .px(${4:4}).py(${5:2})\n  .rounded(${6:\"lg\"})\n  .data(action: ${7:\"click->controller#method\"})"
      when "text"
        Rails.logger.info "Using complex text snippet"
        return "text(${1:\"Your text here\"})\n  .font_size(${2:\"xl\"})\n  .font_weight(${3:\"semibold\"})\n  .text_color(${4:\"gray-800\"})\n  .text_align(${5:\"left\"})\n  .leading(${6:\"relaxed\"})"
      end
      
      # For single required string parameter, use positional format
      if parameters.size == 1 && parameters.values.first.is_a?(Hash)
        param_info = parameters.values.first
        if param_info[:required] && param_info[:type] == "String"
          default_value = param_info[:default] || parameters.keys.first.to_s
          return "#{name}(${1:\"#{default_value}\"})"
        end
      end
      
      "#{name}(#{all_params.join(', ')})"
    end

    def build_modifier_insert_text(modifier, metadata)
      if metadata[:parameters]
        # Provide rich parameter hints with multiple examples based on modifier type
        placeholder = case modifier
        when "bg", "background"
          "${1|\"blue-500\",\"red-500\",\"green-500\",\"yellow-500\",\"purple-500\",\"gray-100\",\"white\",\"black\",\"transparent\"|}"
        when "text_color"
          "${1|\"gray-800\",\"blue-600\",\"red-600\",\"green-600\",\"yellow-600\",\"purple-600\",\"gray-500\",\"white\",\"black\"|}"
        when "border_color"
          "${1|\"gray-300\",\"blue-500\",\"red-500\",\"green-500\",\"yellow-500\",\"purple-500\",\"gray-200\",\"transparent\"|}"
        when "font_size", "text_size"
          "${1|\"xs\",\"sm\",\"base\",\"lg\",\"xl\",\"2xl\",\"3xl\",\"4xl\",\"5xl\",\"6xl\"|}"
        when "font_weight"
          "${1|\"light\",\"normal\",\"medium\",\"semibold\",\"bold\",\"extrabold\"|}"
        when "text_align"
          "${1|\"left\",\"center\",\"right\",\"justify\"|}"
        when "line_height", "leading"
          "${1|\"tight\",\"snug\",\"normal\",\"relaxed\",\"loose\"|}"
        when "letter_spacing", "tracking"
          "${1|\"tight\",\"normal\",\"wide\",\"wider\",\"widest\"|}"
        when "line_clamp"
          "${1|1,2,3,4,5,6|}"
        when "p", "padding"
          "${1|0,1,2,3,4,5,6,8,10,12,16,20,24|}"
        when "m", "margin"
          "${1|0,1,2,3,4,5,6,8,10,12,16,20,24,\"auto\"|}"
        when "px", "py", "pt", "pb", "pl", "pr"
          "${1|0,1,2,3,4,5,6,8,10,12,16,20,24|}"
        when "mx", "my", "mt", "mb", "ml", "mr"
          "${1|0,1,2,3,4,5,6,8,10,12,16,20,24,\"auto\"|}"
        when "w", "width"
          "${1|\"full\",\"1/2\",\"1/3\",\"2/3\",\"1/4\",\"3/4\",\"auto\",\"fit\",\"screen\",\"48\",\"64\",\"96\"|}"
        when "h", "height"
          "${1|\"full\",\"screen\",\"auto\",\"fit\",\"48\",\"64\",\"96\",\"32\",\"24\",\"16\",\"12\",\"8\"|}"
        when "rounded", "corner_radius"
          "${1|\"none\",\"sm\",\"md\",\"lg\",\"xl\",\"2xl\",\"3xl\",\"full\"|}"
        when "shadow"
          "${1|\"none\",\"sm\",\"md\",\"lg\",\"xl\",\"2xl\",\"inner\"|}"
        when "opacity"
          "${1|0,10,20,30,40,50,60,70,80,90,100|}"
        when "hover"
          "${1|\"bg-blue-600\",\"bg-red-600\",\"bg-green-600\",\"scale-105\",\"shadow-lg\",\"opacity-80\"|}"
        when "focus"
          "${1|\"ring-2\",\"ring-blue-500\",\"outline-none\",\"ring-offset-2\"|}"
        when "data"
          "${1|{ controller: \"${2:controller}\" },{ action: \"click->${2:controller}#${3:method}\" },{ ${2:controller}_target: \"${3:target}\" }|}"
        when "flex"
          "${1|\"1\",\"auto\",\"initial\",\"none\"|}"
        when "items"
          "${1|\"start\",\"center\",\"end\",\"stretch\",\"baseline\"|}"
        when "justify"
          "${1|\"start\",\"center\",\"end\",\"between\",\"around\",\"evenly\"|}"
        when "gap"
          "${1|0,1,2,3,4,5,6,8,10,12,16,20,24|}"
        when "z"
          "${1|0,10,20,30,40,50,\"auto\"|}"
        when "transition"
          "${1|\"all\",\"colors\",\"opacity\",\"shadow\",\"transform\"|}"
        when "duration"
          "${1|75,100,150,200,300,500,700,1000|}"
        when "ease"
          "${1|\"linear\",\"in\",\"out\",\"in-out\"|}"
        when "transform"
          "${1|\"translate-x-0\",\"translate-y-0\",\"rotate-0\",\"scale-100\",\"skew-0\"|}"
        when "scale"
          "${1|50,75,90,95,100,105,110,125,150|}"
        when "rotate"
          "${1|0,1,2,3,6,12,45,90,180|}"
        when "translate_x", "translate_y"
          "${1|0,1,2,3,4,5,6,8,10,12,16,20,24|}"
        else
          "${1:value}"
        end
        
        "#{modifier}(#{placeholder})"
      else
        modifier
      end
    end
  end
end
