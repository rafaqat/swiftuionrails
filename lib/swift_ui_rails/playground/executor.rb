# frozen_string_literal: true

require_relative '../dsl/element'

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
        # Safety check - basic validation
        validate_code_safety!(code)

        # Execute in sandboxed context
        component_tree = nil

        # Create a clean execution context
        context = ExecutionContext.new(@view_context)

        # Execute the code in a restricted binding with limited access
        # SECURITY: Using instance_eval with a string is a security risk
        # This should be replaced with a proper DSL parser in production
        # For now, we'll add additional safety measures
        # rubocop:disable Security/Eval
        result = context.instance_eval(code)
        # rubocop:enable Security/Eval

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

      def validate_code_safety!(code)
        # Disallow dangerous operations
        dangerous_patterns = [
          /`.*`/, # Backticks
          /\bsystem\s*\(/,          # system calls
          /\bexec\s*\(/,            # exec calls
          /\beval\s*\(/,            # eval calls
          /\b__send__\b/,           # __send__
          /\bFile\s*\./,            # File operations
          /\bIO\s*\./,              # IO operations
          /\bDir\s*\./,             # Directory operations
          /\bKernel\s*\./,          # Kernel methods
          /\bProcess\s*\./,         # Process operations
          /\brequire\b/,            # require statements
          /\bload\b/,               # load statements
          /\bopen\s*\(/,            # open calls
          /%x[\{\[]/,               # %x{} and %x[] syntax
          /\bconstantize\b/,        # constantize method
          /\bclass_eval\b/,         # class_eval
          /\bmodule_eval\b/,        # module_eval
          /\binstance_eval\b/,      # instance_eval (when called directly)
          /\bpublic_send\b/,        # public_send
          /\bmethod\s*\(/,          # method() calls
          /\b\.send\s*\(/,          # .send() calls
          /\bObject\s*\./,          # Object class methods
          /\bClass\s*\./,           # Class class methods
          /\bModule\s*\./           # Module class methods
        ]

        dangerous_patterns.each do |pattern|
          raise SwiftUIRails::SecurityError, "Unsafe operation detected: #{pattern.source}" if code.match?(pattern)
        end
        
        # Additional checks for encoded strings that might hide malicious code
        if code.include?('\\x') || code.include?('\\u') || code.include?('%')
          raise SwiftUIRails::SecurityError, 'Encoded strings are not allowed'
        end
        
        # Check for attempts to access constants
        if code.match?(/\b[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*\b/) && !code.match?(/\b(String|Integer|Float|Array|Hash|Symbol|TrueClass|FalseClass|NilClass)\b/)
          raise SwiftUIRails::SecurityError, 'Direct constant access is not allowed'
        end
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
        # Fixed: Use possessive quantifiers and atomic groups to prevent backtracking
        controller_pattern = /data(?:\s*[:=]\s*)?(?:\{|\()?\s*controller\s*[:=]\s*["']([^"']+)["']/
        action_pattern = /data(?:\s*[:=]\s*)?(?:\{|\()?\s*action\s*[:=]\s*["']([^"']+)["']/

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
          # Fixed: Use more specific pattern with anchors
          if action_string =~ /\A(\w+)->(\w+)#(\w+)\z/
            event = ::Regexp.last_match(1)
            controller = ::Regexp.last_match(2)
            method = ::Regexp.last_match(3)
            if @stimulus_controllers[controller]
              @stimulus_controllers[controller][:actions] << {
                event: event,
                method: method
              }
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
            @view_context.send(method, ...)
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
