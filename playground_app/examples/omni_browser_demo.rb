# frozen_string_literal: true

require_relative "../../lib/swift_ui_rails/introspection"

module OmniBrowserDemo
  # --- MOCK DATA LAYER ---
  class MockRecord
    include ActiveModel::Model
    include ActiveModel::Attributes
    attr_accessor :id
    
    def self.columns
      # Mocking ActiveRecord columns
      @columns ||= []
    end
    
    def self.add_column(name, type)
      attribute name, type
      @columns ||= []
      @columns << OpenStruct.new(name: name.to_s, type: type)
    end
    
    def self.all; @records ||= []; end
    def self.find(id); all.find { |r| r.id == id }; end
    def self.create(attrs); r = new(attrs); r.id = rand(10000); all << r; r; end
    
    # Mock Reflection
    def self.reflect_on_all_associations(type)
      @associations ||= {}
      @associations[type] || []
    end
    
    def self.has_many(name)
      @associations ||= {}
      @associations[:has_many] ||= []
      @associations[:has_many] << OpenStruct.new(name: name.to_s, klass: "OmniBrowserDemo::#{name.to_s.singularize.camelize}".constantize)
    end
  end

  class Project < MockRecord
    add_column :title, :string
    add_column :active, :boolean
    add_column :budget, :integer
    has_many :tasks
  end

  class Task < MockRecord
    add_column :description, :string
    add_column :completed, :boolean
    add_column :project_id, :integer
  end

  # Seed Data
  if Project.all.empty?
    p1 = Project.create(title: "Website Redesign", active: true, budget: 5000)
    Project.create(title: "Mobile App", active: false, budget: 12000)
    Task.create(description: "Design Mockups", completed: true, project_id: p1.id)
    Task.create(description: "Implement CSS", completed: false, project_id: p1.id)
  end

  # --- THE OMNI BROWSER ---
  
  APP_UI = <<~'RUBY'
    class OmniBrowser < SwiftUIRails::Component::Base
      state :selected_model, "Project"
      state :selected_id, nil
      state :editing_record, nil # Hash of attributes
      state :flash, nil

      def models
        ["Project", "Task"]
      end

      def current_model_class
        "OmniBrowserDemo::#{selected_model}".constantize
      end

      def current_records
        current_model_class.all
      end

      def select_record(id)
        @selected_id = id
        record = current_model_class.find(id)
        # Clone attributes for editing
        @editing_record = record.attributes.symbolize_keys
      end

      def save_record(form_data)
        record = current_model_class.find(@selected_id)
        # Update attributes
        form_data.each do |k, v|
          # Type casting mock
          val = v
          val = (v == "on" || v == true) if [true, false].include?(record.send(k))
          val = v.to_i if record.send(k).is_a?(Integer)
          record.send("#{k}=", val)
        end
        @flash = "Saved!"
      end

      swift_ui do
        vstack.h("screen").bg(:gray_100) do
          # Top Bar
          hstack.padding.bg(:white).border_b do
            Text("OmniBrowser").font(:headline)
            Spacer()
            if flash
              Text(flash).fg(:green).font(:caption).on_appear { @flash = nil } # Auto hide? needs delay
            end
          end

          # Miller Columns
          scroll_view(axes: :horizontal).flex_1 do
            hstack(spacing: 0).h(:full) do
              
              # COL 1: Models
              vstack(spacing: 0).w(250).bg(:gray_50).border_r do
                List(style: :sidebar) do
                  ForEach(models, id: :self) do |model_name|
                    Button { @selected_model = model_name; @selected_id = nil }
                      .bg(selected_model == model_name ? :blue_100 : :transparent)
                      .fg(selected_model == model_name ? :blue : :black)
                      .rounded(:md)
                      .padding(:x, 2).padding(:y, 1)
                      .on_server_click("update_binding")
                      .data(server_action_params_value: ["selected_model", model_name].to_json) do
                        hstack {
                          Image(system_name: :cube)
                          Text(model_name)
                          Spacer()
                          Text("›").fg(:gray_300)
                        }
                      end
                  end
                end
              end

              # COL 2: Records
              vstack(spacing: 0).w(300).bg(:white).border_r do
                # Toolbar
                hstack.padding(2).border_b.bg(:gray_50) do
                  Text(selected_model).font(:headline)
                  Spacer()
                  Button("+") { }.fg(:blue)
                end
                
                # List
                LazyVStack do
                  ForEach(current_records, id: :id) do |record|
                    # Introspect title
                    title = record.attributes.values[1].to_s # Hack for demo
                    
                    Button { select_record(record.id) }
                      .bg(selected_id == record.id ? :blue_600 : :white)
                      .fg(selected_id == record.id ? :white : :black)
                      .on_server_click(:select_record)
                      .data(server_action_params_value: [record.id].to_json) do
                        
                        vstack(alignment: :leading).padding(3).border_b do
                          Text(title).font_bold
                          Text("ID: #{record.id}").font(:caption).opacity(0.8)
                        end
                        
                      end
                  end
                end
              end

              # COL 3: Editor (Auto-Generated)
              if selected_id && editing_record
                vstack(spacing: 0).w(400).bg(:white).border_r do
                  # Header
                  hstack.padding(4).border_b do
                    Text("Editing ##{selected_id}")
                    Spacer()
                    Button("Save")
                      .bg(:blue).fg(:white).padding(:x, 3).padding(:y, 1).rounded
                      .on_server_click(:save_record) # Form submit triggers this
                  end
                  
                  # The AutoForm
                  scroll_view.padding(4) do
                    Form(onSubmit: :save_record) do
                      # Introspect Columns
                      # In a real app, use the ModelReflector
                      # Here we iterate the hash
                      
                      ForEach(editing_record.keys, id: :self) do |key|
                        value = editing_record[key]
                        next if key == :id
                        
                        vstack(alignment: :leading, spacing: 1).padding(:bottom, 4) do
                          Text(key.to_s.humanize).font(:caption).fg(:gray)
                          
                          if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                            Toggle("", isOn: value)
                              # Hack: ReactiveForm doesn't auto-bind to the hash yet without a key
                              # In a real impl, we'd use proper input names
                              .attr("name", key)
                              .attr("value", "on") 
                              .attr("checked", value)
                          elsif value.is_a?(Integer)
                             create_element(:input, type: "number", name: key, value: value, class: "border p-2 rounded w-full")
                          else
                             TextField("", text: value.to_s).attr("name", key)
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              # Placeholder for Right Side
              div.flex_1.bg(:gray_50).flex.items_center.justify_center do
                if !selected_id
                  Text("Select a record").fg(:gray_400)
                end
              end

            end
          end
        end
      end
    end
    
    render OmniBrowser.new
  RUBY
end
