# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Reactive
    # Automatic re-rendering when state changes
    module Rendering
      extend ActiveSupport::Concern

      included do
        class_attribute :reactive_rendering_enabled, default: true

        # We'll handle reactive updates differently
        # Removed after_render hook that was interfering
      end

      class_methods do
        ##
        # Enables or disables reactive rendering for the component class.
        # @param [Boolean] enabled - Whether reactive rendering should be enabled (default: true).
        def reactive_rendering(enabled = true)
          self.reactive_rendering_enabled = enabled
        end
      end

      private

      ##
      # Sets up the component for reactive updates by wrapping its content in a reactive container and registering update triggers if reactive rendering is enabled.
      def setup_reactive_updates
        return unless reactive_rendering_enabled

        # Add component identifier for updates
        component_id = "swift-ui-#{self.class.name.underscore.dasherize}-#{object_id}"

        # Wrap content with reactive container
        @_content = wrap_with_reactive_container(@_content, component_id)

        # Add update triggers
        add_reactive_triggers(component_id)
      end

      ##
      # Wraps the given HTML content in a div with data attributes for reactive identification and controller binding.
      # @param [String] content - The HTML content to be wrapped.
      # @param [String] component_id - The unique identifier for the reactive component.
      # @return [ActiveSupport::SafeBuffer] The HTML-safe div containing the content and reactive metadata.
      def wrap_with_reactive_container(content, component_id)
        <<~HTML.html_safe
          <div data-swift-ui-reactive="true"#{' '}
               data-component-id="#{component_id}"
               data-component-class="#{self.class.name}"
               data-controller="swift-ui-reactive">
            #{content}
          </div>
        HTML
      end

      ##
      # Appends an inline script to the component's HTML to register it with the client-side reactive system.
      # The script provides metadata such as component ID, class, update URL, serialized props, and a state fingerprint for real-time updates.
      # @param [String] component_id The unique identifier for the component instance.
      def add_reactive_triggers(component_id)
        triggers = {
          component_id: component_id,
          component_class: self.class.name,
          update_url: update_url_for_component,
          props: serialize_props,
          state_fingerprint: generate_state_fingerprint
        }

        # Add inline script for immediate setup
        script = <<~JS
          <script data-turbo-eval="false">
            (function() {
              const element = document.querySelector('[data-component-id="#{component_id}"]');
              if (element && window.SwiftUIReactive) {
                window.SwiftUIReactive.register(element, #{triggers.to_json});
              }
            })();
          </script>
        JS

        @_content = (@_content + script).html_safe
      end

      ##
      # Returns the URL endpoint for updating this component via the reactive controller.
      # @return [String] The update URL for the component.
      def update_url_for_component
        # Generate URL for component updates
        # This would be handled by a controller action
        "/swift_ui/components/#{self.class.name.underscore}/update"
      end

      ##
      # Serializes the component's current props into a hash suitable for comparison or transmission.
      # Recursively converts prop values, including nested arrays and hashes, into serializable forms.
      # @return [Hash] The serialized props keyed by prop name.
      def serialize_props
        # Serialize current props for comparison
        props = {}

        self.class.prop_definitions.each_key do |name|
          value = instance_variable_get("@#{name}")
          props[name] = serialize_value(value)
        end

        props
      end

      ##
      # Recursively serializes a value for safe transmission, converting ActiveRecord objects to hashes with ID and type, and processing arrays and hashes deeply.
      # @param value The value to serialize, which may be an ActiveRecord object, array, hash, or primitive.
      # @return The serialized representation suitable for JSON or transport.
      def serialize_value(value)
        case value
        when ActiveRecord::Base
          { id: value.id, type: value.class.name }
        when Array
          value.map { |v| serialize_value(v) }
        when Hash
          value.transform_values { |v| serialize_value(v) }
        else
          value
        end
      end

      ##
      # Generates a SHA256 fingerprint representing the current component state, including state, binding, and observed object values, for change detection.
      # @return [String] The SHA256 hash of the serialized state data.
      def generate_state_fingerprint
        # Create a fingerprint of current state for change detection
        state_data = {}

        # Include @state values
        if respond_to?(:state_definitions)
          self.class.state_definitions.each_key do |name|
            state_data[name] = send(name)
          end
        end

        # Include @binding values
        if respond_to?(:binding_definitions)
          self.class.binding_definitions.each_key do |name|
            state_data[name] = send("#{name}_value")
          end
        end

        # Include @observed_object data
        if respond_to?(:observed_object_definitions)
          self.class.observed_object_definitions.each_key do |name|
            state_data[name] = send("#{name}_data")
          end
        end

        Digest::SHA256.hexdigest(state_data.to_json)
      end
    end

    # Controller concern for handling component updates
    module ReactiveController
      extend ActiveSupport::Concern

      # Allowed components whitelist - CRITICAL SECURITY CONTROL
      ALLOWED_COMPONENTS = Set.new(%w[
                                     ButtonComponent
                                     CardComponent
                                     ModalComponent
                                     CounterComponent
                                     ProductCardComponent
                                     ProductListComponent
                                     AuthFormComponent
                                     EnhancedLoginComponent
                                     EnhancedRegisterComponent
                                     AuthErrorComponent
                                     AuthLayoutComponent
                                     # Add new components here as they are created and security-reviewed
                                   ]).freeze

      included do
        # DO NOT skip CSRF verification - this is a critical security control
        # If CSRF must be disabled for specific use cases, implement alternative
        # authentication such as signed requests or API tokens
        before_action :verify_component_security, only: [:update_component]
      end

      ##
      # Handles secure updates of reactive components via HTTP requests.
      #
      # Validates the requested component class against a whitelist, sanitizes incoming props, instantiates the component, and renders its updated HTML. Responds with either a Turbo Stream or JSON containing the rendered HTML and a state fingerprint. Logs security events and audit trails for both unauthorized and successful updates. Returns a 403 error for unauthorized components and a 500 error for unexpected failures.
      # @return [void]
      def update_component
        # SECURITY: Validate component class against whitelist
        component_class_name = params[:component_class]

        unless component_class_name.is_a?(String) && ALLOWED_COMPONENTS.include?(component_class_name)
          # Log potential security breach attempt
          Rails.logger.error "[SECURITY] Attempted to instantiate unauthorized component: #{component_class_name}"
          audit_log_security_event(
            event_type: 'unauthorized_component_instantiation',
            component_class: component_class_name,
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )

          render json: { error: 'Unauthorized component' }, status: :forbidden
          return
        end

        # Safe constantize with additional validation
        component_class = safe_constantize(component_class_name)

        # Validate and sanitize props
        component_props = sanitize_component_props(params[:props] || {})

        # Instantiate component with sanitized props
        component = component_class.new(**component_props.symbolize_keys)

        # Render component with security context
        rendered = render_to_string(component)

        # Log successful component update for audit trail
        audit_log_component_update(
          component_class: component_class_name,
          component_id: params[:component_id]
        )

        # Return as Turbo Stream
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              params[:component_id],
              rendered
            )
          end

          format.json do
            render json: {
              html: rendered,
              state_fingerprint: component.send(:generate_state_fingerprint)
            }
          end
        end
      rescue StandardError => e
        Rails.logger.error "[SECURITY] Component update failed: #{e.message}"
        render json: { error: 'Component update failed' }, status: :internal_server_error
      end

      ##
      # Handles secure WebSocket update requests for a reactive component.
      #
      # Looks up the component class from a registry, validates the component ID format,
      # retrieves the component instance, verifies authorization, and applies state changes.
      # Raises a SecurityError and logs if validation or authorization fails.
      # @param [String] component_type - The underscored name of the component class.
      # @param [String] component_id - The unique identifier for the component instance.
      # @param [Hash] changes - The state changes to apply to the component.
      def request_update(component_type, component_id, changes)
        # Use component registry instead of constantize
        component_class = component_registry[component_type]
        raise SecurityError, "Unknown component type: #{component_type}" unless component_class

        # Verify component ID format
        raise SecurityError, 'Invalid component ID format' unless /\Aswift-ui-[\w-]+-\d+\z/.match?(component_id)

        # Find component instance (this would need to be implemented based on your storage mechanism)
        component = find_component_instance(component_class, component_id)

        # Verify update authorization
        verify_update_authorization(component, changes)

        # Update the component state
        component.update_reactive_state(changes)
      rescue SecurityError => e
        Rails.logger.error "[SECURITY] Unauthorized update attempt: #{e.message}"
        raise
      end

      private

      ##
      # Returns a cached registry mapping underscored component names to their corresponding classes.
      # The registry is built from the allowed components whitelist.
      # @return [Hash{String => Class}] The component registry keyed by underscored class names.
      def component_registry
        @component_registry ||= build_component_registry
      end

      ##
      # Builds a registry mapping underscored allowed component class names to their class objects.
      # Missing classes are logged as warnings.
      # @return [Hash] A hash with underscored class names as keys and component classes as values.
      def build_component_registry
        registry = {}

        # Register all allowed components
        if defined?(SwiftUIRails::Component::Base::ALLOWED_COMPONENTS)
          SwiftUIRails::Component::Base::ALLOWED_COMPONENTS.each do |class_name|
            klass = class_name.constantize
            # Use a safe key based on the class name
            registry[class_name.underscore] = klass
          rescue NameError
            Rails.logger.warn "Component class not found: #{class_name}"
          end
        end

        registry
      end

      ##
      # Returns a new instance of the given component class.
      # This is a placeholder and does not retrieve persisted component state.
      # @param [Class] component_class The component class to instantiate.
      # @return [Object] A new instance of the specified component class.
      def find_component_instance(component_class, _component_id)
        # This would need to be implemented based on how components are stored
        # For now, return a new instance for demonstration
        component_class.new
      end

      ##
      # Determines whether the update to the component is authorized.
      # Override this method to implement custom authorization logic for component updates.
      # @return [Boolean] Returns true if the update is authorized.
      def verify_update_authorization(_component, _changes)
        # Implement authorization logic
        # For example, check if the current user can update this component
        # raise SecurityError unless can_update?(current_user, component)
        true
      end

      ##
      # Safely constantizes a component class name, ensuring it is whitelisted and inherits from a valid SwiftUI Rails component base class.
      # Raises a SecurityError if the class is not allowed, does not exist, or is not a valid component.
      # @param [String] class_name The name of the component class to constantize.
      # @return [Class] The constantized component class.
      # @raise [SecurityError] If the class is not whitelisted, not found, or not a valid component.
      def safe_constantize(class_name)
        # Double validation - belt and suspenders approach
        raise SecurityError, 'Invalid component class' unless ALLOWED_COMPONENTS.include?(class_name)

        # Ensure the constant exists and is a valid component
        klass = class_name.constantize

        # Verify it's actually a SwiftUI Rails component
        unless klass < SwiftUIRails::Component::Base || klass < ApplicationComponent
          raise SecurityError, 'Class is not a valid SwiftUI Rails component'
        end

        klass
      rescue NameError => e
        Rails.logger.error "[SECURITY] Failed to constantize component: #{class_name} - #{e.message}"
        raise SecurityError, 'Component class not found'
      end

      ##
      # Removes potentially dangerous string properties from the given props hash to prevent injection attacks.
      # Only string values starting with method names like `send`, `eval`, `constantize`, `system`, `exec`, or a backtick are removed.
      # @param [Hash] props - The props hash to sanitize.
      # @return [Hash] A sanitized copy of the props hash with unsafe string values removed.
      def sanitize_component_props(props)
        # Sanitize props to prevent injection attacks
        return {} unless props.is_a?(Hash)

        props.deep_dup.tap do |sanitized|
          sanitized.each do |key, value|
            # Remove any potentially dangerous values
            if value.is_a?(String) && value.match?(/\A_?(send|eval|constantize|system|exec|`)/i)
              sanitized.delete(key)
              Rails.logger.warn "[SECURITY] Removed potentially dangerous prop: #{key}"
            end
          end
        end
      end

      ##
      # Validates that the incoming request is an XHR or Turbo Stream request, rejecting others as invalid.
      # Returns true if the request passes validation; otherwise, renders an error response and returns false.
      def verify_component_security
        # Additional security checks can be added here
        # For example: rate limiting, IP whitelisting, request signing

        # Verify request origin
        unless request.xhr? || request.format.turbo_stream?
          render json: { error: 'Invalid request format' }, status: :bad_request
          return false
        end

        true
      end

      ##
      # Logs a security-related event for auditing purposes.
      # Intended for integration with security monitoring systems.
      # @param [String] event_type - The type of security event.
      # @param [Hash] details - Additional contextual details about the event.
      def audit_log_security_event(event_type:, **details)
        # Implement security event logging
        # This should be sent to a security monitoring system
        Rails.logger.error "[SECURITY AUDIT] #{event_type}: #{details.to_json}"

        # In production, this would send to a SIEM system
        # SecurityEventLogger.log(event_type, details) if defined?(SecurityEventLogger)
      end

      ##
      # Logs a successful component update event for auditing purposes, including component class, ID, and requester IP address.
      # @param component_class [String] The class name of the updated component.
      # @param component_id [String] The identifier of the updated component.
      def audit_log_component_update(component_class:, component_id:)
        # Log successful component updates for audit trail
        Rails.logger.info "[AUDIT] Component updated - Class: #{component_class}, ID: #{component_id}, IP: #{request.remote_ip}"
      end
    end

    # Background job for async updates (only define if Rails is loaded)
    if defined?(::ActiveJob::Base)
      class ReactiveUpdateJob < ApplicationJob
        queue_as :default

        ##
        # Performs a background job to broadcast a reactive component update via ActionCable after validating the component class and ID.
        # Sanitizes props before broadcasting to ensure security.
        # @param [String] component_class_name The name of the component class to update.
        # @param [String] component_id The unique identifier for the component instance.
        # @param [Hash] props The properties to be sent with the update.
        def perform(component_class_name, component_id, props)
          # SECURITY: Validate inputs even in background job
          validate_component_class!(component_class_name)
          validate_component_id!(component_id)

          # Broadcast update via ActionCable
          ReactiveChannel.broadcast_to(
            component_id,
            {
              action: 'update',
              component_class: component_class_name,
              props: sanitize_broadcast_props(props)
            }
          )
        rescue SecurityError => e
          Rails.logger.error "[SECURITY] ReactiveUpdateJob rejected: #{e.message}"
          raise
        end

        private

        ##
        # Validates that the given component class name is properly formatted and included in the allowed whitelist.
        # Raises a SecurityError if the class name is invalid or not permitted.
        # @param [String] class_name The name of the component class to validate.
        # @raise [SecurityError] If the class name format is invalid or not in the whitelist.
        def validate_component_class!(class_name)
          return if class_name.blank?

          unless class_name.match?(/\A[A-Z][A-Za-z0-9]*Component\z/)
            raise SecurityError, 'Invalid component class name format'
          end

          # Additional validation if whitelist is available
          return unless defined?(SwiftUIRails::Component::Base::ALLOWED_COMPONENTS)
          return if SwiftUIRails::Component::Base::ALLOWED_COMPONENTS.include?(class_name)

          raise SecurityError, "Component class not in whitelist: #{class_name}"
        end

        ##
        # Validates that the component ID matches the expected format for reactive components.
        # Raises a SecurityError if the format is invalid.
        # @param [String] component_id The component ID to validate.
        def validate_component_id!(component_id)
          return if /\Aswift-ui-[\w-]+-\d+\z/.match?(component_id)

          raise SecurityError, 'Invalid component ID format'
        end

        ##
        # Converts all keys in the props hash to strings for safe broadcasting.
        # Returns an empty hash if props is not a Hash.
        # @param [Hash] props - The properties to sanitize.
        # @return [Hash] The sanitized hash with stringified keys.
        def sanitize_broadcast_props(props)
          return {} unless props.is_a?(Hash)

          # Basic sanitization for broadcast
          props.deep_stringify_keys
        end
      end
    end

    # ActionCable channel for real-time updates (only define if ActionCable is loaded)
    if defined?(::ActionCable::Channel::Base)
      class ReactiveChannel < ::ActionCable::Channel::Base
        ##
        # Subscribes the client to updates for the specified component ID via a WebSocket stream.
        # Begins streaming updates targeted to the given component instance.
        def subscribed
          component_id = params[:component_id]
          stream_for component_id
        end

        ##
        # Handles WebSocket requests to update a reactive component.
        #
        # Validates the component class and ID, sanitizes incoming props to prevent injection or XSS, and enqueues a background job to process the update. Unauthorized or malformed requests are rejected and logged for security monitoring.
        # @param [Hash] data The data payload containing 'component_class', 'component_id', and 'props'.
        def request_update(data)
          # SECURITY: Validate and sanitize all input from WebSocket
          component_class_name = data['component_class']&.to_s
          component_id = data['component_id']&.to_s
          props = data['props'] || {}

          # Validate component class
          if component_class_name.blank?
            Rails.logger.error '[SECURITY] WebSocket update missing component_class'
            reject_unauthorized
            return
          end

          # SECURITY: Use safe component validation
          unless safe_component_class?(component_class_name)
            Rails.logger.error "[SECURITY] WebSocket attempted to use unauthorized component: #{component_class_name}"
            reject_unauthorized
            return
          end

          # Validate component ID format
          unless /\Aswift-ui-[\w-]+-\d+\z/.match?(component_id)
            Rails.logger.error "[SECURITY] WebSocket update with invalid component_id format: #{component_id}"
            reject_unauthorized
            return
          end

          # Sanitize props to prevent injection
          sanitized_props = sanitize_props(props)

          # Handle update request from client
          if defined?(ReactiveUpdateJob)
            ReactiveUpdateJob.perform_later(
              component_class_name,
              component_id,
              sanitized_props
            )
          end
        rescue StandardError => e
          Rails.logger.error "[SECURITY] WebSocket update error: #{e.message}"
          reject_unauthorized
        end

        private

        ##
        # Determines if the given class name is a safe, whitelisted component class for reactive updates.
        # Returns true if the class name matches the expected pattern and is included in the allowed components list,
        # or if it inherits from a recognized base component class; otherwise, returns false.
        # @param [String] class_name The name of the component class to validate.
        # @return [Boolean] Whether the class name is considered safe for use.
        def safe_component_class?(class_name)
          # Use the same whitelist as the controller
          return false unless class_name.match?(/\A[A-Z][A-Za-z0-9]*Component\z/)

          # Check against allowed components
          if defined?(SwiftUIRails::Component::Base::ALLOWED_COMPONENTS)
            SwiftUIRails::Component::Base::ALLOWED_COMPONENTS.include?(class_name)
          else
            # Fallback: verify it's a valid component class
            begin
              klass = class_name.constantize
              klass < SwiftUIRails::Component::Base ||
                (defined?(ApplicationComponent) && klass < ApplicationComponent)
            rescue NameError
              false
            end
          end
        end

        ##
        # Recursively sanitizes all string values in the given props hash to prevent XSS and injection attacks.
        # @param [Hash] props - The props hash to sanitize.
        # @return [Hash] A sanitized copy of the props hash with all string values cleaned.
        def sanitize_props(props)
          return {} unless props.is_a?(Hash)

          # Deep sanitize to prevent injection
          props.deep_stringify_keys.transform_values do |value|
            case value
            when String
              # Sanitize strings to prevent XSS
              ActionController::Base.helpers.sanitize(value)
            when Hash
              sanitize_props(value)
            when Array
              value.map { |v| v.is_a?(String) ? ActionController::Base.helpers.sanitize(v) : v }
            else
              value
            end
          end
        end

        ##
        # Rejects the WebSocket connection for unauthorized clients.
        def reject_unauthorized
          reject
        end
      end
    end
  end
end
# Copyright 2025
