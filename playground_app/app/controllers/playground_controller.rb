# frozen_string_literal: true

require_relative "../../examples/playground_dogfood_examples"

class PlaygroundController < ApplicationController
  # Skip CSRF for read-only signature lookup only. Preview and completions still require CSRF.
  skip_before_action :verify_authenticity_token, only: [:signatures]
  before_action :validate_same_origin, only: [:preview]

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

      begin
        # Render the component
        @rendered_html = component_class.new.call.to_s
      ensure
        # Clean up the temporary constant - always run even if rendering fails
        Object.send(:remove_const, temp_class_name) if Object.const_defined?(temp_class_name, false)
      end

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
      # We assume Playground::CompletionService exists from the V1 implementation
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

  # Allowlist of component name patterns safe for constantize
  ALLOWED_COMPONENT_PATTERNS = [
    /\A[A-Z][a-zA-Z0-9]*Component\z/,                    # SimpleComponent
    /\ASwiftUIRails::[A-Z][a-zA-Z0-9:]*Component\z/,     # SwiftUIRails::*Component
    /\ASwiftUIRails::Component::[A-Z][a-zA-Z0-9:]*\z/,   # SwiftUIRails::Component::*
    /\A[A-Z][a-zA-Z0-9]*::[A-Z][a-zA-Z0-9]*Component\z/  # Namespace::SimpleComponent
  ].freeze

  def component_schema
    component_name = params[:component]

    # Security: Validate component name against allowlist BEFORE constantize
    unless component_name.present? && ALLOWED_COMPONENT_PATTERNS.any? { |pattern| pattern.match?(component_name) }
      render json: { error: "Invalid component name format" }, status: :bad_request
      return
    end

    begin
      klass = component_name.constantize

      # Double-check inheritance after constantize
      unless klass < SwiftUIRails::Component::Base || klass < ViewComponent::Base
        render json: { error: "Invalid component class" }, status: :bad_request
        return
      end
      
      # Extract props
      props = if klass.respond_to?(:swift_props)
                klass.swift_props.map do |name, config|
                  {
                    name: name,
                    type: config[:type].to_s,
                    required: config[:required],
                    default: config[:default]
                  }
                end
              else
                []
              end
              
      # Render preview if available
      preview_html = if klass.respond_to?(:render_preview)
                       begin
                         klass.render_preview
                       rescue => e
                         "Preview error: #{e.message}"
                       end
                     else
                       nil
                     end
              
      render json: {
        name: klass.name,
        props: props,
        preview_html: preview_html
      }
    rescue NameError
      render json: { error: "Component not found" }, status: :not_found
    end
  end

  def parse_component
    code = params[:code]
    component_name = params[:component_name]
    
    # Simple parser to extract props from Component.new(...)
    # This is an MVP implementation using Regex
    # A production version would use Ripper or the Parser gem
    
    props = {}
    
    # Find the component instantiation
    # Matches: ComponentName.new( arg1: val1, arg2: val2 )
    if code =~ /#{Regexp.escape(component_name)}\.new\s*\((.*?)\)/m
      args_string = $1
      
      # Split by comma, handling potential commas inside quotes
      # This is a naive split, but works for simple cases
      # A better regex would be: /,\s*(?=(?:[^"]*"[^"]*")*[^"]*$)/
      args = args_string.scan(/([a-z_0-9]+):\s*(.*?)(?:,|$)/m)
      
      args.each do |key, value|
        value = value.strip
        
        # Parse value type
        parsed_value = case value
                       when /^"(.*)"$/ then $1 # String
                       when /^'(.*)'$/ then $1 # String
                       when /^:(\w+)$/ then $1 # Symbol
                       when "true" then true
                       when "false" then false
                       when /^\d+$/ then value.to_i # Integer
                       when /^\d+\.\d+$/ then value.to_f # Float
                       else value # Fallback/Complex expression
                       end
                       
        props[key] = parsed_value
      end
    end
    
    render json: { props: props }
  end

  def form_submit_demo
    # Standard Rails Controller Action
    name = ERB::Util.html_escape(params[:name])
    email = ERB::Util.html_escape(params[:email])

    # Render a success message via Turbo Stream
    render turbo_stream: turbo_stream.update("form-feedback", html: <<~HTML.html_safe)
      <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative" role="alert">
        <strong class="font-bold">Success!</strong>
        <span class="block sm:inline">Controller received: #{name} (#{email})</span>
      </div>
    HTML
  end

  private

  # Validates that the request originates from the same origin to prevent CSRF
  def validate_same_origin
    return if Rails.env.development? || Rails.env.test?

    origin = request.headers["Origin"] || request.headers["Referer"]

    # Reject requests with no origin header in production (potential CSRF)
    if origin.blank?
      render json: { error: "Origin header required" }, status: :forbidden
      return
    end

    uri = URI.parse(origin)
    expected_host = request.host

    unless uri.host == expected_host
      render json: { error: "Invalid origin" }, status: :forbidden
    end
  rescue URI::InvalidURIError
    render json: { error: "Invalid origin" }, status: :forbidden
  end

  def contains_dangerous_code?(code)
    # Limit input length to prevent ReDoS
    return true if code.length > 10_000

    dangerous_patterns = [
      /\b(eval|exec|system|backticks|spawn|fork|load|require|open|File|Dir|IO)\b/,
      /`[^`]*`/,           # Fixed: non-greedy backtick matching
      /%x\{[^}]*\}/,       # Fixed: non-greedy %x{} matching
      /%x\[[^\]]*\]/,      # %x[] variant
      /%x\([^)]*\)/,       # %x() variant
      /\$\w+/,
      /@@\w+/,
      /::/,
      /\.send\b/,
      /\.public_send\b/,
      /\.instance_eval\b/,
      /\.class_eval\b/,
      /\.module_eval\b/,
      /Kernel\./,
      /Object\./,
      /Module\./,
      /Class\./
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
          text("Welcome to SwiftUI Rails Playground V2!")
            .font_size("3xl")
            .font_weight("bold")
            .text_color("blue-600")
      
          text("This entire UI is built with the DSL.")
            .text_color("gray-600")
            .font_size("lg")
      
          card(elevation: 2) do
            vstack(spacing: 8) do
              hstack(justify: :between) do
                text("Status")
                  .font_weight("medium")
                badge("Live")
                  .bg("green-100")
                  .text_color("green-800")
              end
              
              divider
              
              text("Edit the code on the left to see changes instantly.")
                .text_color("gray-500")
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
          class_name: "SwiftUIRails::Component::TextComponent", # Example if it existed
          code: 'text("Your text here")
    .font_size("xl")
    .font_weight("semibold")
    .text_color("gray-800")' 
        },
        # ... (Update others if they have real classes)
        { 
          name: "Card", 
          category: "Components", 
          class_name: "CardComponent", # Assuming this exists in the app or lib
          code: <<~'RUBY'
            card(elevation: 2) do
              text("Card Title").font_weight("bold")
              text("Card content")
            end
          RUBY
        },
        # ...
      ]
    end
  def code_examples
    require_relative "../../examples/playground_dogfood_examples"
    require_relative "../../examples/composite_form_example"
    require_relative "../../examples/world_class_demo"
    require_relative "../../examples/reactive_gallery_demo"
    require_relative "../../examples/standard_rails_form_demo"
    require_relative "../../examples/modern_crud_demo"
    require_relative "../../examples/torture_test_demo"
    require_relative "../../examples/omni_browser_demo"
    dogfood_examples = PlaygroundDogfoodExamples.all_examples
    
    [
      {
        name: "OmniBrowser",
        description: "Universal CRUD (Miller Columns)",
        code: OmniBrowserDemo::APP_UI
      },
      {
        name: "Crypto Trader",
        description: "Complex Dashboard & Charts",
        code: TortureTestDemo::CRYPTO_UI
      },
      {
        name: "Kanban Board",
        description: "Horizontal Scroll & Drag Logic",
        code: TortureTestDemo::KANBAN_UI
      },
      {
        name: "Modern CRUD",
        description: "Reactive Form + Database Logic",
        code: ModernCrudDemo::APP_UI
      },
      {
        name: "Reactive Gallery",
        description: "Live State Binding Demo",
        code: ReactiveGalleryDemo::APP_UI
      },
      {
        name: "Standard Rails Form",
        description: "Submit to Rails Controller",
        code: StandardRailsFormDemo::APP_UI
      },
      {
        name: "World Class App",
        description: "Navigation, Virtualization, and Context",
        code: WorldClassDemo::APP_UI
      },
      {
        name: "Settings UI (Composite)",
        description: "iOS-style Settings with List and Section",
        code: CompositeFormExample::SETTINGS_UI
      },
      {
        name: "Product Grid",
        description: "E-commerce product grid",
        code: dogfood_examples[:product_grid]
      },
      {
        name: "Dashboard Stats",
        description: "Analytics dashboard",
        code: dogfood_examples[:dashboard_stats]
      },
      {
        name: "Pricing Cards",
        description: "Interactive pricing table",
        code: dogfood_examples[:pricing_cards]
      },
      {
        name: "Todo List",
        description: "Interactive todo list",
        code: dogfood_examples[:todo_list]
      },
      {
        name: "Navigation Bar",
        description: "Responsive navbar",
        code: dogfood_examples[:navbar]
      },
      {
        name: "Layout Demo",
        description: "Justification examples",
        code: dogfood_examples[:layout_demo]
      },
      {
        name: "Data Table",
        description: "Advanced table with sorting",
        code: dogfood_examples[:data_table]
      }
    ]
  end
end