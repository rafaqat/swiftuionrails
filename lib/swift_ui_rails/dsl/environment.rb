# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Environment
      # environment(accent: :blue) { ... }
      def environment(**values, &block)
        # Push values to thread-local stack
        current_env = Thread.current[:swift_ui_env] ||= {}
        previous_env = current_env.dup
        
        # Merge new values
        Thread.current[:swift_ui_env] = current_env.merge(values)
        
        begin
          yield
        ensure
          # Pop (restore) previous environment
          Thread.current[:swift_ui_env] = previous_env
        end
      end
      
      # Access an environment value
      # env(:accent)
      def env(key)
        (Thread.current[:swift_ui_env] || {})[key]
      end
    end
  end
end
