# frozen_string_literal: true

# Load all component files
require_relative 'components/composed/auth/login_dialog_component'
require_relative 'components/composed/auth/register_dialog_component'
require_relative 'components/composed/layout/toolbar_component'
require_relative 'components/composed/layout/hero_landing_component'

# New components
require_relative 'components/omni_browser_component'

module SwiftUIRails
  module Component
    module Composed
      module Auth
        # Auth components namespace
      end

      module Layout
        # Layout components namespace
      end
    end
  end

  # New components namespace
  module Components
    # Registry of built-in complex components
  end
end
