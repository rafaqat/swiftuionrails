# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module ReactiveFormElements
      # TextField("Label", text: :state_symbol)
      def TextField(label = nil, text: nil, **attrs)
        bind_key = text if text.is_a?(Symbol)
        value = bind_key && @dsl_context ? @dsl_context.send(bind_key) : text
        
        vstack(alignment: :leading, spacing: 1) do
          if label
            Text(label).font(:caption).foreground(:gray_500)
          end
          
          # The Input
          input = create_element(:input, nil, type: "text", value: value, class: "w-full p-2 border rounded focus:ring-2 focus:ring-blue-500 outline-none", **attrs)
          
          if bind_key
            input.data(
              controller: "server-action",
              action: "input->server-action#trigger",
              server_action_name_value: "update_binding",
              server_action_params_value: [bind_key].to_json
            )
          end
          
          input
        end
      end
      
      # Toggle("Label", isOn: :state_symbol)
      def Toggle(label, isOn:, **attrs)
        bind_key = isOn if isOn.is_a?(Symbol)
        value = bind_key && @dsl_context ? @dsl_context.send(bind_key) : isOn
        
        hstack(justify: :between, alignment: :center, **attrs) do
          Text(label).font(:body)
          
          # iOS-style Toggle
          label(class: "relative inline-flex items-center cursor-pointer") do
            create_element(:input, nil, type: "checkbox", checked: value, class: "sr-only peer")
              .data(
                controller: "server-action",
                action: "change->server-action#trigger",
                server_action_name_value: "update_binding",
                server_action_params_value: [bind_key].to_json
              )
            
            div(class: "w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600")
          end
        end.padding(:y, 2)
      end

      # Slider(value: :state_symbol, in: 0..100)
      def Slider(value:, range: 0..100, **attrs)
        bind_key = value if value.is_a?(Symbol)
        current_val = bind_key && @dsl_context ? @dsl_context.send(bind_key) : value
        
        create_element(:input, nil, type: "range", value: current_val, min: range.min, max: range.max, class: "w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer", **attrs)
          .data(
            controller: "server-action",
            action: "change->server-action#trigger", # or input for real-time
            server_action_name_value: "update_binding",
            server_action_params_value: [bind_key].to_json
          )
      end
    end
  end
end