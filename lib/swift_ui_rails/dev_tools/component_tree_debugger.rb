# frozen_string_literal: true

module SwiftUIRails
  module DevTools
    # Component tree visualization for debugging SwiftUI DSL structures
    class ComponentTreeDebugger
      class << self
        ##
        # Generates a visual representation of a SwiftUI component tree in the specified format.
        # Only operates in the local Rails environment.
        # @param component The root component to visualize.
        # @param format [Symbol] The output format: :ascii, :html, or :json (default: :ascii).
        # @param max_depth [Integer, nil] The maximum depth to traverse in the tree (optional).
        # @param include_props [Boolean] Whether to include component properties in the output (default: true).
        # @return [String, nil] The formatted tree string, or nil if not in the local environment.
        # @raise [ArgumentError] If an unknown format is specified.
        def debug_tree(component, format: :ascii, max_depth: nil, include_props: true)
          return unless Rails.env.local?

          case format
          when :ascii
            generate_ascii_tree(component, max_depth: max_depth, include_props: include_props)
          when :html
            generate_html_tree(component, max_depth: max_depth, include_props: include_props)
          when :json
            generate_json_tree(component, max_depth: max_depth, include_props: include_props)
          else
            raise ArgumentError, "Unknown format: #{format}. Use :ascii, :html, or :json"
          end
        end

        ##
        # Generates a visual representation of the component tree and logs it at debug level.
        # @return [String, nil] The generated tree string, or nil if not in the local environment.
        def print_tree(component, **options)
          tree = debug_tree(component, **options)
          Rails.logger.debug tree
          tree
        end

        ##
        # Logs a visual representation of the component tree to the Rails logger at debug level.
        # Prepends a newline before the tree output.
        # @return [String, nil] The generated tree string, or nil if not in the local environment.
        def log_tree(component, **options)
          tree = debug_tree(component, **options)
          Rails.logger.debug { "\n#{tree}" }
          tree
        end

        private

        ##
        # Generates an ASCII representation of the component tree.
        # @param component The root component to visualize.
        # @param max_depth [Integer, nil] The maximum depth to traverse, or nil for unlimited.
        # @param include_props [Boolean] Whether to include component properties in the output.
        # @return [String] The ASCII tree representation.
        def generate_ascii_tree(component, max_depth: nil, include_props: true)
          lines = []
          build_ascii_node(component, lines, '', true, 0, max_depth, include_props)
          lines.join("\n")
        end

        ##
        # Recursively builds the ASCII representation of a component tree node and its children.
        # Adds formatted lines for the node, its properties (if requested), and all descendants to the provided lines array.
        # Stops recursion if the maximum depth is exceeded.
        def build_ascii_node(node, lines, prefix, is_last, depth, max_depth, include_props)
          return if max_depth && depth > max_depth

          # Determine node type and info
          node_info = extract_node_info(node)

          # Build the current line
          connector = is_last ? '└── ' : '├── '
          lines << "#{prefix}#{connector}#{node_info[:display]}"

          # Add props/attributes if requested
          if include_props && node_info[:props].any?
            prop_prefix = prefix + (is_last ? '    ' : '│   ')
            node_info[:props].each_with_index do |prop, i|
              prop_connector = i == node_info[:props].length - 1 ? '└─ ' : '├─ '
              lines << "#{prop_prefix}#{prop_connector}#{prop}"
            end
          end

          # Process children
          children = extract_children(node)
          return unless children.any?

          child_prefix = prefix + (is_last ? '    ' : '│   ')
          children.each_with_index do |child, index|
            is_last_child = index == children.length - 1
            build_ascii_node(child, lines, child_prefix, is_last_child, depth + 1, max_depth, include_props)
          end
        end

        ##
        # Generates an HTML representation of a SwiftUI component tree for debugging.
        # @param component The root component to visualize.
        # @param max_depth [Integer, nil] The maximum depth to traverse in the tree, or nil for unlimited.
        # @param include_props [Boolean] Whether to include component properties in the output.
        # @return [ActiveSupport::SafeBuffer] An HTML-safe string containing the formatted component tree.
        def generate_html_tree(component, max_depth: nil, include_props: true)
          html = +"<div class='swift-ui-debug-tree' style='font-family: monospace; line-height: 1.4;'>"
          html << build_html_node(component, 0, max_depth, include_props)
          html << '</div>'
          html.html_safe
        end

        ##
        # Recursively generates the HTML representation of a component tree node and its children.
        # Returns a styled HTML string for the node, including its type, optional text content, and properties if requested.
        # Returns an empty string if the maximum depth is exceeded.
        # @param node The current component or element node to render.
        # @param depth [Integer] The current depth in the tree.
        # @param max_depth [Integer, nil] The maximum depth to render, or nil for unlimited.
        # @param include_props [Boolean] Whether to include node properties in the output.
        # @return [String] The HTML representation of the node and its subtree.
        def build_html_node(node, depth, max_depth, include_props)
          return '' if max_depth && depth > max_depth

          node_info = extract_node_info(node)

          html = +''
          html << "<div style='margin-left: #{depth * 20}px;'>"
          html << "<span style='color: #0066cc; font-weight: bold;'>#{h(node_info[:type])}</span>"

          html << " <span style='color: #666;'>\"#{h(node_info[:text])}\"</span>" if node_info[:text]

          if include_props && node_info[:props].any?
            html << "<div style='margin-left: 20px; color: #888; font-size: 0.9em;'>"
            node_info[:props].each do |prop|
              html << "• #{h(prop)}<br>"
            end
            html << '</div>'
          end

          children = extract_children(node)
          if children.any?
            html << "<div style='border-left: 1px solid #ddd; margin-left: 10px;'>"
            children.each do |child|
              html << build_html_node(child, depth + 1, max_depth, include_props)
            end
            html << '</div>'
          end

          html << '</div>'
          html
        end

        ##
        # Generates a formatted JSON representation of the component tree.
        # @return [String] The component tree as a pretty-printed JSON string.
        def generate_json_tree(component, max_depth: nil, include_props: true)
          tree = build_json_node(component, 0, max_depth, include_props)
          JSON.pretty_generate(tree)
        end

        ##
        # Recursively builds a JSON-compatible hash representing a component tree node and its children.
        # @param node The current node to process.
        # @param depth The current depth in the tree.
        # @param max_depth The maximum depth to traverse; nodes beyond this depth are omitted.
        # @param include_props Whether to include node properties in the output.
        # @return [Hash, nil] A hash representing the node and its subtree, or nil if the node exceeds max_depth.
        def build_json_node(node, depth, max_depth, include_props)
          return nil if max_depth && depth > max_depth

          node_info = extract_node_info(node)

          json_node = {
            type: node_info[:type],
            depth: depth
          }

          json_node[:text] = node_info[:text] if node_info[:text]
          json_node[:props] = node_info[:props] if include_props && node_info[:props].any?

          children = extract_children(node)
          if children.any?
            json_node[:children] = children.filter_map do |child|
              build_json_node(child, depth + 1, max_depth, include_props)
            end
          end

          json_node
        end

        ##
        # Extracts and summarizes information about a node in the component tree.
        # Returns a hash containing the node's type, properties, text content (if any), and a display string suitable for tree visualization.
        # Handles component nodes, DSL elements, text nodes, blocks, and other types.
        def extract_node_info(node)
          info = { type: 'Unknown', props: [], text: nil, display: 'Unknown' }

          case node
          when SwiftUIRails::Component::Base
            # Component node
            info[:type] = node.class.name.demodulize
            info[:display] = "#{info[:type]} <Component>"

            # Extract props
            node.class.swift_props.each_key do |prop_name|
              value = node.instance_variable_get("@#{prop_name}")
              info[:props] << "#{prop_name}: #{format_value(value)}" if value
            end

          when SwiftUIRails::DSL::Element
            # DSL Element node
            info[:type] = node.tag_name.to_s
            info[:display] = info[:type]

            # Check for text content
            if node.instance_variable_get(:@content).is_a?(String)
              info[:text] = node.instance_variable_get(:@content)
              info[:display] = "#{info[:type]}(\"#{truncate(info[:text])}\")"
            end

            # Extract attributes
            attrs = node.instance_variable_get(:@attributes) || {}
            attrs.each do |key, value|
              next if key == :class && value.empty?

              info[:props] << "#{key}: #{format_value(value)}"
            end

            # Extract CSS classes
            css_classes = node.instance_variable_get(:@css_classes) || []
            info[:props] << "class: #{css_classes.join(' ')}" if css_classes.any?

          when String
            # Text node
            info[:type] = 'Text'
            info[:text] = node
            info[:display] = "\"#{truncate(node)}\""

          when Proc
            # Proc/block node
            info[:type] = 'Block'
            info[:display] = '<Block>'

          else
            # Other types
            info[:type] = node.class.name
            info[:display] = info[:type]
          end

          info
        end

        ##
        # Extracts the child nodes of a given SwiftUI component or DSL element.
        #
        # For components, executes the associated SwiftUI DSL block in a new context to collect child elements.
        # For DSL elements, executes the block if present to gather children, or collects non-string content and manually set children.
        # @return [Array] An array of child nodes, excluding nil values.
        def extract_children(node)
          children = []

          case node
          when SwiftUIRails::Component::Base
            # For components, we need to render the swift_ui block to get children
            # Create a DSL context and execute the component's swift_ui block
            if node.class.instance_variable_get(:@swift_ui_block)
              dsl_context = SwiftUIRails::DSLContext.new(node)
              dsl_context.instance_variable_set(:@component, node)

              # Execute the block but capture the result
              result = dsl_context.instance_eval(&node.class.instance_variable_get(:@swift_ui_block))

              # Get all registered elements from the context
              pending_elements = dsl_context.instance_variable_get(:@pending_elements) || []

              # If the result is an element and not already in pending_elements, add it
              if result.is_a?(SwiftUIRails::DSL::Element) && pending_elements.exclude?(result)
                dsl_context.register_element(result)
                pending_elements = dsl_context.instance_variable_get(:@pending_elements) || []
              end

              children = pending_elements
            end

          when SwiftUIRails::DSL::Element
            # Elements with blocks have their children captured dynamically
            block = node.instance_variable_get(:@block)

            if block
              # Create a sub-context to capture children
              dsl_context = node.instance_variable_get(:@dsl_context)
              if dsl_context
                # Create a new sub-context to isolate child elements
                sub_context = SwiftUIRails::DSLContext.new(dsl_context.instance_variable_get(:@view_context))

                # Transfer component reference if available
                if (comp = dsl_context.instance_variable_get(:@component))
                  sub_context.instance_variable_set(:@component, comp)
                end

                # Execute block in sub-context to collect child elements
                result = sub_context.instance_eval(&block)

                # Get all registered elements from the context
                pending_elements = sub_context.instance_variable_get(:@pending_elements) || []

                # If the result is an element and not already in pending_elements, add it
                if result.is_a?(SwiftUIRails::DSL::Element) && pending_elements.exclude?(result)
                  sub_context.register_element(result)
                  pending_elements = sub_context.instance_variable_get(:@pending_elements) || []
                end

                children = pending_elements
              else
                # No DSL context, can't extract children from block
                children = []
              end
            else
              # For elements without blocks, check for simple content
              content = node.instance_variable_get(:@content)
              children << content if content && !content.is_a?(String)

              # Also check for manually set @children (edge case for testing)
              manual_children = node.instance_variable_get(:@children)
              children.concat(manual_children) if manual_children.is_a?(Array)
            end

          end

          children.compact
        end

        ##
        # Formats a value for display in the component tree output.
        # Strings are truncated and quoted, symbols are prefixed with a colon, arrays and hashes are summarized by size, and other values are converted to strings or inspected as appropriate.
        # @param value The value to format.
        # @return [String] The formatted representation of the value.
        def format_value(value)
          case value
          when String
            "\"#{truncate(value)}\""
          when Symbol
            ":#{value}"
          when Array
            "[#{value.size} items]"
          when Hash
            "{#{value.size} keys}"
          when true, false, nil
            value.inspect
          else
            truncate(value.to_s)
          end
        end

        ##
        # Truncates a string to the specified maximum length, appending an ellipsis if truncated.
        # @param [String] str - The string to truncate.
        # @param [Integer] max_length - The maximum allowed length of the string (default: 30).
        # @return [String] The truncated string with an ellipsis if it exceeded the maximum length.
        def truncate(str, max_length = 30)
          return str if str.length <= max_length

          "#{str[0...max_length]}..."
        end

        ##
        # Escapes HTML special characters in the given text.
        # @param [String] text - The text to be escaped.
        # @return [String] The HTML-escaped string.
        def h(text)
          ERB::Util.html_escape(text)
        end
      end
    end
  end
end
