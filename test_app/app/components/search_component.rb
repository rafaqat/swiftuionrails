# frozen_string_literal: true
# Copyright 2025

class SearchComponent < SwiftUIRails::Component::Base
  prop :query, type: String, default: ""
  prop :results, type: Array, default: []
  prop :search_path, type: String, required: true
  prop :placeholder, type: String, default: "Search..."
  prop :show_results, type: [TrueClass, FalseClass], default: true
  prop :search_delay, type: Integer, default: 300 # Configurable delay in ms
  
  swift_ui do
    vstack(spacing: 4) do
      # Search form - works without JS
      form(action: search_path, method: :get, 
           data: { turbo_frame: "search_results" }) do
        hstack(spacing: 2) do
          div.relative.flex_1 do
            # Search icon
            icon("search", size: 20)
              .absolute
              .left(3)
              .top("50%")
              .transform("translateY(-50%)")
              .text_color("gray-400")
            
            # Input field
            textfield(
              name: "q",
              value: query,
              placeholder: placeholder,
              class: "pl-10 pr-4",
              data: { 
                # Progressive enhancement: Live search with Stimulus
                controller: "search",
                action: "input->search#debouncedSubmit",
                search_delay_value: search_delay.to_s
              }
            )
            .full_width
          end
          
          button("Search", type: "submit")
            .button_style(:primary)
        end
      end
      
      # Results in Turbo Frame
      if show_results
        turbo_frame_tag("search_results") do
          if results.any?
            vstack(spacing: 2) do
              text("Found #{results.count} results").text_sm.text_color("gray-600")
              
              div.border.corner_radius("lg").overflow_hidden do
                results.each_with_index do |result, index|
                  search_result_item(result, index: index)
                end
              end
            end
          elsif query.present?
            div.text_center.padding(8) do
              text("No results found for '#{query}'").text_color("gray-500")
            end
          end
        end
      end
    end
  end
  
  private
  
  def search_result_item(result, index: 0)
    div(class: index > 0 ? "border-t" : "") do
      link(destination: result[:url] || "#") do
        div.padding(4).hover_background("gray-50") do
          vstack(spacing: 1) do
            text(result[:title] || result.to_s)
              .font_weight("medium")
              .text_color("gray-900")
            
            if result[:description]
              text(result[:description])
                .text_sm
                .text_color("gray-600")
                .line_clamp(2)
            end
          end
        end
      end
    end
  end
end
# Copyright 2025
