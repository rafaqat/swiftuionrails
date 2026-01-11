# frozen_string_literal: true

module StandardRailsFormDemo
  APP_UI = <<~'RUBY'
    swift_ui do
      NavigationStack do
        NavigationTitle("Standard Rails Form")
        
        List(style: :inset_grouped) do
          Section(header: "Traditional Submit", footer: "This form submits to a standard Rails controller action.") do
            
            # This renders a standard <form action="/..." method="post">
            # It automatically includes the CSRF token via secure_form
            Form(action: "/v2/playground/form_submit_demo", method: :post) do
              
              vstack(spacing: 4) do
                TextField("Name", name: "name", placeholder: "Enter your name")
                TextField("Email", name: "email", placeholder: "Enter your email")
                
                Button("Submit to Controller", type: "submit")
                  .bg(:blue)
                  .fg(:white)
                  .w(:full)
                  .padding(:y, 2)
                  .rounded(:lg)
              end.padding
              
            end
          end
          
          # Feedback Area
          Section(header: "Feedback") do
            div(id: "form-feedback").padding do
              Text("Submit the form above to see the result here.").fg(:gray_500)
            end
          end
        end
      end
    end
  RUBY
end
