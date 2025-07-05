# frozen_string_literal: true

class ProductFilterComponent < SwiftUIRails::Component::Base
  prop :current_filters, type: Hash, default: {}
  prop :filter_options, type: Hash, required: true
  prop :products_path, type: String, required: true, validate: :url
  
  swift_ui do
    form(action: products_path, method: :get, data: { turbo_frame: "products" }) do
      vstack(spacing: 4) do
        text("Filter Products").font_size("lg").font_weight("semibold").margin_bottom(4)
        
        # Each filter type gets its own select field
        filter_options.each do |filter_type, options|
          vstack(spacing: 2) do
            label(filter_type.to_s.humanize, for: "filter_#{filter_type}")
              .text_sm
              .font_weight("medium")
              .text_color("gray-700")
            
            select(
              name: "filters[#{ERB::Util.html_escape(filter_type)}]",
              id: "filter_#{ERB::Util.html_escape(filter_type)}",
              class: "w-full rounded-md border-gray-300",
              data: { turbo_submits_with: "change" }
            ) do
              option("All #{filter_type.to_s.pluralize.humanize}", value: "")
              options.each do |option_value, option_label|
                option(
                  option_label, 
                  value: option_value,
                  selected: current_filters[filter_type] == option_value
                )
              end
            end
          end
        end
        
        # Submit button (optional since we auto-submit on change)
        button("Apply Filters", type: "submit")
          .button_style(:primary)
          .margin_top(4)
          .full_width
      end
    end
  end
end
# Copyright 2025
