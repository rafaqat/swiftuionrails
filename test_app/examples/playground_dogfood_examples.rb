# Dogfooding Examples for SwiftUI Rails Playground
# These examples showcase real-world patterns and components

module PlaygroundDogfoodExamples
  # 1. E-commerce Product Grid
  PRODUCT_GRID = <<~RUBY
    swift_ui do
      # Responsive product grid with hover effects
      grid(cols: 3, gap: 16) do
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
  DASHBOARD_STATS = <<~RUBY
    swift_ui do
      grid(cols: 4, gap: 16) do
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
                  .text_sm
                  .text_color("gray-600")
                  .font_weight("medium")
                
                div
                  .w(8).h(8)
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
              
              hstack(spacing: 2, alignment: :center) do
                span(stat[:change])
                  .text_sm
                  .font_weight("medium")
                  .text_color("#{stat[:color]}-600")
                
                text("from last month")
                  .text_sm
                  .text_color("gray-500")
              end
            end
          end
        end
      end
    end
  RUBY

  # 3. Interactive Pricing Cards
  PRICING_CARDS = <<~RUBY
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
                button("Get Started")
                  .w("full")
                  .py(3)
                  .rounded("lg")
                  .font_weight("semibold")
                  .transition
                  .tap do |btn|
                    if plan[:popular]
                      btn
                        .bg("gradient-to-r").from("purple-600").to("pink-600")
                        .text_color("white")
                        .hover_shadow("lg")
                        .hover_scale(105)
                    else
                      btn
                        .bg("white")
                        .text_color("gray-900")
                        .border.border_color("gray-300")
                        .hover_bg("gray-50")
                    end
                  end
              end
            end
          end
          .tap { |c| c.scale(105) if plan[:popular] }
        end
      end
    end
  RUBY

  # 4. Interactive Todo List with Stimulus
  TODO_LIST = <<~RUBY
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
  NAVBAR = <<~RUBY
    swift_ui do
      nav.bg("white").shadow("md").sticky.top(0).z(50) do
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
              hstack(spacing: 1).hidden.md_flex do
                ["Home", "Components", "Documentation", "Examples"].each do |item|
                  link(item, destination: "#")
                    .px(4).py(2)
                    .rounded("lg")
                    .text_color("gray-700")
                    .hover_bg("gray-100")
                    .hover_text_color("blue-600")
                    .transition
                end
              end
            end
            
            # Right side actions
            hstack(spacing: 4, alignment: :center) do
              # Search button
              button("")
                .p(2)
                .rounded("lg")
                .text_color("gray-600")
                .hover_bg("gray-100")
                .tap { |b| b.content { text("🔍") } }
              
              # Notifications
              div.relative do
                button("")
                  .p(2)
                  .rounded("lg")
                  .text_color("gray-600")
                  .hover_bg("gray-100")
                  .tap { |b| b.content { text("🔔") } }
                
                # Notification badge
                span("3")
                  .absolute.top(0).right(0)
                  .bg("red-500")
                  .text_color("white")
                  .text_xs
                  .w(5).h(5)
                  .rounded("full")
                  .flex.items_center.justify_center
              end
              
              # User menu
              div.relative.group do
                button
                  .flex.items_center.gap(2)
                  .p(2)
                  .rounded("lg")
                  .hover_bg("gray-100") do
                  div.w(8).h(8).rounded("full").bg("gradient-to-br").from("blue-500").to("purple-600")
                  text("▼").text_xs.text_color("gray-600")
                end
                
                # Dropdown menu
                div
                  .absolute.right(0).top(12)
                  .w(48)
                  .bg("white")
                  .rounded("lg")
                  .shadow("lg")
                  .border.border_color("gray-200")
                  .hidden.group_hover_block
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
              button("")
                .p(2)
                .rounded("lg")
                .text_color("gray-600")
                .hover_bg("gray-100")
                .md_hidden
                .tap { |b| b.content { text("☰") } }
            end
          end
        end
      end
    end
  RUBY

  def self.all_examples
    {
      product_grid: PRODUCT_GRID,
      dashboard_stats: DASHBOARD_STATS,
      pricing_cards: PRICING_CARDS,
      todo_list: TODO_LIST,
      navbar: NAVBAR
    }
  end
end