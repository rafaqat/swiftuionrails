# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module ServerActions
      # .on_action(:method_name)
      # Triggers a server-side method call via Turbo Stream
      def on_action(event, method_name)
        # We need to construct a URL that triggers the action
        # /swift_ui/action?component=Class&id=ID&method=method_name
        
        # NOTE: This relies on the frontend `server-action` controller being present
        data(
          controller: "server-action",
          action: "#{event}->server-action#trigger",
          server_action_name_value: method_name
        )
        self
      end

      # Alias for common clicks
      def on_server_click(method_name)
        on_action("click", method_name)
      end
    end
  end
end
