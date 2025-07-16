# frozen_string_literal: true

class PlaygroundController < ApplicationController
  layout "playground"
  
  # Skip CSRF for IntelliSense API endpoints and preview
  skip_before_action :verify_authenticity_token, only: [:completions, :signatures, :preview]

  def index
    @playground = PlaygroundComponent.new(
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

  def completions
    prefix = params[:prefix] || ""
    context = params[:context] || ""
    line = params[:line] || 1
    column = params[:column] || 1
    
    position = {
      "lineNumber" => line.to_i,
      "column" => column.to_i
    }
    
    begin
      service = Playground::CompletionService.new(context, position)
      completions = service.generate_completions
      
      render json: {
        completions: completions.map do |completion|
          {
            label: completion[:label],
            kind: completion[:kind],
            detail: completion[:detail],
            documentation: completion[:documentation],
            insertText: completion[:insertText],
            snippet: completion[:insertTextFormat] == 2
          }
        end
      }
    rescue => e
      Rails.logger.error "Completion error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { completions: [] }
    end
  end

  def signatures
    render json: {
      signatures: [
        {
          label: "text(content: String)",
          documentation: "Display text content with styling options",
          parameters: [
            { label: "content", documentation: "The text to display" }
          ]
        },
        {
          label: "button(title: String)",
          documentation: "Create an interactive button",
          parameters: [
            { label: "title", documentation: "The button text" }
          ]
        },
        {
          label: "vstack(spacing: Integer, align: Symbol, justify: Symbol)",
          documentation: "Create a vertical stack layout",
          parameters: [
            { label: "spacing", documentation: "Space between elements" },
            { label: "align", documentation: "Horizontal alignment" },
            { label: "justify", documentation: "Vertical alignment" }
          ]
        },
        {
          label: "hstack(spacing: Integer, align: Symbol, justify: Symbol)",
          documentation: "Create a horizontal stack layout",
          parameters: [
            { label: "spacing", documentation: "Space between elements" },
            { label: "align", documentation: "Vertical alignment" },
            { label: "justify", documentation: "Horizontal alignment" }
          ]
        }
      ]
    }
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
          # Test justify: :between layout
          text("Layout Test: justify: :between")
            .font_weight("semibold")
            .text_color("gray-800")
      #{'    '}
          hstack(justify: :between) do
            text("Left Text")
              .font_weight("bold")
              .text_color("blue-600")
            text("Right Text")
              .font_weight("bold")
              .text_color("red-600")
          end
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
              text("Built with SwiftUI Rails DSL")
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
      { 
        name: "Text", 
        category: "Basic", 
        code: 'text("Your text here")
  .font_size("xl")
  .font_weight("semibold")
  .text_color("gray-800")
  .text_align("left")
  .leading("relaxed")' 
      },
      { 
        name: "Button", 
        category: "Basic", 
        code: 'button("Click Me")
  .bg("blue-500")
  .text_color("white")
  .px(4).py(2)
  .rounded("lg")
  .data(action: "click->controller#method")' 
      },
      { name: "Image", category: "Basic", code: 'image(src: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop", alt: "Beautiful sunflower")' },
      { 
        name: "VStack", 
        category: "Layout", 
        code: <<~'RUBY'
          vstack(spacing: 16) do
            text("First Item")
            text("Second Item")
            text("Third Item")
          end
        RUBY
      },
      { 
        name: "HStack", 
        category: "Layout", 
        code: <<~'RUBY'
          hstack(justify: :between) do
            text("Left")
            text("Right")
          end
        RUBY
      },
      { 
        name: "Card", 
        category: "Components", 
        code: <<~'RUBY'
          card(elevation: 2) do
            text("Card Title")
              .font_size("xl")
              .font_weight("bold")
            text("Card content goes here")
              .text_color("gray-600")
          end
        RUBY
      },
      { 
        name: "List", 
        category: "Components", 
        code: <<~'RUBY'
          vstack(spacing: 8) do
            (1..5).each do |i|
              button("Click Me Item #{i}")
                .bg("blue")
                .text_color("white")
                .px(4).py(2)
                .rounded("lg")
                .hover("bg-blue-600")
                .data(action: "click->controller#method")
            end
          end
        RUBY
      },
      { 
        name: "Grid", 
        category: "Layout", 
        code: <<~'RUBY'
          grid(columns: 3, spacing: 16) do
            (1..6).each do |i|
              card(elevation: 1) do
                text("Grid Item #{i}")
              end
            end
          end
        RUBY
      },
      { 
        name: "Form", 
        category: "Forms", 
        code: <<~'RUBY'
          form(action: "#", method: :post) do
            textfield(name: "email", placeholder: "Enter email")
              .w("full")
              .mb(4)
            button("Submit", type: "submit")
              .bg("blue-500")
              .text_color("white")
              .px(4).py(2)
              .rounded("lg")
          end
        RUBY
      },
      { name: "TextField", category: "Forms", code: 'textfield(name: "email", placeholder: "Enter email")' },
      { 
        name: "Simple Table", 
        category: "Tables", 
        code: <<~'RUBY'
          table do
            thead do
              tr do
                th.px(4).py(2).text_left { text("Name") }
                th.px(4).py(2).text_left { text("Role") }
                th.px(4).py(2).text_left { text("Status") }
              end
            end
            tbody do
              tr.border_t do
                td.px(4).py(2) { text("John Doe") }
                td.px(4).py(2) { text("Admin") }
                td.px(4).py(2) { text("Active") }
              end
              tr.border_t do
                td.px(4).py(2) { text("Jane Smith") }
                td.px(4).py(2) { text("User") }
                td.px(4).py(2) { text("Inactive") }
              end
            end
          end
        RUBY
      },
      { 
        name: "Data Table", 
        category: "Tables", 
        code: <<~'RUBY'
          data_table(
            title: "Users",
            data: [
              { name: "John", role: "Admin", status: "Active" },
              { name: "Jane", role: "User", status: "Inactive" }
            ],
            columns: [
              { key: :name, label: "Name" },
              { key: :role, label: "Role", format: :badge },
              { key: :status, label: "Status", format: :badge }
            ]
          )
        RUBY
      },
      { 
        name: "Table", 
        category: "Tables", 
        code: <<~'RUBY'
          table do
            thead do
              tr do
                th { text("Header") }
              end
            end
            tbody do
              tr do
                td { text("Data") }
              end
            end
          end
        RUBY
      }
    ]
  end

  def code_examples
    # Load dogfood examples
    require Rails.root.join("examples/playground_dogfood_examples.rb")
    dogfood_examples = PlaygroundDogfoodExamples.all_examples
    
    [
      {
        name: "Layout Demo",
        description: "HStack justification examples (start, center, between, etc.)",
        code: dogfood_examples[:layout_demo]
      },
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
      },
      {
        name: "Simple Table",
        description: "Basic table with headers and rows",
        code: dogfood_examples[:simple_table]
      },
      {
        name: "Data Table",
        description: "Advanced table with sorting, search, and rich formatting",
        code: dogfood_examples[:data_table]
      },
      {
        name: "Sales Report",
        description: "Sales table with currency formatting and growth indicators",
        code: dogfood_examples[:sales_table]
      },
      {
        name: "Employee Directory",
        description: "Employee table with avatars, badges, and pagination",
        code: dogfood_examples[:employee_table]
      }
    ]
  end
end