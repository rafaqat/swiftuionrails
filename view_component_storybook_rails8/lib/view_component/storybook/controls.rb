# frozen_string_literal: true
# Copyright 2025

require "active_support/dependencies/autoload"

module ViewComponent
  module Storybook
    module Controls
      extend ActiveSupport::Autoload

      autoload :Control
      autoload :SimpleControl
      autoload :Text
      autoload :Boolean
      autoload :Color
      autoload :Number
      autoload :BaseOptions
      autoload :Options
      autoload :MultiOptions
      autoload :Date
      autoload :Object
    end
  end
end
# Copyright 2025
