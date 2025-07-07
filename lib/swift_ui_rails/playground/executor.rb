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
