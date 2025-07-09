# frozen_string_literal: true

# Copyright 2025

# A clean component base for tests that doesn't include ComponentValidator
# This prevents test components from inheriting validations from other components
# when eager loading is enabled (CI=true)
class TestComponentBase < ::ViewComponent::Base
  include SwiftUIRails::DSL

  # Add orientation support
  attr_reader :orientation

  class_attribute :swift_props, default: {}

  class << self
    def prop(name, type: nil, required: false, default: nil)
      self.swift_props = swift_props.merge(
        name => { type: type, required: required, default: default }
      )
      attr_reader name
    end

    def swift_ui(&block)
      @swift_ui_block = block

      define_method :call do
        # Create a DSL context for proper element management
        dsl_context = SwiftUIRails::DSLContext.new(self)

        # Store component reference in the context
        dsl_context.instance_variable_set(:@component, self)

        # Execute the block in the DSL context
        dsl_context.instance_eval(&self.class.instance_variable_get(:@swift_ui_block))

        # Flush all collected elements
        dsl_context.flush_elements
      end
    end
  end

  def initialize(**props)
    # Extract orientation
    @orientation = props.delete(:orientation) || :portrait

    # Set props
    self.class.swift_props.each do |name, config|
      value = props.fetch(name, config[:default])
      instance_variable_set("@#{name}", value)
    end

    super(**props.except(*self.class.swift_props.keys))
  end

  # Include orientation helpers
  include SwiftUIRails::Orientation::Helpers
  include SwiftUIRails::Orientation::SizeClasses

  # Add component_id method
  def component_id
    @component_id ||= "test_component_#{object_id}"
  end
end
# Copyright 2025
