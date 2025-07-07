# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module DevTools
    # Error boundary for graceful error handling in development
    module ErrorBoundary
      extend ActiveSupport::Concern

      included do
        around_action :wrap_in_error_boundary if Rails.env.development?
      end

      class ComponentError < StandardError
        attr_reader :component_class, :props, :original_error

        def initialize(component_class, props, original_error)
          @component_class = component_class
          @props = props
          @original_error = original_error

          super("Error rendering #{component_class}: #{original_error.message}")
        end
      end

      # Wrap component rendering in error boundary
      def self.wrap_component(component_class, **props)
        return yield unless Rails.env.development?

        begin
          yield
        rescue StandardError => e
          handle_component_error(ComponentError.new(component_class, props, e))
        end
      end

      # Handle component errors gracefully
      def self.handle_component_error(error)
        Rails.logger.error "SwiftUI Component Error: #{error.message}"
        Rails.logger.error error.original_error.backtrace.join("\n")

        # Return error UI instead of crashing
        render_error_ui(error)
      end

      # Render a nice error UI in development
      def self.render_error_ui(error)
        component_name = error.component_class.to_s
        error_message = error.original_error.message
        backtrace = error.original_error.backtrace.first(5)

        <<~HTML.html_safe
          <div class="swift-ui-error-boundary" style="
            border: 2px solid #ef4444;
            border-radius: 8px;
            padding: 16px;
            margin: 16px 0;
            background: #fef2f2;
            font-family: system-ui, -apple-system, sans-serif;
          ">
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 12px;">
              <span style="color: #ef4444; font-size: 20px;">⚠️</span>
              <h3 style="margin: 0; color: #991b1b; font-size: 18px; font-weight: 600;">
                Component Error: #{ERB::Util.html_escape(component_name)}
              </h3>
            </div>
          #{'  '}
            <div style="
              background: white;
              border: 1px solid #fecaca;
              border-radius: 4px;
              padding: 12px;
              margin-bottom: 12px;
            ">
              <p style="margin: 0 0 8px 0; color: #7f1d1d; font-weight: 500;">
                Error Message:
              </p>
              <pre style="
                margin: 0;
                color: #991b1b;
                font-size: 14px;
                white-space: pre-wrap;
                word-break: break-word;
              ">#{error_message}</pre>
            </div>
          #{'  '}
            <details style="margin-bottom: 12px;">
              <summary style="
                cursor: pointer;
                color: #7f1d1d;
                font-weight: 500;
                margin-bottom: 8px;
              ">
                Props (click to expand)
              </summary>
              <pre style="
                background: white;
                border: 1px solid #fecaca;
                border-radius: 4px;
                padding: 8px;
                margin: 0;
                font-size: 12px;
                overflow-x: auto;
              ">#{ERB::Util.html_escape(JSON.pretty_generate(error.props))}</pre>
            </details>
          #{'  '}
            <details>
              <summary style="
                cursor: pointer;
                color: #7f1d1d;
                font-weight: 500;
                margin-bottom: 8px;
              ">
                Stack Trace (click to expand)
              </summary>
              <pre style="
                background: white;
                border: 1px solid #fecaca;
                border-radius: 4px;
                padding: 8px;
                margin: 0;
                font-size: 12px;
                overflow-x: auto;
                color: #7f1d1d;
              ">#{backtrace.join("\n")}</pre>
            </details>
          #{'  '}
            <div style="
              margin-top: 16px;
              padding-top: 16px;
              border-top: 1px solid #fecaca;
              font-size: 14px;
              color: #7f1d1d;
            ">
              💡 <strong>Tip:</strong> Check your component's swift_ui block and props for errors.
              This error boundary prevented your app from crashing.
            </div>
          </div>
        HTML
      end

      private

      def wrap_in_error_boundary
        yield
      rescue StandardError => e
        if request.xhr? || request.format.json?
          render json: {
            error: e.message,
            backtrace: e.backtrace.first(10),
            component: e.respond_to?(:component_class) ? e.component_class.to_s : 'Unknown'
          }, status: :internal_server_error
        else
          @error = e
          render 'swift_ui_rails/errors/component_error', layout: true, status: :internal_server_error
        end
      end
    end

    # Monkey patch ViewComponent to add error boundaries
    module ViewComponentExtension
      def render_in(view_context)
        SwiftUIRails::DevTools::ErrorBoundary.wrap_component(self.class, **@props) do
          super
        end
      end
    end
  end
end

# Apply the extension in development
ViewComponent::Base.prepend(SwiftUIRails::DevTools::ViewComponentExtension) if Rails.env.development?
# Copyright 2025
