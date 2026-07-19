# frozen_string_literal: true

module SwiftUIRails
  module DSL
    BADGE_TONES = {
      neutral: "bg-gray-100 text-gray-700 ring-gray-500/10",
      info: "bg-blue-50 text-blue-700 ring-blue-700/10",
      success: "bg-green-50 text-green-800 ring-green-600/20",
      warning: "bg-amber-50 text-amber-800 ring-amber-600/20",
      danger: "bg-red-50 text-red-700 ring-red-600/10"
    }.freeze

    # A web-semantic status pill. SwiftUI doesn't ship a generic status Badge
    # view, but extracting this repeated composition follows SwiftUI's approach
    # of naming small, reusable views.
    def badge(content, tone: :neutral, announce: false, **attrs)
      tone_classes = BADGE_TONES.fetch(tone.to_sym) do
        raise ArgumentError, "unknown badge tone: #{tone.inspect}; expected one of: #{BADGE_TONES.keys.join(', ')}"
      end
      attrs[:class] = class_names(
        "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ring-1 ring-inset",
        tone_classes,
        attrs[:class]
      )
      attrs[:role] ||= "status" if announce
      create_element(:span, content, **attrs)
    end

    # Native HTML progress gives browsers and assistive technology the same
    # determinate/indeterminate semantics that SwiftUI's ProgressView exposes.
    def progress_view(value: nil, total: 1.0, label: "Progress", **attrs)
      maximum = finite_number!(total, name: "total")
      raise ArgumentError, "total must be greater than zero" unless maximum.positive?

      attrs[:max] = maximum
      attrs[:value] = finite_number!(value, name: "value").clamp(0, maximum) unless value.nil?
      attrs[:aria] = { label: label }.merge(attrs.fetch(:aria, {}))
      attrs[:class] = class_names("swift-ui-progress", attrs[:class])

      fallback = value.nil? ? label : "#{((attrs[:value] / maximum) * 100).round}%"
      create_element(:progress, fallback, **attrs)
    end

    # Uses the HTML meter primitive so min/max/current-value semantics remain
    # available without JavaScript.
    def gauge(value:, range: 0..100, label: "Value", **attrs)
      minimum, maximum = normalized_numeric_range(range)
      current = finite_number!(value, name: "value").clamp(minimum, maximum)
      attrs[:min] = minimum
      attrs[:max] = maximum
      attrs[:value] = current
      attrs[:aria] = { label: label }.merge(attrs.fetch(:aria, {}))
      attrs[:class] = class_names("swift-ui-gauge", attrs[:class])
      create_element(:meter, "#{current} #{label}", **attrs)
    end

    def control_group(label: nil, **attrs, &block)
      attrs[:role] ||= "group"
      attrs[:aria] = { label: label }.merge(attrs.fetch(:aria, {})) if label
      attrs[:class] = class_names("inline-flex items-center gap-2", attrs[:class])

      create_element(:fieldset, nil, **attrs) do
        create_element(:legend, label, class: "sr-only") if label
        instance_eval(&block) if block
      end
    end

    # Details/summary is the progressive-enhancement equivalent of SwiftUI's
    # DisclosureGroup: keyboard-operable and useful without JavaScript.
    def disclosure_group(label, expanded: false, **attrs, &block)
      attrs[:open] = true if expanded
      attrs[:class] = class_names("swift-ui-disclosure", attrs[:class])

      create_element(:details, nil, **attrs) do
        create_element(:summary, label, class: "cursor-pointer")
        instance_eval(&block) if block
      end
    end

    # A browser-native disclosure menu that preserves keyboard and
    # no-JavaScript behavior without an application controller.
    def menu(label, **attrs, &block)
      attrs[:class] = class_names("swift-ui-menu relative", attrs[:class])

      create_element(:details, nil, **attrs) do
        create_element(:summary, label, role: "button", class: "cursor-pointer")
        create_element(:div, nil, role: "menu", &block)
      end
    end

    def date_picker(name:, value: nil, min: nil, max: nil, include_time: false, **attrs)
      attrs[:type] = include_time ? "datetime-local" : "date"
      attrs[:name] = name
      attrs[:value] = temporal_input_value(value, include_time: include_time) if value
      attrs[:min] = temporal_input_value(min, include_time: include_time) if min
      attrs[:max] = temporal_input_value(max, include_time: include_time) if max
      create_element(:input, nil, **attrs)
    end

    def color_picker(name:, value: "#000000", **attrs)
      color = value.to_s
      unless color.match?(/\A#[0-9a-fA-F]{6}\z/)
        raise ArgumentError, "color picker value must use #RRGGBB"
      end

      attrs[:type] = "color"
      attrs[:name] = name
      attrs[:value] = color
      create_element(:input, nil, **attrs)
    end

    # Browsers already expose an accessible stepper for number inputs. This
    # keeps increment/decrement behavior functional without client JavaScript.
    def stepper(name:, value:, range: nil, step: 1, **attrs)
      attrs[:type] = "number"
      attrs[:name] = name
      attrs[:value] = finite_number!(value, name: "value")
      attrs[:step] = finite_number!(step, name: "step")
      raise ArgumentError, "step must be greater than zero" unless attrs[:step].positive?

      if range
        minimum, maximum = normalized_numeric_range(range)
        attrs[:min] = minimum
        attrs[:max] = maximum
        attrs[:value] = attrs[:value].clamp(minimum, maximum)
      end

      create_element(:input, nil, **attrs)
    end

    private

    def finite_number!(value, name:)
      number = Float(value)
      raise ArgumentError, "#{name} must be finite" unless number.finite?

      number
    rescue TypeError, ArgumentError
      raise ArgumentError, "#{name} must be a finite number"
    end

    def normalized_numeric_range(range)
      unless range.respond_to?(:begin) && range.respond_to?(:end)
        raise ArgumentError, "range must have numeric endpoints"
      end

      minimum = finite_number!(range.begin, name: "range minimum")
      maximum = finite_number!(range.end, name: "range maximum")
      raise ArgumentError, "range maximum must be greater than its minimum" unless maximum > minimum

      [minimum, maximum]
    end

    def temporal_input_value(value, include_time:)
      parsed = if value.respond_to?(:strftime)
        value
      else
        include_time ? Time.zone.parse(value.to_s) : Date.iso8601(value.to_s)
      end
      parsed.strftime(include_time ? "%Y-%m-%dT%H:%M" : "%Y-%m-%d")
    rescue ArgumentError, TypeError
      raise ArgumentError, "invalid #{include_time ? 'date and time' : 'date'} value"
    end
  end
end
