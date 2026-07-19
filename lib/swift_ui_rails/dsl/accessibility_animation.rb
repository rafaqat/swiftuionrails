# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # First-class web accessibility and value-driven animation modifiers.
    # These map portable SwiftUI intent to ARIA, semantic HTML metadata, and
    # CSS transitions while keeping the browser accessibility tree authoritative.
    module AccessibilityAnimationModifiers
      ACCESSIBILITY_ROLES = %w[
        alert alertdialog application article banner button cell checkbox
        columnheader complementary contentinfo dialog feed figure form grid
        gridcell group heading img link list listbox listitem log main marquee
        math menu menubar menuitem meter navigation note option progressbar
        radio radiogroup region row rowgroup rowheader scrollbar search slider
        spinbutton status switch tab table tablist tabpanel term textbox timer
        toolbar tooltip tree treegrid treeitem
      ].freeze
      ACCESSIBILITY_LIVE_VALUES = %w[off polite assertive].freeze
      ACCESSIBILITY_CURRENT_VALUES = %w[page step location date time true false].freeze
      ACCESSIBILITY_TRAITS = %i[button link header image selected disabled].freeze

      ANIMATION_CURVES = {
        linear: "linear",
        ease_in: "ease-in",
        ease_out: "ease-out",
        ease_in_out: "ease-in-out",
        spring: "cubic-bezier(0.22, 1, 0.36, 1)"
      }.freeze
      ANIMATION_PROPERTIES = {
        all: "all",
        opacity: "opacity",
        transform: "transform",
        colors: "color, background-color, border-color, text-decoration-color, fill, stroke",
        shadow: "box-shadow"
      }.freeze
      CONTENT_TRANSITIONS = %i[identity opacity numeric_text interpolate].freeze

      def accessibility_label(value)
        set_accessibility_attribute("aria-label", value, name: "accessibility label")
      end

      def accessibility_value(value)
        set_accessibility_attribute("aria-valuetext", value, name: "accessibility value")
      end

      def accessibility_hint(value)
        set_accessibility_attribute("aria-description", value, name: "accessibility hint")
      end

      def accessibility_role(value)
        role = value.to_s.tr("_", "-")
        raise ArgumentError, "unknown accessibility role: #{value.inspect}" unless ACCESSIBILITY_ROLES.include?(role)

        @attributes["role"] = role
        self
      end

      def accessibility_hidden(hidden = true)
        set_accessibility_boolean("aria-hidden", hidden)
      end

      def accessibility_live(value = :polite, atomic: nil)
        live = value.to_s
        raise ArgumentError, "accessibility live value must be :off, :polite, or :assertive" unless ACCESSIBILITY_LIVE_VALUES.include?(live)

        @attributes["aria-live"] = live
        set_accessibility_boolean("aria-atomic", atomic) unless atomic.nil?
        self
      end

      def accessibility_heading(level: 2)
        heading_level = Integer(level)
        raise ArgumentError, "accessibility heading level must be between 1 and 6" unless heading_level.between?(1, 6)

        @attributes["role"] = "heading"
        @attributes["aria-level"] = heading_level
        self
      rescue TypeError, ArgumentError => error
        raise error if error.message.start_with?("accessibility heading")

        raise ArgumentError, "accessibility heading level must be between 1 and 6"
      end

      def accessibility_identifier(value)
        identifier = value.to_s
        unless identifier.match?(/\A[A-Za-z][A-Za-z0-9_-]{0,127}\z/)
          raise ArgumentError, "accessibility identifier must be a safe DOM id"
        end

        @attributes["id"] = identifier
        self
      end

      def accessibility_state(selected: nil, expanded: nil, pressed: nil, busy: nil, checked: nil, current: nil)
        {
          "aria-selected" => selected,
          "aria-expanded" => expanded,
          "aria-pressed" => pressed,
          "aria-busy" => busy,
          "aria-checked" => checked
        }.each do |attribute, value|
          set_accessibility_boolean(attribute, value) unless value.nil?
        end

        unless current.nil?
          normalized = current.to_s
          unless ACCESSIBILITY_CURRENT_VALUES.include?(normalized)
            raise ArgumentError, "unknown accessibility current value: #{current.inspect}"
          end
          @attributes["aria-current"] = normalized
        end

        self
      end

      def accessibility_traits(*traits)
        normalized = traits.flatten.map(&:to_sym)
        invalid = normalized - ACCESSIBILITY_TRAITS
        raise ArgumentError, "unknown accessibility traits: #{invalid.join(', ')}" if invalid.any?

        normalized.each do |trait|
          case trait
          when :button then @attributes["role"] = "button"
          when :link then @attributes["role"] = "link"
          when :header then accessibility_heading
          when :image then @attributes["role"] = "img"
          when :selected then @attributes["aria-selected"] = "true"
          when :disabled then @attributes["aria-disabled"] = "true"
          end
        end
        self
      end

      # CSS is the web animation authority. `value:` becomes stable render
      # metadata so Turbo/morphing can associate a transition with a specific
      # state change; reduced-motion CSS disables the transition globally.
      def animation(curve = :ease_in_out, duration: 0.2, delay: 0, value: nil, properties: :all)
        curve_name = curve.to_sym
        property_name = properties.to_sym
        timing = ANIMATION_CURVES.fetch(curve_name) do
          raise ArgumentError, "unknown animation curve: #{curve.inspect}"
        end
        property = ANIMATION_PROPERTIES.fetch(property_name) do
          raise ArgumentError, "unknown animation properties: #{properties.inspect}"
        end
        duration_value = accessibility_animation_number(duration, name: "duration", maximum: 10)
        delay_value = accessibility_animation_number(delay, name: "delay", maximum: 10)

        declarations = [
          "transition-property: #{property}",
          "transition-duration: #{duration_value}s",
          "transition-timing-function: #{timing}",
          "transition-delay: #{delay_value}s"
        ]
        @options[:style] = [@options[:style], *declarations].compact.reject(&:blank?).join("; ")
        tw("swift-ui-value-animation")

        unless value.nil?
          serialized = value.is_a?(String) ? value : value.to_json
          raise ArgumentError, "animation value must be at most 512 bytes" if serialized.bytesize > 512

          @attributes["data-sui-animation-value"] = serialized
        end
        self
      end

      def content_transition(effect = :opacity)
        normalized = effect.to_sym
        raise ArgumentError, "unknown content transition: #{effect.inspect}" unless CONTENT_TRANSITIONS.include?(normalized)

        @attributes["data-sui-content-transition"] = normalized.to_s.tr("_", "-")
        tw("tabular-nums") if normalized == :numeric_text
        self
      end

      private

      def set_accessibility_attribute(attribute, value, name:)
        text = value.to_s.strip
        raise ArgumentError, "#{name} cannot be blank" if text.empty?
        raise ArgumentError, "#{name} must be at most 1024 bytes" if text.bytesize > 1024
        raise ArgumentError, "#{name} cannot contain control characters" if text.match?(/[\u0000-\u001f\u007f]/)

        @attributes[attribute] = text
        self
      end

      def set_accessibility_boolean(attribute, value)
        unless value == true || value == false
          raise ArgumentError, "#{attribute} must be true or false"
        end

        @attributes[attribute] = value.to_s
        self
      end

      def accessibility_animation_number(value, name:, maximum:)
        number = Float(value)
        unless number.finite? && number.between?(0, maximum)
          raise ArgumentError, "animation #{name} must be between 0 and #{maximum} seconds"
        end

        number.to_s
      rescue TypeError, ArgumentError
        raise ArgumentError, "animation #{name} must be between 0 and #{maximum} seconds"
      end
    end
  end
end

SwiftUIRails::DSL::Element.prepend(SwiftUIRails::DSL::AccessibilityAnimationModifiers)
