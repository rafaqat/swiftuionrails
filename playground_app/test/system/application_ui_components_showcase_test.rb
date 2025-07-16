# frozen_string_literal: true

require_relative "component_showcase_base"

class ApplicationUIComponentsShowcaseTest < ComponentShowcaseBase
  test "creates data table with sorting" do
    test_component(
      name: "Data Table",
      category: "Application UI",
      code: <<~'RUBY',
        swift_ui do
          div(class: "p-6") do
            # Users data
            users = [
              { name: "Jane Cooper", email: "jane@example.com", role: "Admin", status: "Active", joined: "Jan 12, 2024" },
              { name: "Wade Warren", email: "wade@example.com", role: "Editor", status: "Active", joined: "Jan 15, 2024" },
              { name: "Esther Howard", email: "esther@example.com", role: "User", status: "Inactive", joined: "Jan 25, 2024" }
            ]
            
            # Use high-level data_table DSL
            data_table(
              data: users,
              columns: [
                { key: :name, label: "Name", sortable: true, format: :avatar_with_text },
                { key: :email, label: "Email", sortable: true },
                { key: :role, label: "Role" },
                { key: :status, label: "Status", format: :badge },
                { key: :joined, label: "Joined", sortable: true },
                { key: :actions, label: "Actions", format: :actions, actions: [:edit, :delete] }
              ],
              title: "Users",
              add_button: { text: "Add User", destination: "#" },
              paginate: true,
              current_page: 1,
              per_page: 10,
              total_count: 24
            )
          end
        end
      RUBY
      assertions: {
        "has table title" => -> { assert_text "Users" },
        "has table headers" => -> { assert_text "Name" ; assert_text "Email" ; assert_text "Status" },
        "has user data" => -> { assert_text "Jane Cooper" ; assert_text "jane@example.com" },
        "has actions" => -> { assert_text "Edit" ; assert_text "Delete" },
        "has pagination" => -> { assert_text "Showing 1 to 3" }
      }
    )
  end

  test "creates kanban board" do
    test_component(
      name: "Kanban Board",
      category: "Application UI",
      code: <<~'RUBY',
        swift_ui do
          div(class: "p-6 bg-gray-50 min-h-screen") do
            # Header
            hstack(justify: :between) do
              h1(class: "text-2xl font-bold text-gray-900") { text("Project Tasks") }
              button { text("+ New Task") }
                .bg("blue-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("md")
                .font_weight("medium")
            end
            
            # Kanban columns
            grid(columns: 4, spacing: 6) do
              columns = [
                { name: "Backlog", color: "gray", count: 3 },
                { name: "In Progress", color: "blue", count: 2 },
                { name: "Review", color: "yellow", count: 1 },
                { name: "Done", color: "green", count: 4 }
              ]
              
              columns.each do |column|
                # Column
                div(class: "bg-gray-100 rounded-lg p-4") do
                  # Column header
                  hstack(justify: :between) do
                    hstack(spacing: 2) do
                      color_class = case column[:color]
                      when "gray" then "bg-gray-500"
                      when "blue" then "bg-blue-500"
                      when "yellow" then "bg-yellow-500"
                      when "green" then "bg-green-500"
                      end
                      div(class: "w-3 h-3 rounded-full " + color_class)
                      h3(class: "font-semibold text-gray-700") { text(column[:name]) }
                    end
                    span(class: "text-sm text-gray-500") { text(column[:count].to_s) }
                  end
                  
                  # Tasks
                  vstack(spacing: 3) do
                    tasks = case column[:name]
                    when "Backlog"
                      [
                        { title: "Design new dashboard", priority: "high", assignee: "JC" },
                        { title: "Update documentation", priority: "low", assignee: "WW" },
                        { title: "Fix login bug", priority: "medium", assignee: "EH" }
                      ]
                    when "In Progress"
                      [
                        { title: "Implement search feature", priority: "high", assignee: "JC" },
                        { title: "Optimize database queries", priority: "medium", assignee: "WW" }
                      ]
                    when "Review"
                      [
                        { title: "Performance testing", priority: "medium", assignee: "EH" }
                      ]
                    else
                      []
                    end
                    
                    tasks.each do |task|
                      card(elevation: 1) do
                        vstack(spacing: 3, alignment: :start) do
                          # Priority badge
                          priority_class = case task[:priority]
                          when "high" then "bg-red-100 text-red-800"
                          when "medium" then "bg-yellow-100 text-yellow-800"
                          when "low" then "bg-green-100 text-green-800"
                          end
                          span(class: "text-xs px-2 py-1 rounded " + priority_class) do
                            text(task[:priority].upcase)
                          end
                          
                          # Title
                          p(class: "text-sm font-medium text-gray-900") { text(task[:title]) }
                          
                          # Assignee
                          hstack(justify: :end) do
                            div(class: "w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center") do
                              span(class: "text-xs font-medium") { text(task[:assignee]) }
                            end
                          end
                        end
                      end.p(3).bg("white")
                    end
                    
                    # Add task button
                    button(class: "w-full") do
                      text("+ Add task")
                    end
                    .py(2)
                    .border("dashed")
                    .border_color("gray-300")
                    .rounded("md")
                    .text_sm
                    .text_color("gray-500")
                    .hover("bg-gray-50")
                  end.mt(4)
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has board title" => -> { assert_text "Project Tasks" },
        "has columns" => -> { assert_text "Backlog" ; assert_text "In Progress" ; assert_text "Review" ; assert_text "Done" },
        "has tasks" => -> { assert_text "Design new dashboard" ; assert_text "Implement search feature" },
        "has priority badges" => -> { assert_text "HIGH" ; assert_text "MEDIUM" },
        "has add task buttons" => -> { assert_text "+ Add task" }
      }
    )
  end

  test "creates modal dialog" do
    test_component(
      name: "Modal Dialog",
      category: "Application UI",
      code: <<~'RUBY',
        swift_ui do
          # Background with modal
          div(class: "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4") do
            # Modal
            card(elevation: 4) do
              # Header
              hstack(justify: :between) do
                h3(class: "text-lg font-semibold text-gray-900") { text("Create New Project") }
                button(class: "text-gray-400 hover:text-gray-600") do
                  span(class: "text-2xl") { text("×") }
                end
              end
              
              # Content
              form do
                vstack(spacing: 4) do
                  # Project name
                  div do
                    label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Project Name") }
                    textfield(
                      type: "text",
                      name: "name",
                      placeholder: "Enter project name",
                      class: "w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    )
                  end
                  
                  # Description
                  div do
                    label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Description") }
                    textarea(
                      name: "description",
                      rows: 3,
                      placeholder: "What's this project about?",
                      class: "w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    )
                  end
                  
                  # Team members
                  div do
                    label(class: "block text-sm font-medium text-gray-700 mb-1") { text("Team Members") }
                    select(name: "members", multiple: true, class: "w-full px-3 py-2 border rounded-md") do
                      option(value: "1") { text("Jane Cooper") }
                      option(value: "2") { text("Wade Warren") }
                      option(value: "3") { text("Esther Howard") }
                    end
                  end
                end
              end
              
              # Footer
              hstack(justify: :end, spacing: 3) do
                button { text("Cancel") }
                  .px(4).py(2)
                  .border
                  .rounded("md")
                  .font_weight("medium")
                  .hover("bg-gray-50")
                
                button { text("Create Project") }
                  .bg("blue-600")
                  .text_color("white")
                  .px(4).py(2)
                  .rounded("md")
                  .font_weight("medium")
                  .hover("bg-blue-700")
              end.mt(6)
            end.max_width("md").width("full").p(6).bg("white").rounded("lg")
          end
        end
      RUBY
      assertions: {
        "has modal title" => -> { assert_text "Create New Project" },
        "has form fields" => -> { assert_text "Project Name" ; assert_text "Description" ; assert_text "Team Members" },
        "has close button" => -> { assert_text "×" },
        "has action buttons" => -> { assert_text "Cancel" ; assert_text "Create Project" }
      }
    )
  end

  test "creates sidebar navigation" do
    test_component(
      name: "Sidebar Navigation",
      category: "Application UI",
      code: <<~'RUBY',
        swift_ui do
          div(class: "flex h-screen bg-gray-100") do
            # Sidebar
            div(class: "w-64 bg-white shadow-lg") do
              # Logo
              div(class: "p-6 border-b") do
                h2(class: "text-2xl font-bold text-gray-800") { text("Dashboard") }
              end
              
              # Navigation
              nav(class: "p-4") do
                vstack(spacing: 2) do
                  nav_items = [
                    { icon: "🏠", label: "Home", active: true },
                    { icon: "📊", label: "Analytics", badge: nil, active: false },
                    { icon: "👥", label: "Users", badge: 12, active: false },
                    { icon: "📧", label: "Messages", badge: 3, active: false },
                    { icon: "⚙️", label: "Settings", active: false }
                  ]
                  
                  nav_items.each do |item|
                    link(destination: "#", class: "block") do
                      hstack(justify: :between) do
                        hstack(spacing: 3) do
                          span { text(item[:icon]) }
                          text(item[:label]).font_weight(item[:active] ? "semibold" : "normal")
                        end
                        
                        if item[:badge]
                          span(class: "bg-red-500 text-white text-xs px-2 py-1 rounded-full") do
                            text(item[:badge].to_s)
                          end
                        end
                      end
                    end
                    .px(4).py(3)
                    .rounded("lg")
                    .bg(item[:active] ? "blue-50" : "white")
                    .text_color(item[:active] ? "blue-600" : "gray-700")
                    .hover(item[:active] ? nil : "bg-gray-50")
                  end
                end
              end
              
              # User section at bottom
              div(class: "absolute bottom-0 w-full p-4 border-t") do
                hstack(spacing: 3) do
                  div(class: "w-10 h-10 rounded-full bg-gray-300")
                  div do
                    p(class: "text-sm font-medium text-gray-900") { text("John Doe") }
                    p(class: "text-xs text-gray-500") { text("john@example.com") }
                  end
                end
              end
            end
            
            # Main content
            div(class: "flex-1 p-8") do
              h1(class: "text-3xl font-bold text-gray-900") { text("Welcome back!") }
              p(class: "mt-2 text-gray-600") { text("Here's what's happening with your projects today.") }
            end
          end
        end
      RUBY
      assertions: {
        "has dashboard title" => -> { assert_text "Dashboard" },
        "has nav items" => -> { assert_text "Home" ; assert_text "Analytics" ; assert_text "Users" },
        "has notification badges" => -> { assert_text "12" ; assert_text "3" },
        "has user info" => -> { assert_text "John Doe" ; assert_text "john@example.com" }
      }
    )
  end

  test "creates notification toast" do
    test_component(
      name: "Notification Toast",
      category: "Application UI",
      code: <<~'RUBY',
        swift_ui do
          # Toast container
          div(class: "fixed top-4 right-4 z-50 space-y-4") do
            # Success toast
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-green-500") do
              hstack(spacing: 3) do
                # Icon
                div(class: "flex-shrink-0") do
                  span(class: "text-green-500 text-xl") { text("✓") }
                end
                
                # Content
                div(class: "flex-1") do
                  h4(class: "font-semibold text-gray-900") { text("Success!") }
                  p(class: "text-sm text-gray-600") { text("Your changes have been saved.") }
                end
                
                # Close button
                button(class: "text-gray-400 hover:text-gray-600") do
                  span { text("×") }
                end
              end
            end
            
            # Warning toast
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-yellow-500") do
              hstack(spacing: 3) do
                div(class: "flex-shrink-0") do
                  span(class: "text-yellow-500 text-xl") { text("⚠") }
                end
                
                div(class: "flex-1") do
                  h4(class: "font-semibold text-gray-900") { text("Warning") }
                  p(class: "text-sm text-gray-600") { text("Your session will expire in 5 minutes.") }
                end
                
                button(class: "text-gray-400 hover:text-gray-600") do
                  span { text("×") }
                end
              end
            end
            
            # Error toast with action
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-red-500") do
              vstack(spacing: 3) do
                hstack(spacing: 3) do
                  div(class: "flex-shrink-0") do
                    span(class: "text-red-500 text-xl") { text("✕") }
                  end
                  
                  div(class: "flex-1") do
                    h4(class: "font-semibold text-gray-900") { text("Error occurred") }
                    p(class: "text-sm text-gray-600") { text("Failed to save your changes. Please try again.") }
                  end
                  
                  button(class: "text-gray-400 hover:text-gray-600") do
                    span { text("×") }
                  end
                end
                
                # Action buttons
                hstack(spacing: 2, justify: :end) do
                  button { text("Dismiss") }
                    .text_sm
                    .text_color("gray-600")
                    .hover("text-gray-800")
                  
                  button { text("Retry") }
                    .text_sm
                    .text_color("red-600")
                    .font_weight("semibold")
                    .hover("text-red-800")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has success toast" => -> { assert_text "Success!" ; assert_text "changes have been saved" },
        "has warning toast" => -> { assert_text "Warning" ; assert_text "session will expire" },
        "has error toast" => -> { assert_text "Error occurred" ; assert_text "Failed to save" },
        "has toast actions" => -> { assert_text "Retry" ; assert_text "Dismiss" }
      }
    )
  end
end