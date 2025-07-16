# frozen_string_literal: true

# Register SwiftUI Rails DSL elements for playground completions
Rails.application.reloader.to_prepare do
  registry = Playground::DslRegistry.instance

  # Clear existing registrations to avoid duplicates on reload
  registry.clear!

  # Text elements
  registry.register(:text, {
    description: "Display styled text content with typography options",
    parameters: { 
      content: { type: "String", required: true, default: "Hello World" }
    },
    modifiers: %w[font_size font_weight text_color text_align line_clamp letter_spacing leading opacity],
    examples: [ 
      'text("Hello World")',
      'text("Title").font_size("2xl").font_weight("bold")',
      'text("Subtitle").text_color("gray-600").font_size("lg")',
      'text("Body text").line_clamp(3).text_align("center")',
      'text("Highlighted").bg("yellow-200").text_color("yellow-800").px(2).py(1).rounded("md")'
    ]
  })

  # Layout containers
  registry.register(:vstack, {
    description: "Vertical stack layout",
    parameters: { 
      spacing: { type: "Integer", required: false, default: 16 },
      align: { type: "Symbol", required: false, default: ":start", options: [":start", ":center", ":end"] },
      justify: { type: "Symbol", required: false, default: ":start", options: [":start", ":center", ":end", ":between", ":around", ":evenly"] }
    },
    modifiers: %w[padding margin background spacing align justify],
    examples: [ "vstack { }", "vstack(spacing: 16) { }", "vstack(justify: :between) { }" ]
  })

  registry.register(:hstack, {
    description: "Horizontal stack layout",
    parameters: { 
      spacing: { type: "Integer", required: false, default: 8 },
      align: { type: "Symbol", required: false, default: ":start", options: [":start", ":center", ":end"] },
      justify: { type: "Symbol", required: false, default: ":start", options: [":start", ":center", ":end", ":between", ":around", ":evenly"] }
    },
    modifiers: %w[padding margin background spacing align justify],
    examples: [ "hstack { }", "hstack(spacing: 8) { }", "hstack(justify: :between) { }" ]
  })

  registry.register(:zstack, {
    description: "Layered stack layout",
    parameters: {},
    modifiers: %w[padding margin background],
    examples: [ "zstack { }" ]
  })

  # Basic elements
  registry.register(:button, {
    description: "Interactive button with click handler",
    parameters: { 
      title: { type: "String", required: false, default: "Click Me" }
    },
    modifiers: %w[bg text_color padding rounded hover disabled data],
    examples: [ 
      'button("Click Me")',
      'button("Submit").bg("blue-500")',
      'button("Save").data(action: "click->form#save")',
      'button("Toggle").data(controller: "toggle", action: "click->toggle#switch")'
    ]
  })

  registry.register(:image, {
    description: "Display an image",
    parameters: { 
      src: { type: "String", required: true, default: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop" },
      alt: { type: "String", required: true, default: "Beautiful sunflower" }
    },
    modifiers: %w[width height rounded object_cover],
    examples: [ 'image(src: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop", alt: "Beautiful sunflower")' ]
  })

  registry.register(:card, {
    description: "Card container component",
    parameters: { 
      elevation: { type: "Integer", required: false, default: 1, options: [0, 1, 2, 3, 4, 5] }
    },
    modifiers: %w[padding background rounded shadow],
    examples: [ "card { }", "card(elevation: 2) { }" ]
  })

  registry.register(:div, {
    description: "Generic container element",
    parameters: {},
    modifiers: %w[padding margin background border rounded flex grid],
    examples: [ "div { }", "div.flex { }" ]
  })

  registry.register(:span, {
    description: "Inline container element",
    parameters: { 
      content: { type: "String", required: false, default: "text" }
    },
    modifiers: %w[text_color font_weight],
    examples: [ 'span("text")', 'span { "inline" }' ]
  })

  registry.register(:spacer, {
    description: "Flexible space that expands",
    parameters: {},
    modifiers: %w[],
    examples: [ "spacer" ]
  })

  # Form elements
  registry.register(:textfield, {
    description: "Text input field",
    parameters: { 
      name: { type: "String", required: true, default: "field_name" },
      placeholder: { type: "String", required: false, default: "Enter text" },
      value: { type: "String", required: false, default: "" },
      type: { type: "String", required: false, default: "text", options: ["text", "email", "password", "number", "tel", "url"] }
    },
    modifiers: %w[width disabled required],
    examples: [ 'textfield(name: "email", placeholder: "Enter email")' ]
  })

  registry.register(:form, {
    description: "Form container",
    parameters: { 
      action: { type: "String", required: true, default: "/submit" },
      method: { type: "Symbol", required: false, default: ":post", options: [":get", ":post", ":patch", ":put", ":delete"] }
    },
    modifiers: %w[],
    examples: [ 'form(action: "/submit", method: :post) { }' ]
  })

  registry.register(:label, {
    description: "Form label",
    parameters: { 
      text: { type: "String", required: true, default: "Label" },
      for: { type: "String", required: false, default: "field_id" }
    },
    modifiers: %w[font_weight text_color],
    examples: [ 'label("Email", for: "email")' ]
  })

  # Lists
  registry.register(:list, {
    description: "List container",
    parameters: {},
    modifiers: %w[spacing],
    examples: [ "list { }" ]
  })

  registry.register(:list_item, {
    description: "List item",
    parameters: {},
    modifiers: %w[padding hover],
    examples: [ "list_item { }" ]
  })

  Rails.logger.info "Registered #{registry.all.size} DSL elements for playground completions"
end
