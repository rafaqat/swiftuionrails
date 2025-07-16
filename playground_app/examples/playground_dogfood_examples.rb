# Dogfooding Examples for SwiftUI Rails Playground
# These examples showcase real-world patterns and components

module PlaygroundDogfoodExamples
  # 1. E-commerce Product Grid
  PRODUCT_GRID = <<~'RUBY'
    swift_ui do
      # Responsive product grid with hover effects
      grid(columns: 3, spacing: 16) do
        6.times do |i|
          card(elevation: 2) do
            vstack(spacing: 0) do
              # Product image with overlay on hover
              div.relative.group do
                image(
                  src: "https://via.placeholder.com/300x200",
                  alt: "Product #{i + 1}"
                ).w("full").h(200).object_cover
                
                # Hover overlay with quick actions
                div
                  .absolute.inset(0)
                  .bg("black").opacity(0)
                  .group_hover_opacity(75)
                  .transition.duration(300)
                  .flex.items_center.justify_center
                  .gap(2) do
                  button("Quick View")
                    .bg("white").text_color("black")
                    .px(4).py(2).rounded("lg")
                    .opacity(0).group_hover_opacity(100)
                    .transform.translate_y(4).group_hover_translate_y(0)
                    .transition.delay(100)
                  
                  button("♡")
                    .bg("white").text_color("red-500")
                    .w(10).h(10).rounded("full")
                    .opacity(0).group_hover_opacity(100)
                    .transform.translate_y(4).group_hover_translate_y(0)
                    .transition.delay(200)
                end
              end
              
              # Product details
              vstack(spacing: 2, alignment: :start).p(4) do
                text("Premium Product #{i + 1}")
                  .font_weight("semibold")
                  .text_color("gray-900")
                
                hstack(spacing: 2) do
                  text("$#{(99 + i * 20).to_s}")
                    .font_size("xl")
                    .font_weight("bold")
                    .text_color("green-600")
                  
                  text("$#{(149 + i * 20).to_s}")
                    .font_size("sm")
                    .text_color("gray-500")
                    .line_through
                end
                
                hstack(spacing: 1) do
                  5.times do |star|
                    text(star < 4 ? "★" : "☆")
                      .text_color("yellow-500")
                  end
                  text("(#{45 + i * 7})")
                    .text_sm
                    .text_color("gray-600")
                end
              end
            end
          end
          .hover_scale(105)
          .transition.duration(300)
        end
      end
    end
  RUBY

  # 2. Dashboard Stats Cards
  DASHBOARD_STATS = <<~'RUBY'
    swift_ui do
      grid(columns: 4, spacing: 16) do
        [
          { label: "Total Revenue", value: "$45,678", change: "+12.5%", trend: "up", color: "green" },
          { label: "Active Users", value: "2,345", change: "+5.2%", trend: "up", color: "blue" },
          { label: "Conversion Rate", value: "3.4%", change: "-0.8%", trend: "down", color: "red" },
          { label: "Avg Order Value", value: "$126", change: "+8.1%", trend: "up", color: "purple" }
        ].each do |stat|
          card(elevation: 1) do
            vstack(spacing: 4, alignment: :start) do
              hstack(justify: :between) do
                text(stat[:label])
                  .text_size("sm")
                  .text_color("gray-600")
                  .font_weight("medium")
                
                div
                  .width("8").height("8")
                  .rounded("full")
                  .bg("#{stat[:color]}-100")
                  .flex.items_center.justify_center do
                  text(stat[:trend] == "up" ? "↑" : "↓")
                    .text_color("#{stat[:color]}-600")
                    .font_weight("bold")
                end
              end
              
              text(stat[:value])
                .font_size("3xl")
                .font_weight("bold")
                .text_color("gray-900")
              
              hstack(alignment: :center, spacing: 2) do
                span do
                  text(stat[:change])
                end
                  .text_size("sm")
                  .font_weight("medium")
                  .text_color("#{stat[:color]}-600")
                
                text("from last month")
                  .text_size("sm")
                  .text_color("gray-500")
              end
            end
          end
        end
      end
    end
  RUBY

  # 3. Interactive Pricing Cards
  PRICING_CARDS = <<~'RUBY'
    swift_ui do
      hstack(spacing: 16, alignment: :stretch) do
        [
          { 
            name: "Starter", 
            price: "$9", 
            features: ["10 Projects", "2 Team Members", "10GB Storage", "Basic Support"],
            popular: false
          },
          { 
            name: "Professional", 
            price: "$29", 
            features: ["Unlimited Projects", "10 Team Members", "100GB Storage", "Priority Support", "Advanced Analytics"],
            popular: true
          },
          { 
            name: "Enterprise", 
            price: "$99", 
            features: ["Everything in Pro", "Unlimited Team Members", "1TB Storage", "24/7 Phone Support", "Custom Integrations", "SLA"],
            popular: false
          }
        ].each do |plan|
          card(elevation: plan[:popular] ? 4 : 2) do
            div.relative do
              # Popular badge
              if plan[:popular]
                div
                  .absolute.top(-3).right(4)
                  .bg("gradient-to-r").from("purple-600").to("pink-600")
                  .text_color("white")
                  .px(4).py(1)
                  .rounded("full")
                  .text_sm
                  .font_weight("medium") do
                  text("Most Popular")
                end
              end
              
              vstack(spacing: 6).p(8) do
                # Plan name
                text(plan[:name])
                  .font_size("2xl")
                  .font_weight("bold")
                  .text_color(plan[:popular] ? "purple-700" : "gray-900")
                
                # Price
                hstack(alignment: :end, spacing: 1) do
                  text(plan[:price])
                    .font_size("5xl")
                    .font_weight("black")
                    .text_color("gray-900")
                  text("/month")
                    .text_color("gray-600")
                    .mb(2)
                end
                
                # Features list
                vstack(spacing: 3, alignment: :start).my(6) do
                  plan[:features].each do |feature|
                    hstack(spacing: 3) do
                      text("✓")
                        .text_color(plan[:popular] ? "purple-600" : "green-600")
                        .font_weight("bold")
                      text(feature)
                        .text_color("gray-700")
                    end
                  end
                end
                
                # CTA Button
                if plan[:popular]
                  button("Get Started")
                    .w("full")
                    .py(3)
                    .rounded("lg")
                    .font_weight("semibold")
                    .transition
                    .bg("gradient-to-r").from("purple-600").to("pink-600")
                    .text_color("white")
                    .hover_shadow("lg")
                    .hover_scale(105)
                else
                  button("Get Started")
                    .w("full")
                    .py(3)
                    .rounded("lg")
                    .font_weight("semibold")
                    .transition
                    .bg("white")
                    .text_color("gray-900")
                    .border.border_color("gray-300")
                    .hover_bg("gray-50")
                end
              end
            end
          end
        end
      end
    end
  RUBY

  # 4. Interactive Todo List with Stimulus
  TODO_LIST = <<~'RUBY'
    swift_ui do
      div(data: { 
        controller: "todo-list",
        todo_list_items_value: "[]"
      }) do
        card(elevation: 2) do
          vstack(spacing: 0) do
            # Header
            div.border_b.border_color("gray-200").p(6) do
              hstack(justify: :between, alignment: :center) do
                vstack(spacing: 1, alignment: :start) do
                  text("My Tasks")
                    .font_size("2xl")
                    .font_weight("bold")
                  text("")
                    .text_sm
                    .text_color("gray-600")
                    .data("todo-list-target": "counter")
                end
                
                button("+")
                  .bg("blue-600")
                  .text_color("white")
                  .w(10).h(10)
                  .rounded("full")
                  .font_size("xl")
                  .hover_bg("blue-700")
                  .data(action: "click->todo-list#showAddForm")
              end
            end
            
            # Add form (hidden by default)
            div
              .hidden
              .p(6)
              .border_b.border_color("gray-200")
              .bg("gray-50")
              .data("todo-list-target": "addForm") do
              form.flex.gap(2).data(action: "submit->todo-list#addItem") do
                textfield(
                  placeholder: "What needs to be done?",
                  data: { "todo-list-target": "input" }
                ).flex_1
                
                button("Add", type: "submit")
                  .bg("green-600")
                  .text_color("white")
                  .px(4).py(2)
                  .rounded("lg")
                  .hover_bg("green-700")
                
                button("Cancel", type: "button")
                  .bg("gray-300")
                  .text_color("gray-700")
                  .px(4).py(2)
                  .rounded("lg")
                  .hover_bg("gray-400")
                  .data(action: "click->todo-list#hideAddForm")
              end
            end
            
            # Todo items container
            vstack(spacing: 0)
              .data("todo-list-target": "itemsContainer") do
              # Items will be dynamically added here
            end
            
            # Empty state
            div
              .p(16)
              .text_center
              .data("todo-list-target": "emptyState") do
              text("No tasks yet. Click + to add one!")
                .text_color("gray-500")
            end
          end
        end
      end
    end
  RUBY

  # 5. Navigation Bar Component
  NAVBAR = <<~'RUBY'
    swift_ui do
      nav do
        div.max_w("7xl").mx("auto").px(4) do
          hstack(justify: :between, alignment: :center).h(16) do
            # Logo and primary nav
            hstack(spacing: 8, alignment: :center) do
              # Logo
              text("SwiftUI Rails")
                .font_size("xl")
                .font_weight("bold")
                .text_color("blue-600")
              
              # Navigation links
              hstack(spacing: 1).hidden.md("flex") do
                ["Home", "Components", "Documentation", "Examples"].each do |item|
                  link(item, destination: "#")
                    .px(4).py(2)
                    .rounded("lg")
                    .text_color("gray-700")
                    .hover_bg("gray-100")
                    .tw("hover:text-blue-600")
                    .transition
                end
              end
            end
            
            # Right side actions
            hstack(spacing: 4, alignment: :center) do
              # Search button
              button("🔍")
                .p(2)
                .rounded("lg")
                .text_color("gray-600")
                .hover_bg("gray-100")
              
              # Notifications
              div.relative do
                button("🔔")
                  .p(2)
                  .rounded("lg")
                  .text_color("gray-600")
                  .hover_bg("gray-100")
                
                # Notification badge
                span
                  .absolute.top(0).right(0)
                  .bg("red-500")
                  .text_color("white")
                  .text_xs
                  .w(5).h(5)
                  .rounded("full")
                  .flex.items_center.justify_center do
                  text("3")
                end
              end
              
              # User menu
              div.relative.group do
                button("👤")
                  .flex.items_center.gap(2)
                  .p(2)
                  .rounded("lg")
                  .hover_bg("gray-100")
                
                # Dropdown menu
                div
                  .absolute.right(0).top(12)
                  .w(48)
                  .bg("white")
                  .rounded("lg")
                  .shadow("lg")
                  .border.border_color("gray-200")
                  .hidden.tw("group-hover:block")
                  .py(2) do
                  ["Profile", "Settings", "Sign out"].each do |item|
                    link(item, destination: "#")
                      .block.px(4).py(2)
                      .text_color("gray-700")
                      .hover_bg("gray-100")
                  end
                end
              end
              
              # Mobile menu button
              button("☰")
                .p(2)
                .rounded("lg")
                .text_color("gray-600")
                .hover_bg("gray-100")
                .md("hidden")
            end
          end
        end
      end
      .bg("white")
      .shadow("md")
      .sticky
      .top(0)
      .z(50)
    end
  RUBY

  # 6. Layout Justification Demo
  LAYOUT_DEMO = <<~'RUBY'
    swift_ui do
      vstack(spacing: 16) do
        text("HStack Justification Examples")
          .font_size("2xl")
          .font_weight("bold")
          .text_color("blue-600")
          .text_align("center")
        
        divider
        
        vstack(spacing: 12) do
          # justify: :start (default)
          vstack(spacing: 4) do
            text("justify: :start (default)")
              .font_weight("semibold")
              .text_color("gray-700")
              .text_align("left")
            
            div.border.border_color("gray-200").rounded("lg").p(4).bg("gray-50") do
              hstack(justify: :start) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("A")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("B")
                end
                div.bg("purple-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("C")
                end
              end
            end
          end
          
          # justify: :center
          vstack(spacing: 4) do
            text("justify: :center")
              .font_weight("semibold")
              .text_color("gray-700")
              .text_align("left")
            
            div.border.border_color("gray-200").rounded("lg").p(4).bg("gray-50") do
              hstack(justify: :center) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("A")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("B")
                end
                div.bg("purple-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("C")
                end
              end
            end
          end
          
          # justify: :end
          vstack(spacing: 4) do
            text("justify: :end")
              .font_weight("semibold")
              .text_color("gray-700")
              .text_align("left")
            
            div.border.border_color("gray-200").rounded("lg").p(4).bg("gray-50") do
              hstack(justify: :end) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("A")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("B")
                end
                div.bg("purple-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("C")
                end
              end
            end
          end
          
          # justify: :between
          vstack(spacing: 4) do
            text("justify: :between")
              .font_weight("semibold")
              .text_color("gray-700")
              .text_align("left")
            
            div.border.border_color("gray-200").rounded("lg").p(4).bg("gray-50") do
              hstack(justify: :between) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("A")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("B")
                end
                div.bg("purple-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("C")
                end
              end
            end
          end
          
          # justify: :around
          vstack(spacing: 4) do
            text("justify: :around")
              .font_weight("semibold")
              .text_color("gray-700")
              .text_align("left")
            
            div.border.border_color("gray-200").rounded("lg").p(4).bg("gray-50") do
              hstack(justify: :around) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("A")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("B")
                end
                div.bg("purple-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("C")
                end
              end
            end
          end
          
          # justify: :evenly
          vstack(spacing: 4) do
            text("justify: :evenly")
              .font_weight("semibold")
              .text_color("gray-700")
              .text_align("left")
            
            div.border.border_color("gray-200").rounded("lg").p(4).bg("gray-50") do
              hstack(justify: :evenly) do
                div.bg("blue-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("A")
                end
                div.bg("green-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("B")
                end
                div.bg("purple-500").text_color("white").px(4).py(2).rounded("md").font_weight("bold") do
                  text("C")
                end
              end
            end
          end
        end
      end
    end
  RUBY

  # 7. Simple Table Example
  SIMPLE_TABLE = <<~'RUBY'
    swift_ui do
      vstack(spacing: 16) do
        text("Simple Table Example")
          .font_size("2xl")
          .font_weight("bold")
          .text_color("blue-600")
          .text_align("center")
        
        div.border.border_color("gray-300").rounded("lg").shadow("sm") do
          table do
            thead do
              tr do
                th.px(4).py(2).text_left { text("Name") }
                th.px(4).py(2).text_left { text("Role") }
                th.px(4).py(2).text_left { text("Email") }
                th.px(4).py(2).text_left { text("Status") }
              end
            end
            
            tbody do
              tr.border_t do
                td.px(4).py(2) { text("John Doe") }
                td.px(4).py(2) { text("Admin") }
                td.px(4).py(2) { text("john@example.com") }
                td.px(4).py(2) { text("Active") }
              end
              
              tr.border_t do
                td.px(4).py(2) { text("Jane Smith") }
                td.px(4).py(2) { text("User") }
                td.px(4).py(2) { text("jane@example.com") }
                td.px(4).py(2) { text("Active") }
              end
              
              tr.border_t do
                td.px(4).py(2) { text("Bob Johnson") }
                td.px(4).py(2) { text("Manager") }
                td.px(4).py(2) { text("bob@example.com") }
                td.px(4).py(2) { text("Inactive") }
              end
              
              tr.border_t do
                td.px(4).py(2) { text("Alice Brown") }
                td.px(4).py(2) { text("User") }
                td.px(4).py(2) { text("alice@example.com") }
                td.px(4).py(2) { text("Pending") }
              end
            end
          end
        end
      end
    end
  RUBY

  # 8. Advanced Data Table with Rich Formatting
  DATA_TABLE = <<~'RUBY'
    swift_ui do
      vstack(spacing: 16) do
        text("Advanced Data Table")
          .font_size("2xl")
          .font_weight("bold")
          .text_color("blue-600")
          .text_align("center")
        
        data_table(
          title: "User Management",
          data: [
            { name: "John Doe", role: "Admin", email: "john@example.com", status: "Active", last_login: "2024-01-15", actions: [:edit, :delete] },
            { name: "Jane Smith", role: "User", email: "jane@example.com", status: "Active", last_login: "2024-01-14", actions: [:edit, :delete] },
            { name: "Bob Johnson", role: "Manager", email: "bob@example.com", status: "Inactive", last_login: "2024-01-10", actions: [:edit, :delete] },
            { name: "Alice Brown", role: "User", email: "alice@example.com", status: "Pending", last_login: "2024-01-12", actions: [:edit, :delete] }
          ],
          columns: [
            { 
              key: :name, 
              label: "Name", 
              format: :avatar_with_text, 
              sortable: true 
            },
            { 
              key: :role, 
              label: "Role", 
              format: :badge,
              badge_map: {
                "Admin" => "bg-red-100 text-red-800",
                "Manager" => "bg-blue-100 text-blue-800",
                "User" => "bg-green-100 text-green-800"
              }
            },
            { 
              key: :email, 
              label: "Email", 
              sortable: true 
            },
            { 
              key: :status, 
              label: "Status", 
              format: :badge,
              badge_map: {
                "Active" => "bg-green-100 text-green-800",
                "Inactive" => "bg-gray-100 text-gray-800",
                "Pending" => "bg-yellow-100 text-yellow-800"
              }
            },
            { 
              key: :last_login, 
              label: "Last Login", 
              format: :date,
              date_format: "%b %d, %Y"
            },
            { 
              key: :actions, 
              label: "Actions", 
              format: :actions,
              actions: [
                { label: "Edit", path: "#", class: "text-blue-600 hover:text-blue-900" },
                { label: "Delete", path: "#", class: "text-red-600 hover:text-red-900" }
              ]
            }
          ],
          add_button: { text: "Add User", destination: "#" },
          search: { placeholder: "Search users...", name: "search" },
          sortable: true,
          paginate: false,
          elevation: 2
        )
      end
    end
  RUBY

  # 9. Sales Report Table with Currency and Custom Formatting
  SALES_TABLE = <<~'RUBY'
    swift_ui do
      vstack(spacing: 16) do
        text("Sales Report Table")
          .font_size("2xl")
          .font_weight("bold")
          .text_color("blue-600")
          .text_align("center")
        
        data_table(
          title: "Q1 2024 Sales Report",
          data: [
            { product: "iPhone 15", category: "Electronics", sales: 15420, revenue: 12336000, growth: 12.5 },
            { product: "MacBook Pro", category: "Electronics", sales: 8765, revenue: 17530000, growth: 8.2 },
            { product: "AirPods Pro", category: "Audio", sales: 25678, revenue: 6419500, growth: 15.8 },
            { product: "Apple Watch", category: "Wearables", sales: 12890, revenue: 5156000, growth: -2.1 },
            { product: "iPad Air", category: "Tablets", sales: 6543, revenue: 3925800, growth: 5.4 }
          ],
          columns: [
            { 
              key: :product, 
              label: "Product", 
              sortable: true,
              header_class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
            },
            { 
              key: :category, 
              label: "Category", 
              format: :badge,
              badge_map: {
                "Electronics" => "bg-blue-100 text-blue-800",
                "Audio" => "bg-purple-100 text-purple-800",
                "Wearables" => "bg-green-100 text-green-800",
                "Tablets" => "bg-yellow-100 text-yellow-800"
              }
            },
            { 
              key: :sales, 
              label: "Units Sold", 
              format: :custom,
              render: ->(value, row) { text("#{value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}") }
            },
            { 
              key: :revenue, 
              label: "Revenue", 
              format: :currency,
              currency: "$",
              sortable: true
            },
            { 
              key: :growth, 
              label: "Growth %", 
              format: :custom,
              render: ->(value, row) { 
                color = value > 0 ? "text-green-600" : "text-red-600"
                symbol = value > 0 ? "↑" : "↓"
                span(class: color) do
                  text("#{symbol} #{value.abs}%")
                end
              }
            }
          ],
          add_button: { text: "Add Product", destination: "#" },
          search: { placeholder: "Search products...", name: "product_search" },
          sortable: true,
          paginate: true,
          per_page: 10,
          current_page: 1,
          total_count: 25,
          elevation: 3
        )
      end
    end
  RUBY

  # 10. Employee Directory with Pagination
  EMPLOYEE_TABLE = <<~'RUBY'
    swift_ui do
      vstack(spacing: 16) do
        text("Employee Directory")
          .font_size("2xl")
          .font_weight("bold")
          .text_color("blue-600")
          .text_align("center")
        
        data_table(
          title: "Company Directory",
          data: [
            { name: "Sarah Connor", department: "Engineering", position: "Senior Developer", salary: 95000, hire_date: "2022-03-15", email: "sarah@company.com" },
            { name: "John Matrix", department: "Sales", position: "Sales Manager", salary: 78000, hire_date: "2021-11-20", email: "john@company.com" },
            { name: "Ellen Ripley", department: "Engineering", position: "Tech Lead", salary: 110000, hire_date: "2020-07-10", email: "ellen@company.com" },
            { name: "Dutch Schaefer", department: "Marketing", position: "Marketing Director", salary: 85000, hire_date: "2023-01-08", email: "dutch@company.com" },
            { name: "Kyle Reese", department: "HR", position: "HR Specialist", salary: 65000, hire_date: "2022-09-12", email: "kyle@company.com" }
          ],
          columns: [
            { 
              key: :name, 
              label: "Employee", 
              format: :avatar_with_text, 
              sortable: true 
            },
            { 
              key: :department, 
              label: "Department", 
              format: :badge,
              badge_map: {
                "Engineering" => "bg-blue-100 text-blue-800",
                "Sales" => "bg-green-100 text-green-800",
                "Marketing" => "bg-purple-100 text-purple-800",
                "HR" => "bg-yellow-100 text-yellow-800"
              }
            },
            { 
              key: :position, 
              label: "Position", 
              sortable: true 
            },
            { 
              key: :salary, 
              label: "Salary", 
              format: :currency,
              currency: "$",
              sortable: true
            },
            { 
              key: :hire_date, 
              label: "Hire Date", 
              format: :date,
              date_format: "%b %d, %Y",
              sortable: true
            },
            { 
              key: :actions, 
              label: "Actions", 
              format: :actions,
              actions: [
                { label: "View", path: "#", class: "text-blue-600 hover:text-blue-900" },
                { label: "Edit", path: "#", class: "text-indigo-600 hover:text-indigo-900" },
                { label: "Delete", path: "#", class: "text-red-600 hover:text-red-900" }
              ]
            }
          ],
          add_button: { text: "Add Employee", destination: "#" },
          search: { placeholder: "Search employees...", name: "employee_search" },
          sortable: true,
          paginate: true,
          per_page: 5,
          current_page: 1,
          total_count: 50,
          elevation: 2,
          empty_message: "No employees found"
        )
      end
    end
  RUBY

  def self.all_examples
    {
      product_grid: PRODUCT_GRID,
      dashboard_stats: DASHBOARD_STATS,
      pricing_cards: PRICING_CARDS,
      todo_list: TODO_LIST,
      navbar: NAVBAR,
      layout_demo: LAYOUT_DEMO,
      simple_table: SIMPLE_TABLE,
      data_table: DATA_TABLE,
      sales_table: SALES_TABLE,
      employee_table: EMPLOYEE_TABLE
    }
  end
end