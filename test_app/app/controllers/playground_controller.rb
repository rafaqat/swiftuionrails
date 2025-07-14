# frozen_string_literal: true

class PlaygroundController < ApplicationController
  layout "playground"

  def index
    @default_code = default_playground_code
    @components = available_components
    @examples = code_examples
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
      # Use const_set to give it a name to avoid anonymous class issues
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
    if error.message =~ /:(\d+):/
      line_number = $1.to_i
      lines = code.split("\n")

      # Build a nice error message with context
      message = "Syntax error on line #{line_number}\n\n"

      # Show 2 lines before and after the error
      start_line = [ line_number - 3, 0 ].max
      end_line = [ line_number + 1, lines.length - 1 ].min

      (start_line..end_line).each do |i|
        line_num = i + 1
        prefix = line_num == line_number ? "→ " : "  "
        message += "#{prefix}#{line_num.to_s.rjust(3)}: #{lines[i]}\n" if lines[i]
      end

      message += "\n#{error.message}"
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
          text("Edit the code on the left to see live updates")
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
              text("This is a card component")
                .font_weight("semibold")
              text("You can nest components inside")
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
      { name: "Text", category: "Basic", code: 'text("Hello World")' },
      { name: "Button", category: "Basic", code: 'button("Click Me")' },
      { name: "Image", category: "Basic", code: 'image(src: "https://via.placeholder.com/150", alt: "Placeholder")' },
      { name: "VStack", category: "Layout", code: 'vstack(spacing: 16) do\n  # Add content here\nend' },
      { name: "HStack", category: "Layout", code: 'hstack(spacing: 16) do\n  # Add content here\nend' },
      { name: "Card", category: "Components", code: 'card(elevation: 2) do\n  # Add content here\nend' },
      { name: "List", category: "Components", code: 'list do\n  (1..5).each do |i|\n    list_item { text("Item #{i}") }\n  end\nend' },
      { name: "Grid", category: "Layout", code: 'grid(cols: 3, gap: 16) do\n  # Add grid items here\nend' },
      { name: "Form", category: "Forms", code: 'form(action: "#", method: :post) do\n  # Add form fields here\nend' },
      { name: "TextField", category: "Forms", code: 'textfield(name: "email", placeholder: "Enter email")' }
    ]
  end

  def code_examples
    [
      {
        name: "Counter Component",
        description: "Interactive counter with Stimulus",
        code: <<~RUBY
          swift_ui do
            div(data: {#{' '}
              controller: "counter",
              "counter-count-value": 0#{' '}
            }) do
              vstack(spacing: 16) do
                text("")
                  .font_size("6xl")
                  .font_weight("bold")
                  .data("counter-target": "display")
          #{'      '}
                hstack(spacing: 8) do
                  button("-")
                    .bg("red-500")
                    .text_color("white")
                    .px(4).py(2)
                    .rounded("lg")
                    .data(action: "click->counter#decrement")
          #{'        '}
                  button("+")
                    .bg("green-500")
                    .text_color("white")
                    .px(4).py(2)
                    .rounded("lg")
                    .data(action: "click->counter#increment")
                end
              end
            end
          end
        RUBY
      },
      {
        name: "Product Card",
        description: "E-commerce product card",
        code: <<~RUBY
          swift_ui do
            card(elevation: 3) do
              vstack(spacing: 12) do
                image(
                  src: "https://via.placeholder.com/300x200",
                  alt: "Product"
                ).rounded("lg").w("full")
          #{'      '}
                vstack(spacing: 4, align: :start) do
                  text("Amazing Product")
                    .font_size("xl")
                    .font_weight("semibold")
          #{'        '}
                  text("$99.99")
                    .font_size("2xl")
                    .font_weight("bold")
                    .text_color("green-600")
          #{'        '}
                  text("In stock - Ships tomorrow")
                    .text_sm
                    .text_color("gray-600")
                end
          #{'      '}
                button("Add to Cart")
                  .bg("blue-600")
                  .text_color("white")
                  .w("full")
                  .py(3)
                  .rounded("lg")
                  .hover("bg-blue-700")
                  .transition
              end
            end.max_w("sm")
          end
        RUBY
      },
      {
        name: "Login Form",
        description: "Authentication form with validation",
        code: <<~RUBY
          swift_ui do
            card(elevation: 2) do
              form(action: "#", method: :post) do
                vstack(spacing: 16) do
                  text("Sign In")
                    .font_size("2xl")
                    .font_weight("bold")
                    .text_align("center")
          #{'        '}
                  vstack(spacing: 12) do
                    div do
                      label("Email", for: "email")
                        .font_weight("medium")
                      textfield(
                        name: "email",
                        type: "email",
                        placeholder: "you@example.com",
                        required: true
                      ).mt(4)
                    end
          #{'          '}
                    div do
                      label("Password", for: "password")
                        .font_weight("medium")
                      textfield(
                        name: "password",
                        type: "password",
                        placeholder: "••••••••",
                        required: true
                      ).mt(4)
                    end
                  end
          #{'        '}
                  button("Sign In", type: "submit")
                    .bg("blue-600")
                    .text_color("white")
                    .w("full")
                    .py(3)
                    .rounded("lg")
                    .hover("bg-blue-700")
                    .transition
                end
              end
            end.max_w("md").mx("auto")
          end
        RUBY
      }
    ]
  end
end
