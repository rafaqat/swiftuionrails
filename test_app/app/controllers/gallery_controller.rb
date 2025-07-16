# frozen_string_literal: true

class GalleryController < ApplicationController
  def index
    @components = [
      {
        name: "Counter",
        description: "Interactive counter with Stimulus",
        component: CounterComponent.new(initial_count: 0, step: 1, counter_label: "Demo Counter")
      },
      {
        name: "Product Card", 
        description: "E-commerce product display",
        component: nil, # We'll render inline DSL
        dsl_code: <<~RUBY
          swift_ui do
            dsl_product_card(
              name: "MacBook Pro 14\"",
              price: "1,999",
              image_url: "/images/product-placeholder.png",
              variant: "Space Gray",
              show_cta: true,
              cta_text: "Add to Cart",
              elevation: 2
            )
          end
        RUBY
      },
      {
        name: "Loading States",
        description: "Various loading indicators",
        dsl_code: <<~RUBY
          swift_ui do
            vstack(spacing: 6) do
              # Simple spinner
              hstack(spacing: 2) do
                spinner(size: :md)
                text("Loading...").text_color("gray-600")
              end
              
              # Button with loading state
              button("Save")
                .bg("blue-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("lg")
                .disabled
                .opacity(75) do
                hstack(spacing: 2) do
                  spinner(size: :sm, spinner_color: "white")
                  text("Saving...")
                end
              end
              
              # Card skeleton
              card do
                vstack(spacing: 3) do
                  div.h(4).bg("gray-200").rounded("md").animate("pulse")
                  div.h(3).bg("gray-200").rounded("md").w("2/3").animate("pulse")
                  div.h(20).bg("gray-200").rounded("md").mt(2).animate("pulse")
                end
              end
            end
          end
        RUBY
      },
      {
        name: "Form Components",
        description: "Input fields and form elements",
        dsl_code: <<~RUBY
          swift_ui do
            form do
              vstack(spacing: 4, alignment: :start) do
                # Text input
                vstack(spacing: 1, alignment: :start) do
                  label("Username", for: "username").font_weight("medium")
                  textfield(
                    name: "username",
                    placeholder: "Enter username"
                  ).w("full")
                end
                
                # Select dropdown
                vstack(spacing: 1, alignment: :start) do
                  label("Country", for: "country").font_weight("medium")
                  select(name: "country").w("full") do
                    option("", "Select a country")
                    option("us", "United States")
                    option("ca", "Canada")
                    option("uk", "United Kingdom")
                  end
                end
                
                # Checkbox
                hstack(spacing: 2) do
                  input(type: "checkbox", id: "terms", name: "terms")
                  label("I agree to the terms", for: "terms")
                end
                
                # Submit button
                button("Submit", type: "submit")
                  .bg("blue-600")
                  .text_color("white")
                  .px(6).py(2)
                  .rounded("lg")
                  .mt(4)
              end
            end
          end
        RUBY
      }
    ]
  end
  
  def show
    @component_name = params[:id]
    # Load specific component details
  end
end