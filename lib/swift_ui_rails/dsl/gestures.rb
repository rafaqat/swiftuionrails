# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Gestures
      # .onTapGesture { ... }
      # Adds a click handler (Stimulus action)
      def onTapGesture(count: 1, &block)
        # In a real app, this maps to a Stimulus controller that handles tap counting/debouncing.
        # For now, it maps to click.
        on_click(&block)
      end

      # .onLongPressGesture(minimumDuration: 0.5) { ... }
      def onLongPressGesture(minimumDuration: 0.5, &block)
        # This requires a 'gestures' controller
        data(
          controller: "gestures",
          action: "mousedown->gestures#startLongPress mouseup->gestures#cancelLongPress mouseleave->gestures#cancelLongPress touchstart->gestures#startLongPress touchend->gestures#cancelLongPress",
          gestures_duration_value: minimumDuration * 1000
        )
        # We need a way to register the callback action ID for the controller to trigger
        # For now, this is a placeholder for the architecture
        self
      end
      
      # .onHover { |isHovering| ... }
      def onHover(&block)
        on_mouse_enter(&block)
        on_mouse_leave(&block) # Logic to pass boolean requires JS-to-Server communication
        self
      end
    end
  end
end
