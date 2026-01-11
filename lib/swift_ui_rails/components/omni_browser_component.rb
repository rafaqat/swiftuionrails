# frozen_string_literal: true

require_relative '../introspection'

module SwiftUIRails
  module Components
    # OmniBrowserComponent provides a Miller column interface for browsing
    # and editing ActiveRecord models. It displays three columns:
    # 1. Model list - shows available models with search filtering
    # 2. Record list - shows records for the selected model
    # 3. Editor - auto-generated form for editing selected record
    #
    # @example Basic usage with automatic model discovery
    #   render SwiftUIRails::Components::OmniBrowserComponent.new
    #
    # @example With explicit model list
    #   render SwiftUIRails::Components::OmniBrowserComponent.new(
    #     models: ["User", "Post", "Comment"]
    #   )
    #
    # Props:
    #   models - Array of model class names as strings. If empty, discovers
    #            all ActiveRecord models automatically.
    #
    class OmniBrowserComponent < Component::Base
      # Props
      prop :models, default: [] # List of model class names as strings ["User", "Post"]

      # State
      state :selected_model_name, nil
      state :selected_record_id, nil
      state :editing_attributes, {}
      state :flash_message, nil
      state :available_models, []
      state :model_search, ""

      # Initializes the component state on first render.
      # Populates available_models from props or auto-discovers all ActiveRecord models.
      # @return [void]
      def mount
        @available_models = models.presence || Introspection::SystemScanner.all_models
      end

      # Returns models filtered by the current search query.
      # @return [Array<String>] Array of model class names matching the search
      def filtered_models
        if model_search.blank?
          available_models
        else
          available_models.select { |m| m.downcase.include?(model_search.downcase) }
        end
      end

      # Returns the ActiveRecord class for the currently selected model.
      # Validates the model name against available_models allowlist before constantize
      # to prevent arbitrary class instantiation (RCE) attacks.
      # @return [Class, nil] The model class or nil if invalid/not found
      def current_model_class
        return nil unless selected_model_name.present?
        return nil unless available_models.include?(selected_model_name)
        selected_model_name.constantize
      rescue NameError
        nil
      end

      # Returns all records for the currently selected model.
      # @return [ActiveRecord::Relation, Array] Collection of records or empty array
      def current_records
        current_model_class&.all || []
      end

      # Returns a ModelReflector for the current model, memoized for performance.
      # @return [Introspection::ModelReflector, nil] Reflector instance or nil
      def reflector
        @reflector ||= current_model_class ? Introspection::ModelReflector.new(current_model_class) : nil
      end

      # Selects a model by name and resets record selection.
      # Clears the memoized reflector to prevent stale cache issues.
      # @param name [String] The model class name to select
      # @return [void]
      def select_model(name)
        @selected_model_name = name
        @selected_record_id = nil
        @editing_attributes = {}
        @reflector = nil  # Clear cached reflector when model changes
      end

      # Selects a record by ID and loads its attributes for editing.
      # Uses find_by to gracefully handle missing records instead of raising.
      # @param id [Integer, String] The record ID to select
      # @return [void]
      def select_record(id)
        @selected_record_id = id
        record = current_model_class&.find_by(id: id)
        @editing_attributes = record&.attributes&.symbolize_keys || {}
      end

      # Saves the selected record with form data updates.
      # Sets a flash message indicating success or validation errors.
      # @param form_data [Hash] Hash of attribute name to value pairs
      # @return [void]
      def save_record(form_data)
        # Use find_by to return nil instead of raising RecordNotFound
        record = current_model_class&.find_by(id: @selected_record_id)
        return unless record

        form_data.each do |k, v|
          record.send("#{k}=", v) if record.respond_to?("#{k}=")
        end

        # Check save result before setting success message
        if record.save
          @flash_message = "Saved!"
        else
          @flash_message = "Save failed: #{record.errors.full_messages.join(', ')}"
        end
      end

      swift_ui do
        vstack.h("screen").bg(:gray_100) do
          # Top Bar
          hstack.padding.bg(:white).border_b do
            Text("OmniBrowser").font(:headline)
            Spacer()
            if flash_message
              Text(flash_message).fg(:green).font(:caption)
            end
          end

          # Miller Columns
          scroll_view(axes: :horizontal).flex_1 do
            hstack(spacing: 0).h(:full) do

              # COLUMN 1: Models
              vstack(spacing: 0).w(250).bg(:gray_50).border_r do
                # Search
                div.padding(2).border_b do
                  TextField("Search models...", text: :model_search)
                end

                List(style: :sidebar) do
                  Section(header: "Tables") do
                    ForEach(filtered_models, id: :self) do |name|
                      Button { select_model(name) }
                        .bg(selected_model_name == name ? :blue_100 : :transparent)
                        .fg(selected_model_name == name ? :blue : :black)
                        .rounded(:md).padding(:x, 2).padding(:y, 1)
                        .on_server_click(:select_model).data(server_action_params_value: [name].to_json) do
                          hstack {
                            Image(system_name: :table_cells)
                            Text(name)
                            Spacer()
                            Text("›").fg(:gray_300)
                          }
                        end
                    end
                  end
                end
              end

              # COLUMN 2: Records
              if current_model_class
                vstack(spacing: 0).w(300).bg(:white).border_r do
                  # Toolbar
                  hstack.padding(2).border_b.bg(:gray_50) do
                    Text(selected_model_name).font(:headline)
                    Spacer()
                    Text("#{current_model_class.count} records").font(:caption).fg(:gray)
                  end

                  # List
                  LazyVStack do
                    ForEach(current_records, id: :id) do |record|
                      # Guess a title
                      title = reflector&.title_column ? record.send(reflector.title_column) : record.id

                      Button { select_record(record.id) }
                        .bg(selected_record_id == record.id ? :blue_600 : :white)
                        .fg(selected_record_id == record.id ? :white : :black)
                        .on_server_click(:select_record).data(server_action_params_value: [record.id].to_json) do

                          vstack(alignment: :leading).padding(3).border_b do
                            Text(title.to_s).font_bold.line_clamp(1)
                            Text("ID: #{record.id}").font(:caption).opacity(0.8)
                          end

                        end
                    end
                  end
                end
              end

              # COLUMN 3: Editor
              if selected_record_id && !editing_attributes.empty?
                vstack(spacing: 0).w(400).bg(:white).border_r do
                  # Header
                  hstack.padding(4).border_b do
                    Text("Edit ##{selected_record_id}")
                    Spacer()
                    Button("Save")
                      .bg(:blue).fg(:white).padding(:x, 3).padding(:y, 1).rounded
                      .on_server_click(:save_record)
                  end

                  # Auto-Generated Form
                  scroll_view.padding(4) do
                    Form(onSubmit: :save_record) do

                      # Iterate over REAL columns
                      ForEach(reflector&.columns || [], id: :name) do |col|
                        value = editing_attributes[col.name]

                        vstack(alignment: :leading, spacing: 1).padding(:bottom, 4) do
                          Text(col.name.humanize).font(:caption).fg(:gray)

                          case col.type
                          when :boolean
                            Toggle("", isOn: !!value)
                              .attr("name", col.name)
                              .attr("value", "1")
                              .attr("checked", !!value)
                          when :integer, :float, :decimal
                            create_element(:input, type: "number", name: col.name, value: value, class: "border p-2 rounded w-full")
                          when :text
                            create_element(:textarea, name: col.name, class: "border p-2 rounded w-full h-24") { value.to_s }
                          when :datetime, :date
                            formatted_date = format_date_value(value)
                            create_element(:input, type: "date", name: col.name, value: formatted_date, class: "border p-2 rounded w-full")
                          else
                            # Default String
                            create_element(:input, type: "text", name: col.name, value: value, class: "border p-2 rounded w-full")
                          end
                        end
                      end

                      Button("Save Changes", type: "submit")
                        .w(:full).bg(:blue).fg(:white).rounded(:lg).padding(:y, 2)
                    end
                  end
                end
              end

              # Empty State
              div.flex_1.bg(:gray_50).flex.items_center.justify_center do
                unless selected_record_id
                  Text("Select a record to edit").fg(:gray_400)
                end
              end

            end
          end
        end
      end

      private

      # Safely format date values for input fields
      # @param value [Date, DateTime, String, nil] the value to format
      # @return [String, nil] formatted date string or nil
      def format_date_value(value)
        return nil if value.nil?
        return value.strftime("%Y-%m-%d") if value.respond_to?(:strftime)
        value.to_s.split(" ").first
      end
    end
  end
end
