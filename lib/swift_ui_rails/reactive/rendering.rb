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
      
      included do
        skip_before_action :verify_authenticity_token, only: [:update_component]
      end
      
      def update_component
        component_class = params[:component_class].constantize
        component_props = params[:props] || {}
        
        # Instantiate component with props
        component = component_class.new(**component_props.symbolize_keys)
        
        # Render component
        rendered = render_to_string(component)
        
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
      end
    end
    
    # Background job for async updates (only define if Rails is loaded)
    if defined?(::ActiveJob::Base)
      class ReactiveUpdateJob < ::ActiveJob::Base
        queue_as :default
        
        def perform(component_class, component_id, props)
          # Broadcast update via ActionCable
          ReactiveChannel.broadcast_to(
            component_id,
            {
              action: "update",
              component_class: component_class,
              props: props
            }
          )
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
          # Handle update request from client
          if defined?(ReactiveUpdateJob)
            ReactiveUpdateJob.perform_later(
              data["component_class"],
              data["component_id"],
              data["props"]
            )
          end
        end
      end
    end
  end
end