# frozen_string_literal: true

require_relative '../introspection'

module SwiftUIRails
  module Components
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

      def mount
        # ... (rest of mount)
      end
      
      def filtered_models
        if model_search.blank?
          available_models
        else
          available_models.select { |m| m.downcase.include?(model_search.downcase) }
        end
      end

      # ... (Helpers) ...

      # ... (Actions) ...

      # ... (UI) ...
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
                      title = reflector.title_column ? record.send(reflector.title_column) : record.id
                      
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
                      # Form submit handles this, but button can too if outside form
                  end
                  
                  # Auto-Generated Form
                  scroll_view.padding(4) do
                    Form(onSubmit: :save_record) do
                      
                      # Iterate over REAL columns
                      ForEach(reflector.columns, id: :name) do |col|
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
                            create_element(:textarea, value, name: col.name, class: "border p-2 rounded w-full h-24")
                          when :datetime, :date
                            create_element(:input, type: "date", name: col.name, value: value.to_s.split(" ").first, class: "border p-2 rounded w-full")
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
    end
  end
end
