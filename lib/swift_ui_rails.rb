# frozen_string_literal: true

module SwiftUIRails
  class Error < StandardError; end
  class SecurityError < Error; end
end

require_relative "swift_ui_rails/version"
require_relative "swift_ui_rails/compatibility"
require_relative "swift_ui_rails/render_ir"
require_relative "swift_ui_rails/engine"
require_relative "swift_ui_rails/tailwind"
require_relative "swift_ui_rails/dsl"
require_relative "swift_ui_rails/dsl/semantic_controls"
require_relative "swift_ui_rails/dsl/navigation_presentation"
require_relative "swift_ui_rails/dsl/portable_workflows"
require_relative "swift_ui_rails/component"
require_relative "swift_ui_rails/environment"
require_relative "swift_ui_rails/focus_state"
require_relative "swift_ui_rails/dsl/interaction"
require_relative "swift_ui_rails/dsl/accessibility_animation"
require_relative "swift_ui_rails/render_ir/runtime"
require_relative "swift_ui_rails/helpers"
require_relative "swift_ui_rails/dev_tools/error_boundary" if Rails.env.development?

module SwiftUIRails
  STORYBOOK_REQUIRE_PATH = "view_component/storybook"

  class << self
    attr_accessor :configuration

    # ViewComponent Storybook is a development-time integration, not a core
    # runtime dependency. Load it when a compatible provider is available and
    # leave the core DSL usable when it is not installed.
    def load_storybook
      return true if storybook_available?

      begin
        require STORYBOOK_REQUIRE_PATH
      rescue LoadError => error
        raise unless error.path == STORYBOOK_REQUIRE_PATH

        return false
      end

      require_relative "swift_ui_rails/storybook"
      storybook_available?
    end

    def storybook_available?
      !!(defined?(ViewComponent::Storybook::Stories) &&
        defined?(SwiftUIRails::Storybook::Stories))
    end
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
    attr_accessor :allowed_components
    attr_accessor :reactive_authorization_context
    # When true, style modifiers reject unknown palette/scale values with
    # domain-phrased errors instead of silently rendering unstyled markup.
    # Intended for development/test (and LLM generation loops); production
    # keeps silent sanitization for untrusted runtime input.
    attr_accessor :strict_css

    def initialize
      @default_transition_duration = 300
      @default_animation_easing = "ease-out"
      @component_prefix = ""
      @tailwind_enabled = true
      @reactive_authorization_context = nil
      @strict_css = false
      
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

SwiftUIRails.load_storybook
