# frozen_string_literal: true

require_relative 'layouts'
require_relative 'previews'
require_relative 'documentation'

module SwiftUIRails
  class Storybook
    class Stories < ViewComponent::Storybook::Stories
      include Helpers
      include Layouts
      include Previews
      include Documentation
    end
  end
end
