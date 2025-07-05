# frozen_string_literal: true

class ExampleComponent < ApplicationComponent
  prop :title, type: String, default: "Hello from SwiftUI Rails!"
  prop :description, type: String
  
  state :counter, 0
  state :show_details, false
  
  computed :button_text do
    show_details ? "Hide Details" : "Show Details"
  end
  
  # Effects for interactive stories
  effect :counter do |new_value, old_value|
    Rails.logger.info "Counter changed from #{old_value} to #{new_value}" if story_session_id
  end
  
  effect :show_details do |new_value, old_value|
    Rails.logger.info "Show details toggled: #{new_value}" if story_session_id
  end
  
  def call
    # Capture instance variables before entering DSL block
    component_title = title
    component_counter = counter
    component_button_text = button_text
    component_show_details = show_details
    component_description = description
    
    helpers.swift_ui do
      vstack(spacing: 16, class: "bg-white rounded-lg shadow-md p-6") do
        text component_title, class: "text-2xl font-bold"
        
        hstack(spacing: 12) do
          button("-", 
            class: "px-4 py-2 bg-red-500 text-white rounded",
            data: { 
              action: "click->live-story#handleComponentAction", 
              action_name: "decrement",
              component_id: "example_component"
            }
          )
          text "Count: #{component_counter}", class: "text-lg"
          button("+", 
            class: "px-4 py-2 bg-green-500 text-white rounded",
            data: { 
              action: "click->live-story#handleComponentAction", 
              action_name: "increment",
              component_id: "example_component"
            }
          )
        end
        
        button component_button_text, 
          class: "px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600",
          data: { 
            action: "click->live-story#handleComponentAction", 
            action_name: "toggle_details",
            component_id: "example_component"
          }
        
        if component_show_details && component_description
          hr(class: "border-t border-gray-300 my-4")
          text component_description, class: "text-gray-600"
        end
      end
    end
  end
  
  # Interactive action handlers for live stories
  def handle_increment
    self.counter = counter + 1
  end
  
  def handle_decrement
    self.counter = [counter - 1, 0].max
  end
  
  def handle_toggle_details
    self.show_details = !show_details
  end
  
  # Alternative action names for consistency
  alias_method :handle_toggle, :handle_toggle_details
  
  def handle_reset_counter
    self.counter = 0
  end
end
# Copyright 2025
