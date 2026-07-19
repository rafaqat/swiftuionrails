# frozen_string_literal: true

module SwiftUIRails
  # A versioned, queryable contract describing how this gem relates to SwiftUI.
  #
  # Compatibility and delivery are deliberately separate. A browser-native
  # equivalent can be the correct long-term design while still being planned,
  # and a currently available API can still offer only partial semantics.
  module Compatibility
    class InvalidRegistryError < StandardError; end

    BASELINE = {
      release: "SwiftUI 2027 releases",
      announced_at: "WWDC26",
      toolchain: "Xcode 27",
      reviewed_on: "2026-07-18"
    }.freeze

    SOURCES = {
      swiftui_reference: {
        title: "SwiftUI documentation",
        url: "https://developer.apple.com/documentation/swiftui/"
      },
      wwdc26_guide: {
        title: "WWDC26 SwiftUI guide",
        url: "https://developer.apple.com/wwdc26/guides/swiftui/"
      },
      wwdc26_whats_new: {
        title: "What's new in SwiftUI (WWDC26)",
        url: "https://developer.apple.com/videos/play/wwdc2026/269/"
      },
      swiftui_updates: {
        title: "SwiftUI updates",
        url: "https://developer.apple.com/documentation/updates/swiftui"
      },
      tn3211: {
        title: "TN3211: Resolving SwiftUI source incompatibilities for State and ContentBuilder",
        url: "https://developer.apple.com/documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder"
      }
    }.freeze

    CATEGORIES = {
      declarative_layout: "Declarative composition, layout, and controls",
      modifiers_composition: "Modifiers, props, slots, and reusable composition",
      data_flow: "State, binding, observation, and updates",
      navigation_interaction: "Navigation, presentation, environment, gestures, and focus",
      rich_platform: "Rich content and platform integration",
      wwdc26: "SwiftUI additions announced at WWDC26"
    }.freeze

    STATUS_DEFINITIONS = {
      supported: "A first-class gem API preserves the portable SwiftUI intent on the web.",
      partial: "A first-party API exists, but its behavior or breadth does not yet match the portable SwiftUI concept.",
      web_equivalent: "Rails or browser semantics are the intentional equivalent; native API parity is not the goal.",
      not_applicable: "The feature belongs to Apple's compiler, operating systems, hardware, or native host lifecycle."
    }.freeze

    DELIVERY_DEFINITIONS = {
      available: "Implemented and suitable for use within the documented web contract.",
      prototype: "Implemented experimentally, with known semantic or lifecycle gaps.",
      planned: "Specified by this contract but not implemented as a first-class gem API.",
      not_applicable: "No gem implementation is intended."
    }.freeze

    deep_freeze = nil
    deep_freeze = lambda do |value|
      case value
      when Hash
        value.each do |key, item|
          deep_freeze.call(key)
          deep_freeze.call(item)
        end
      when Array
        value.each { |item| deep_freeze.call(item) }
      end

      value.freeze
    end

    feature = lambda do |id:, category:, swiftui:, status:, delivery:, web_contract:, apis: [], gap: nil, sources: [:swiftui_reference]|
      deep_freeze.call(
        id: id,
        category: category,
        swiftui: swiftui,
        status: status,
        delivery: delivery,
        web_contract: web_contract,
        apis: apis,
        gap: gap,
        sources: sources
      )
    end

    FEATURES = [
      feature.call(
        id: :declarative_blocks,
        category: :declarative_layout,
        swiftui: "Result-builder view composition",
        status: :supported,
        delivery: :available,
        web_contract: "Ruby blocks execute once into immutable resolved RenderIR, then the IR-native backend emits HTML in declaration order.",
        apis: ["SwiftUIRails::Component::Base.swift_ui", "SwiftUIRails::DSLContext", "SwiftUIRails::RenderIR"]
      ),
      feature.call(
        id: :stack_layouts,
        category: :declarative_layout,
        swiftui: "VStack and HStack",
        status: :supported,
        delivery: :available,
        web_contract: "Flexbox-backed vertical and horizontal stacks support alignment and spacing.",
        apis: ["vstack", "hstack"]
      ),
      feature.call(
        id: :overlay_layout,
        category: :declarative_layout,
        swiftui: "ZStack",
        status: :supported,
        delivery: :available,
        web_contract: "A single-cell CSS Grid overlays direct children and supports the documented alignment values.",
        apis: ["zstack"]
      ),
      feature.call(
        id: :basic_views_and_controls,
        category: :declarative_layout,
        swiftui: "Text, Image, Button, Link, and form controls",
        status: :supported,
        delivery: :available,
        web_contract: "Semantic HTML elements are produced with chainable attributes and modifiers.",
        apis: ["text", "image", "button", "link", "textfield", "toggle", "slider", "select"]
      ),
      feature.call(
        id: :grid_layout,
        category: :declarative_layout,
        swiftui: "Grid",
        status: :supported,
        delivery: :available,
        web_contract: "CSS Grid provides finite responsive grid composition.",
        apis: ["grid", "grid_item", "grid_item_wrapper"]
      ),
      feature.call(
        id: :lazy_containers,
        category: :declarative_layout,
        swiftui: "LazyVGrid and lazy stacks",
        status: :partial,
        delivery: :prototype,
        web_contract: "The DSL exposes grid syntax but currently renders the complete HTML collection.",
        apis: ["lazy_vgrid"],
        gap: "There is no viewport-driven DOM virtualization or incremental materialization."
      ),
      feature.call(
        id: :conditional_composition,
        category: :declarative_layout,
        swiftui: "Conditional and repeated content in builders",
        status: :supported,
        delivery: :available,
        web_contract: "Ruby if, case, and Enumerable iteration compose directly inside DSL blocks.",
        apis: ["Ruby conditional expressions", "Enumerable#each"]
      ),
      feature.call(
        id: :modifier_chains,
        category: :modifiers_composition,
        swiftui: "View modifiers",
        status: :partial,
        delivery: :available,
        web_contract: "Element modifiers safely compose semantic styles, HTML attributes, Turbo, and validated RenderIR metadata.",
        apis: ["SwiftUIRails::DSL::Element", "SwiftUIRails::Tailwind::Modifiers"],
        gap: "The catalog is a web-focused subset; typed environment propagation is an explicit server render scope rather than an implicit property-wrapper runtime."
      ),
      feature.call(
        id: :component_props,
        category: :modifiers_composition,
        swiftui: "View inputs",
        status: :supported,
        delivery: :available,
        web_contract: "Components declare typed, required, defaulted, and validated props.",
        apis: ["prop"]
      ),
      feature.call(
        id: :component_slots,
        category: :modifiers_composition,
        swiftui: "Content closures and builder parameters",
        status: :supported,
        delivery: :available,
        web_contract: "Named single or collection slots accept captured component content.",
        apis: ["slot", "wrapped_slot", "slot_if"]
      ),
      feature.call(
        id: :collection_composition,
        category: :modifiers_composition,
        swiftui: "ForEach-style reusable collection rendering",
        status: :supported,
        delivery: :available,
        web_contract: "ViewComponent collection rendering and DSL collection helpers render server-owned collections.",
        apis: ["with_collection", "collection", "vstack_collection", "hstack_collection", "grid_collection"]
      ),
      feature.call(
        id: :semantic_views_and_controls,
        category: :modifiers_composition,
        swiftui: "ProgressView, Gauge, ControlGroup, DisclosureGroup, Menu, DatePicker, ColorPicker, and Stepper",
        status: :supported,
        delivery: :available,
        web_contract: "Semantic HTML progress, meter, details, fieldset, and input elements preserve browser and assistive-technology behavior.",
        apis: ["progress_view", "gauge", "control_group", "disclosure_group", "menu", "date_picker", "color_picker", "stepper"]
      ),
      feature.call(
        id: :status_badges,
        category: :modifiers_composition,
        swiftui: "Reusable semantic status view composition",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "A tone-based badge owns repeated status styling and can opt into an announced ARIA status.",
        apis: ["badge"]
      ),
      feature.call(
        id: :semantic_control_styles,
        category: :modifiers_composition,
        swiftui: "ButtonStyle, LabelStyle, and control style roles",
        status: :partial,
        delivery: :available,
        web_contract: "Allowlisted button styles and sizes map semantic names to an enforced web design-system contract.",
        apis: ["button_style", "button_size"],
        gap: "The catalog is intentionally smaller than SwiftUI's environment-driven control and label style protocols."
      ),
      feature.call(
        id: :semantic_text_styles,
        category: :modifiers_composition,
        swiftui: "Font text styles, foregroundStyle, and backgroundStyle",
        status: :partial,
        delivery: :available,
        web_contract: "Allowlisted font, foreground, background, and composite text roles map application vocabulary " \
          "to stable design tokens instead of exposing a Tailwind palette at every call site.",
        apis: ["font", "foreground_style", "background_style", "text_style"],
        gap: "The portable role catalog does not reproduce arbitrary ShapeStyle values, custom fonts, gradients, " \
          "or Apple's platform-specific Dynamic Type metrics."
      ),
      feature.call(
        id: :custom_view_appearances,
        category: :modifiers_composition,
        swiftui: "Custom ViewModifier composition",
        status: :partial,
        delivery: :available,
        web_contract: "A validated appearance identifier separates application intent from CSS implementation, " \
          "while visually_hidden provides framework-owned accessibility-preserving presentation.",
        apis: ["appearance", "visually_hidden"],
        gap: "CSS remains the platform implementation; the hook is not a generic Swift ViewModifier type or an " \
          "environment-driven style protocol."
      ),
      feature.call(
        id: :animation_and_transition,
        category: :modifiers_composition,
        swiftui: "Value-driven animation and transitions",
        status: :partial,
        delivery: :available,
        web_contract: "Allowlisted value-associated CSS transitions and content-transition metadata respect reduced-motion preferences.",
        apis: ["animation", "content_transition", "transition"],
        gap: "CSS transitions do not reproduce SwiftUI transactions or an insertion/removal transition lifecycle."
      ),
      feature.call(
        id: :accessibility_semantics,
        category: :modifiers_composition,
        swiftui: "Accessibility modifiers",
        status: :partial,
        delivery: :available,
        web_contract: "Semantic HTML plus bounded, allowlisted ARIA modifiers express labels, values, hints, roles, live regions, headings, identifiers, traits, and state.",
        apis: ["accessibility_label", "accessibility_value", "accessibility_hint", "accessibility_role", "accessibility_hidden", "accessibility_live", "accessibility_heading", "accessibility_identifier", "accessibility_state", "accessibility_traits"],
        gap: "Custom accessibility actions, rotors, and Apple-platform assistive-technology APIs remain outside the browser contract."
      ),
      feature.call(
        id: :local_state,
        category: :data_flow,
        swiftui: "State",
        status: :partial,
        delivery: :available,
        web_contract: "Typed component-local state survives authorized server round trips in a one-time encrypted snapshot and is renewed after each render.",
        apis: ["state", "state_values", "restore_reactive_snapshot"],
        gap: "State lifetime follows the rendered component and request/capability cycle rather than SwiftUI view identity and transactions."
      ),
      feature.call(
        id: :bindings,
        category: :data_flow,
        swiftui: "Binding and projected values",
        status: :partial,
        delivery: :available,
        web_contract: "Typed root bindings round-trip through native input, checkbox, and select metadata; getter/setter mapping and projection remain server-local compositions.",
        apis: ["binding", "pass_binding", "SwiftUIRails::Reactive::Binding::BindingValue", "input_attributes", "checkbox_attributes", "select_attributes"],
        gap: "Mapped and projected bindings are not independent browser transport roots, and arbitrary client controls need an application adapter."
      ),
      feature.call(
        id: :observation,
        category: :data_flow,
        swiftui: "Observable and observed models",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Observed resources reload authoritative server data after opaque Action Cable invalidations; thread-safe ObservableStore supports in-process coordination.",
        apis: ["observed_resource", "observed_object", "SwiftUIRails::Reactive::ObservableStore", "SwiftUIRails::Reactive::ObservableStore.invalidate"],
        gap: "Invalidation is resource-scoped rather than SwiftUI property-access dependency tracking, and ObservableStore is not a distributed datastore."
      ),
      feature.call(
        id: :environment_values,
        category: :data_flow,
        swiftui: "Environment and EnvironmentValues",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Fiber/request-scoped immutable contexts carry typed, inheritable server values without serializing private context into HTML.",
        apis: ["environment", "with_environment", "environment_value", "environment_scope", "SwiftUIRails::Environment"]
      ),
      feature.call(
        id: :reactive_rendering,
        category: :data_flow,
        swiftui: "Automatic view updates after data changes",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "One-time encrypted, authorization-bound component snapshots renew through serialized HTTP updates; read-only Action Cable invalidations request an authoritative rerender.",
        apis: ["reactive_rendering", "SwiftUIRails::Reactive::ReactiveComponentSnapshot", "SwiftUIRails::Reactive::ReactiveStreamToken", "SwiftUIRails::Reactive::ReactiveChannel"]
      ),
      feature.call(
        id: :task_lifecycle,
        category: :data_flow,
        swiftui: "task and refreshable",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "DOM connect/disconnect owns lifecycle events and cancellable same-origin browser tasks with explicit loading, success, failure, and refresh events.",
        apis: ["lifecycle_scope", "lifecycle", "on_appear", "on_disappear", "task", "refreshable"]
      ),
      feature.call(
        id: :navigation_stack,
        category: :navigation_interaction,
        swiftui: "NavigationStack, NavigationPath, and navigationDestination",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Labelled navigation landmarks and validated real anchors delegate paths, deep links, history, and Turbo visits to Rails and the browser.",
        apis: ["navigation_stack", "navigation_link", "tab_view", "tab"],
        gap: "There is intentionally no second in-memory NavigationPath or typed destination registry beside Rails routes."
      ),
      feature.call(
        id: :presentation,
        category: :navigation_interaction,
        swiftui: "sheet, popover, fullScreenCover, and presentation modifiers",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Native dialog and details elements provide sheet/popover presentation with same-origin route fallbacks, focus handling, and server-owned state.",
        apis: ["sheet", "popover", "presentation_trigger"],
        gap: "Native full-screen covers, detents, and Apple presentation-controller behavior have no direct browser equivalent."
      ),
      feature.call(
        id: :alerts_and_dialogs,
        category: :navigation_interaction,
        swiftui: "alert and confirmationDialog",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Accessible alertdialog builders pair native dismissal with ordinary server-authorized Rails actions and optional item-driven state.",
        apis: ["alert", "confirmation_dialog"]
      ),
      feature.call(
        id: :gestures,
        category: :navigation_interaction,
        swiftui: "Tap, hover, keyboard, drag, magnification, and composed gestures",
        status: :partial,
        delivery: :available,
        web_contract: "Accessible tap and long-press activation, filtered key presses, and value-producing pointer or opt-in keyboard drag events use finite data-sui behavior descriptors interpreted by the shared runtime.",
        apis: ["on_tap", "on_long_press", "on_drag", "on_key_press", "on_hover", "on_keydown", "on_keyup"],
        gap: "Recognizer composition, rotation, magnification, and transferable drag-and-drop remain outside this gesture slice."
      ),
      feature.call(
        id: :focus,
        category: :navigation_interaction,
        swiftui: "FocusState and focus scopes",
        status: :partial,
        delivery: :available,
        web_contract: "Reactive FocusState expresses next-render focus intent while native activeElement, scoped events, and semantic tab stops own live browser focus.",
        apis: ["focus_state", "focused", "default_focus", "focus_scope", "focusable", "on_focus", "on_blur"],
        gap: "Live activeElement changes intentionally remain client-owned and advanced route-level restoration and focus-section traversal are not implemented."
      ),
      feature.call(
        id: :drag_and_drop,
        category: :navigation_interaction,
        swiftui: "Transferable drag and drop",
        status: :web_equivalent,
        delivery: :planned,
        web_contract: "HTML Drag and Drop and pointer events should map payloads through signed Rails actions.",
        gap: "The available stable-key reorder workflow is intentionally narrower; no general transferable payload or drop-destination API exists."
      ),
      feature.call(
        id: :toolbars,
        category: :navigation_interaction,
        swiftui: "toolbar and ToolbarItem placement",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Labelled browser toolbars provide semantic placement hooks, priority-aware responsive overflow, pinned actions, roving focus, and optional scroll minimization.",
        apis: ["toolbar", "toolbar_item"],
        gap: "Placement is a styling/interaction contract, not Apple window-toolbar placement."
      ),
      feature.call(
        id: :charts,
        category: :rich_platform,
        swiftui: "Swift Charts",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Bar and line charts render as server-owned accessible SVG with exact values repeated in a hidden data table.",
        apis: ["chart"],
        gap: "The bounded chart helper does not yet expose Swift Charts' full mark, axis, scale, interaction, or selection model."
      ),
      feature.call(
        id: :maps,
        category: :rich_platform,
        swiftui: "MapKit for SwiftUI",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "A privacy-preserving schematic SVG coordinate plot renders bounded markers and an accessible exact-coordinate list without contacting a tile provider.",
        apis: ["map", "map_marker"],
        gap: "Street maps, navigation, live location, tiles, and MapKit overlays require a separately selected provider integration."
      ),
      feature.call(
        id: :canvas,
        category: :rich_platform,
        swiftui: "Canvas, GraphicsContext, and custom drawing",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "A bounded declarative drawing-command vocabulary renders safe SVG with an accessible label and fallback text.",
        apis: ["canvas"],
        gap: "Arbitrary paths, code execution, images, shaders, and high-frequency imperative GraphicsContext drawing are outside this helper."
      ),
      feature.call(
        id: :rich_text,
        category: :rich_platform,
        swiftui: "AttributedString and rich Text composition",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Sanitized semantic HTML represents a bounded editorial vocabulary with validated safe links.",
        apis: ["rich_text"],
        gap: "This is sanitized document markup, not a mutable AttributedString run model."
      ),
      feature.call(
        id: :web_view,
        category: :rich_platform,
        swiftui: "WebView",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "A titled, sandboxed iframe embeds allowlisted same-origin or approved external documents with a constrained permission policy.",
        apis: ["web_view"],
        gap: "This is an iframe security boundary, not a native WebView, navigation delegate, cookie jar, or process model."
      ),
      feature.call(
        id: :scenes_and_windows,
        category: :rich_platform,
        swiftui: "App, Scene, WindowGroup, and window management",
        status: :not_applicable,
        delivery: :not_applicable,
        web_contract: "Rails application boot, routes, requests, and browser tabs own the host lifecycle.",
        gap: "Native process, scene session, and window lifecycle parity is outside the gem's scope."
      ),
      feature.call(
        id: :apple_platform_integration,
        category: :rich_platform,
        swiftui: "UIKit/AppKit interop, widgets, watch complications, and immersive spaces",
        status: :not_applicable,
        delivery: :not_applicable,
        web_contract: "Web integrations should use standards-based browser capabilities and Rails adapters.",
        gap: "Apple framework and device-host integration requires native application code."
      ),
      feature.call(
        id: :content_builder,
        category: :wwdc26,
        swiftui: "ContentBuilder unification and Xcode 27 type-checking improvements",
        status: :not_applicable,
        delivery: :not_applicable,
        web_contract: "Ruby blocks already accept heterogeneous DSL content without Swift result-builder type checking.",
        sources: [:wwdc26_guide, :wwdc26_whats_new, :swiftui_updates, :tn3211]
      ),
      feature.call(
        id: :state_macro,
        category: :wwdc26,
        swiftui: "Macro-based State and lazy Observable initialization",
        status: :not_applicable,
        delivery: :not_applicable,
        web_contract: "Ruby has no equivalent compile-time macro migration; web state lifetime remains an explicit gem contract.",
        sources: [:wwdc26_guide, :wwdc26_whats_new, :tn3211]
      ),
      feature.call(
        id: :arbitrary_container_reordering,
        category: :wwdc26,
        swiftui: "Reordering in lists, grids, sections, and custom layouts",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Stable-key list, grid, and custom collections expose visible move forms; optional drag submits the same authorized Rails mutation.",
        apis: ["reorderable_collection"],
        gap: "The server remains the ordering authority; the client does not provide SwiftUI's in-process collection mutation model.",
        sources: [:wwdc26_guide, :wwdc26_whats_new]
      ),
      feature.call(
        id: :swipe_actions_container,
        category: :wwdc26,
        swiftui: "Swipe actions in arbitrary scroll containers",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Visible, focusable Rails action forms remain authoritative while leading/trailing pointer swipes only reveal and announce the action rail.",
        apis: ["swipe_action", "swipe_actions"],
        gap: "Full-swipe execution is intentionally absent because a gesture is not authorization for a server mutation.",
        sources: [:wwdc26_guide, :wwdc26_whats_new]
      ),
      feature.call(
        id: :toolbar_visibility_and_overflow,
        category: :wwdc26,
        swiftui: "Toolbar visibility priority, overflow menu, pinned actions, and minimize behavior",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Toolbar items declare low/automatic/high/pinned priority, automatic/visible/overflow visibility, and optional scroll minimization while preserving a complete no-JavaScript fallback.",
        apis: ["toolbar", "toolbar_item"],
        gap: "Adaptation follows measured browser space rather than Apple toolbar/window placement rules.",
        sources: [:wwdc26_guide, :wwdc26_whats_new]
      ),
      feature.call(
        id: :document_api,
        category: :wwdc26,
        swiftui: "ReadableDocument, WritableDocument, and DocumentCreationSource",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "Route-backed import, signed creation provenance, server validation helpers, Active Storage hooks, native progress, and streaming export form a Rails document workflow.",
        apis: ["document_workflow", "document_import", "document_creation_action", "document_export", "SwiftUIRails::DocumentWorkflow"],
        gap: "Rails requests, storage, jobs, and browser downloads own lifecycle and persistence rather than native document scenes.",
        sources: [:wwdc26_guide, :wwdc26_whats_new]
      ),
      feature.call(
        id: :async_image_caching,
        category: :wwdc26,
        swiftui: "AsyncImage HTTP caching, URLRequest, URLSession, and URLCache control",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "A native img keeps browser HTTP caching and decoding authoritative while progressive enhancement exposes loading, success, and failure phases.",
        apis: ["async_image"],
        gap: "Only the browser cache policy is exposed; URLSession, URLRequest, and URLCache are native networking APIs.",
        sources: [:wwdc26_guide, :wwdc26_whats_new]
      ),
      feature.call(
        id: :item_bound_presentations,
        category: :wwdc26,
        swiftui: "Item-binding patterns for alerts and confirmation dialogs",
        status: :web_equivalent,
        delivery: :available,
        web_contract: "sheet, alert, and confirmation dialog derive server-rendered visibility and yielded content from an optional item.",
        apis: ["sheet", "alert", "confirmation_dialog"],
        gap: "Clearing or replacing the item remains explicit application/server state rather than a client Binding side effect.",
        sources: [:wwdc26_guide, :wwdc26_whats_new]
      ),
      feature.call(
        id: :liquid_glass_refresh,
        category: :wwdc26,
        swiftui: "Automatic refreshed Liquid Glass appearance on Apple 2027 OS releases",
        status: :not_applicable,
        delivery: :not_applicable,
        web_contract: "Web applications retain an explicit, product-owned design system rather than adopting an OS material automatically.",
        sources: [:wwdc26_whats_new]
      )
    ].freeze

    REQUIRED_FEATURE_KEYS = %i[
      id category swiftui status delivery web_contract apis gap sources
    ].freeze

    class << self
      def features
        FEATURES
      end

      def feature(id)
        id = id.to_sym if id.respond_to?(:to_sym)
        FEATURES.find { |candidate| candidate[:id] == id }
      end

      def fetch(id)
        feature(id) || raise(KeyError, "unknown SwiftUI compatibility feature: #{id.inspect}")
      end

      def select(category: nil, status: nil, delivery: nil)
        FEATURES.select do |candidate|
          (!category || candidate[:category] == category.to_sym) &&
            (!status || candidate[:status] == status.to_sym) &&
            (!delivery || candidate[:delivery] == delivery.to_sym)
        end.freeze
      end

      def summary
        {
          total: FEATURES.length,
          by_status: count_by(:status),
          by_delivery: count_by(:delivery),
          by_category: count_by(:category)
        }.freeze
      end

      def to_h
        {
          baseline: BASELINE,
          sources: SOURCES,
          categories: CATEGORIES,
          statuses: STATUS_DEFINITIONS,
          delivery: DELIVERY_DEFINITIONS,
          features: FEATURES
        }.freeze
      end

      def validate!
        errors = []
        ids = FEATURES.map { |candidate| candidate[:id] }

        errors << "feature ids must be unique" unless ids.uniq.length == ids.length
        errors << "all categories must be represented" unless CATEGORIES.keys.all? { |category| FEATURES.any? { |candidate| candidate[:category] == category } }
        errors << "all statuses must be represented" unless STATUS_DEFINITIONS.keys.all? { |status| FEATURES.any? { |candidate| candidate[:status] == status } }
        errors << "all delivery states must be represented" unless DELIVERY_DEFINITIONS.keys.all? { |delivery| FEATURES.any? { |candidate| candidate[:delivery] == delivery } }

        FEATURES.each do |candidate|
          missing_keys = REQUIRED_FEATURE_KEYS - candidate.keys
          errors << "#{candidate[:id] || "unnamed feature"}: missing #{missing_keys.join(", ")}" if missing_keys.any?
          errors << "#{candidate[:id]}: unknown category" unless CATEGORIES.key?(candidate[:category])
          errors << "#{candidate[:id]}: unknown status" unless STATUS_DEFINITIONS.key?(candidate[:status])
          errors << "#{candidate[:id]}: unknown delivery" unless DELIVERY_DEFINITIONS.key?(candidate[:delivery])
          errors << "#{candidate[:id]}: unknown source" unless candidate[:sources].all? { |source| SOURCES.key?(source) }

          not_applicable = candidate[:status] == :not_applicable
          delivery_not_applicable = candidate[:delivery] == :not_applicable
          if not_applicable != delivery_not_applicable
            errors << "#{candidate[:id]}: not_applicable status and delivery must be paired"
          end

          if candidate[:delivery] == :planned && candidate[:gap].to_s.empty?
            errors << "#{candidate[:id]}: planned features must state the implementation gap"
          end
        end

        raise InvalidRegistryError, errors.join("; ") if errors.any?

        true
      end

      private

      def count_by(key)
        FEATURES.each_with_object(Hash.new(0)) do |candidate, counts|
          counts[candidate[key]] += 1
        end.freeze
      end
    end

    validate!
  end
end
