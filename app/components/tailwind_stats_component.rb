class TailwindStatsComponent < SwiftUIComponent
  prop :stats, type: Array, required: true # [{ label: "Total Users", value: "1,234", change: "+12%", trend: :up }]
  prop :columns, type: Integer, default: 3
  
  swift_ui do
    div.tw("bg-white overflow-hidden shadow rounded-lg") do
      div.tw("grid grid-cols-1 md:grid-cols-#{columns} divide-y md:divide-y-0 md:divide-x divide-gray-200") do
        stats.each do |stat|
          div.tw("px-6 py-5") do
            div.tw("text-sm font-medium text-gray-500 truncate") do
              text(stat[:label])
            end
            
            div.tw("mt-1 flex items-baseline") do
              div.tw("text-2xl font-semibold text-gray-900") do
                text(stat[:value])
              end
              
              if stat[:change]
                div.tw("ml-2 flex items-baseline text-sm font-semibold #{trend_color(stat[:trend])}") do
                  if stat[:trend] == :up
                    # Up arrow
                    svg(class: "self-center flex-shrink-0 h-5 w-5 text-green-500", fill: "currentColor", viewBox: "0 0 20 20") do
                      path(fill_rule: "evenodd", d: "M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z", clip_rule: "evenodd")
                    end
                  elsif stat[:trend] == :down
                    # Down arrow
                    svg(class: "self-center flex-shrink-0 h-5 w-5 text-red-500", fill: "currentColor", viewBox: "0 0 20 20") do
                      path(fill_rule: "evenodd", d: "M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z", clip_rule: "evenodd")
                    end
                  end
                  
                  span.tw("sr-only") { stat[:trend] == :up ? "Increased by" : "Decreased by" }
                  text(stat[:change])
                end
              end
            end
            
            if stat[:description]
              div.tw("mt-2 text-sm text-gray-600") do
                text(stat[:description])
              end
            end
          end
        end
      end
    end
  end
  
  private
  
  def trend_color(trend)
    case trend
    when :up
      "text-green-600"
    when :down
      "text-red-600"
    else
      "text-gray-600"
    end
  end
end

# Usage example:
# <%= swift_ui do
#   div.tw("min-h-screen bg-gray-50") do
#     # Navigation
#     render TailwindNavigationComponent.new(
#       brand: { name: "MyApp", logo: "/logo.svg" },
#       items: [
#         { title: "Dashboard", path: "/dashboard" },
#         { title: "Users", path: "/users" },
#         { title: "Settings", path: "/settings" }
#       ],
#       current_path: request.path
#     )
#     
#     # Page content
#     div.tw("max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8") do
#       # Stats
#       div.tw("mb-8") do
#         render TailwindStatsComponent.new(
#           stats: [
#             { label: "Total Revenue", value: "$45,231", change: "+20.1%", trend: :up },
#             { label: "Active Users", value: "2,651", change: "+4.75%", trend: :up },
#             { label: "Conversion Rate", value: "3.24%", change: "-1.5%", trend: :down }
#           ]
#         )
#       end
#       
#       # Form in a card
#       render TailwindCardComponent.new(variant: :elevated, padding: :lg) do |card|
#         card.with_header do
#           h2.tw("text-xl font-semibold text-gray-900") { "User Settings" }
#         end
#         
#         card.with_content do
#           render TailwindFormComponent.new(
#             model: @user,
#             url: user_path(@user),
#             method: :patch
#           ) do |form|
#             form.with_fields do
#               render TailwindInputComponent.new(
#                 name: "user[name]",
#                 label: "Full Name",
#                 value: @user.name,
#                 required: true
#               )
#             end
#             
#             form.with_fields do
#               render TailwindInputComponent.new(
#                 name: "user[email]",
#                 label: "Email Address",
#                 type: :email,
#                 value: @user.email,
#                 help_text: "We'll never share your email with anyone else."
#               )
#             end
#             
#             form.with_fields do
#               render TailwindInputComponent.new(
#                 name: "user[notifications]",
#                 label: "Email Notifications",
#                 type: :toggle,
#                 value: @user.notifications_enabled
#               )
#             end
#             
#             form.with_actions do
#               render TailwindButtonComponent.new(
#                 title: "Cancel",
#                 variant: :secondary
#               )
#               render TailwindButtonComponent.new(
#                 title: "Save Changes",
#                 variant: :primary,
#                 type: :submit
#               )
#             end
#           end
#         end
#       end
#     end
#   end
# end %>