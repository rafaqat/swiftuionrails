# frozen_string_literal: true

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
        # Enable/disable reactive rendering
        def reactive_rendering(enabled = true)
          self.reactive_rendering_enabled = enabled
        end
      end
      
      private
      
      def setup_reactive_updates
        return unless reactive_rendering_enabled
        
        # Add component identifier for updates
        component_id = "swift-ui-#{self.class.name.underscore.dasherize}-#{object_id}"
        
        # Wrap content with reactive container
        @_content = wrap_with_reactive_container(@_content, component_id)
        
        # Add update triggers
        add_reactive_triggers(component_id)
      end
      
      def wrap_with_reactive_container(content, component_id)
        <<~HTML.html_safe
          <div data-swift-ui-reactive="true" 
               data-component-id="#{component_id}"
               data-component-class="#{self.class.name}"
               data-controller="swift-ui-reactive">
            #{content}
          </div>
        HTML
      end
      
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
      
      def update_url_for_component
        # Generate URL for component updates
        # This would be handled by a controller action
        "/swift_ui/components/#{self.class.name.underscore}/update"
      end
      
      def serialize_props
        # Serialize current props for comparison
        props = {}
        
        self.class.prop_definitions.each do |name, definition|
          value = instance_variable_get("@#{name}")
          props[name] = serialize_value(value)
        end
        
        props
      end
      
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
      
      # SECURITY: Safe request_update method for WebSocket updates
      def request_update(component_type, component_id, changes)
        # Use component registry instead of constantize
        component_class = component_registry[component_type]
        raise SecurityError, "Unknown component type: #{component_type}" unless component_class
        
        # Verify component ID format
        unless component_id =~ /\Aswift-ui-[\w-]+-\d+\z/
          raise SecurityError, "Invalid component ID format"
        end
        
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
      
      def component_registry
        @component_registry ||= build_component_registry
      end
      
      def build_component_registry
        registry = {}
        
        # Register all allowed components
        if defined?(SwiftUIRails::Component::Base::ALLOWED_COMPONENTS)
          SwiftUIRails::Component::Base::ALLOWED_COMPONENTS.each do |class_name|
            begin
              klass = class_name.constantize
              # Use a safe key based on the class name
              registry[class_name.underscore] = klass
            rescue NameError
              Rails.logger.warn "Component class not found: #{class_name}"
            end
          end
        end
        
        registry
      end
      
      def find_component_instance(component_class, component_id)
        # This would need to be implemented based on how components are stored
        # For now, return a new instance for demonstration
        component_class.new
      end
      
      def verify_update_authorization(component, changes)
        # Implement authorization logic
        # For example, check if the current user can update this component
        # raise SecurityError unless can_update?(current_user, component)
        true
      end
      
      def safe_constantize(class_name)
        # Double validation - belt and suspenders approach
        raise SecurityError, "Invalid component class" unless ALLOWED_COMPONENTS.include?(class_name)
        
        # Ensure the constant exists and is a valid component
        klass = class_name.constantize
        
        # Verify it's actually a SwiftUI Rails component
        unless klass < SwiftUIRails::Component::Base || klass < ApplicationComponent
          raise SecurityError, "Class is not a valid SwiftUI Rails component"
        end
        
        klass
      rescue NameError => e
        Rails.logger.error "[SECURITY] Failed to constantize component: #{class_name} - #{e.message}"
        raise SecurityError, "Component class not found"
      end
      
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
      
      def audit_log_security_event(event_type:, **details)
        # Implement security event logging
        # This should be sent to a security monitoring system
        Rails.logger.error "[SECURITY AUDIT] #{event_type}: #{details.to_json}"
        
        # In production, this would send to a SIEM system
        # SecurityEventLogger.log(event_type, details) if defined?(SecurityEventLogger)
      end
      
      def audit_log_component_update(component_class:, component_id:)
        # Log successful component updates for audit trail
        Rails.logger.info "[AUDIT] Component updated - Class: #{component_class}, ID: #{component_id}, IP: #{request.remote_ip}"
      end
    end
    
    # Background job for async updates (only define if Rails is loaded)
    if defined?(::ActiveJob::Base)
      class ReactiveUpdateJob < ::ActiveJob::Base
        queue_as :default
        
        def perform(component_class_name, component_id, props)
          # SECURITY: Validate inputs even in background job
          validate_component_class!(component_class_name)
          validate_component_id!(component_id)
          
          # Broadcast update via ActionCable
          ReactiveChannel.broadcast_to(
            component_id,
            {
              action: "update",
              component_class: component_class_name,
              props: sanitize_broadcast_props(props)
            }
          )
        rescue SecurityError => e
          Rails.logger.error "[SECURITY] ReactiveUpdateJob rejected: #{e.message}"
          raise
        end
        
        private
        
        def validate_component_class!(class_name)
          return if class_name.blank?
          
          unless class_name.match?(/\A[A-Z][A-Za-z0-9]*Component\z/)
            raise SecurityError, "Invalid component class name format"
          end
          
          # Additional validation if whitelist is available
          if defined?(SwiftUIRails::Component::Base::ALLOWED_COMPONENTS)
            unless SwiftUIRails::Component::Base::ALLOWED_COMPONENTS.include?(class_name)
              raise SecurityError, "Component class not in whitelist: #{class_name}"
            end
          end
        end
        
        def validate_component_id!(component_id)
          unless component_id =~ /\Aswift-ui-[\w-]+-\d+\z/
            raise SecurityError, "Invalid component ID format"
          end
        end
        
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
        def subscribed
          component_id = params[:component_id]
          stream_for component_id
        end
        
        def request_update(data)
          # SECURITY: Validate and sanitize all input from WebSocket
          component_class_name = data["component_class"]&.to_s
          component_id = data["component_id"]&.to_s
          props = data["props"] || {}
          
          # Validate component class
          unless component_class_name.present?
            Rails.logger.error "[SECURITY] WebSocket update missing component_class"
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
          unless component_id =~ /\Aswift-ui-[\w-]+-\d+\z/
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
        
        def reject_unauthorized
          reject
        end
      end
    end
  end
end
# Copyright 2025
