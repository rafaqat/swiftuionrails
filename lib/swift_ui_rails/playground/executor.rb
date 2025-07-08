# frozen_string_literal: true

require_relative '../dsl/element'
require_relative 'safe_dsl_parser'
require_relative 'token_parser'

module SwiftUIRails
  module Playground
    class Executor
      include SwiftUIRails::DSL
      include SwiftUIRails::Helpers

      attr_reader :session_id, :view_context

      Result = Struct.new(:success?, :html, :error, :component_tree, :stimulus_controllers, keyword_init: true)

      def initialize(session_id, view_context = nil)
        @session_id = session_id
        @view_context = view_context || create_view_context
        @stimulus_controllers = {}
      end

      def execute(code)
        # Execute in sandboxed context
        component_tree = nil

        # Create a clean execution context
        context = ExecutionContext.new(@view_context)

        # SECURITY: Parse and execute DSL code safely without eval
        # This uses a safe DSL parser that only allows whitelisted methods
        result = safe_execute_dsl(context, code)

        # Convert result to HTML
        html = if result.respond_to?(:to_s)
                 result.to_s.html_safe
               else
                 '<div>No output generated</div>'.html_safe
               end

        # Extract component tree if available
        component_tree = extract_component_tree(result) if result.is_a?(SwiftUIRails::DSL::Element)

        # Extract Stimulus controllers from the code
        extract_stimulus_controllers(code)

        Result.new(
          success?: true,
          html: html,
          component_tree: component_tree,
          stimulus_controllers: @stimulus_controllers
        )
      rescue SyntaxError => e
        Result.new(
          success?: false,
          error: "Syntax Error: #{e.message}"
        )
      rescue StandardError => e
        Result.new(
          success?: false,
          error: "#{e.class}: #{e.message}"
        )
      end

      private

      def safe_execute_dsl(context, code)
        # Use the token parser for safe DSL parsing
        parser = TokenParser.new(code)
        ast = parser.parse

        # Execute the AST in the given context
        execute_ast(context, ast)
      rescue TokenParser::ParseError => e
        raise SwiftUIRails::SecurityError, "Parse error: #{e.message}"
      end

      def execute_ast(context, node)
        case node[:type]
        when :root
          # Execute all top-level statements
          results = node[:children].map { |child| execute_ast(context, child) }
          results.last
        when :method_call
          execute_method_call(context, node)
        when :chained_call
          # Execute the receiver first
          receiver = execute_ast(context, node[:receiver])
          # Then execute the method on it
          execute_method_on_receiver(receiver, node[:method], node[:args], node[:block])
        when :literal
          node[:value]
        when :identifier
          # For simple identifiers, treat as method calls
          # SECURITY: Validate identifier before calling
          validate_allowed_method(node[:name].to_s)
          context.public_send(node[:name])
        when :hash
          # Convert hash AST to Ruby hash
          node[:pairs].each_with_object({}) do |pair, hash|
            key = execute_ast(context, pair[:key])
            value = execute_ast(context, pair[:value])
            hash[key] = value
          end
        when :array
          node[:elements].map { |elem| execute_ast(context, elem) }
        else
          raise "Unknown AST node type: #{node[:type]}"
        end
      end

      def execute_method_call(context, node)
        method_name = node[:method].to_s

        # SECURITY: Validate method is allowed before calling
        validate_allowed_method(method_name)

        args = node[:args].map { |arg| execute_ast(context, arg) }

        # Handle block if present
        if node[:block]
          block_proc = proc do
            node[:block][:children].map { |stmt| execute_ast(context, stmt) }.last
          end
          context.public_send(method_name, *args, &block_proc)
        else
          context.public_send(method_name, *args)
        end
      end

      def execute_method_on_receiver(receiver, method_name, args, block)
        # SECURITY: Validate method is allowed before calling
        validate_allowed_method(method_name.to_s)

        evaluated_args = args.map { |arg| execute_ast(receiver, arg) }

        if block
          block_proc = proc do
            block[:children].map { |stmt| execute_ast(receiver, stmt) }.last
          end
          receiver.public_send(method_name, *evaluated_args, &block_proc)
        else
          receiver.public_send(method_name, *evaluated_args)
        end
      end

      def validate_allowed_method(method_name)
        # Use the same whitelist from TokenParser
        allowed = TokenParser::DSL_METHODS + TokenParser::MODIFIER_METHODS
        return if allowed.include?(method_name)

        raise SwiftUIRails::SecurityError, "Method '#{method_name}' is not allowed in playground"
      end

      def create_view_context
        # Create a minimal view context for rendering
        controller = ApplicationController.new
        controller.request = ActionDispatch::Request.new(
          'HTTP_HOST' => 'localhost:3000',
          'rack.url_scheme' => 'http'
        )
        view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, controller)
        view.extend(ApplicationHelper) if defined?(ApplicationHelper)
        view.extend(SwiftUIRails::Helpers)
        view
      end

      def extract_component_tree(element)
        # Build a tree representation of the component structure
        {
          type: element.tag_name,
          props: element.options,
          children: element.children&.map { |child| extract_component_tree(child) }
        }.compact
      end

      def extract_stimulus_controllers(code)
        # Parse code for data-controller attributes
        # SECURITY: Fixed polynomial regex vulnerability - simplified patterns
        controller_pattern = /data-controller\s*=\s*["']([^"']+)["']/
        action_pattern = /data-action\s*=\s*["']([^"']+)["']/

        code.scan(controller_pattern) do |match|
          controller_name = match[0]
          @stimulus_controllers[controller_name] ||= {
            values: {},
            targets: [],
            actions: []
          }
        end

        code.scan(action_pattern) do |match|
          action_string = match[0]
          # Parse action string like "click->controller#method"
          # SECURITY: Use simple split instead of regex to avoid ReDoS
          parts = action_string.split('->')
          if parts.length == 2 && parts[1].include?('#')
            event = parts[0]
            controller_method = parts[1].split('#')
            if controller_method.length == 2
              controller = controller_method[0]
              method = controller_method[1]
              if @stimulus_controllers[controller]
                @stimulus_controllers[controller][:actions] << {
                  event: event,
                  method: method
                }
              end
            end
          end
        end
      end

      # Execution context with DSL methods available
      class ExecutionContext
        include SwiftUIRails::DSL
        include SwiftUIRails::Helpers

        attr_reader :view_context

        def initialize(view_context)
          @view_context = view_context
        end

        # Delegate missing methods to view_context for Rails helpers
        def method_missing(method, ...)
          if @view_context.respond_to?(method)
            @view_context.public_send(method, ...)
          else
            super
          end
        end

        def respond_to_missing?(method, include_private = false)
          @view_context.respond_to?(method, include_private) || super
        end

        # Override methods that might be dangerous
        def require(*_args)
          raise SecurityError, 'require is not allowed in playground'
        end

        def load(*_args)
          raise SecurityError, 'load is not allowed in playground'
        end

        # Provide safe alternatives for common needs
        def puts(message)
          # Convert puts to a text element
          text(message.to_s).p(2).bg('gray-100').rounded('md')
        end

        def p(value)
          # Convert p to a formatted text element
          text(value.inspect).font_family('mono').text_sm.p(2).bg('gray-50').rounded
        end
      end
    end
  end
end
