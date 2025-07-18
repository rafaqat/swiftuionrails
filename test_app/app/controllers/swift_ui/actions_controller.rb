# frozen_string_literal: true

# Copyright 2025

module SwiftUi
  class ActionsController < ApplicationController
    # SECURITY: DO NOT skip CSRF verification without proper authentication
    # If CSRF must be disabled for specific use cases, implement alternative
    # authentication such as signed requests or API tokens
    before_action :verify_component_security
    before_action :check_rate_limit

    def create
      action_data = params.permit(:action_id, :component_id, :component_class, :event_type, :target_value, :target_checked,
                                  :story_session_id, :story_name, :story_variant, target_dataset: {})

      # Check if we're in storybook mode
      if action_data[:story_session_id].present? && action_data[:story_name].present?
        # Use StorySession to maintain component state
        story_session = StorySession.find_or_create(
          action_data[:story_name],
          action_data[:story_variant] || "default",
          action_data[:story_session_id]
        )

        # Get the component instance from the story session
        component = story_session.component_instance

        # The component needs to be re-rendered to register actions
        # So we need to render it first to register the actions
        if component
          # Render the component to register actions
          helpers.capture { component.call }

          # Now execute the action
          if component.respond_to?(:execute_action)
            component.execute_action(action_data[:action_id], action_data)

            # Save the updated state back to the session
            story_session.save_component_state(component)
          end
        end
      else
        # Fallback to original behavior for non-storybook usage
        # SECURITY: Validate component class against whitelist
        component_class_name = action_data[:component_class]
        component_class = safe_constantize_component(component_class_name)

        # Get stored state and props from session
        component_key = "component_#{action_data[:component_id]}"
        stored_data = session[component_key] || {}

        # Merge state and props
        component_props = stored_data[:props] || {}
        component_state = stored_data[:state] || {}

        # Create component with original props
        component = component_class.new(**component_props.symbolize_keys)

        # Restore state values if component supports it
        if component.respond_to?(:state_values=) && component_state.any?
          component.instance_variable_set(:@state_values, component_state.symbolize_keys)
        end

        # Render the component to register actions
        helpers.capture { component.call }

        # Execute the action
        if component.respond_to?(:execute_action)
          component.execute_action(action_data[:action_id], action_data)

          # Store updated state and props in session
          session[component_key] = {
            props: component_props,
            state: component.respond_to?(:state_values) ? component.state_values : {}
          }
        end
      end

      # Re-render the component
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            action_data[:component_id],
            component
          )
        end

        format.json do
          render json: {
            success: true,
            component_id: action_data[:component_id],
            state: component.respond_to?(:state_values) ? component.state_values : {}
          }
        end
      end
    rescue => e
      Rails.logger.error "SwiftUI Action Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end

    private

    def verify_component_security
      # Verify request origin
      unless request.xhr? || request.format.turbo_stream?
        render json: { error: "Invalid request format" }, status: :bad_request
        return false
      end

      true
    end

    def safe_constantize_component(component_class_name)
      # SECURITY: Use the same whitelist as ReactiveController
      unless component_class_name.is_a?(String) && allowed_component?(component_class_name)
        Rails.logger.error "[SECURITY] Attempted to instantiate unauthorized component in ActionsController: #{component_class_name}"
        audit_log_security_event(
          event_type: "unauthorized_component_instantiation",
          component_class: component_class_name,
          controller: "ActionsController"
        )

        raise SecurityError, "Unauthorized component: #{component_class_name}"
      end

      begin
        # SECURITY: Use explicit mapping instead of constantize to avoid code injection
        # This mapping is maintained in sync with allowed_component? method
        component_class = case component_class_name
        when "ButtonComponent" then ButtonComponent
        when "CardComponent" then CardComponent
        when "TextComponent" then TextComponent
        when "ImageComponent" then ImageComponent
        when "LinkComponent" then LinkComponent
        when "CounterComponent" then CounterComponent
        when "FormComponent" then FormComponent
        when "ToggleComponent" then ToggleComponent
        when "ListComponent" then ListComponent
        when "GridComponent" then GridComponent
        when "ModalComponent" then ModalComponent
        when "TabsComponent" then TabsComponent
        when "ProductCardComponent" then ProductCardComponent
        when "ProductListComponent" then ProductListComponent
        when "ProductLayoutComponent" then ProductLayoutComponent
        when "ProductPriceComponent" then ProductPriceComponent
        when "ProductRatingComponent" then ProductRatingComponent
        when "ProductVariantsComponent" then ProductVariantsComponent
        when "EnhancedLoginComponent" then EnhancedLoginComponent
        when "EnhancedRegisterComponent" then EnhancedRegisterComponent
        when "AuthLayoutComponent" then AuthLayoutComponent
        when "AuthErrorComponent" then AuthErrorComponent
        when "ExampleComponent" then ExampleComponent
        when "GridTestComponent" then GridTestComponent
        else
          # SECURITY: No constantize allowed - all components must be explicitly mapped
          # This prevents any possibility of code injection
          raise NameError, "Component not found in explicit mapping: #{component_class_name}"
        end

        # Verify it's actually a SwiftUI Rails component
        unless component_class < SwiftUIRails::Component::Base ||
               (defined?(ApplicationComponent) && component_class < ApplicationComponent) ||
               (defined?(ViewComponent::Base) && component_class < ViewComponent::Base)
          Rails.logger.error "[SECURITY] Class #{component_class_name} is not a valid component"
          raise SecurityError, "#{component_class_name} is not a valid SwiftUI Rails component"
        end

        # Log successful component instantiation
        Rails.logger.info "[AUDIT] ActionsController instantiated component: #{component_class_name}"

        component_class
      rescue NameError => e
        Rails.logger.error "[ERROR] Component class not found: #{component_class_name} - #{e.message}"
        raise ArgumentError, "Component #{component_class_name} not found"
      end
    end

    def allowed_component?(component_name)
      # Use the same whitelist as ReactiveController for consistency
      allowed_components = %w[
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
      ]

      allowed_components.include?(component_name)
    end

    def audit_log_security_event(event_type:, **details)
      Rails.logger.error "[SECURITY AUDIT] #{event_type}: #{details.merge(
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        timestamp: Time.current
      ).to_json}"
    end

    def check_rate_limit
      # Simple rate limiting using Rails cache
      cache_key = "swift_ui_actions:#{request.remote_ip}"
      request_count = Rails.cache.increment(cache_key, 1, expires_in: 1.minute)

      # Allow 60 requests per minute per IP
      if request_count && request_count > 60
        audit_log_security_event(
          event_type: "RATE_LIMIT_EXCEEDED",
          ip: request.remote_ip,
          count: request_count
        )

        render json: { error: "Rate limit exceeded. Please try again later." },
               status: :too_many_requests
      end
    end
  end
end
# Copyright 2025
