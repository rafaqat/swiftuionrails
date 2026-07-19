# frozen_string_literal: true

require "json"

module SwiftUIRails
  module DSL
    # Navigation and presentation are deliberately expressed in browser terms:
    # Rails routes own navigation, native HTML owns the no-JavaScript behavior,
    # and a finite semantic runtime adds patterns HTML cannot provide alone.
    PRESENTATION_UNSET = Object.new.freeze
    private_constant :PRESENTATION_UNSET

    TabDefinition = Struct.new(:label, :value, :destination, :attributes, :content, keyword_init: true)
    private_constant :TabDefinition

    TOOLBAR_PLACEMENTS = %i[
      automatic
      navigation
      principal
      primary_action
      secondary_action
      confirmation_action
      cancellation_action
      destructive_action
      status
    ].freeze

    TOOLBAR_PRIORITIES = %i[low automatic high pinned].freeze
    TOOLBAR_VISIBILITIES = %i[automatic visible overflow].freeze
    TOOLBAR_MINIMIZE_THRESHOLD_RANGE = (0..1_000).freeze

    # NavigationStack maps to a labelled navigation landmark. Browser history
    # and Turbo remain the stack/path authority; this helper does not maintain a
    # second client-side navigation path.
    def navigation_stack(label:, **attrs, &block)
      accessible_label = accessible_text!(label, name: "navigation label")
      attrs[:class] = class_names("swift-ui-navigation-stack", attrs[:class])
      attrs[:aria] = semantic_attributes(attrs[:aria], label: accessible_label)

      create_element(:nav, nil, **attrs, &block)
    end

    # A NavigationLink is a real anchor. It therefore works with JavaScript
    # disabled, supports open-in-new-tab, and participates in browser history.
    def navigation_link(
      title = nil,
      destination:,
      current: nil,
      replace: false,
      turbo_frame: nil,
      **attrs,
      &block
    )
      if title.nil? && !block_given?
        raise ArgumentError, "navigation_link requires a title or block"
      end

      href = safe_navigation_destination!(destination)
      replace = boolean!(replace, name: "replace")
      current = navigation_destination_current?(href) if current.nil?
      current = boolean!(current, name: "current")

      data = attrs.delete(:data)
      navigation_data = { turbo_action: replace ? "replace" : "advance" }
      navigation_data[:turbo_frame] = safe_dom_token!(turbo_frame, name: "turbo frame") if turbo_frame

      attrs[:href] = href
      attrs[:class] = class_names("swift-ui-navigation-link", attrs[:class])
      attrs[:data] = semantic_data(data, **navigation_data)
      attrs[:aria] = semantic_attributes(attrs[:aria], current: ("page" if current))

      if attrs[:target].to_s == "_blank"
        attrs[:rel] = merge_rel_values(attrs[:rel], "noopener", "noreferrer")
      end

      if block_given?
        create_element(:a, nil, **attrs, &block)
      else
        create_element(:a, title, **attrs)
      end
    end

    # TabView uses route/hash anchors as its progressive fallback. Before the
    # semantic runtime connects every panel is readable and every tab link is
    # navigable. Enhancement applies the ARIA tab keyboard and visibility model.
    def tab_view(selection: nil, id: nil, label:, **attrs, &block)
      raise ArgumentError, "tab_view requires a block" unless block

      definitions = collect_tab_definitions(&block)
      raise ArgumentError, "tab_view requires at least one tab" if definitions.empty?

      root_id = id ? safe_dom_token!(id, name: "tab view id") : next_semantic_id("tabs")
      tabs = normalize_tab_definitions(definitions)
      selected_tab = tabs.find { |tab| tab.value == selection.to_s } || tabs.first
      accessible_label = accessible_text!(label, name: "tab view label")

      attrs[:id] = root_id
      attrs[:class] = class_names("swift-ui-tab-view", attrs[:class])
      attrs[:data] = semantic_data(
        attrs[:data],
        sui_tabs: JSON.generate(
          selection: selected_tab.value,
          initialSelection: selected_tab.value
        )
      )

      create_element(:div, nil, **attrs) do
        create_element(
          :div,
          nil,
          role: "tablist",
          aria: { label: accessible_label },
          class: "swift-ui-tab-list"
        ) do
          tabs.each do |tab_definition|
            render_tab_link(tab_definition, selected_tab: selected_tab, root_id: root_id)
          end
        end

        create_element(:div, nil, class: "swift-ui-tab-panels") do
          tabs.each do |tab_definition|
            render_tab_panel(tab_definition, selected_tab: selected_tab, root_id: root_id)
          end
        end
      end
    end

    # Declares a child of TabView. Local tabs use an in-page anchor; providing a
    # destination makes the tab route-backed and leaves selection to Rails.
    def tab(label, value:, destination: nil, **attrs, &block)
      definitions = instance_variable_get(:@_swift_ui_tab_definitions)
      raise ArgumentError, "tab must be declared inside tab_view" unless definitions
      raise ArgumentError, "tab requires a content block" unless block

      definitions << TabDefinition.new(
        label: accessible_text!(label, name: "tab label"),
        value: value.to_s,
        destination: destination,
        attributes: attrs,
        content: block
      )
      nil
    end

    # Sheet maps to a native dialog. `presented` is the server-rendered source
    # of truth; the controller upgrades an open non-modal dialog with showModal.
    def sheet(
      title,
      presented: PRESENTATION_UNSET,
      item: PRESENTATION_UNSET,
      id: nil,
      dismiss_label: "Close",
      dismiss_path: nil,
      dismissible: true,
      **attrs,
      &block
    )
      active, payload, item_bound = presentation_state(presented, item)
      return nil if item_bound && !active

      render_presentation_dialog(
        :sheet,
        title: title,
        presented: active,
        id: id,
        dismiss_label: dismiss_label,
        dismiss_path: dismiss_path,
        dismissible: dismissible,
        role: "dialog",
        attrs: attrs,
        body_block: presentation_content_block(block, payload, item_bound, active)
      )
    end

    # Popover is a details/summary disclosure so it remains operable without
    # JavaScript. The semantic runtime adds Escape and outside-click dismissal.
    def popover(label, id: nil, expanded: false, **attrs, &block)
      raise ArgumentError, "popover requires a content block" unless block

      expanded = boolean!(expanded, name: "expanded")
      popover_id = id ? safe_dom_token!(id, name: "popover id") : next_semantic_id("popover")
      label_id = "#{popover_id}-label"
      content_id = "#{popover_id}-content"

      attrs[:id] = popover_id
      attrs.delete(:open)
      attrs.delete("open")
      attrs[:open] = true if expanded
      attrs[:class] = class_names("swift-ui-popover", attrs[:class])
      attrs[:data] = semantic_data(attrs[:data], sui_popover: "1")

      create_element(:details, nil, **attrs) do
        create_element(
          :summary,
          accessible_text!(label, name: "popover label"),
          id: label_id,
          aria: { controls: content_id, haspopup: "dialog" },
          class: "swift-ui-popover-trigger"
        )
        create_element(
          :div,
          nil,
          id: content_id,
          role: "dialog",
          aria: { labelledby: label_id },
          class: "swift-ui-popover-content",
          &block
        )
      end
    end

    # Alert is a modal alertdialog with a guaranteed dismissal action. Any
    # custom block declares additional server-owned actions, not client callbacks.
    def alert(
      title,
      message: nil,
      presented: PRESENTATION_UNSET,
      item: PRESENTATION_UNSET,
      id: nil,
      dismiss_label: "OK",
      dismiss_path: nil,
      **attrs,
      &block
    )
      active, payload, item_bound = presentation_state(presented, item)
      return nil if item_bound && !active

      render_presentation_dialog(
        :alert,
        title: title,
        message: message,
        presented: active,
        id: id,
        dismiss_label: dismiss_label,
        dismiss_path: dismiss_path,
        dismissible: true,
        role: "alertdialog",
        attrs: attrs,
        actions_block: presentation_content_block(block, payload, item_bound, active)
      )
    end

    # ConfirmationDialog keeps mutations in Rails forms/links supplied by the
    # caller and always adds an explicit cancellation action.
    def confirmation_dialog(
      title,
      message: nil,
      presented: PRESENTATION_UNSET,
      item: PRESENTATION_UNSET,
      id: nil,
      cancel_label: "Cancel",
      dismiss_path: nil,
      **attrs,
      &block
    )
      active, payload, item_bound = presentation_state(presented, item)
      return nil if item_bound && !active

      render_presentation_dialog(
        :confirmation,
        title: title,
        message: message,
        presented: active,
        id: id,
        dismiss_label: cancel_label,
        dismiss_path: dismiss_path,
        dismissible: true,
        role: "alertdialog",
        attrs: attrs,
        actions_block: presentation_content_block(block, payload, item_bound, active)
      )
    end

    # A trigger is a real anchor. Its href can route to a server-rendered open
    # presentation; when the target dialog is already in the DOM, the runtime opens
    # it locally and suppresses that fallback navigation.
    def presentation_trigger(label = nil, target:, fallback: nil, **attrs, &block)
      if label.nil? && !block_given?
        raise ArgumentError, "presentation_trigger requires a label or block"
      end

      target_id = safe_dom_token!(target, name: "presentation target")
      href = fallback ? safe_application_route!(fallback, name: "presentation fallback") : "##{target_id}"
      attrs[:href] = href
      attrs[:class] = class_names("swift-ui-presentation-trigger", attrs[:class])
      attrs[:aria] = semantic_attributes(attrs[:aria], haspopup: "dialog", controls: target_id)
      attrs[:data] = semantic_data(attrs[:data], sui_present: target_id)

      if block_given?
        create_element(:a, nil, **attrs, &block)
      else
        create_element(:a, label, **attrs)
      end
    end

    # Toolbar preserves a labelled action region without JavaScript. Every item
    # starts in the main row, so the native fallback never strands an action in
    # a CSS-only menu. The semantic runtime progressively adds priority-aware overflow,
    # optional scroll minimization, roving focus, and arrow/Home/End keys.
    def toolbar(
      label:,
      orientation: :horizontal,
      overflow: true,
      overflow_label: "More actions",
      minimize_on_scroll: false,
      minimize_threshold: 24,
      **attrs,
      &block
    )
      orientation = orientation.to_sym
      unless %i[horizontal vertical].include?(orientation)
        raise ArgumentError, "orientation must be :horizontal or :vertical"
      end
      overflow = boolean!(overflow, name: "overflow")
      minimize_on_scroll = boolean!(minimize_on_scroll, name: "minimize_on_scroll")
      if minimize_on_scroll && !overflow
        raise ArgumentError, "minimize_on_scroll requires overflow: true"
      end

      threshold = toolbar_minimize_threshold!(minimize_threshold)
      accessible_overflow_label = accessible_text!(overflow_label, name: "toolbar overflow label")
      overflow_id = next_semantic_id("toolbar-overflow")

      attrs[:role] = "toolbar"
      attrs[:class] = class_names("swift-ui-toolbar swift-ui-toolbar--#{orientation}", attrs[:class])
      attrs[:aria] = semantic_attributes(
        attrs[:aria],
        label: accessible_text!(label, name: "toolbar label"),
        orientation: orientation
      )
      attrs[:data] = semantic_data(
        attrs[:data],
        sui_toolbar: JSON.generate(
          orientation: orientation,
          overflow: overflow,
          minimizeOnScroll: minimize_on_scroll,
          minimizeThreshold: threshold
        )
      )

      create_element(:div, nil, **attrs) do
        create_element(
          :div,
          nil,
          class: "swift-ui-toolbar-items",
          data: { sui_toolbar_role: "items" },
          &block
        )

        create_element(
          :details,
          nil,
          id: overflow_id,
          hidden: true,
          class: "swift-ui-toolbar-overflow",
          data: { sui_toolbar_role: "overflow" }
        ) do
          create_element(
            :summary,
            accessible_overflow_label,
            class: "swift-ui-toolbar-overflow-trigger",
            aria: { controls: "#{overflow_id}-items" }
          )
          create_element(
            :div,
            nil,
            id: "#{overflow_id}-items",
            role: "group",
            aria: { label: accessible_overflow_label },
            class: "swift-ui-toolbar-overflow-items",
            data: { sui_toolbar_role: "overflow-items" }
          )
        end
      end
    end

    # Priority controls the order in which automatic items enter overflow: low,
    # automatic, then high. Pinned and explicitly visible items never move.
    # Explicit overflow is still rendered in the main row until JavaScript
    # connects, preserving a complete keyboard-accessible native fallback.
    def toolbar_item(placement: :automatic, priority: :automatic, visibility: :automatic, **attrs, &block)
      normalized_placement = placement.to_s.tr("-", "_").to_sym
      normalized_priority = priority.to_s.tr("-", "_").to_sym
      normalized_visibility = visibility.to_s.tr("-", "_").to_sym
      unless TOOLBAR_PLACEMENTS.include?(normalized_placement)
        raise ArgumentError, "unknown toolbar placement: #{placement.inspect}"
      end
      unless TOOLBAR_PRIORITIES.include?(normalized_priority)
        raise ArgumentError, "unknown toolbar priority: #{priority.inspect}"
      end
      unless TOOLBAR_VISIBILITIES.include?(normalized_visibility)
        raise ArgumentError, "unknown toolbar visibility: #{visibility.inspect}"
      end
      if normalized_priority == :pinned && normalized_visibility == :overflow
        raise ArgumentError, "a pinned toolbar item cannot require overflow"
      end

      attrs[:class] = class_names("swift-ui-toolbar-item", attrs[:class])
      attrs[:data] = semantic_data(
        attrs[:data],
        sui_toolbar_placement: normalized_placement,
        sui_toolbar_priority: normalized_priority,
        sui_toolbar_visibility: normalized_visibility
      )

      create_element(:div, nil, **attrs, &block)
    end

    private

    def toolbar_minimize_threshold!(value)
      unless value.is_a?(Integer) && TOOLBAR_MINIMIZE_THRESHOLD_RANGE.cover?(value)
        raise ArgumentError, "minimize_threshold must be an integer between 0 and 1000"
      end

      value
    end

    def collect_tab_definitions(&block)
      previous = instance_variable_get(:@_swift_ui_tab_definitions)
      definitions = []
      instance_variable_set(:@_swift_ui_tab_definitions, definitions)
      instance_eval(&block)
      definitions
    ensure
      if previous
        instance_variable_set(:@_swift_ui_tab_definitions, previous)
      else
        remove_instance_variable(:@_swift_ui_tab_definitions) if instance_variable_defined?(:@_swift_ui_tab_definitions)
      end
    end

    def normalize_tab_definitions(definitions)
      seen_values = {}

      definitions.map do |definition|
        value = safe_dom_token!(definition.value, name: "tab value")
        if seen_values.key?(value)
          raise ArgumentError, "tab values must be unique: #{definition.value.inspect}"
        end

        seen_values[value] = true
        destination = definition.destination && safe_navigation_destination!(definition.destination)
        TabDefinition.new(
          label: definition.label,
          value: value,
          destination: destination,
          attributes: definition.attributes,
          content: definition.content
        )
      end
    end

    def render_tab_link(tab_definition, selected_tab:, root_id:)
      selected = tab_definition.equal?(selected_tab)
      tab_id = "#{root_id}-tab-#{tab_definition.value}"
      panel_id = "#{root_id}-panel-#{tab_definition.value}"
      attrs = tab_definition.attributes.dup
      attrs[:id] = tab_id
      attrs[:href] = tab_definition.destination || "##{panel_id}"
      attrs[:role] = "tab"
      attrs[:class] = class_names("swift-ui-tab", attrs[:class])
      attrs[:aria] = semantic_attributes(
        attrs[:aria],
        selected: selected,
        controls: panel_id
      )
      attrs[:data] = semantic_data(
        attrs[:data],
        sui_tab: JSON.generate(
          value: tab_definition.value,
          local: tab_definition.destination.nil?
        ),
        # Turbo owns route visits, but a local fragment is native browser state.
        # Keeping Turbo out of this anchor also preserves its fallback when
        # malformed application-authored markup has no matching panel.
        turbo: (false if tab_definition.destination.nil?)
      )

      create_element(:a, tab_definition.label, **attrs)
    end

    def render_tab_panel(tab_definition, selected_tab:, root_id:)
      selected = tab_definition.equal?(selected_tab)
      tab_id = "#{root_id}-tab-#{tab_definition.value}"
      panel_id = "#{root_id}-panel-#{tab_definition.value}"

      create_element(
        :section,
        nil,
        id: panel_id,
        role: "tabpanel",
        tabindex: 0,
        aria: { labelledby: tab_id },
        class: "swift-ui-tab-panel",
        data: {
          sui_tab_panel: JSON.generate(value: tab_definition.value, selected: selected)
        }
      ) do
        instance_eval(&tab_definition.content)
      end
    end

    def render_presentation_dialog(
      kind,
      title:,
      presented:,
      id:,
      dismiss_label:,
      dismiss_path:,
      dismissible:,
      role:,
      attrs:,
      message: nil,
      body_block: nil,
      actions_block: nil
    )
      presented = boolean!(presented, name: "presented")
      dismissible = boolean!(dismissible, name: "dismissible")
      title_text = accessible_text!(title, name: "#{kind} title")
      dismiss_text = accessible_text!(dismiss_label, name: "dismiss label") if dismissible
      dialog_id = id ? safe_dom_token!(id, name: "#{kind} id") : next_semantic_id(kind.to_s)
      title_id = "#{dialog_id}-title"
      description_id = "#{dialog_id}-description" if message
      safe_dismiss_path = dismiss_path && safe_application_route!(dismiss_path, name: "dismiss path")

      attrs = attrs.dup
      attrs[:id] = dialog_id
      attrs.delete(:open)
      attrs.delete("open")
      attrs[:open] = true if presented
      attrs[:role] = role
      attrs[:class] = class_names("swift-ui-dialog swift-ui-#{kind}", attrs[:class])
      attrs[:aria] = semantic_attributes(
        attrs[:aria],
        # `dialog[open]` is a useful non-modal HTML fallback. The runtime upgrades
        # it with showModal() and flips this value only after the browser has
        # actually made the rest of the document inert.
        modal: false,
        labelledby: title_id,
        describedby: description_id
      )
      attrs[:data] = semantic_data(
        attrs[:data],
        sui_dialog: JSON.generate(
          kind: kind,
          presented: presented,
          dismissible: dismissible
        )
      )

      create_element(:dialog, nil, **attrs) do
        create_element(:div, nil, class: "swift-ui-dialog-surface") do
          create_element(:header, nil, class: "swift-ui-dialog-header") do
            create_element(:h2, title_text, id: title_id, class: "swift-ui-dialog-title")
            render_dialog_dismiss_control(
              dismiss_text,
              dismiss_path: safe_dismiss_path,
              dialog_id: dialog_id
            ) if dismissible && kind == :sheet
          end

          create_element(:div, nil, class: "swift-ui-dialog-body") do
            create_element(:p, message, id: description_id, class: "swift-ui-dialog-message") if message
            instance_eval(&body_block) if body_block
          end

          if actions_block || (dismissible && kind != :sheet)
            create_element(:footer, nil, class: "swift-ui-dialog-actions") do
              instance_eval(&actions_block) if actions_block
              render_dialog_dismiss_control(
                dismiss_text,
                dismiss_path: safe_dismiss_path,
                dialog_id: dialog_id,
                compact: false
              ) if dismissible && kind != :sheet
            end
          end
        end
      end
    end

    def render_dialog_dismiss_control(label, dismiss_path:, dialog_id:, compact: true)
      classes = compact ? "swift-ui-dialog-close" : "swift-ui-dialog-dismiss"

      if dismiss_path
        create_element(
          :a,
          label,
          href: dismiss_path,
          class: classes,
          aria: { controls: dialog_id, label: (label if compact) }
        )
      else
        create_element(:form, nil, method: "dialog", class: "swift-ui-dialog-dismiss-form") do
          create_element(
            :button,
            label,
            type: "submit",
            value: "dismiss",
            class: classes,
            aria: { controls: dialog_id, label: (label if compact) }
          )
        end
      end
    end

    def presentation_state(presented, item)
      if !presented.equal?(PRESENTATION_UNSET) && !item.equal?(PRESENTATION_UNSET)
        raise ArgumentError, "provide either presented: or item:, not both"
      end

      if !item.equal?(PRESENTATION_UNSET)
        [!item.nil?, item, true]
      elsif presented.equal?(PRESENTATION_UNSET)
        [true, nil, false]
      else
        [boolean!(presented, name: "presented"), nil, false]
      end
    end

    def presentation_content_block(block, payload, item_bound, active)
      return nil unless block
      return nil if item_bound && !active

      if item_bound
        proc { instance_exec(payload, &block) }
      else
        proc { instance_eval(&block) }
      end
    end

    def navigation_destination_current?(destination)
      current_request = request if respond_to?(:request)
      if !current_request && respond_to?(:view_context) && view_context.respond_to?(:request)
        current_request = view_context.request
      end
      request_path = current_request&.path
      return false unless request_path

      destination_uri = URI.parse(destination)
      return false unless destination_uri.relative? && destination_uri.host.nil?
      return false if destination_uri.fragment && destination_uri.path.empty? && destination_uri.query.nil?

      destination_path = destination_uri.path
      destination_path = request_path if destination_path.empty? && destination_uri.query
      destination_path == request_path
    rescue URI::InvalidURIError
      false
    end

    def safe_navigation_destination!(destination)
      value = destination.to_s
      safe_value = Security::URLValidator.validate_link_href(value)
      unless safe_value && safe_value == value
        raise ArgumentError, "destination must be a safe HTTP(S), route, or fragment URL"
      end

      safe_value
    end

    # Presentation fallbacks and dismissals represent application state, not
    # arbitrary outbound navigation. Requiring an unambiguous same-origin path
    # means a missing client target safely reaches Rails without turning a UI
    # declaration into an open redirect or a base-relative surprise.
    def safe_application_route!(destination, name: "route")
      value = safe_navigation_destination!(destination)
      uri = URI.parse(value)
      safe_path = uri.relative? && uri.host.nil? && value.start_with?("/") &&
        !value.start_with?("//") && !value.include?("\\")
      unless safe_path
        raise ArgumentError, "#{name} must be a same-origin absolute path"
      end

      value
    rescue URI::InvalidURIError
      raise ArgumentError, "#{name} must be a same-origin absolute path"
    end

    def safe_dom_token!(value, name: "id")
      token = value.to_s.strip
      unless token.match?(/\A[a-zA-Z][a-zA-Z0-9_-]{0,127}\z/)
        raise ArgumentError, "#{name} must start with a letter and contain only letters, numbers, hyphens, and underscores"
      end

      token
    end

    def accessible_text!(value, name: "label")
      text = value.to_s.strip
      raise ArgumentError, "#{name} cannot be blank" if text.empty?

      text
    end

    def boolean!(value, name:)
      return value if value == true || value == false

      raise ArgumentError, "#{name} must be true or false"
    end

    def next_semantic_id(prefix)
      context = if is_a?(SwiftUIRails::DSLContext)
        self
      elsif instance_variable_defined?(:@_swift_ui_dsl_context)
        instance_variable_get(:@_swift_ui_dsl_context)
      end

      render_state = context&.send(:render_state)
      if render_state
        render_state[:semantic_sequence] = render_state.fetch(:semantic_sequence, 0) + 1
        sequence = render_state[:semantic_sequence]
      else
        @_swift_ui_semantic_sequence = instance_variable_get(:@_swift_ui_semantic_sequence).to_i + 1
        sequence = @_swift_ui_semantic_sequence
      end

      "swift-ui-#{prefix}-#{sequence}"
    end

    def semantic_attributes(existing, additions = nil, **keyword_additions)
      attrs = existing.is_a?(Hash) ? existing.dup : {}
      generated = additions || keyword_additions
      generated.each do |key, value|
        next if value.nil?

        attrs[key] = value
      end
      attrs
    end

    def semantic_data(existing, additions = nil, **keyword_additions)
      attrs = existing.is_a?(Hash) ? existing.dup : {}
      generated = additions || keyword_additions
      generated.each { |key, value| attrs[key] = value unless value.nil? }
      attrs
    end

    def merge_rel_values(existing, *values)
      (existing.to_s.split + values).uniq.join(" ")
    end
  end
end
