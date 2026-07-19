# frozen_string_literal: true

require "json"
require "uri"
require_relative "../render_ir/semantic_action_events"

module SwiftUIRails
  module DSL
    # A server-only environment boundary. Values are inherited while the block
    # renders but are never emitted into the resulting HTML.
    def environment_scope(**values, &block)
      raise ArgumentError, "environment_scope requires a block" unless block

      div(&block).environment(values)
    end

    # A concrete DOM boundary for lifecycle, task, and focus events.
    def lifecycle_scope(id: nil, **attrs, &block)
      div(**attrs, &block).lifecycle(id: id)
    end

    def focus_scope(name, **attrs, &block)
      div(**attrs, &block).focus_scope(name)
    end

    module InteractionElement
      ACTION_EVENTS = SwiftUIRails::RenderIR::SemanticActionEvents::ALL
      NATIVE_FOCUSABLE_TAGS = %i[button input select textarea summary].freeze
      TASK_METHODS = %i[get post].freeze
      TASK_TRIGGERS = %i[appear manual].freeze
      TASK_RESPONSES = %i[event replace_content].freeze
      DRAG_AXES = %i[both horizontal vertical].freeze
      KEY_PHASES = { down: "keydown", up: "keyup" }.freeze
      KEY_SCOPES = %i[element window].freeze
      KEY_MODIFIERS = %i[alt control meta shift].freeze
      NAMED_KEYS = {
        enter: "Enter",
        space: " ",
        escape: "Escape",
        tab: "Tab",
        arrow_up: "ArrowUp",
        arrow_down: "ArrowDown",
        arrow_left: "ArrowLeft",
        arrow_right: "ArrowRight",
        home: "Home",
        end: "End",
        page_up: "PageUp",
        page_down: "PageDown",
        backspace: "Backspace",
        delete: "Delete"
      }.freeze

      # Validate the finite event vocabulary before Element records the Ruby
      # action in its framework-neutral data-sui-actions map.
      def add_server_action(event_type, &block)
        event_name = normalize_action_event(event_type)
        super(event_name, &block)
      end

      # SwiftUI-style environment override for this element's render subtree.
      def environment(name = nil, value = Environment::UNSET, **values)
        additions = if name.is_a?(Hash)
          raise ArgumentError, "pass either a values hash or keyword values" unless value.equal?(Environment::UNSET)

          name.merge(values)
        elsif name
          raise ArgumentError, "an environment value is required" if value.equal?(Environment::UNSET)

          values.merge(name => value)
        else
          values
        end

        @swift_ui_environment_overrides = (@swift_ui_environment_overrides || {}).merge(
          Environment.normalize_values(additions)
        ).freeze
        self
      end

      def to_s
        if @swift_ui_environment_overrides&.any?
          Environment.with(@swift_ui_environment_overrides) { super }
        else
          super
        end
      end

      # Marks a DOM boundary whose connect/disconnect events are the web-native
      # view lifecycle. Disappear events are best effort during page teardown;
      # critical persistence belongs in forms or explicit server actions.
      def lifecycle(id: nil)
        @attributes["data-sui-lifecycle"] = "1"
        @attributes["data-sui-lifecycle-id"] = normalize_client_id(id) if id
        self
      end

      def on_appear(&block)
        lifecycle
        add_server_action("swift-ui-appear", &block) if block
        self
      end

      def on_disappear(&block)
        lifecycle
        add_server_action("swift-ui-disappear", &block) if block
        self
      end

      # A cancellable same-origin browser fetch tied to this element's DOM
      # lifecycle. The initial server-rendered content remains the no-JS path.
      def task(url:, id: nil, method: :get, trigger: :appear, response: :event)
        safe_method = method.to_s.downcase.to_sym
        safe_trigger = trigger.to_s.downcase.to_sym
        safe_response = response.to_s.downcase.to_sym
        raise ArgumentError, "task method must be get or post" unless TASK_METHODS.include?(safe_method)
        raise ArgumentError, "task trigger must be appear or manual" unless TASK_TRIGGERS.include?(safe_trigger)
        raise ArgumentError, "task response must be event or replace_content" unless TASK_RESPONSES.include?(safe_response)
        if safe_method == :post && safe_trigger != :manual
          raise ArgumentError, "POST tasks must be manual; use refreshable or trigger: :manual"
        end

        lifecycle(id: id)
        @attributes["data-sui-task"] = JSON.generate(
          url: validate_task_url!(url),
          method: safe_method.to_s.upcase,
          trigger: safe_trigger.to_s,
          response: safe_response.to_s
        )
        self
      end

      # refreshable is an explicit user-triggered task. Applications can
      # dispatch `swift-ui:refresh` from a button, keyboard shortcut, or their
      # own pull-to-refresh enhancement.
      def refreshable(url:, id: nil, method: :get, response: :event)
        task(url: url, id: id, method: method, trigger: :manual, response: response)
      end

      def focusable(enabled = true)
        if enabled
          unless natively_focusable?
            @attributes["tabindex"] ||= "0"
            @swift_ui_added_tabindex = true
          end
        elsif @swift_ui_added_tabindex
          @attributes.delete("tabindex")
          @attributes.delete(:tabindex)
          @swift_ui_added_tabindex = false
        end

        self
      end

      # Binds a focusable element to declared FocusState. Browser focus changes
      # are exposed as `swift-ui-focus-change` events; setting FocusState on the
      # server requests focus after the next render.
      def focused(binding_or_name, equals: true, default: false)
        owner, name, current_value = resolve_focus_binding(binding_or_name)
        serialized_value = FocusState.serialize_value(equals)
        serialized_current = FocusState.serialize_value(current_value)
        active = serialized_current == serialized_value || (default && current_value.nil?)

        @attributes["data-sui-focus"] = JSON.generate(
          key: name.to_s,
          value: serialized_value,
          active: active
        )
        @attributes["data-sui-focus-state"] = active ? "focused" : "unfocused"
        @attributes["autofocus"] = true if active

        # Keep the owner alive through rendering when a projected binding was
        # passed directly. No client-side object reference is serialized.
        @swift_ui_focus_owner = owner
        self
      end

      def default_focus(binding_or_name, equals: true)
        focused(binding_or_name, equals: equals, default: true)
      end

      def focus_scope(name)
        scope = FocusState.normalize_name(name)
        @attributes["data-sui-focus-scope"] = scope.to_s
        self
      end

      # A tap on a non-native element becomes a real keyboard-operable button.
      # Prefer the DSL's button/link helpers whenever those semantics fit.
      def on_tap(count: 1, &block)
        raise ArgumentError, "tap count must be 1 or 2" unless [1, 2].include?(count)

        event_name = count == 2 ? "dblclick" : "click"
        add_server_action(event_name, &block)
        @attributes["data-sui-tap"] = count.to_s
        ensure_keyboard_activation! unless natively_interactive?
        self
      end

      def on_click(&block)
        on_tap(&block)
      end

      def on_long_press(minimum_duration: 0.5, maximum_distance: 10, &block)
        duration_ms = bounded_number!(minimum_duration, name: "minimum_duration", min: 0.2, max: 10) * 1000
        distance = bounded_number!(maximum_distance, name: "maximum_distance", min: 0, max: 200)

        ensure_custom_control_accessibility! unless natively_interactive?
        @attributes["data-sui-long-press"] = JSON.generate(
          duration: duration_ms.round,
          distance: distance
        )
        add_server_action("swift-ui-long-press", &block) if block
        self
      end

      # Pointer dragging emits start/change/end CustomEvents. Only the end event
      # invokes the optional Ruby action, avoiding a request per pointer move.
      # Arrow-key dragging is opt-in because generic drag has no universal
      # accessible keyboard meaning.
      def on_drag(minimum_distance: 10, axis: :both, keyboard_step: nil, &block)
        safe_axis = axis.to_s.downcase.to_sym
        raise ArgumentError, "drag axis must be both, horizontal, or vertical" unless DRAG_AXES.include?(safe_axis)

        distance = bounded_number!(minimum_distance, name: "minimum_distance", min: 0, max: 200)
        step = keyboard_step.nil? ? nil : bounded_number!(keyboard_step, name: "keyboard_step", min: 0.1, max: 10_000)

        descriptor = { distance: distance, axis: safe_axis.to_s }
        descriptor[:keyboardStep] = step if step
        @attributes["data-sui-drag"] = JSON.generate(descriptor)
        append_fixed_touch_action!(safe_axis)
        focusable if step
        add_server_action("swift-ui-drag-end", &block) if block
        self
      end

      def on_key_press(keys:, modifiers: [], phase: :down, scope: :element, prevent_default: false, &block)
        raise ArgumentError, "on_key_press requires an action block" unless block
        raise ArgumentError, "only one on_key_press declaration is supported per element" if @swift_ui_key_press_configured

        event_name = KEY_PHASES[phase.to_s.downcase.to_sym]
        safe_scope = scope.to_s.downcase.to_sym
        raise ArgumentError, "key phase must be down or up" unless event_name
        raise ArgumentError, "key scope must be element or window" unless KEY_SCOPES.include?(safe_scope)

        key_names = Array(keys).map { |key| normalize_key_name(key) }.uniq
        raise ArgumentError, "at least one key is required" if key_names.empty?
        safe_modifiers = Array(modifiers).map { |modifier| modifier.to_s.downcase.to_sym }.uniq
        unknown_modifiers = safe_modifiers - KEY_MODIFIERS
        raise ArgumentError, "unknown key modifiers: #{unknown_modifiers.join(', ')}" if unknown_modifiers.any?

        focusable if safe_scope == :element
        @attributes["data-sui-keypress"] = JSON.generate(
          keys: key_names,
          modifiers: safe_modifiers.map(&:to_s),
          phase: event_name,
          scope: safe_scope.to_s,
          preventDefault: prevent_default == true
        )
        add_server_action("swift-ui-key-press", &block)
        @swift_ui_key_press_configured = true
        self
      end

      private

      def normalize_action_event(event_type)
        event_name = event_type.to_s
        return event_name if ACTION_EVENTS.include?(event_name)

        raise ArgumentError,
          "unsupported SwiftUI Rails event '#{event_name}'; use a delegated semantic action event"
      end

      def normalize_client_id(value)
        identifier = value.to_s
        unless identifier.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.:-]{0,127}\z/)
          raise ArgumentError, "lifecycle task identifiers contain only letters, numbers, dot, colon, underscore, and dash"
        end

        identifier
      end

      def validate_task_url!(url)
        value = url.to_s
        raise ArgumentError, "task URL is too long" if value.bytesize > 2048
        raise ArgumentError, "task URL must be an absolute same-origin path" unless value.start_with?("/") && !value.start_with?("//")
        raise ArgumentError, "task URL contains invalid characters" if value.include?("\\") || value.match?(/[\u0000-\u001f\u007f]/)

        uri = URI.parse(value)
        if uri.scheme || uri.host || uri.userinfo
          raise ArgumentError, "task URL must be an absolute same-origin path"
        end

        value
      rescue URI::InvalidURIError
        raise ArgumentError, "task URL is invalid"
      end

      def resolve_focus_binding(binding_or_name)
        if binding_or_name.is_a?(FocusState::Binding)
          return [binding_or_name.owner, binding_or_name.name, binding_or_name.value]
        end

        name = FocusState.normalize_name(binding_or_name)
        owner = @component
        unless owner && owner.class.respond_to?(:swift_focus_state_definitions) && owner.class.swift_focus_state_definitions.key?(name)
          raise ArgumentError, "focus state '#{name}' is not declared on this component"
        end

        [owner, name, owner.public_send(name)]
      end

      def natively_focusable?
        return true if NATIVE_FOCUSABLE_TAGS.include?(@tag_name.to_sym)
        return true if @tag_name.to_sym == :a && (@attributes["href"] || @options[:href] || @options["href"])

        @attributes.key?("tabindex") || @attributes.key?(:tabindex) || @options.key?(:tabindex) || @options.key?("tabindex")
      end

      def natively_interactive?
        return true if NATIVE_FOCUSABLE_TAGS.include?(@tag_name.to_sym)
        return true if @tag_name.to_sym == :a && (@attributes["href"] || @options[:href] || @options["href"])

        false
      end

      def ensure_keyboard_activation!
        ensure_custom_control_accessibility!
        @attributes["data-sui-keyboard-activate"] = "1"
      end

      def ensure_custom_control_accessibility!
        focusable
        @attributes["role"] ||= "button"
      end

      def bounded_number!(value, name:, min:, max:)
        number = Float(value)
        unless number.finite? && number.between?(min, max)
          raise ArgumentError, "#{name} must be between #{min} and #{max}"
        end

        number
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{name} must be between #{min} and #{max}"
      end

      def append_fixed_touch_action!(axis)
        value = { horizontal: "pan-y", vertical: "pan-x", both: "none" }.fetch(axis)
        existing = @options[:style].to_s.strip.sub(/;\z/, "")
        @options[:style] = [existing.presence, "touch-action: #{value}"].compact.join("; ")
      end

      def normalize_key_name(key)
        named = NAMED_KEYS[key.to_s.downcase.tr("-", "_").to_sym]
        return named if named

        literal = key.to_s
        return literal.downcase if literal.match?(/\A[a-zA-Z0-9]\z/)

        raise ArgumentError, "unsupported key '#{literal}'"
      end
    end
  end
end

SwiftUIRails::DSL::Element.prepend(SwiftUIRails::DSL::InteractionElement)
