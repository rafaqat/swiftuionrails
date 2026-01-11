# frozen_string_literal: true

module ModernCrudDemo
  # Mock ActiveRecord Model
  class User
    include ActiveModel::Model
    attr_accessor :id, :name, :email, :role
    
    validates :name, presence: true
    validates :email, presence: true, format: { with: /@/ }
    
    def self.all
      @users ||= []
    end
    
    def self.create(attrs)
      user = new(attrs)
      if user.valid?
        user.id = (all.max_by(&:id)&.id || 0) + 1
        all << user
        true
      else
        false
      end
    end
  end

  APP_UI = <<~'RUBY'
    class CreateUserView < SwiftUIRails::Component::Base
      # Form State
      state :name, ""
      state :email, ""
      state :role, "User"
      
      # UI State
      state :users, []
      state :flash_message, nil
      state :flash_type, nil # :success or :error

      def mount
        # Load initial data
        @users = ModernCrudDemo::User.all
      end

      # Server Action: Handle Creation
      def save_user(form_data)
        # We can use the form_data OR our bound state variables
        # Since we are using bindings, @name and @email are already updated!
        
        user = ModernCrudDemo::User.new(name: @name, email: @email, role: @role)
        
        if user.valid?
          # Save to "DB"
          ModernCrudDemo::User.all << user
          
          # Optimistic UI Update
          @users = ModernCrudDemo::User.all
          
          # Reset Form
          @name = ""
          @email = ""
          
          # Show Success
          @flash_message = "User #{user.name} created successfully!"
          @flash_type = :success
        else
          # Show Errors
          @flash_message = user.errors.full_messages.join(", ")
          @flash_type = :error
        end
      end
      
      def delete_user(id)
        ModernCrudDemo::User.all.reject! { |u| u.id == id }
        @users = ModernCrudDemo::User.all
        @flash_message = "User deleted."
        @flash_type = :success
      end

      swift_ui do
        NavigationStack do
          NavigationTitle("User Management")
          
          # Flash Message
          if flash_message
            div.padding.bg(flash_type == :success ? :green_100 : :red_100)
               .fg(flash_type == :success ? :green_800 : :red_800)
               .rounded(:md).margin_bottom(4).transition do
              hstack {
                Image(system_name: flash_type == :success ? :checkmark_circle : :exclamationmark_triangle)
                Text(flash_message)
                Spacer()
                Button("×").on_server_click(:clear_flash).fg(:gray_500)
              }
            end
          end

          List(style: :inset_grouped) do
            
            # CREATE SECTION
            Section(header: "New User") do
              # We use a Reactive Form that calls :save_user on submit
              Form(onSubmit: :save_user) do
                TextField("Name", text: :name)
                TextField("Email", text: :email)
                
                # Custom Select (Native) wrapped in reactive logic
                # Ideally we build a Picker component, for now standard select
                hstack(justify: :between) do
                  Text("Role")
                  create_element(:select, name: "role", class: "bg-transparent text-right outline-none") do
                    option("User", selected: role == "User")
                    option("Admin", selected: role == "Admin")
                  end.data(
                    controller: "server-action",
                    action: "change->server-action#trigger",
                    server_action_name_value: "update_binding",
                    server_action_params_value: ["role"].to_json
                  )
                end.padding(:y, 2)
                
                Button("Create User", type: "submit")
                  .w(:full).bg(:blue).fg(:white).rounded(:lg).padding(:y, 2).margin_top(2)
              end
            end
            
            # LIST SECTION
            Section(header: "Users (#{users.count})") do
              if users.empty?
                Text("No users found").fg(:gray_500).italic.padding
              else
                ForEach(users) do |user|
                  hstack(justify: :between) do
                    vstack(alignment: :leading) do
                      Text(user.name).font(:headline)
                      Text(user.email).font(:caption).fg(:gray)
                    end
                    
                    hstack {
                      Badge(user.role, color: user.role == "Admin" ? :purple : :gray)
                      
                      Button(type: "button") {
                        Image(system_name: :trash).fg(:red)
                      }.on_server_click(:delete_user).data(server_action_params_value: [user.id].to_json)
                    }
                  end.padding(:y, 2)
                end
              end
            end
            
          end
        end
      end
      
      def clear_flash
        @flash_message = nil
      end
    end
    
    render CreateUserView.new
  RUBY
end
