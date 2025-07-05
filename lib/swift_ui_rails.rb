# frozen_string_literal: true

require_relative "swift_ui_rails/version"
require_relative "swift_ui_rails/engine"
require_relative "swift_ui_rails/tailwind"
require_relative "swift_ui_rails/dsl"
require_relative "swift_ui_rails/component"
require_relative "swift_ui_rails/helpers"
require_relative "swift_ui_rails/storybook"
require_relative "swift_ui_rails/dev_tools/error_boundary" if Rails.env.development?

module SwiftUIRails
  class Error < StandardError; end
  class SecurityError < Error; end

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
    attr_accessor :allowed_components

    def initialize
      @default_transition_duration = 300
      @default_animation_easing = "ease-out"
      @component_prefix = ""
      @tailwind_enabled = true
      @stimulus_controller_suffix = "component"
      
      # SECURITY: Whitelist of allowed components to prevent RCE
      # Components must be explicitly added to this list
      @allowed_components = Set.new([
        "Button",
        "Card", 
        "Modal",
        "Counter",
        "ProductCard",
        "ProductList",
        "AuthForm",
        "EnhancedLogin",
        "EnhancedRegister",
        "AuthError",
        "AuthLayout",
        "Text",
        "Image",
        "List",
        "ListItem",
        "ScrollView",
        "VStack",
        "HStack",
        "ZStack",
        "Grid",
        "Divider",
        "Spacer",
        "SimpleButton",
        # Add new components here after security review
      ])
    end
    
    # Helper method to check if a component is allowed
    def component_allowed?(component_name)
      allowed_components.include?(component_name.to_s)
    end
  end
end