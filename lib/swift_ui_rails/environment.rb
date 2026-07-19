# frozen_string_literal: true

module SwiftUIRails
  # Request/fiber-local values inherited by nested component renders.
  #
  # Environment values are a server-rendering concern. They are deliberately
  # not serialized into HTML because applications commonly use the environment
  # for authorization objects, current accounts, and other private context.
  module Environment
    class MissingValueError < KeyError; end

    UNSET = Object.new.freeze
    EXECUTION_KEY = :swift_ui_rails_environment_context
    KEY_PATTERN = /\A[a-z][a-z0-9_]{0,63}\z/.freeze
    RESERVED_READER_NAMES = %i[
      call render_in render? before_render initialize method_missing respond_to_missing?
      class object_id send public_send __send__ instance_eval instance_exec
      environment environment_value environment_values with_environment
    ].freeze

    BUILT_IN_DEFAULTS = {
      locale: -> { defined?(I18n) ? I18n.locale : :en },
      time_zone: -> { Time.zone&.name if Time.respond_to?(:zone) },
      color_scheme: -> { :light },
      layout_direction: -> { :left_to_right },
      reduced_motion: -> { false }
    }.freeze

    # An immutable linked context keeps nested overrides cheap and prevents a
    # child render from mutating its parent's values.
    class Context
      attr_reader :parent

      def initialize(values = {}, parent: nil)
        @values = Environment.normalize_values(values).freeze
        @parent = parent
        freeze
      end

      def key?(name)
        key = Environment.normalize_key(name)
        @values.key?(key) || !!parent&.key?(key)
      end

      def fetch(name, fallback = UNSET)
        key = Environment.normalize_key(name)
        return @values.fetch(key) if @values.key?(key)
        return parent.fetch(key, fallback) if parent
        return fallback unless fallback.equal?(UNSET)

        raise MissingValueError, "Environment value '#{key}' is missing"
      end

      def merge(values)
        self.class.new(values, parent: self)
      end

      def to_h
        (parent ? parent.to_h : {}).merge(@values)
      end
    end

    class << self
      def current
        # Thread#[] is fiber-local in supported Ruby versions. Rails'
        # IsolatedExecutionState defaults to thread isolation, which can leak
        # context when a server interleaves more than one fiber on a thread.
        Thread.current[EXECUTION_KEY] || Context.new
      end

      def with(values = nil, **keyword_values)
        base_values = values || {}
        raise TypeError, "environment values must be a Hash" unless base_values.is_a?(Hash)

        additions = normalize_values(base_values.merge(keyword_values))
        with_context(current.merge(additions)) { yield }
      end

      def with_context(context)
        raise TypeError, "environment context must be a Context" unless context.is_a?(Context)

        previous = Thread.current[EXECUTION_KEY]
        begin
          Thread.current[EXECUTION_KEY] = context
          yield
        ensure
          Thread.current[EXECUTION_KEY] = previous
        end
      end

      def fetch(name, default: UNSET)
        key = normalize_key(name)
        return current.fetch(key) if current.key?(key)

        provider = BUILT_IN_DEFAULTS[key]
        return provider.call if provider
        return default unless default.equal?(UNSET)

        raise MissingValueError, "Environment value '#{key}' is missing"
      end

      def normalize_key(name)
        key = name.to_s
        unless key.match?(KEY_PATTERN)
          raise ArgumentError, "environment keys must match #{KEY_PATTERN.inspect}"
        end

        key.to_sym
      end

      def normalize_values(values)
        raise TypeError, "environment values must be a Hash" unless values.is_a?(Hash)

        values.each_with_object({}) do |(name, value), normalized|
          normalized[normalize_key(name)] = value
        end
      end
    end

    module ComponentSupport
      extend ActiveSupport::Concern

      included do
        class_attribute :swift_environment_definitions,
          instance_accessor: false,
          default: {}
      end

      class_methods do
        # Declare a dependency supplied by an ancestor environment scope.
        def environment(name, default: UNSET, type: nil, required: false)
          key = Environment.normalize_key(name)
          validate_environment_reader!(key)
          validate_environment_type!(type)

          self.swift_environment_definitions = swift_environment_definitions.merge(
            key => { default: default, type: type, required: required == true }.freeze
          ).freeze

          define_method(key) { environment_value(key) }
        end

        private

        def validate_environment_reader!(key)
          locally_defined = instance_methods(false).include?(key) ||
            private_instance_methods(false).include?(key) ||
            protected_instance_methods(false).include?(key)
          return unless locally_defined || Environment::RESERVED_READER_NAMES.include?(key)

          raise ArgumentError, "environment '#{key}' would replace an existing component method"
        end

        def validate_environment_type!(type)
          candidates = Array(type).compact
          return if candidates.all? { |candidate| candidate.is_a?(Module) }

          raise TypeError, "environment type must be a class/module or an array of classes/modules"
        end
      end

      # Apply values to this component render and every nested component render.
      def with_environment(values = nil, **keyword_values)
        base_values = values || {}
        raise TypeError, "environment values must be a Hash" unless base_values.is_a?(Hash)

        additions = Environment.normalize_values(base_values.merge(keyword_values))
        validate_environment_overrides!(additions)
        @swift_environment_overrides = (@swift_environment_overrides || {}).merge(additions).freeze
        self
      end

      def environment_value(name, default: UNSET)
        key = Environment.normalize_key(name)
        definition = self.class.swift_environment_definitions[key]
        context = @swift_environment_context || Environment.current
        value = context.key?(key) ? context.fetch(key) : UNSET

        if value.equal?(UNSET) && definition && !definition[:default].equal?(UNSET)
          configured_default = definition[:default]
          value = configured_default.respond_to?(:call) ? instance_exec(&configured_default) : duplicate_environment_default(configured_default)
        end

        if value.equal?(UNSET) && Environment::BUILT_IN_DEFAULTS.key?(key)
          value = Environment::BUILT_IN_DEFAULTS.fetch(key).call
        end

        value = default unless !value.equal?(UNSET) || default.equal?(UNSET)

        if value.equal?(UNSET)
          if definition&.fetch(:required, false)
            raise MissingValueError, "Required environment value '#{key}' is missing"
          end

          return nil
        end

        validate_environment_value!(key, value, definition)
        value
      end

      # Only declared values are exposed. This prevents an inspection helper
      # from accidentally dumping an authorization object inherited by a child.
      def environment_values
        self.class.swift_environment_definitions.each_key.to_h do |name|
          [name, environment_value(name)]
        end
      end

      def render_in(view_context, **options, &block)
        parent_context = Environment.current
        render_context = parent_context.merge(@swift_environment_overrides || {})
        @swift_environment_context = render_context

        Environment.with_context(render_context) { super }
      end

      private

      def validate_environment_overrides!(values)
        values.each do |name, value|
          validate_environment_value!(name, value, self.class.swift_environment_definitions[name])
        end
      end

      def validate_environment_value!(name, value, definition)
        if definition&.fetch(:required, false) && value.nil?
          raise MissingValueError, "Required environment value '#{name}' is missing"
        end

        expected = definition&.fetch(:type, nil)
        return value if expected.nil? || value.nil?

        valid = Array(expected).any? { |candidate| value.is_a?(candidate) }
        return value if valid

        raise TypeError, "Environment value '#{name}' must be a #{Array(expected).map(&:to_s).join(' or ')}"
      end

      def duplicate_environment_default(value)
        value.respond_to?(:deep_dup) ? value.deep_dup : value
      end
    end
  end
end

SwiftUIRails::Component::Base.include(SwiftUIRails::Environment::ComponentSupport)
