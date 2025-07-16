# frozen_string_literal: true

class PlaygroundV2Controller < ApplicationController
  layout "playground"

  def index
    @playground = PlaygroundV2Component.new(
      default_code: default_playground_code,
      components: available_components,
      examples: code_examples
    )
  end

  def preview
    code = params[:code]

    # Security check - only allow DSL code in playground
    if Rails.env.production? && contains_dangerous_code?(code)
      render_error("Code contains potentially dangerous operations")
      return
    end

    begin
      # First, validate the Ruby syntax
      RubyVM::InstructionSequence.compile(code)

      # Detect if the code already has swift_ui wrapper
      has_swift_ui_wrapper = code.strip.start_with?("swift_ui do")

      # Create a temporary component class to evaluate the DSL
      temp_class_name = "PlaygroundComponent#{SecureRandom.hex(8)}"
      component_class = Class.new(ApplicationComponent) do
        include SwiftUIRails::DSL
        include SwiftUIRails::Helpers

        if has_swift_ui_wrapper
          # If code already has swift_ui wrapper, just evaluate it
          class_eval <<-RUBY
            def call
              #{code}
            end
          RUBY
        else
          # Otherwise, wrap it in swift_ui block
          class_eval <<-RUBY
            def call
              swift_ui do
                #{code}
              end
            end
          RUBY
        end
      end

      # Give the class a name to avoid nil name issues
      Object.const_set(temp_class_name, component_class)

      # Render the component
      @rendered_html = component_class.new.call.to_s

      # Clean up the temporary constant
      Object.send(:remove_const, temp_class_name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("preview-container", @rendered_html)
        end
        format.html { render partial: "preview", locals: { html: @rendered_html } }
      end
    rescue SyntaxError => e
      # Format syntax errors nicely
      formatted_error = SyntaxError.new(format_syntax_error(e, code))
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("preview-container",
            render_to_string(partial: "error", locals: { error: formatted_error }))
        end
        format.html { render partial: "error", locals: { error: formatted_error } }
      end
    rescue => e
      # Handle other errors
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("preview-container",
            render_to_string(partial: "error", locals: { error: e }))
        end
        format.html { render partial: "error", locals: { error: e } }
      end
    end
  end

  def signatures
    method_name = params[:method]
    active_parameter = params[:active_parameter].to_i if params[:active_parameter].present?

    begin
      service = SignatureHelpService.new
      signatures = service.get_signatures(method_name, active_parameter: active_parameter)

      render json: { signatures: signatures }
    rescue => e
      Rails.logger.error "Signature help error: #{e.message}"
      render json: { signatures: [] }
    end
  end

  private

  def contains_dangerous_code?(code)
    dangerous_patterns = [
      /\b(eval|exec|system|backticks|%x|spawn|fork|load|require|open|File|Dir|IO)\b/,
      /`.*`/,
      /%x\{.*\}/,
      /\$\w+/,
      /@@\w+/,
      /\:\:/,
      /\.send/,
      /\.public_send/
    ]

    dangerous_patterns.any? { |pattern| code =~ pattern }
  end

  def render_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("preview-container",
          render_to_string(partial: "error", locals: { error: SecurityError.new(message) }))
      end
      format.html { render partial: "error", locals: { error: SecurityError.new(message) } }
    end
  end

  def format_syntax_error(error, code)
    # Extract line number from error message
    if error.message =~ /:(\\d+):/
      line_number = $1.to_i
      lines = code.split("\\n")

      # Build a nice error message with context
      message = "Syntax error on line #{line_number}\\n\\n"

      # Show 2 lines before and after the error
      start_line = [ line_number - 3, 0 ].max
      end_line = [ line_number + 1, lines.length - 1 ].min

      (start_line..end_line).each do |i|
        line_num = i + 1
        prefix = line_num == line_number ? "→ " : "  "
        message += "#{prefix}#{line_num.to_s.rjust(3)}: #{lines[i]}\\n" if lines[i]
      end

      message += "\\n#{error.message}"
    else
      error.message
    end
  end

  def default_playground_code
    <<~RUBY
      swift_ui do
        vstack(spacing: 16) do
          text("Welcome to SwiftUI Rails Playground!")
            .font_size("2xl")
            .font_weight("bold")
            .text_color("blue-600")
      #{'    '}
          text("Built with our own DSL 🎉")
            .text_color("gray-600")
      #{'    '}
          hstack(spacing: 8) do
            button("Click Me")
              .bg("blue-500")
              .text_color("white")
              .px(4).py(2)
              .rounded("lg")
              .hover("bg-blue-600")
              .data(action: "click->playground#handleClick")
      #{'      '}
            button("Reset")
              .bg("gray-500")
              .text_color("white")
              .px(4).py(2)
              .rounded("lg")
              .hover("bg-gray-600")
          end
      #{'    '}
          card(elevation: 2) do
            vstack(spacing: 8) do
              text("This is the SwiftUI Rails Playground")
                .font_weight("semibold")
              text("100% built with SwiftUI Rails DSL")
                .text_sm
                .text_color("gray-600")
            end
          end
        end
      end
    RUBY
  end

  def available_components
    [
      { name: "Text", category: "Basic", icon: "📝", code: 'text("Hello World")' },
      { name: "Button", category: "Basic", icon: "🔘", code: 'button("Click Me")' },
      { name: "Image", category: "Basic", icon: "🖼️", code: 'image(src: "https://via.placeholder.com/150", alt: "Placeholder")' },
      { name: "VStack", category: "Layout", icon: "⬇️", code: 'vstack(spacing: 16) do\\n  # Add content here\\nend' },
      { name: "HStack", category: "Layout", icon: "➡️", code: 'hstack(spacing: 16) do\\n  # Add content here\\nend' },
      { name: "Card", category: "Components", icon: "🃏", code: 'card(elevation: 2) do\\n  # Add content here\\nend' },
      { name: "List", category: "Components", icon: "📋", code: 'list do\\n  (1..5).each do |i|\\n    list_item { text("Item #{i}") }\\n  end\\nend' },
      { name: "Grid", category: "Layout", icon: "⚏", code: 'grid(cols: 3, gap: 16) do\\n  # Add grid items here\\nend' },
      { name: "Form", category: "Forms", icon: "📄", code: 'form(action: "#", method: :post) do\\n  # Add form fields here\\nend' },
      { name: "TextField", category: "Forms", icon: "🔤", code: 'textfield(name: "email", placeholder: "Enter email")' }
    ]
  end

  def code_examples
    # Load dogfood examples
    require Rails.root.join("examples/playground_dogfood_examples.rb")
    dogfood_examples = PlaygroundDogfoodExamples.all_examples
    
    [
      {
        name: "Product Grid",
        description: "E-commerce product grid with hover effects",
        code: dogfood_examples[:product_grid]
      },
      {
        name: "Dashboard Stats",
        description: "Analytics dashboard with stat cards",
        code: dogfood_examples[:dashboard_stats]
      },
      {
        name: "Pricing Cards",
        description: "Interactive pricing table with popular badge",
        code: dogfood_examples[:pricing_cards]
      },
      {
        name: "Todo List",
        description: "Interactive todo list with Stimulus",
        code: dogfood_examples[:todo_list]
      },
      {
        name: "Navigation Bar",
        description: "Responsive navbar with dropdown menus",
        code: dogfood_examples[:navbar]
      }
    ]
  end
end