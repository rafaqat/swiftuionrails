# frozen_string_literal: true

# Register SwiftUI Rails DSL elements for playground completions
Rails.application.reloader.to_prepare do
  registry = Playground::DslRegistry.instance
  
  # Clear existing registrations to avoid duplicates on reload
  registry.clear!
  
  # Text elements
  registry.register(:text, {
    description: "Display text content",
    parameters: { content: "String" },
    modifiers: %w[font_size font_weight text_color text_align line_clamp],
    examples: ['text("Hello World")', 'text("Welcome").font_size("xl")']
  })
  
  # Layout containers
  registry.register(:vstack, {
    description: "Vertical stack layout",
    parameters: { spacing: "Integer", align: "Symbol" },
    modifiers: %w[padding margin background spacing align],
    examples: ['vstack { }', 'vstack(spacing: 16) { }']
  })
  
  registry.register(:hstack, {
    description: "Horizontal stack layout", 
    parameters: { spacing: "Integer", align: "Symbol" },
    modifiers: %w[padding margin background spacing align],
    examples: ['hstack { }', 'hstack(spacing: 8) { }']
  })
  
  registry.register(:zstack, {
    description: "Layered stack layout",
    parameters: {},
    modifiers: %w[padding margin background],
    examples: ['zstack { }']
  })
  
  # Basic elements
  registry.register(:button, {
    description: "Interactive button",
    parameters: { label: "String", action: "String" },
    modifiers: %w[bg text_color padding rounded hover disabled],
    examples: ['button("Click Me")', 'button("Submit").bg("blue-500")']
  })
  
  registry.register(:image, {
    description: "Display an image",
    parameters: { src: "String", alt: "String" },
    modifiers: %w[width height rounded object_cover],
    examples: ['image(src: "photo.jpg", alt: "Photo")']
  })
  
  registry.register(:card, {
    description: "Card container component",
    parameters: { elevation: "Integer" },
    modifiers: %w[padding background rounded shadow],
    examples: ['card { }', 'card(elevation: 2) { }']
  })
  
  registry.register(:div, {
    description: "Generic container element",
    parameters: {},
    modifiers: %w[padding margin background border rounded flex grid],
    examples: ['div { }', 'div.flex { }']
  })
  
  registry.register(:span, {
    description: "Inline container element",
    parameters: { content: "String" },
    modifiers: %w[text_color font_weight],
    examples: ['span("text")', 'span { "inline" }']
  })
  
  registry.register(:spacer, {
    description: "Flexible space that expands",
    parameters: {},
    modifiers: %w[],
    examples: ['spacer']
  })
  
  # Form elements
  registry.register(:textfield, {
    description: "Text input field",
    parameters: { name: "String", placeholder: "String", value: "String" },
    modifiers: %w[width disabled required],
    examples: ['textfield(name: "email", placeholder: "Enter email")']
  })
  
  registry.register(:form, {
    description: "Form container",
    parameters: { action: "String", method: "Symbol" },
    modifiers: %w[],
    examples: ['form(action: "/submit", method: :post) { }']
  })
  
  registry.register(:label, {
    description: "Form label",
    parameters: { text: "String", for: "String" },
    modifiers: %w[font_weight text_color],
    examples: ['label("Email", for: "email")']
  })
  
  # Lists
  registry.register(:list, {
    description: "List container",
    parameters: {},
    modifiers: %w[spacing],
    examples: ['list { }']
  })
  
  registry.register(:list_item, {
    description: "List item",
    parameters: {},
    modifiers: %w[padding hover],
    examples: ['list_item { }']
  })
  
  Rails.logger.info "Registered #{registry.all.size} DSL elements for playground completions"
end