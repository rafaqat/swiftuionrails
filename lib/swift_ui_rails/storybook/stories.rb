# frozen_string_literal: true

module SwiftUIRails
  module Storybook
    class Stories < ViewComponent::Storybook::Stories
      include Layouts
      include Previews
      include Documentation
    end
  end
end