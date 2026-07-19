# frozen_string_literal: true

module SwiftUIRails
  # Server intent for browser focus. The browser's activeElement remains the
  # source of truth while a page is live; this value selects the element to
  # focus after the next server render or Turbo replacement.
  module FocusState
    IDENTIFIER_PATTERN = /\A[a-z][a-z0-9_]{0,63}\z/.freeze
    UNSET = Object.new.freeze

    class Binding
      attr_reader :owner, :name

      def initialize(owner, name)
        @owner = owner
        @name = FocusState.normalize_name(name)
        freeze
      end

      def value
        owner.public_send(name)
      end

      def value=(new_value)
        owner.public_send("#{name}=", new_value)
      end
    end

    class << self
      def normalize_name(name)
        value = name.to_s
        unless value.match?(IDENTIFIER_PATTERN)
          raise ArgumentError, "focus state names must match #{IDENTIFIER_PATTERN.inspect}"
        end

        value.to_sym
      end

      def serialize_value(value)
        serialized = case value
        when nil then ""
        when String, Symbol, Integer, Float, TrueClass, FalseClass then value.to_s
        else
          raise TypeError, "focus values must be scalar strings, symbols, numbers, booleans, or nil"
        end

        if serialized.bytesize > 128 || serialized.match?(/[\u0000-\u001f\u007f]/)
          raise ArgumentError, "focus values must be at most 128 bytes and contain no control characters"
        end

        serialized
      end
    end

    module ComponentSupport
      extend ActiveSupport::Concern

      included do
        class_attribute :swift_focus_state_definitions,
          instance_accessor: false,
          default: {}
      end

      class_methods do
        # Focus state is backed by the component's existing State machinery so
        # an action can request focus and preserve that request across a signed
        # reactive render. It intentionally does not mirror every activeElement
        # change back to the server.
        def focus_state(name, default: nil, values: nil)
          key = FocusState.normalize_name(name)
          allowed_values = values.nil? ? nil : Array(values).dup.freeze
          allowed_values&.each { |value| FocusState.serialize_value(value) }
          FocusState.serialize_value(default)
          if allowed_values && !default.nil? && !allowed_values.include?(default)
            raise ArgumentError, "Focus state '#{key}' default must be one of #{allowed_values.inspect}"
          end

          if method_defined?(key) || private_method_defined?(key) || protected_method_defined?(key)
            raise ArgumentError, "focus state '#{key}' would replace an existing component method"
          end

          state(key, default, type: Object)
          generated_setter = instance_method("#{key}=")

          define_method("#{key}=") do |value|
            FocusState.serialize_value(value)
            if allowed_values && !value.nil? && !allowed_values.include?(value)
              raise ArgumentError, "Focus state '#{key}' must be one of #{allowed_values.inspect}"
            end

            generated_setter.bind_call(self, value)
          end

          define_method("#{key}_focus_binding") do
            FocusState::Binding.new(self, key)
          end

          self.swift_focus_state_definitions = swift_focus_state_definitions.merge(
            key => { default: default, values: allowed_values }.freeze
          ).freeze
        end
      end
    end
  end
end

SwiftUIRails::Component::Base.include(SwiftUIRails::FocusState::ComponentSupport)
