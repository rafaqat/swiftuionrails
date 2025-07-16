# frozen_string_literal: true

class ShowcaseController < ApplicationController
  def index
    # Main showcase page - overview of SwiftUI Rails DSL
  end
  
  def components
    # Showcase basic DSL components
    @examples = {
      text: {
        title: "Text Component",
        description: "Display styled text with chainable modifiers",
        code: <<~RUBY
          text("Hello, SwiftUI Rails!")
            .font_size("2xl")
            .font_weight("bold")
            .text_color("blue-600")
            .italic
        RUBY
      },
      button: {
        title: "Button Component",
        description: "Interactive buttons with various styles",
        code: <<~RUBY
          button("Click Me")
            .bg("blue-600")
            .text_color("white")
            .px(6).py(3)
            .rounded("lg")
            .hover("bg-blue-700")
            .data(action: "click->controller#method")
        RUBY
      },
      card: {
        title: "Card Component",
        description: "Container with elevation and padding",
        code: <<~RUBY
          card(elevation: 2) do
            vstack(spacing: 4) do
              text("Card Title").font_size("lg").font_weight("semibold")
              text("Card content goes here").text_color("gray-600")
            end
          end
        RUBY
      }
    }
  end
  
  def layouts
    # Showcase layout components
    @examples = {
      vstack: {
        title: "Vertical Stack",
        description: "Stack elements vertically with spacing",
        code: <<~RUBY
          vstack(spacing: 4, alignment: :start) do
            text("First item")
            text("Second item")
            text("Third item")
          end
        RUBY
      },
      hstack: {
        title: "Horizontal Stack",
        description: "Stack elements horizontally",
        code: <<~RUBY
          hstack(spacing: 4, alignment: :center) do
            icon("star").text_color("yellow-500")
            text("5.0 Rating")
            spacer
            button("Rate").button_size(:sm)
          end
        RUBY
      },
      grid: {
        title: "Grid Layout",
        description: "Responsive grid with configurable columns",
        code: <<~RUBY
          grid(columns: 3, spacing: 4) do
            6.times do |i|
              card do
                text("Item #{i + 1}").text_center
              end
            end
          end
        RUBY
      }
    }
  end
  
  def forms
    # Showcase form components and patterns
    @examples = {
      textfield: {
        title: "Text Field",
        description: "Input fields with various types",
        code: <<~RUBY
          form do
            vstack(spacing: 4) do
              label("Email", for: "email")
              textfield(
                name: "email",
                type: "email",
                placeholder: "you@example.com"
              ).w("full")
              
              label("Password", for: "password")
              textfield(
                name: "password",
                type: "password",
                placeholder: "••••••••"
              ).w("full")
              
              button("Sign In", type: "submit")
                .bg("blue-600")
                .text_color("white")
                .w("full")
            end
          end
        RUBY
      }
    }
  end
  
  def animations
    # Showcase animations and transitions
    @examples = {
      hover: {
        title: "Hover Effects",
        description: "Smooth transitions on hover",
        code: <<~RUBY
          button("Hover Me")
            .bg("gray-200")
            .hover("bg-gray-300")
            .hover_scale("105")
            .transition
            .duration("200")
        RUBY
      },
      loading: {
        title: "Loading States",
        description: "Spinner and loading indicators",
        code: <<~RUBY
          hstack(spacing: 2) do
            spinner(size: :sm)
            text("Loading...").text_color("gray-600")
          end
        RUBY
      }
    }
  end
  
  def responsive
    # Showcase responsive design patterns
    @examples = {
      responsive_grid: {
        title: "Responsive Grid",
        description: "Grid that adapts to screen size",
        code: <<~RUBY
          grid(
            columns: { base: 1, sm: 2, lg: 3, xl: 4 },
            spacing: 4
          ) do
            products.each do |product|
              dsl_product_card(
                name: product.name,
                price: product.price,
                image_url: product.image
              )
            end
          end
        RUBY
      }
    }
  end
  
  def state_management
    # Showcase state management patterns
    @examples = {
      stimulus: {
        title: "Client-side State with Stimulus",
        description: "Manage UI state on the client",
        code: <<~RUBY
          div(data: { 
            controller: "toggle",
            toggle_open_value: false
          }) do
            button("Toggle Menu")
              .data(action: "click->toggle#toggle")
            
            div(data: { toggle_target: "content" })
              .hidden do
              text("Menu content here")
            end
          end
        RUBY
      },
      turbo_frames: {
        title: "Server State with Turbo Frames",
        description: "Partial page updates with server state",
        code: <<~RUBY
          turbo_frame_tag "counter" do
            text(@count)
            button_to "+", increment_path, method: :post
          end
        RUBY
      }
    }
  end
end