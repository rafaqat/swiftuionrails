# frozen_string_literal: true

class SignatureHelpService
  def initialize
    @signatures = build_signature_map
  end
  
  def get_signatures(method_name)
    return [] unless method_name.present?
    
    # Get the signature for the method
    signature_info = @signatures[method_name.to_sym]
    return [] unless signature_info
    
    # Format for Monaco signature help
    [{
      label: signature_info[:label],
      documentation: signature_info[:documentation],
      parameters: signature_info[:parameters].map do |param|
        {
          label: param[:label],
          documentation: param[:documentation]
        }
      end,
      activeParameter: 0
    }]
  end
  
  private
  
  def build_signature_map
    {
      # Layout components
      vstack: {
        label: "vstack(spacing: Integer = 0, align: Symbol = :center, &block)",
        documentation: "Creates a vertical stack layout",
        parameters: [
          { label: "spacing: Integer = 0", documentation: "Space between child elements in pixels" },
          { label: "align: Symbol = :center", documentation: "Alignment of children (:start, :center, :end)" },
          { label: "&block", documentation: "Block containing child elements" }
        ]
      },
      hstack: {
        label: "hstack(spacing: Integer = 0, align: Symbol = :center, &block)",
        documentation: "Creates a horizontal stack layout",
        parameters: [
          { label: "spacing: Integer = 0", documentation: "Space between child elements in pixels" },
          { label: "align: Symbol = :center", documentation: "Alignment of children (:start, :center, :end)" },
          { label: "&block", documentation: "Block containing child elements" }
        ]
      },
      zstack: {
        label: "zstack(align: Symbol = :center, &block)",
        documentation: "Creates a layered stack where children overlap",
        parameters: [
          { label: "align: Symbol = :center", documentation: "Alignment of layers (:start, :center, :end)" },
          { label: "&block", documentation: "Block containing child elements" }
        ]
      },
      grid: {
        label: "grid(cols: Integer, gap: Integer = 16, &block)",
        documentation: "Creates a grid layout",
        parameters: [
          { label: "cols: Integer", documentation: "Number of columns" },
          { label: "gap: Integer = 16", documentation: "Gap between grid items in pixels" },
          { label: "&block", documentation: "Block containing grid items" }
        ]
      },
      
      # Basic elements
      text: {
        label: "text(content)",
        documentation: "Displays text content",
        parameters: [
          { label: "content", documentation: "Text to display (String or any object that responds to to_s)" }
        ]
      },
      button: {
        label: "button(label, type: String = 'button', **attrs, &block)",
        documentation: "Creates an interactive button",
        parameters: [
          { label: "label", documentation: "Button text label" },
          { label: "type: String = 'button'", documentation: "Button type: 'button', 'submit', or 'reset'" },
          { label: "**attrs", documentation: "Additional HTML attributes" },
          { label: "&block", documentation: "Optional block for button content" }
        ]
      },
      image: {
        label: "image(src: String, alt: String = '', **attrs)",
        documentation: "Displays an image",
        parameters: [
          { label: "src: String", documentation: "Image source URL" },
          { label: "alt: String = ''", documentation: "Alternative text for accessibility" },
          { label: "**attrs", documentation: "Additional HTML attributes" }
        ]
      },
      link: {
        label: "link(text, destination: String, **attrs, &block)",
        documentation: "Creates a hyperlink",
        parameters: [
          { label: "text", documentation: "Link text" },
          { label: "destination: String", documentation: "URL or path to link to" },
          { label: "**attrs", documentation: "Additional HTML attributes" },
          { label: "&block", documentation: "Optional block for link content" }
        ]
      },
      
      # Form elements
      form: {
        label: "form(action: String, method: Symbol = :post, **attrs, &block)",
        documentation: "Creates a form",
        parameters: [
          { label: "action: String", documentation: "Form submission URL" },
          { label: "method: Symbol = :post", documentation: "HTTP method (:get, :post, :patch, :put, :delete)" },
          { label: "**attrs", documentation: "Additional HTML attributes" },
          { label: "&block", documentation: "Block containing form fields" }
        ]
      },
      textfield: {
        label: "textfield(name: String, value: String = nil, type: String = 'text', **attrs)",
        documentation: "Creates a text input field",
        parameters: [
          { label: "name: String", documentation: "Field name for form submission" },
          { label: "value: String = nil", documentation: "Initial value" },
          { label: "type: String = 'text'", documentation: "Input type (text, email, password, etc.)" },
          { label: "**attrs", documentation: "Additional HTML attributes" }
        ]
      },
      textarea: {
        label: "textarea(name: String, value: String = nil, rows: Integer = 4, **attrs)",
        documentation: "Creates a multi-line text input",
        parameters: [
          { label: "name: String", documentation: "Field name for form submission" },
          { label: "value: String = nil", documentation: "Initial value" },
          { label: "rows: Integer = 4", documentation: "Number of visible text rows" },
          { label: "**attrs", documentation: "Additional HTML attributes" }
        ]
      },
      select: {
        label: "select(name: String, selected: String = nil, **attrs, &block)",
        documentation: "Creates a dropdown select field",
        parameters: [
          { label: "name: String", documentation: "Field name for form submission" },
          { label: "selected: String = nil", documentation: "Initially selected value" },
          { label: "**attrs", documentation: "Additional HTML attributes" },
          { label: "&block", documentation: "Block containing option elements" }
        ]
      },
      option: {
        label: "option(value: String, text_content: String = nil, selected: Boolean = false, **attrs)",
        documentation: "Creates an option for a select field",
        parameters: [
          { label: "value: String", documentation: "Option value" },
          { label: "text_content: String = nil", documentation: "Display text (defaults to value)" },
          { label: "selected: Boolean = false", documentation: "Whether option is selected" },
          { label: "**attrs", documentation: "Additional HTML attributes" }
        ]
      },
      label: {
        label: "label(text_content: String = nil, for_input: String = nil, **attrs, &block)",
        documentation: "Creates a form label",
        parameters: [
          { label: "text_content: String = nil", documentation: "Label text" },
          { label: "for_input: String = nil", documentation: "ID of associated input field" },
          { label: "**attrs", documentation: "Additional HTML attributes" },
          { label: "&block", documentation: "Optional block for label content" }
        ]
      },
      
      # Components
      card: {
        label: "card(elevation: Integer = 1, &block)",
        documentation: "Creates a card container with shadow",
        parameters: [
          { label: "elevation: Integer = 1", documentation: "Shadow elevation level (0-5)" },
          { label: "&block", documentation: "Block containing card content" }
        ]
      },
      list: {
        label: "list(style: Symbol = :none, &block)",
        documentation: "Creates a list container",
        parameters: [
          { label: "style: Symbol = :none", documentation: "List style (:none, :disc, :decimal)" },
          { label: "&block", documentation: "Block containing list items" }
        ]
      },
      list_item: {
        label: "list_item(**attrs, &block)",
        documentation: "Creates a list item",
        parameters: [
          { label: "**attrs", documentation: "Additional HTML attributes" },
          { label: "&block", documentation: "Block containing item content" }
        ]
      },
      
      # Modifiers with parameters
      bg: {
        label: "bg(color: String)",
        documentation: "Sets background color using Tailwind classes",
        parameters: [
          { label: "color: String", documentation: "Tailwind color class (e.g., 'blue-500', 'teal')" }
        ]
      },
      text_color: {
        label: "text_color(color: String)",
        documentation: "Sets text color using Tailwind classes",
        parameters: [
          { label: "color: String", documentation: "Tailwind color class (e.g., 'red-600', 'yellow')" }
        ]
      },
      font_size: {
        label: "font_size(size: String)",
        documentation: "Sets font size",
        parameters: [
          { label: "size: String", documentation: "Size value (xs, sm, base, lg, xl, 2xl, 3xl, etc.)" }
        ]
      },
      rounded: {
        label: "rounded(size: String = 'md')",
        documentation: "Sets border radius",
        parameters: [
          { label: "size: String = 'md'", documentation: "Radius size (none, sm, md, lg, xl, 2xl, 3xl, full)" }
        ]
      },
      shadow: {
        label: "shadow(size: String = 'md')",
        documentation: "Adds drop shadow",
        parameters: [
          { label: "size: String = 'md'", documentation: "Shadow size (none, sm, md, lg, xl, 2xl, inner)" }
        ]
      },
      hover: {
        label: "hover(classes: String)",
        documentation: "Adds hover state styles",
        parameters: [
          { label: "classes: String", documentation: "Tailwind classes to apply on hover" }
        ]
      },
      data: {
        label: "data(attributes: Hash)",
        documentation: "Sets data attributes for Stimulus",
        parameters: [
          { label: "attributes: Hash", documentation: "Hash of data attributes (e.g., { controller: 'name', action: 'click->name#method' })" }
        ]
      }
    }
  end
end