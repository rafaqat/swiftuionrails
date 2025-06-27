# frozen_string_literal: true

module SwiftUi
  class ActionsController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def create
      action_data = params.permit(:action_id, :component_id, :component_class, :event_type, :target_value, :target_checked, 
                                  :story_session_id, :story_name, :story_variant, target_dataset: {})
      
      # Check if we're in storybook mode
      if action_data[:story_session_id].present? && action_data[:story_name].present?
        # Use StorySession to maintain component state
        story_session = StorySession.find_or_create(
          action_data[:story_name],
          action_data[:story_variant] || 'default',
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
        component_class = action_data[:component_class].constantize
        
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
  end
end