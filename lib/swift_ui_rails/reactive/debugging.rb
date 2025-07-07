# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Reactive
    # State debugging tools
    module Debugging
      extend ActiveSupport::Concern

      included do
        class_attribute :state_debugging_enabled, default: Rails.env.development?

        # Temporarily disabled to debug rendering issue
      end

      class_methods do
        ##
        # Enables or disables state debugging for the component.
        # @param [Boolean] enabled - Whether to enable state debugging (default: true).
        def debug_state(enabled = true)
          self.state_debugging_enabled = enabled
        end
      end

      ##
      # Returns a snapshot of the component's current state, including metadata, state values, bindings, observed objects, props, and recent state changes.
      # @return [Hash] A hash containing component information, current state, bindings, observed objects, props, and a log of state changes.
      def state_snapshot
        {
          component: {
            class: self.class.name,
            object_id: object_id,
            render_count: @render_count || 0
          },
          state: collect_state_values,
          bindings: collect_binding_values,
          observed: collect_observed_values,
          props: collect_prop_values,
          changes: @state_change_log || []
        }
      end

      ##
      # Returns an array of previous state snapshots for the component, or an empty array if no history exists.
      # @return [Array<Hash>] The history of state snapshots, up to the last 10.
      def state_history
        @state_history || []
      end

      ##
      # Records a state change event with details including category, name, old and new values, timestamp, and a backtrace, if state debugging is enabled.
      # @param [String, Symbol] category - The category of the state change (e.g., :state, :binding).
      # @param [String, Symbol] name - The name of the state variable or property that changed.
      # @param old_value - The previous value before the change.
      # @param new_value - The new value after the change.
      def log_state_change(category, name, old_value, new_value)
        return unless state_debugging_enabled

        @state_change_log ||= []
        @state_change_log << {
          category: category,
          name: name,
          old_value: old_value,
          new_value: new_value,
          timestamp: Time.current.to_f,
          backtrace: caller(2, 5) # Get 5 frames starting 2 levels up
        }
      end

      private

      ##
      # Captures the current state snapshot before rendering and updates the render count and state history.
      # Maintains a history of the last 10 state snapshots.
      def capture_initial_state
        @render_count = (@render_count || 0) + 1
        @state_before_render = state_snapshot

        # Keep history of last 10 renders
        @state_history ||= []
        @state_history << @state_before_render
        @state_history = @state_history.last(10)
      end

      ##
      # Appends the HTML debug panel to the component's content if state debugging is enabled.
      def add_debug_info
        return unless state_debugging_enabled

        debug_panel = generate_debug_panel
        @_content = (@_content.to_s + debug_panel).html_safe
      end

      ##
      # Generates an interactive HTML debug panel displaying the current component state, metadata, and recent changes for development inspection.
      # @return [String] HTML markup for the debug panel, trigger button, and embedded styles.
      def generate_debug_panel
        state_data = state_snapshot

        <<~HTML
          <div class="swift-ui-debug-panel"#{' '}
               data-controller="swift-ui-debug"
               data-swift-ui-debug-state-value='#{state_data.to_json}'
               style="display: none;">
            <div class="debug-header">
              <h4>#{self.class.name} State Inspector</h4>
              <button data-action="click->swift-ui-debug#toggle">×</button>
            </div>
            <div class="debug-content">
              #{generate_debug_sections(state_data)}
            </div>
          </div>
          <button class="swift-ui-debug-trigger"
                  data-action="click->swift-ui-debug#show"
                  title="Inspect Component State">
            🔍
          </button>
          #{debug_styles}
        HTML
      end

      ##
      # Generates HTML sections for the debug panel, displaying component metadata, props, state, bindings, observed objects, and recent state changes.
      # @param [Hash] state_data - The current state snapshot containing component info, props, state, bindings, observed objects, and changes.
      # @return [String] HTML markup for the debug panel sections.
      def generate_debug_sections(state_data)
        sections = []

        # Component info
        sections << debug_section('Component', state_data[:component])

        # Props
        sections << debug_section('Props', state_data[:props]) if state_data[:props].any?

        # State values
        sections << debug_section('@State', state_data[:state]) if state_data[:state].any?

        # Bindings
        sections << debug_section('@Binding', state_data[:bindings]) if state_data[:bindings].any?

        # Observed objects
        sections << debug_section('@ObservedObject', state_data[:observed]) if state_data[:observed].any?

        # Recent changes
        sections << debug_changes_section(state_data[:changes].last(5)) if state_data[:changes].any?

        sections.join("\n")
      end

      ##
      # Generates an HTML section with a title and a table displaying key-value pairs for debugging.
      # @param [String] title - The section title.
      # @param [Hash] data - The key-value pairs to display in the table.
      # @return [String] The generated HTML for the debug section.
      def debug_section(title, data)
        <<~HTML
          <div class="debug-section">
            <h5>#{title}</h5>
            <table class="debug-table">
              #{data.map { |k, v| debug_row(k, v) }.join("\n")}
            </table>
          </div>
        HTML
      end

      ##
      # Generates an HTML table row displaying a key and its formatted value for the debug panel.
      # @param [String] key - The label for the value.
      # @param value - The value to be formatted and displayed.
      # @return [String] An HTML string representing the table row.
      def debug_row(key, value)
        formatted_value = format_debug_value(value)
        value_class = value.class.name.downcase

        <<~HTML
          <tr>
            <td class="debug-key">#{key}</td>
            <td class="debug-value #{value_class}">#{formatted_value}</td>
          </tr>
        HTML
      end

      ##
      # Generates an HTML section displaying a list of recent state changes for debugging purposes.
      # @param [Array<Hash>] changes - The collection of state change entries to display.
      # @return [String] HTML markup for the recent changes debug section.
      def debug_changes_section(changes)
        <<~HTML
          <div class="debug-section">
            <h5>Recent Changes</h5>
            <div class="debug-changes">
              #{changes.map { |change| debug_change_entry(change) }.join("\n")}
            </div>
          </div>
        HTML
      end

      ##
      # Generates an HTML entry displaying a single state change, including its category, name, time since change, and old and new values.
      # @param [Hash] change - The state change data containing category, name, timestamp, old_value, and new_value.
      # @return [String] HTML markup representing the formatted state change entry.
      def debug_change_entry(change)
        time_ago = Time.current - Time.zone.at(change[:timestamp])

        <<~HTML
          <div class="debug-change">
            <div class="change-header">
              <span class="change-name">#{change[:category]}.#{change[:name]}</span>
              <span class="change-time">#{time_ago.round}s ago</span>
            </div>
            <div class="change-values">
              <span class="old-value">#{format_debug_value(change[:old_value])}</span>
              →
              <span class="new-value">#{format_debug_value(change[:new_value])}</span>
            </div>
          </div>
        HTML
      end

      ##
      # Formats a Ruby value as an HTML-safe string for display in the debug panel.
      # Returns a stylized representation based on the value's type, such as quoted strings, symbol notation, or summaries for arrays and hashes.
      # @param value The value to format.
      # @return [String] The formatted HTML-safe string representation.
      def format_debug_value(value)
        case value
        when nil
          '<em>nil</em>'
        when String
          %("#{value}")
        when Symbol
          ":#{value}"
        when TrueClass, FalseClass
          value.to_s
        when Numeric
          value.to_s
        when Array
          "[#{value.size} items]"
        when Hash
          "{#{value.size} keys}"
        else
          "#{value.class.name}##{value.object_id}"
        end
      end

      ##
      # Collects the current values of all defined state variables for the component.
      # @return [Hash] A hash mapping state variable names to their current values.
      def collect_state_values
        return {} unless respond_to?(:state_definitions)

        self.class.state_definitions.keys.each_with_object({}) do |name, hash|
          hash[name] = send(name) if respond_to?(name)
        end
      end

      ##
      # Collects the current values of all defined bindings for the component.
      # @return [Hash] A hash mapping binding names to their current values.
      def collect_binding_values
        return {} unless respond_to?(:binding_definitions)

        self.class.binding_definitions.keys.each_with_object({}) do |name, hash|
          hash[name] = send("#{name}_value") if respond_to?("#{name}_value")
        end
      end

      ##
      # Collects the current values of all observed objects defined for the component.
      # @return [Hash] A hash mapping observed object names to their current data, or an empty hash if none are defined.
      def collect_observed_values
        return {} unless respond_to?(:observed_object_definitions)

        self.class.observed_object_definitions.keys.each_with_object({}) do |name, hash|
          hash[name] = send("#{name}_data") if respond_to?("#{name}_data")
        end
      end

      ##
      # Collects the current values of all defined props for the component.
      # @return [Hash] A hash mapping prop names to their current values. Returns an empty hash if no prop definitions are present.
      def collect_prop_values
        return {} unless self.class.respond_to?(:prop_definitions)

        self.class.prop_definitions.keys.index_with do |name|
          instance_variable_get("@#{name}")
        end
      end

      ##
      # Returns the embedded CSS styles for the state debugging panel and trigger button.
      # The styles define layout, colors, and interactive behavior for the debugging UI elements.
      def debug_styles
        <<~CSS
          <style>
            .swift-ui-debug-trigger {
              position: fixed;
              bottom: 20px;
              right: 20px;
              width: 40px;
              height: 40px;
              border-radius: 50%;
              background: #3b82f6;
              color: white;
              border: none;
              font-size: 20px;
              cursor: pointer;
              box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
              z-index: 9990;
              transition: transform 0.2s;
            }
          #{'  '}
            .swift-ui-debug-trigger:hover {
              transform: scale(1.1);
            }
          #{'  '}
            .swift-ui-debug-panel {
              position: fixed;
              bottom: 80px;
              right: 20px;
              width: 400px;
              max-height: 600px;
              background: white;
              border: 1px solid #e5e7eb;
              border-radius: 8px;
              box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
              z-index: 9991;
              overflow: hidden;
              display: flex;
              flex-direction: column;
            }
          #{'  '}
            .swift-ui-debug-panel.open {
              display: flex !important;
            }
          #{'  '}
            .debug-header {
              background: #1f2937;
              color: white;
              padding: 12px 16px;
              display: flex;
              justify-content: space-between;
              align-items: center;
            }
          #{'  '}
            .debug-header h4 {
              margin: 0;
              font-size: 14px;
              font-weight: 600;
            }
          #{'  '}
            .debug-header button {
              background: none;
              border: none;
              color: white;
              font-size: 20px;
              cursor: pointer;
              padding: 0;
              width: 24px;
              height: 24px;
            }
          #{'  '}
            .debug-content {
              flex: 1;
              overflow-y: auto;
              padding: 16px;
            }
          #{'  '}
            .debug-section {
              margin-bottom: 20px;
            }
          #{'  '}
            .debug-section h5 {
              margin: 0 0 8px 0;
              font-size: 12px;
              font-weight: 600;
              text-transform: uppercase;
              color: #6b7280;
              letter-spacing: 0.05em;
            }
          #{'  '}
            .debug-table {
              width: 100%;
              font-size: 13px;
            }
          #{'  '}
            .debug-table tr {
              border-bottom: 1px solid #f3f4f6;
            }
          #{'  '}
            .debug-table tr:last-child {
              border-bottom: none;
            }
          #{'  '}
            .debug-key {
              padding: 8px 12px 8px 0;
              font-weight: 600;
              color: #374151;
              vertical-align: top;
            }
          #{'  '}
            .debug-value {
              padding: 8px 0;
              color: #111827;
              word-break: break-word;
            }
          #{'  '}
            .debug-value.string {
              color: #059669;
            }
          #{'  '}
            .debug-value.number,
            .debug-value.integer,
            .debug-value.float {
              color: #3b82f6;
            }
          #{'  '}
            .debug-value.trueclass,
            .debug-value.falseclass {
              color: #8b5cf6;
            }
          #{'  '}
            .debug-value em {
              color: #6b7280;
              font-style: normal;
            }
          #{'  '}
            .debug-changes {
              font-size: 12px;
            }
          #{'  '}
            .debug-change {
              padding: 8px;
              background: #f9fafb;
              border-radius: 4px;
              margin-bottom: 8px;
            }
          #{'  '}
            .debug-change:last-child {
              margin-bottom: 0;
            }
          #{'  '}
            .change-header {
              display: flex;
              justify-content: space-between;
              margin-bottom: 4px;
            }
          #{'  '}
            .change-name {
              font-weight: 600;
              color: #374151;
            }
          #{'  '}
            .change-time {
              color: #6b7280;
              font-size: 11px;
            }
          #{'  '}
            .change-values {
              color: #6b7280;
            }
          #{'  '}
            .old-value {
              color: #ef4444;
            }
          #{'  '}
            .new-value {
              color: #10b981;
            }
          </style>
        CSS
      end
    end
  end
end
# Copyright 2025
