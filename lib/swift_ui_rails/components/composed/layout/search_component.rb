# frozen_string_literal: true

require_relative 'search_sanitizer'

module SwiftUIRails
  module Component
    module Composed
      module Layout
        # SearchComponent - Toolbar search functionality
        class SearchComponent < SwiftUIRails::Component::Base
          include SearchSanitizer
          
          # Props
          prop :search_url, type: String, default: "/search"
          prop :search_placeholder, type: String, default: "Search..."
          prop :responsive, type: [TrueClass, FalseClass], default: true
          prop :compact, type: [TrueClass, FalseClass], default: false
          
          swift_ui do
            if compact || responsive
              compact_search_widget
            else
              full_search_widget
            end
          end
          
          private
          
          def compact_search_widget
            button do
              span { "🔍" }
            end
            .p(2)
            .text_color("gray-400")
            .hover_text_color("gray-600")
            .rounded("md")
            .hover_bg("gray-100")
            .data(action: "click->toolbar#toggleSearch")
          end
          
          def full_search_widget
            form.flex.items_center
              .data(
                controller: "search",
                action: "submit->search#submit",
                "search-url-value": search_url
              ) do
              
              div.relative do
                input(
                  type: "search",
                  name: "q",
                  placeholder: search_placeholder,
                  maxlength: 255,  # Prevent overly long inputs
                  pattern: sanitized_search_pattern,  # HTML5 pattern validation
                  title: "Search terms (letters, numbers, spaces, and basic punctuation only)"
                )
                .w(64)
                .px(4)
                .py(2)
                .pr(10)
                .text_sm
                .border
                .border_color("gray-300")
                .rounded("lg")
                .focus_outline_none
                .focus_ring(2)
                .focus_ring_color("blue-500")
                .data(
                  "search-target": "input",
                  action: "input->search#handleInput blur->search#validateInput"
                )
                
                button(type: "submit") do
                  span { "🔍" }
                end
                .absolute
                .right(2)
                .top("50%")
                .transform("translate-y-1/2")
                .p(1)
                .text_color("gray-400")
                .hover_text_color("gray-600")
                .data("search-target": "submitButton")
                
                # Error message container
                div.hidden.absolute.top("full").left(0).mt(1).text_xs.text_color("red-600")
                  .data("search-target": "errorMessage") do
                  text("Invalid search characters detected")
                end
              end
            end
          end
          
          # Safe search pattern - only allow alphanumeric, spaces, and safe punctuation
          def sanitized_search_pattern
            "[a-zA-Z0-9\\s\\-_.,!?'\"()]*"
          end
          
          def mobile_search_section
            div.px(4).py(3).border_b.border_color("gray-100") do
              text("Search").font_weight("medium").text_color("gray-900").text_sm.mb(2)
              full_search_widget
            end
          end
        end
      end
    end
  end
end