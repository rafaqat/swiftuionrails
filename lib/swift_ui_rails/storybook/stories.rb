# frozen_string_literal: true

# Copyright 2025

require_relative 'layouts'
require_relative 'previews'
require_relative 'documentation'

module SwiftUIRails
  module Storybook
    class Stories < ViewComponent::Storybook::Stories
      include Layouts
      include Previews
      include Documentation
    end
  end
end
# Copyright 2025
