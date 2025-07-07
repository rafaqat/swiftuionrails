# frozen_string_literal: true

require "ostruct"

module Playground
  class PlaygroundController < ApplicationController
    # CSRF protection is intentionally disabled for the playground execute endpoint
    # This is safe because:
    # 1. The playground is a development tool, not for production use
    # 2. No user data is modified - it only renders preview HTML
    # 3. The executor has strict code validation to prevent dangerous operations
    skip_before_action :verify_authenticity_token, only: [ :execute ]

    def index
      @initial_code = default_playground_code
      @snippets = load_snippets
    end

    def execute
      code = params[:code]
      session_id = params[:session_id] || SecureRandom.uuid

      # Execute DSL code safely with view context
      executor = SwiftUIRails::Playground::Executor.new(session_id, view_context)
      result = executor.execute(code)

      if result.success?
        render turbo_stream: [
          turbo_stream.update(
            "playground-preview",
            html: result.html
          ),
          turbo_stream.update(
            "playground-errors",
            html: ""
          )
        ]
      else
        render turbo_stream: turbo_stream.update(
          "playground-errors",
          partial: "playground/playground/error",
          locals: { error: OpenStruct.new(message: result.error) }
        )
      end
    rescue => e
      Rails.logger.error "Playground execution failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render turbo_stream: turbo_stream.update(
        "playground-errors",
        partial: "playground/playground/error",
        locals: { error: e }
      )
    end

    def export
      export_id = params[:id]
      export_data = retrieve_export(export_id)

      if export_data
        send_data export_data[:content],
                  filename: export_data[:filename],
                  type: "text/plain",
                  disposition: "attachment"
      else
        redirect_to playground_root_path, alert: "Export not found"
      end
    end

    private

    def default_playground_code
      <<~RUBY
        swift_ui do
          vstack(spacing: 16) do
            text("Welcome to SwiftUI Rails Playground! 🚀")
              .font_size("2xl")
              .font_weight("bold")
              .text_color("blue-600")
        #{'      '}
            text("Edit the code on the left to see live updates here")
              .text_color("gray-600")
        #{'      '}
            hstack(spacing: 8) do
              button("Primary")
                .bg("blue-500")
                .text_color("white")
                .px(4).py(2)
                .rounded("lg")
                .hover("bg-blue-600")
                .attr("data-action", "click->playground#showAlert")
        #{'        '}
              button("Secondary")
                .border(2)
                .border_color("gray-300")
                .px(4).py(2)
                .rounded("lg")
                .hover("bg-gray-50")
            end
        #{'    '}
            card(elevation: 2) do
              vstack(spacing: 4, alignment: :start) do
                text("Interactive Card")
                  .font_weight("semibold")
                  .text_size("lg")
        #{'          '}
                text("This card updates as you type. Try changing the elevation prop!")
                  .text_color("gray-600")
                  .text_size("sm")
              end
            end
            .p(6)
          end
          .p(8)
          .data(controller: "playground")
        end
      RUBY
    end

    def load_snippets
      # Load predefined code snippets organized by category
      [
        # Basic Components
        {
          id: "dsl_button",
          name: "DSL Button",
          description: "Basic button with styling",
          category: "Basic Components",
          code: dsl_button_snippet
        },
        {
          id: "dsl_card",
          name: "DSL Card",
          description: "Card component with elevation",
          category: "Basic Components",
          code: dsl_card_snippet
        },
        {
          id: "dsl_text",
          name: "DSL Text",
          description: "Text with various styles",
          category: "Basic Components",
          code: dsl_text_snippet
        },
        {
          id: "dsl_image",
          name: "DSL Image",
          description: "Image with styling",
          category: "Basic Components",
          code: dsl_image_snippet
        },

        # Layout Components
        {
          id: "dsl_vstack",
          name: "DSL VStack",
          description: "Vertical stack layout",
          category: "Layout",
          code: dsl_vstack_snippet
        },
        {
          id: "dsl_hstack",
          name: "DSL HStack",
          description: "Horizontal stack layout",
          category: "Layout",
          code: dsl_hstack_snippet
        },
        {
          id: "dsl_grid",
          name: "DSL Grid",
          description: "Responsive grid layout",
          category: "Layout",
          code: dsl_grid_snippet
        },
        {
          id: "dsl_spacer",
          name: "DSL Spacer & Divider",
          description: "Spacing utilities",
          category: "Layout",
          code: dsl_spacer_snippet
        },

        # Interactive Components
        {
          id: "counter",
          name: "Interactive Counter",
          description: "Counter with Stimulus",
          category: "Interactive",
          code: counter_snippet
        },
        {
          id: "toggle",
          name: "Toggle Switch",
          description: "Interactive toggle",
          category: "Interactive",
          code: toggle_snippet
        },
        {
          id: "dropdown",
          name: "Dropdown Menu",
          description: "Dropdown with Stimulus",
          category: "Interactive",
          code: dropdown_snippet
        },

        # Form Components
        {
          id: "form",
          name: "Complete Form",
          description: "Form with validation",
          category: "Forms",
          code: form_snippet
        },
        {
          id: "input_fields",
          name: "Input Fields",
          description: "Various input types",
          category: "Forms",
          code: input_fields_snippet
        },
        {
          id: "select_dropdown",
          name: "Select Dropdown",
          description: "Select with options",
          category: "Forms",
          code: select_dropdown_snippet
        },

        # Complex Examples
        {
          id: "product_card",
          name: "Product Card",
          description: "E-commerce product card",
          category: "Complex",
          code: product_card_snippet
        },
        {
          id: "grid",
          name: "Product Grid",
          description: "Grid of products",
          category: "Complex",
          code: grid_snippet
        },
        {
          id: "dashboard",
          name: "Dashboard Layout",
          description: "Stats dashboard",
          category: "Complex",
          code: dashboard_snippet
        }
      ]
    end

    def counter_snippet
      <<~RUBY
        swift_ui do
          vstack(spacing: 4) do
            text("0")
              .font_size("6xl")
              .font_weight("black")
              .data("counter-target": "count")
        #{'    '}
            hstack(spacing: 2) do
              button("-")
                .bg("red-500")
                .text_color("white")
                .px(4).py(2)
                .rounded("lg")
                .data(action: "click->counter#decrement")
        #{'      '}
              button("+")
                .bg("green-500")
                .text_color("white")
                .px(4).py(2)
                .rounded("lg")
                .data(action: "click->counter#increment")
            end
          end
          .data(
            controller: "counter",
            "counter-count-value": 0,
            "counter-step-value": 1
          )
        end
      RUBY
    end

    def form_snippet
      <<~RUBY
        swift_ui do
          form(action: "#", method: "post") do
            vstack(spacing: 6) do
              vstack(spacing: 2, alignment: :start) do
                label("Name", for_input: "name")
                  .font_weight("medium")
        #{'          '}
                textfield(
                  name: "name",
                  placeholder: "Enter your name",
                  required: true
                )
                .w("full")
                .px(3).py(2)
                .border
                .rounded("md")
              end
        #{'      '}
              vstack(spacing: 2, alignment: :start) do
                label("Email", for_input: "email")
                  .font_weight("medium")
        #{'          '}
                input(
                  type: "email",
                  name: "email",
                  placeholder: "you@example.com",
                  required: true
                )
                .w("full")
                .px(3).py(2)
                .border
                .rounded("md")
              end
        #{'      '}
              button("Submit", type: "submit")
                .bg("blue-600")
                .text_color("white")
                .px(6).py(3)
                .rounded("lg")
                .w("full")
                .hover("bg-blue-700")
            end
          end
          .max_w("md")
          .mx("auto")
        end
      RUBY
    end

    def grid_snippet
      <<~'RUBY'
        swift_ui do
          grid(columns: 3, spacing: 6, responsive: true) do
            5.times do |i|
              dsl_product_card(
                name: "Product #{i + 1}",
                price: "#{(i + 1) * 10}.99",
                image_url: "https://via.placeholder.com/200",
                variant: ["Blue", "Red", "Green", "Black", "White"][i],
                elevation: 2
              )
            end
          end
        end
      RUBY
    end

    def retrieve_export(export_id)
      # In a real app, this would retrieve from cache or database
      # For now, we'll regenerate based on current session
      nil
    end

    # Basic Component Snippets
    def dsl_button_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 4) do
            # Basic button
            button("Click Me")
              .bg("blue-500")
              .text_color("white")
              .px(4).py(2)
              .rounded("lg")
              .hover("bg-blue-600")

            # Outline button
            button("Secondary")
              .border(2)
              .border_color("gray-300")
              .px(4).py(2)
              .rounded("lg")
              .hover("bg-gray-50")

            # Icon button
            button("Download")
              .bg("green-500")
              .text_color("white")
              .px(6).py(3)
              .rounded("full")
              .shadow("lg")
              .hover("shadow-xl")
              .transition

            # Disabled button
            button("Disabled")
              .bg("gray-300")
              .text_color("gray-500")
              .px(4).py(2)
              .rounded("lg")
              .opacity(50)
              .cursor("not-allowed")
          end
        end
      RUBY
    end

    def dsl_card_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6) do
            # Basic card
            card(elevation: 1) do
              text("Basic Card")
                .font_weight("semibold")
                .mb(2)
              text("This is a simple card with elevation")
                .text_color("gray-600")
            end
            .p(6)

            # Card with header and footer
            card(elevation: 2) do
              vstack(spacing: 0) do
                # Header
                div do
                  text("Card Header")
                    .font_weight("bold")
                end
                .px(6).py(4)
                .border_b
                .bg("gray-50")

                # Content
                div do
                  text("Card content goes here")
                end
                .p(6)

                # Footer
                div do
                  hstack(justify: :end, spacing: 2) do
                    button("Cancel")
                      .text_color("gray-600")
                      .px(4).py(2)
                    button("Save")
                      .bg("blue-500")
                      .text_color("white")
                      .px(4).py(2)
                      .rounded("md")
                  end
                end
                .px(6).py(4)
                .border_t
                .bg("gray-50")
              end
            end

            # Colored card
            card(elevation: 3) do
              text("Premium Feature")
                .font_weight("bold")
                .text_color("white")
                .mb(2)
              text("Upgrade to unlock")
                .text_color("blue-100")
            end
            .p(6)
            .bg("gradient-to-r from-blue-500 to-purple-600")
          end
        end
      RUBY
    end

    def dsl_text_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 4, alignment: :start) do
            # Headings
            text("Heading 1")
              .font_size("4xl")
              .font_weight("bold")

            text("Heading 2")
              .font_size("2xl")
              .font_weight("semibold")
              .text_color("gray-800")

            text("Heading 3")
              .font_size("xl")
              .font_weight("medium")
              .text_color("gray-700")

            divider.my(4)

            # Body text
            text("Regular body text with normal weight")
              .text_color("gray-600")

            text("Emphasized text")
              .font_weight("semibold")
              .text_color("blue-600")

            text("Small caption text")
              .text_sm
              .text_color("gray-500")

            divider.my(4)

            # Special styles
            text("Monospace code")
              .font_family("mono")
              .bg("gray-100")
              .px(2).py(1)
              .rounded("md")

            text("Truncated very long text that should be cut off...")
              .max_w("xs")
              .truncate

            text("Uppercase Text")
              .uppercase
              .tracking("wide")
              .text_color("purple-600")
              .font_weight("bold")
          end
        end
      RUBY
    end

    def dsl_image_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6) do
            text("Image Examples")
              .font_size("xl")
              .font_weight("bold")
              .mb(4)

            # Basic image
            image(
              src: "https://via.placeholder.com/300x200",
              alt: "Placeholder image"
            )
            .rounded("lg")
            .shadow("md")

            # Circular avatar
            image(
              src: "https://via.placeholder.com/150",
              alt: "Avatar"
            )
            .w(20).h(20)
            .rounded("full")
            .ring(4)
            .ring_color("white")
            .shadow("xl")

            # Image with overlay
            div.relative do
              image(
                src: "https://via.placeholder.com/400x200",
                alt: "Hero image"
              )
              .rounded("lg")
              .brightness(75)

              div do
                text("Overlay Text")
                  .text_color("white")
                  .font_size("2xl")
                  .font_weight("bold")
              end
              .absolute
              .inset(0)
              .flex
              .items_center
              .justify_center
            end
          end
        end
      RUBY
    end

    # Layout Snippets
    def dsl_vstack_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 4) do
            text("VStack Example")
              .font_weight("bold")
              .mb(2)

            # Default center alignment
            vstack(spacing: 2) do
              div.w(32).h(8).bg("red-500").rounded
              div.w(24).h(8).bg("green-500").rounded
              div.w(16).h(8).bg("blue-500").rounded
            end
            .p(4)
            .border
            .rounded("lg")

            # Left alignment
            text("Left Aligned").text_sm.text_color("gray-600").mt(4)
            vstack(spacing: 2, alignment: :start) do
              div.w(32).h(8).bg("purple-500").rounded
              div.w(24).h(8).bg("pink-500").rounded
              div.w(16).h(8).bg("indigo-500").rounded
            end
            .p(4)
            .border
            .rounded("lg")

            # Right alignment
            text("Right Aligned").text_sm.text_color("gray-600").mt(4)
            vstack(spacing: 2, alignment: :end) do
              div.w(32).h(8).bg("yellow-500").rounded
              div.w(24).h(8).bg("orange-500").rounded
              div.w(16).h(8).bg("red-500").rounded
            end
            .p(4)
            .border
            .rounded("lg")
          end
        end
      RUBY
    end

    def dsl_hstack_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6) do
            text("HStack Examples")
              .font_weight("bold")
              .mb(2)

            # Basic horizontal stack
            hstack(spacing: 4) do
              div.w(16).h(16).bg("red-500").rounded("lg")
              div.w(16).h(16).bg("green-500").rounded("lg")
              div.w(16).h(16).bg("blue-500").rounded("lg")
            end

            # With spacer
            hstack(spacing: 4) do
              text("Left")
              spacer
              text("Right")
            end
            .p(4)
            .bg("gray-100")
            .rounded("lg")

            # Justified content
            hstack(spacing: 2) do
              button("Previous").px(3).py(1).text_sm.bg("gray-200").rounded

              hstack(spacing: 1) do
                (1..5).each do |i|
                  button(i.to_s)
                    .w(8).h(8)
                    .text_sm
                    .bg(i == 3 ? "blue-500" : "white")
                    .text_color(i == 3 ? "white" : "gray-700")
                    .border
                    .rounded
                end
              end

              button("Next").px(3).py(1).text_sm.bg("gray-200").rounded
            end

            # Vertical alignment
            hstack(spacing: 4, alignment: :center) do
              div.w(12).h(12).bg("purple-500").rounded
              div.w(12).h(20).bg("pink-500").rounded
              div.w(12).h(16).bg("indigo-500").rounded
            end
            .p(4)
            .border
            .rounded("lg")
          end
        end
      RUBY
    end

    def dsl_grid_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6) do
            text("Grid Layouts")
              .font_size("xl")
              .font_weight("bold")

            # Fixed columns
            text("3 Column Grid").text_sm.text_color("gray-600")
            grid(columns: 3, spacing: 4) do
              6.times do |i|
                div do
                  text("Item #{i + 1}")
                    .text_center
                end
                .p(4)
                .bg("blue-#{(i + 1) * 100}")
                .text_color("white")
                .rounded("lg")
              end
            end

            # Responsive grid
            text("Responsive Grid").text_sm.text_color("gray-600").mt(6)
            grid(columns: { base: 1, sm: 2, lg: 4 }, spacing: 4) do
              8.times do |i|
                card(elevation: 1) do
                  text("Card #{i + 1}")
                    .font_weight("semibold")
                end
                .p(4)
              end
            end

            # Auto-fit grid
            text("Auto-fit Grid").text_sm.text_color("gray-600").mt(6)
            grid(
              columns: "auto-fit",
              min_item_width: 200,
              spacing: 4
            ) do
              5.times do |i|
                div do
                  text("Flexible #{i + 1}")
                end
                .p(6)
                .bg("gradient-to-br from-purple-400 to-pink-400")
                .text_color("white")
                .rounded("lg")
              end
            end
          end
        end
      RUBY
    end

    def dsl_spacer_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 4) do
            text("Spacer & Divider Examples")
              .font_weight("bold")
              .mb(4)

            # Spacer in HStack
            card do
              hstack do
                text("Left aligned")
                spacer
                text("Right aligned")
              end
            end
            .p(4)

            # Spacer with min length
            card do
              hstack do
                text("Start")
                spacer(min_length: 100)
                text("End")
              end
            end
            .p(4)

            # Dividers
            vstack(spacing: 4) do
              text("Section 1")
              divider
              text("Section 2")
              divider.my(4).border_color("blue-300")
              text("Section 3 with custom divider")

              # Vertical divider in HStack
              hstack(spacing: 4) do
                text("Left")
                div.h(6).w(0).border_r.border_gray_300
                text("Right")
              end
            end
            .p(4)
            .bg("gray-50")
            .rounded("lg")
          end
        end
      RUBY
    end

    # Interactive Snippets
    def toggle_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6) do
            text("Interactive Toggles")
              .font_weight("bold")
              .mb(4)

            # Basic toggle
            hstack(spacing: 4) do
              label("Enable notifications", for_input: "notifications")
              input(
                type: "checkbox",
                id: "notifications",
                data: {
                  controller: "toggle",
                  action: "change->toggle#update"
                }
              )
              .w(4).h(4)
            end

            # Styled toggle switch
            div(data: { controller: "toggle-switch" }) do
              label.flex.items_center.cursor_pointer do
                input(
                  type: "checkbox",
                  data: { "toggle-switch-target": "input" }
                ).sr_only

                div do
                  div.transform.transition
                    .bg("white")
                    .w(5).h(5)
                    .rounded("full")
                    .shadow
                    .data("toggle-switch-target": "thumb")
                end
                .relative
                .w(11).h(6)
                .bg("gray-200")
                .rounded("full")
                .transition
                .data("toggle-switch-target": "track")

                span("Dark mode").ml(3)
              end
            end

            # Radio group
            vstack(spacing: 2, alignment: :start) do
              text("Choose option:").font_weight("medium").mb(2)

              ["Option A", "Option B", "Option C"].each do |option|
                label.flex.items_center do
                  input(
                    type: "radio",
                    name: "options",
                    value: option.downcase.gsub(" ", "_")
                  )
                  .mr(2)

                  text(option)
                end
                .cursor_pointer
                .p(2)
                .hover("bg-gray-50")
                .rounded
              end
            end
            .p(4)
            .border
            .rounded("lg")
          end
        end
      RUBY
    end

    def dropdown_snippet
      <<~'RUBY'
        swift_ui do
          div(data: { controller: "dropdown" }) do
            # Dropdown button
            button("Options")
              .bg("white")
              .border
              .px(4).py(2)
              .rounded("lg")
              .hover("bg-gray-50")
              .data(action: "click->dropdown#toggle")

            # Dropdown menu
            div do
              vstack(spacing: 0) do
                ["Edit", "Duplicate", "Archive", "Delete"].each do |action|
                  button(action)
                    .w("full")
                    .text_left
                    .px(4).py(2)
                    .hover("bg-gray-100")
                    .text_sm
                    .text_color(action == "Delete" ? "red-600" : "gray-700")
                end
              end
            end
            .absolute
            .mt(2)
            .w(48)
            .bg("white")
            .rounded("lg")
            .shadow("lg")
            .border
            .hidden
            .data("dropdown-target": "menu")
          end
          .relative
        end
      RUBY
    end

    # Form Snippets
    def input_fields_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6, alignment: :start) do
            # Text input
            vstack(spacing: 2, alignment: :start) do
              label("Username", for_input: "username")
                .font_weight("medium")
              textfield(
                name: "username",
                placeholder: "Enter username"
              )
              .w("full")
              .px(3).py(2)
              .border
              .rounded("md")
              .focus("ring-2 ring-blue-500 border-blue-500")
            end

            # Password input
            vstack(spacing: 2, alignment: :start) do
              label("Password", for_input: "password")
                .font_weight("medium")
              input(
                type: "password",
                name: "password",
                placeholder: "Enter password"
              )
              .w("full")
              .px(3).py(2)
              .border
              .rounded("md")
            end

            # Email with validation
            vstack(spacing: 2, alignment: :start) do
              label("Email", for_input: "email")
                .font_weight("medium")
              input(
                type: "email",
                name: "email",
                placeholder: "you@example.com",
                required: true
              )
              .w("full")
              .px(3).py(2)
              .border
              .rounded("md")
              .invalid("border-red-500")
            end

            # Textarea
            vstack(spacing: 2, alignment: :start) do
              label("Message", for_input: "message")
                .font_weight("medium")
              div do
                # Using raw HTML for textarea
                "<textarea name='message' rows='4' class='w-full px-3 py-2 border rounded-md' placeholder='Type your message...'></textarea>".html_safe
              end
            end

            # Number input
            vstack(spacing: 2, alignment: :start) do
              label("Quantity", for_input: "quantity")
                .font_weight("medium")
              input(
                type: "number",
                name: "quantity",
                min: 1,
                max: 100,
                value: 1
              )
              .w(32)
              .px(3).py(2)
              .border
              .rounded("md")
            end
          end
          .max_w("md")
        end
      RUBY
    end

    def select_dropdown_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6, alignment: :start) do
            # Basic select
            vstack(spacing: 2, alignment: :start) do
              label("Country", for_input: "country")
                .font_weight("medium")
              select(name: "country") do
                option("", "Choose a country")
                option("us", "United States")
                option("uk", "United Kingdom")
                option("ca", "Canada")
                option("au", "Australia")
              end
              .w("full")
              .px(3).py(2)
              .border
              .rounded("md")
              .bg("white")
            end

            # Select with groups
            vstack(spacing: 2, alignment: :start) do
              label("Product Category", for_input: "category")
                .font_weight("medium")
              select(name: "category") do
                option("", "Select category")
                "<optgroup label='Electronics'>".html_safe
                option("phones", "Phones")
                option("laptops", "Laptops")
                option("tablets", "Tablets")
                "</optgroup>".html_safe
                "<optgroup label='Clothing'>".html_safe
                option("shirts", "Shirts")
                option("pants", "Pants")
                option("shoes", "Shoes")
                "</optgroup>".html_safe
              end
              .w("full")
              .px(3).py(2)
              .border
              .rounded("md")
              .bg("white")
            end

            # Multi-select (using size attribute)
            vstack(spacing: 2, alignment: :start) do
              label("Skills", for_input: "skills")
                .font_weight("medium")
              text("Hold Ctrl/Cmd to select multiple")
                .text_sm
                .text_color("gray-500")
              select(name: "skills", multiple: true, size: 5) do
                option("ruby", "Ruby")
                option("javascript", "JavaScript")
                option("python", "Python")
                option("go", "Go")
                option("rust", "Rust")
              end
              .w("full")
              .px(3).py(2)
              .border
              .rounded("md")
              .bg("white")
            end
          end
        end
      RUBY
    end

    # Complex Examples
    def product_card_snippet
      <<~'RUBY'
        swift_ui do
          dsl_product_card(
            name: "Premium Headphones",
            price: "299.99",
            image_url: "https://via.placeholder.com/400x400",
            variant: "Midnight Black",
            elevation: 2
          )
          .max_w("sm")
          .mx("auto")
        end
      RUBY
    end

    def dashboard_snippet
      <<~'RUBY'
        swift_ui do
          vstack(spacing: 6) do
            # Header
            text("Dashboard")
              .font_size("2xl")
              .font_weight("bold")
              .mb(4)

            # Stats grid
            grid(columns: { base: 1, sm: 2, lg: 4 }, spacing: 4) do
              # Stat cards
              [
                { label: "Total Users", value: "1,234", change: "+12%" },
                { label: "Revenue", value: "$45,678", change: "+23%" },
                { label: "Orders", value: "89", change: "-5%" },
                { label: "Conversion", value: "3.4%", change: "+2%" }
              ].each do |stat|
                card(elevation: 1) do
                  vstack(spacing: 2, alignment: :start) do
                    text(stat[:label])
                      .text_sm
                      .text_color("gray-600")

                    hstack(spacing: 2, alignment: :end) do
                      text(stat[:value])
                        .font_size("2xl")
                        .font_weight("bold")

                      text(stat[:change])
                        .text_sm
                        .text_color(stat[:change].start_with?("+") ? "green-600" : "red-600")
                        .font_weight("medium")
                    end
                  end
                end
                .p(4)
              end
            end

            # Chart placeholder
            card(elevation: 1) do
              vstack(spacing: 4) do
                text("Revenue Over Time")
                  .font_weight("semibold")

                div do
                  text("Chart goes here")
                    .text_color("gray-400")
                end
                .h(64)
                .bg("gray-50")
                .rounded("lg")
                .flex
                .items_center
                .justify_center
              end
            end
            .p(6)
            .mt(6)
          end
        end
      RUBY
    end
  end
end
