# frozen_string_literal: true

require 'singleton'
require 'concurrent'

module Playground
  class DslRegistry
    include Singleton
    
    attr_reader :version
    
    def initialize
      @map = Concurrent::Map.new
      @version = Time.now.to_i
      register_core_dsl
    end
    
    # Register a DSL element with its metadata
    def register(name, metadata)
      @map[name.to_s] = metadata.merge(
        registered_at: Time.now,
        source: metadata[:source] || :core
      )
      bump_version
    end
    
    # Register multiple elements at once
    def register_bulk(elements)
      elements.each { |name, meta| register(name, meta) }
    end
    
    # Get metadata for a DSL element
    def [](name)
      @map[name.to_s]
    end
    
    # Get all registered elements
    def all
      @map.each_pair.to_h
    end
    
    # Get elements by category
    def by_category(category)
      @map.select { |_, meta| meta[:category] == category }.to_h
    end
    
    # Clear the registry (useful for reloading in development)
    def clear
      @map.clear
      bump_version
    end
    
    # Alias for consistency with initializer
    alias_method :clear!, :clear
    
    # Reload core DSL (for hot reloading)
    def reload!
      clear
      register_core_dsl
    end
    
    # Rebuild by triggering Rails reload
    def rebuild!
      clear!
      # Let the initializer re-register everything
    end
    
    private
    
    def bump_version
      @version = Time.now.to_i
    end
    
    def register_core_dsl
      # Layout elements
      register_bulk({
        vstack: {
          category: :layout,
          parameters: { alignment: ":center", spacing: "8" },
          description: "Vertical stack layout",
          modifiers: %w[padding margin spacing items_center justify_center gap],
          examples: ['vstack(spacing: 16) { }']
        },
        hstack: {
          category: :layout,
          parameters: { alignment: ":center", spacing: "8" },
          description: "Horizontal stack layout",
          modifiers: %w[padding margin spacing items_center justify_center gap],
          examples: ['hstack(spacing: 8) { }']
        },
        zstack: {
          category: :layout,
          parameters: {},
          description: "Z-axis stack layout (overlapping)",
          modifiers: %w[padding margin position],
          examples: ['zstack { }']
        },
        grid: {
          category: :layout,
          parameters: { columns: "2", spacing: "8" },
          description: "Grid layout",
          modifiers: %w[padding margin gap columns],
          examples: ['grid(columns: 3, spacing: 16) { }']
        },
        
        # UI elements
        text: {
          category: :elements,
          parameters: { content: "String" },
          description: "Text element",
          modifiers: %w[font_size font_weight text_color text_align line_height italic underline truncate],
          examples: ['text("Hello World")']
        },
        button: {
          category: :elements,
          parameters: { title: "String" },
          description: "Button element",
          modifiers: %w[bg hover disabled type text_color padding rounded data],
          examples: ['button("Click Me")']
        },
        image: {
          category: :elements,
          parameters: { src: "String", alt: "String" },
          description: "Image element",
          modifiers: %w[w h rounded object_fit],
          examples: ['image(src: "photo.jpg", alt: "Description")']
        },
        
        # Form elements
        textfield: {
          category: :forms,
          parameters: { placeholder: "String", value: "String" },
          description: "Text input field",
          modifiers: %w[w padding border focus],
          examples: ['textfield(placeholder: "Enter text")']
        },
        form: {
          category: :forms,
          parameters: { action: "String", method: ":post" },
          description: "Form container",
          modifiers: %w[padding margin],
          examples: ['form(action: "/submit", method: :post) { }']
        },
        
        # Container elements
        card: {
          category: :containers,
          parameters: { elevation: "1" },
          description: "Card container",
          modifiers: %w[padding margin shadow rounded bg],
          examples: ['card(elevation: 2) { }']
        },
        div: {
          category: :containers,
          parameters: {},
          description: "Generic container",
          modifiers: %w[padding margin bg border rounded position flex],
          examples: ['div { }']
        }
      })
      
      # Register modifier metadata
      register_modifiers
    end
    
    def register_modifiers
      @modifiers = {
        # Colors
        bg: { values: :tailwind_colors, description: "Background color" },
        text_color: { values: :tailwind_colors, description: "Text color" },
        border_color: { values: :tailwind_colors, description: "Border color" },
        
        # Spacing
        padding: { values: :spacing_values, description: "Padding" },
        p: { values: :spacing_values, description: "Padding shorthand" },
        margin: { values: :spacing_values, description: "Margin" },
        m: { values: :spacing_values, description: "Margin shorthand" },
        
        # Typography
        font_size: { values: %w[xs sm base lg xl 2xl 3xl 4xl 5xl], description: "Font size" },
        font_weight: { values: %w[thin light normal medium semibold bold], description: "Font weight" },
        
        # Layout
        w: { values: :size_values, description: "Width" },
        h: { values: :size_values, description: "Height" },
        
        # Effects
        rounded: { values: %w[none sm md lg xl 2xl 3xl full], description: "Border radius" },
        shadow: { values: %w[none sm md lg xl 2xl inner], description: "Box shadow" }
      }
    end
    
    def modifiers
      @modifiers ||= {}
    end
  end
end

# Auto-registration hook for DSL components
module SwiftUIRails
  module DSL
    module Registerable
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def register_dsl(name, metadata = {})
          Playground::DslRegistry.instance.register(name, metadata)
        end
      end
    end
  end
end

# Hot-reload support is handled in config/initializers/playground_dsl_registry.rb