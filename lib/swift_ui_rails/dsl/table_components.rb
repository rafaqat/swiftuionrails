# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # High-level table components for SwiftUI Rails DSL
    # Provides SwiftUI-inspired declarative table API
    module TableComponents
      # High-level data table with sorting, pagination, and rich formatting
      def data_table(data:, columns:, **options)
        # Extract options
        title = options[:title]
        add_button = options[:add_button]
        sortable = options.fetch(:sortable, true)
        paginate = options.fetch(:paginate, false)
        per_page = options[:per_page] || 10
        current_page = options[:current_page] || 1
        total_count = options[:total_count] || data.size
        search = options[:search]
        empty_message = options[:empty_message] || "No data available"
        table_class = options[:table_class] || "min-w-full divide-y divide-gray-200"
        container_class = options[:container_class] || ""
        
        # Main container
        div(class: container_class) do
          card(elevation: options[:elevation] || 2) do
            # Header section with title and add button
            if title || add_button
              div(class: "px-6 py-4 border-b") do
                hstack(justify: :between) do
                  if title
                    h2(class: "text-xl font-semibold text-gray-900") { text(title) }
                  else
                    div # Empty div for spacing
                  end
                  
                  if add_button
                    if add_button.is_a?(Hash)
                      link(add_button[:text] || "Add", destination: add_button[:destination] || "#") do
                        button { text(add_button[:text] || "Add") }
                          .bg("blue-600")
                          .text_color("white")
                          .px(4).py(2)
                          .rounded("md")
                          .font_weight("medium")
                          .hover("bg-blue-700")
                      end
                    end
                  end
                end
              end
            end
            
            # Search bar
            if search
              div(class: "px-6 py-4 border-b") do
                textfield(
                  placeholder: search[:placeholder] || "Search...",
                  value: search[:value] || "",
                  name: search[:name] || "search",
                  class: "w-full px-4 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                )
              end
            end
            
            # Table container
            div(class: "overflow-x-auto") do
              if data.empty?
                # Empty state
                div(class: "text-center py-12") do
                  text(empty_message).text_color("gray-500")
                end
              else
                # Render table using lower-level table methods
                table(class: table_class) do
                  # Table header
                  thead(class: "bg-gray-50 border-b") do
                    tr do
                      columns.each do |column|
                        th(class: column[:header_class] || "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                          if sortable && column[:sortable]
                            button(class: "group inline-flex items-center") do
                              text(column[:label])
                              span(class: "ml-2 text-gray-400") { text("↕") }
                            end
                          else
                            text(column[:label])
                          end
                        end
                      end
                    end
                  end
                  
                  # Table body
                  tbody(class: "bg-white divide-y divide-gray-200") do
                    data.each do |row|
                      tr(class: "hover:bg-gray-50") do
                        columns.each do |column|
                          td(class: column[:cell_class] || "px-6 py-4 whitespace-nowrap") do
                            render_table_cell(row, column)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            
            # Pagination
            if paginate && !data.empty?
              render_pagination(
                current_page: current_page,
                per_page: per_page,
                total_count: total_count
              )
            end
          end
        end
      end
      
      # Simple table for basic use cases
      def simple_table(headers:, rows:, **options)
        div(class: options[:container_class] || "") do
          div(class: "overflow-x-auto") do
            table(class: options[:table_class] || "min-w-full") do
              if headers.any?
                thead do
                  tr do
                    headers.each do |header|
                      th(class: "px-4 py-2 text-left") { text(header) }
                    end
                  end
                end
              end
              
              tbody do
                rows.each do |row|
                  tr(class: "border-t") do
                    row.each do |cell|
                      td(class: "px-4 py-2") { text(cell) }
                    end
                  end
                end
              end
            end
          end
        end
      end
      
      # Table-related HTML elements (for backwards compatibility)
      def table(**attrs, &block)
        create_element(:table, nil, **attrs, &block)
      end

      def thead(**attrs, &block)
        create_element(:thead, nil, **attrs, &block)
      end

      def tbody(**attrs, &block)
        create_element(:tbody, nil, **attrs, &block)
      end

      def tr(**attrs, &block)
        create_element(:tr, nil, **attrs, &block)
      end

      def td(**attrs, &block)
        create_element(:td, nil, **attrs, &block)
      end

      def th(**attrs, &block)
        create_element(:th, nil, **attrs, &block)
      end
      
      private
      
      def render_table_cell(row, column)
        value = get_nested_value(row, column[:key])
        
        case column[:format]
        when :badge
          render_badge(value, column[:badge_map])
        when :avatar_with_text
          render_avatar_with_text(row, column)
        when :currency
          text(format_currency(value, column[:currency] || "$"))
        when :date
          text(format_date(value, column[:date_format]))
        when :actions
          render_actions(row, column[:actions] || [])
        when :custom
          if column[:render]
            instance_exec(value, row, &column[:render])
          else
            text(value.to_s)
          end
        else
          text(value.to_s)
        end
      end
      
      def get_nested_value(obj, key)
        if key.is_a?(Symbol) || key.is_a?(String)
          obj[key] || obj[key.to_s] || obj[key.to_sym]
        elsif key.is_a?(Array)
          # Support nested keys like [:user, :name]
          key.reduce(obj) { |o, k| o ? (o[k] || o[k.to_s] || o[k.to_sym]) : nil }
        elsif key.respond_to?(:call)
          # Support lambda/proc for computed values
          key.call(obj)
        else
          nil
        end
      end
      
      def render_badge(value, badge_map = nil)
        badge_map ||= {
          "Active" => "bg-green-100 text-green-800",
          "Inactive" => "bg-gray-100 text-gray-800",
          "Pending" => "bg-yellow-100 text-yellow-800",
          "Error" => "bg-red-100 text-red-800"
        }
        
        badge_class = badge_map[value] || "bg-gray-100 text-gray-800"
        
        span(class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " + badge_class) do
          text(value.to_s)
        end
      end
      
      def render_avatar_with_text(row, column)
        name = get_nested_value(row, column[:key])
        initials = name.to_s.split.map(&:first).join.upcase
        
        hstack(spacing: 3) do
          # Avatar
          div(class: "h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center") do
            span(class: "text-sm font-medium text-gray-600") do
              text(initials)
            end
          end
          
          # Name
          text(name).font_weight("medium").text_color("gray-900")
        end
      end
      
      def render_actions(row, actions)
        hstack(spacing: 2) do
          actions.each do |action|
            if action.is_a?(Hash)
              link(action[:label], destination: action[:path] || "#", class: action[:class] || "text-indigo-600 hover:text-indigo-900")
            else
              # Default actions
              case action
              when :edit
                link("Edit", destination: "#", class: "text-indigo-600 hover:text-indigo-900")
              when :delete
                link("Delete", destination: "#", class: "text-red-600 hover:text-red-900")
              when :view
                link("View", destination: "#", class: "text-gray-600 hover:text-gray-900")
              end
            end
          end
        end
      end
      
      def format_currency(value, symbol = "$")
        "#{symbol}#{value}"
      end
      
      def format_date(value, format = nil)
        return "" unless value
        
        date = case value
               when String then Date.parse(value) rescue value
               when Date, DateTime, Time then value
               else value
               end
        
        if date.respond_to?(:strftime)
          format ||= "%b %d, %Y"
          date.strftime(format)
        else
          value.to_s
        end
      end
      
      def render_pagination(current_page:, per_page:, total_count:)
        total_pages = (total_count.to_f / per_page).ceil
        
        div(class: "px-6 py-4 border-t") do
          hstack(justify: :between) do
            # Results info
            from = ((current_page - 1) * per_page) + 1
            to = [current_page * per_page, total_count].min
            text("Showing #{from} to #{to} of #{total_count} results").text_sm.text_color("gray-700")
            
            # Pagination buttons
            hstack(spacing: 2) do
              # Previous button
              if current_page > 1
                button { text("Previous") }
                  .px(3).py(1)
                  .border
                  .rounded("md")
                  .text_sm
              else
                button { text("Previous") }
                  .px(3).py(1)
                  .border
                  .rounded("md")
                  .text_sm
                  .disabled
              end
              
              # Page numbers (simplified - you can make this more sophisticated)
              if total_pages <= 5
                (1..total_pages).each do |page|
                  if page == current_page
                    button { text(page.to_s) }
                      .px(3).py(1)
                      .bg("blue-600")
                      .text_color("white")
                      .rounded("md")
                      .text_sm
                  else
                    button { text(page.to_s) }
                      .px(3).py(1)
                      .border
                      .rounded("md")
                      .text_sm
                  end
                end
              end
              
              # Next button
              if current_page < total_pages
                button { text("Next") }
                  .px(3).py(1)
                  .border
                  .rounded("md")
                  .text_sm
              else
                button { text("Next") }
                  .px(3).py(1)
                  .border
                  .rounded("md")
                  .text_sm
                  .disabled
              end
            end
          end
        end
      end
    end
  end
end