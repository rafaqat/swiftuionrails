# frozen_string_literal: true

require_relative '../dsl/element'

module SwiftUIRails
  module Playground
    class Executor
      include SwiftUIRails::DSL
      include SwiftUIRails::Helpers

      attr_reader :session_id, :view_context

      Result = Struct.new(:success?, :html, :error, :component_tree, :stimulus_controllers, keyword_init: true)

      ##
      # Initializes a new Executor with the given session ID and an optional view context.
      # If no view context is provided, a minimal Rails view context is created.
      # @param [String] session_id - Unique identifier for the execution session.
      def initialize(session_id, view_context = nil)
        @session_id = session_id
        @view_context = view_context || create_view_context
        @stimulus_controllers = {}
      end

      ##
      # Executes SwiftUIRails DSL code in a sandboxed environment and returns the result.
      #
      # Validates the code for unsafe patterns, evaluates it within a restricted context, and returns a structured result containing HTML output, a component tree (if applicable), and detected Stimulus controllers.
      # Returns a failure result with an error message if a syntax or runtime error occurs.
      # @param [String] code The SwiftUIRails DSL code to execute.
      # @return [Result] The structured result of the execution, including success status, HTML output, component tree, Stimulus controllers, and error message if any.
      def execute(code)
        # Safety check - basic validation
        validate_code_safety!(code)

        # Execute in sandboxed context
        component_tree = nil

        # Create a clean execution context
        context = ExecutionContext.new(@view_context)

        # Execute the code
        result = context.instance_eval(code)

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

      ##
      # Checks the provided code for potentially dangerous operations and raises a SecurityError if any are detected.
      # @param [String] code The code to be validated for safety.
      # @raise [SecurityError] If the code contains unsafe patterns such as system calls, file operations, or dynamic code execution.
      def validate_code_safety!(code)
        # Disallow dangerous operations
        dangerous_patterns = [
          /`.*`/, # Backticks
          /\bsystem\b/,             # system calls
          /\bexec\b/,               # exec calls
          /\beval\b/,               # eval (except in our context)
          /\b__send__\b/,           # __send__
          /\bFile\b/,               # File operations
          /\bIO\b/,                 # IO operations
          /\bDir\b/,                # Directory operations
          /\bKernel\b/,             # Kernel methods
          /\bProcess\b/,            # Process operations
          /\brequire\b/,            # require statements
          /\bload\b/,               # load statements
          /\bopen\b/,               # open calls
          /%x\{/ # %x{} syntax
        ]

        dangerous_patterns.each do |pattern|
          raise SecurityError, "Unsafe operation detected: #{pattern.source}" if code.match?(pattern)
        end
      end

      ##
      # Creates a minimal Rails view context for rendering DSL output.
      # The context includes the application helper and SwiftUIRails helpers if available.
      # @return [ActionView::Base] A configured view context instance.
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

      ##
      # Recursively constructs a hash representation of a DSL element and its children, forming a component tree.
      # @param element [SwiftUIRails::DSL::Element] The root DSL element to extract the tree from.
      # @return [Hash] A nested hash describing the element's type, properties, and child components.
      def extract_component_tree(element)
        # Build a tree representation of the component structure
        {
          type: element.tag_name,
          props: element.options,
          children: element.children&.map { |child| extract_component_tree(child) }
        }.compact
      end

      ##
      # Extracts Stimulus controller names and their associated actions from the provided code string.
      # Populates the @stimulus_controllers hash with controller names as keys and their actions as parsed from data-controller and data-action attributes.
      # @param [String] code The code string to scan for Stimulus controller and action definitions.
      def extract_stimulus_controllers(code)
        # Parse code for data-controller attributes
        controller_pattern = /data[:\s]*[\{\(]?\s*controller[:\s]*["']([^"']+)["']/
        action_pattern = /data[:\s]*[\{\(]?\s*action[:\s]*["']([^"']+)["']/

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
          if action_string =~ /(\w+)->(\w+)#(\w+)/
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

        ##
        # Initializes the execution context with the provided view context.
        # @param [Object] view_context - The view context to delegate helper methods to.
        def initialize(view_context)
          @view_context = view_context
        end

        ##
        # Forwards missing method calls to the view context if it responds to them, enabling access to Rails helper methods within the execution context.
        # Calls `super` if the view context does not handle the method.
        def method_missing(method, ...)
          if @view_context.respond_to?(method)
            @view_context.send(method, ...)
          else
            super
          end
        end

        ##
        # Determines whether the view context or superclass responds to the given method.
        # @param [Symbol] method - The method name to check.
        # @param [Boolean] include_private - Whether to include private methods in the check.
        # @return [Boolean] True if the method is handled, false otherwise.
        def respond_to_missing?(method, include_private = false)
          @view_context.respond_to?(method, include_private) || super
        end

        ##
        # Prevents the use of `require` within the playground execution context for security reasons.
        # @raise [SecurityError] Always raised to block dynamic code loading.
        def require(*_args)
          raise SecurityError, 'require is not allowed in playground'
        end

        ##
        # Raises a SecurityError to prevent the use of `load` within the playground execution context.
        def load(*_args)
          raise SecurityError, 'load is not allowed in playground'
        end

        ##
        # Returns a styled text element displaying the given message, as a safe alternative to standard output.
        # @param [Object] message - The message to display.
        def puts(message)
          # Convert puts to a text element
          text(message.to_s).p(2).bg('gray-100').rounded('md')
        end

        ##
        # Returns a styled text element displaying the inspected value in monospace font.
        def p(value)
          # Convert p to a formatted text element
          text(value.inspect).font_family('mono').text_sm.p(2).bg('gray-50').rounded
        end
      end
    end
  end
end
