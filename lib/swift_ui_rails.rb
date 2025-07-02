# frozen_string_literal: true

require_relative "swift_ui_rails/version"
require_relative "swift_ui_rails/engine"
require_relative "swift_ui_rails/tailwind"
require_relative "swift_ui_rails/dsl"
require_relative "swift_ui_rails/component"
require_relative "swift_ui_rails/helpers"
require_relative "swift_ui_rails/storybook"

module SwiftUIRails
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  class Configuration
    attr_accessor :default_transition_duration
    attr_accessor :default_animation_easing
    attr_accessor :component_prefix
    attr_accessor :tailwind_enabled
    attr_accessor :stimulus_controller_suffix

    def initialize
      @default_transition_duration = 300
      @default_animation_easing = "ease-out"
      @component_prefix = ""
      @tailwind_enabled = true
      @stimulus_controller_suffix = "component"
    end
  end
end