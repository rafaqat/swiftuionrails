# frozen_string_literal: true

require_relative 'css_validator'

module SwiftUIRails
  module Security
    # Opt-in deterministic validation for style modifier values.
    #
    # The silent-sanitize behavior in CSSValidator exists for untrusted
    # runtime input and must not raise in production. But for authored code —
    # human or LLM-generated — a hallucinated value like bg("cerulean-500")
    # otherwise renders silently unstyled (Tailwind never compiled the class),
    # which destroys the generate→validate→repair loop. With
    # `config.strict_css = true` these checks raise ArgumentError with
    # domain-phrased messages that enumerate the valid vocabulary.
    #
    # `.tw(...)` is deliberately NOT validated: it is the documented escape
    # hatch for application-owned utilities.
    module StrictCSS
      OVERRIDE_KEY = :__swift_ui_rails_strict_css_override

      module_function

      def enabled?
        override = Thread.current[OVERRIDE_KEY]
        override.nil? ? SwiftUIRails.configuration.strict_css : override
      end

      # Temporarily overrides strict validation for only the current Ruby
      # execution fiber. Thread#[] storage is fiber-local, which prevents a
      # development lint request from changing concurrent render behavior.
      # Nested scopes and exceptions restore the exact previous value.
      def with(enabled:)
        raise ArgumentError, 'strict CSS enabled: must be true or false' unless [true, false].include?(enabled)

        previous = Thread.current[OVERRIDE_KEY]
        Thread.current[OVERRIDE_KEY] = enabled
        begin
          yield
        ensure
          Thread.current[OVERRIDE_KEY] = previous
        end
      end

      # Palette tokens: "blue-500", "white", "slate-900/10".
      def check_color!(kind, value)
        return value unless enabled? && value

        token = value.to_s
        return value if token.empty? || token.start_with?('[', '#', '--')

        base, opacity = token.split('/', 2)
        color, shade = split_color(base)

        validate_color!(kind, value, color)
        validate_shade!(kind, value, shade)
        validate_opacity!(kind, value, opacity)
        value
      end

      def check_allowlist!(kind, value, allowlist, allow_blank: false)
        return value unless enabled?

        token = value.to_s
        return value if allow_blank && token.empty?
        return value if token.start_with?('[')
        return value if allowlist.include?(token)

        raise ArgumentError,
              "unknown #{kind} #{value.inspect}; expected one of: #{allowlist.join(', ')}"
      end

      def split_color(base)
        color, shade = base.split('-', 2)
        [color, shade]
      end

      def validate_color!(kind, value, color)
        return if CSSValidator::VALID_COLORS.include?(color)

        raise ArgumentError,
              "unknown #{kind} #{value.inspect}; expected a Tailwind palette token like \"blue-500\" " \
              "with color in: #{CSSValidator::VALID_COLORS.join(', ')}"
      end

      def validate_shade!(kind, value, shade)
        return unless shade && CSSValidator::VALID_SHADES.exclude?(shade)

        raise ArgumentError,
              "unknown #{kind} shade in #{value.inspect}; expected one of: #{CSSValidator::VALID_SHADES.join(', ')}"
      end

      def validate_opacity!(kind, value, opacity)
        return unless opacity && CSSValidator::VALID_OPACITIES.exclude?(opacity)

        raise ArgumentError,
              "unknown #{kind} opacity in #{value.inspect}; " \
              "expected one of: /#{CSSValidator::VALID_OPACITIES.join(', /')}"
      end
    end
  end
end
