class TailwindFormComponent < SwiftUIComponent
  prop :model, required: true
  prop :url, type: String, required: true
  prop :method, type: Symbol, default: :post
  prop :layout, type: Symbol, default: :vertical # :vertical, :horizontal, :inline
  
  renders_many :fields
  renders_one :actions
  
  swift_ui do
    form(action: url, method: method == :get ? :get : :post) do
      # Add Rails CSRF token
      if method != :get
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      end
      
      # Add method override for PUT/PATCH/DELETE
      if [:put, :patch, :delete].include?(method)
        input(type: "hidden", name: "_method", value: method.to_s)
      end
      
      vstack(spacing: 0).tw("space-y-6") do
        # Render fields
        fields.each do |field|
          div.tw(field_wrapper_classes) do
            field
          end
        end
        
        # Actions
        if actions?
          div.tw("flex items-center justify-end space-x-3 pt-6") do
            actions
          end
        end
      end
    end
  end
  
  private
  
  def field_wrapper_classes
    case layout
    when :horizontal
      "grid grid-cols-3 gap-6 items-start"
    when :inline
      "flex items-center space-x-4"
    else
      ""
    end
  end
end