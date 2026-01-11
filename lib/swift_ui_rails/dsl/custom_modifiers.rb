# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module CustomModifiers
      extend ActiveSupport::Concern

      included do
        class_attribute :registered_modifiers, default: {}
      end

      class_methods do
        # register_modifier(:primary_button) { |el| el.bg(:blue).fg(:white).rounded(:lg).padding(:x, 4).padding(:y, 2) }
        def register_modifier(name, &block)
          self.registered_modifiers = registered_modifiers.merge(name => block)
        end
      end

      # Apply a registered modifier
      # element.modifier(:primary_button)
      def modifier(name)
        # Find the modifier block
        # We need access to the component class if we are inside an instance
        # or globally registered modifiers
        
        # Check global/component context
        modifier_block = SwiftUIRails::DSL::CustomModifiers.registered_modifiers[name]
        
        # If we are in a component, check its specific modifiers (if we implemented local registration)
        # For now, global registry is a good start.
        
        if modifier_block
          modifier_block.call(self)
        else
          # Warn or ignore
          Rails.logger.warn "Modifier :#{name} not found"
        end
        self
      end
      
      # Alias for style
      alias_method :style, :modifier
    end
  end
end
