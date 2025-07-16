# frozen_string_literal: true

class PlaygroundDataController < ApplicationController
  def signatures
    # Try to serve compressed signatures data if available
    # Since there's no signatures.json.b64 file, we'll generate it
    signatures_data = {
      compressed: generate_compressed_signatures
    }
    
    render json: signatures_data
  end
  
  def completions
    # Serve the existing completion data (try base64 first, then fallback)
    b64_file = Rails.root.join('public', 'playground', 'data', 'completion_data.json.b64')
    json_file = Rails.root.join('public', 'playground', 'data', 'completion_data.json')
    
    if File.exist?(b64_file)
      # Serve base64 compressed data
      compressed_data = File.read(b64_file).strip
      render json: { compressed: compressed_data }
    elsif File.exist?(json_file)
      # Serve raw JSON data
      data = JSON.parse(File.read(json_file))
      render json: { compressed: data }
    else
      # Fallback to generated data
      render json: { compressed: generate_fallback_completions }
    end
  end
  
  private
  
  def generate_compressed_signatures
    # Basic DSL method signatures for IntelliSense
    {
      "text" => {
        "parameters" => [
          { "name" => "content", "type" => "String", "required" => true }
        ],
        "description" => "Creates a text element with the given content",
        "returns" => "Element"
      },
      "button" => {
        "parameters" => [
          { "name" => "label", "type" => "String", "required" => true },
          { "name" => "type", "type" => "String", "required" => false }
        ],
        "description" => "Creates a button element",
        "returns" => "Element"
      },
      "vstack" => {
        "parameters" => [
          { "name" => "spacing", "type" => "Integer", "required" => false },
          { "name" => "alignment", "type" => "Symbol", "required" => false }
        ],
        "description" => "Creates a vertical stack container",
        "returns" => "Element"
      },
      "hstack" => {
        "parameters" => [
          { "name" => "spacing", "type" => "Integer", "required" => false },
          { "name" => "alignment", "type" => "Symbol", "required" => false }
        ],
        "description" => "Creates a horizontal stack container",
        "returns" => "Element"
      },
      "card" => {
        "parameters" => [
          { "name" => "elevation", "type" => "Integer", "required" => false }
        ],
        "description" => "Creates a card container with shadow",
        "returns" => "Element"
      }
    }
  end
  
  def generate_fallback_completions
    # Basic DSL completions for IntelliSense
    {
      "version" => Time.current.to_i,
      "dsl_methods" => [
        { "name" => "text", "category" => "basic", "description" => "Text element" },
        { "name" => "button", "category" => "basic", "description" => "Button element" },
        { "name" => "vstack", "category" => "layout", "description" => "Vertical stack" },
        { "name" => "hstack", "category" => "layout", "description" => "Horizontal stack" },
        { "name" => "card", "category" => "container", "description" => "Card container" },
        { "name" => "div", "category" => "basic", "description" => "Division element" },
        { "name" => "span", "category" => "basic", "description" => "Span element" },
        { "name" => "image", "category" => "media", "description" => "Image element" }
      ],
      "modifiers" => [
        { "name" => "bg", "description" => "Background color" },
        { "name" => "text_color", "description" => "Text color" },
        { "name" => "padding", "description" => "Padding" },
        { "name" => "margin", "description" => "Margin" },
        { "name" => "rounded", "description" => "Border radius" },
        { "name" => "shadow", "description" => "Box shadow" }
      ]
    }
  end
end