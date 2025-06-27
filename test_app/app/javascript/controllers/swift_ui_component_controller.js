import { Controller } from "@hotwired/stimulus"

// Handle SwiftUI Rails component interactions
export default class extends Controller {
  static values = {
    componentId: String,
    componentClass: String,
    updateUrl: String
  }
  
  connect() {
    console.log("SwiftUIComponent controller connected to:", this.element)
    console.log("Component values:", {
      componentId: this.componentIdValue,
      componentClass: this.componentClassValue,
      updateUrl: this.updateUrlValue
    })
    // Store reference to the component
    this.componentElement = this.element
  }
  
  handleAction(event) {
    // Get the action ID from the event target
    const target = event.currentTarget
    console.log("Button clicked, element:", target)
    console.log("Button dataset:", target.dataset)
    console.log("Button attributes:", Array.from(target.attributes).map(a => `${a.name}="${a.value}"`).join(' '))
    
    const actionId = this.findActionId(target)
    
    if (!actionId) {
      console.warn("No action ID found for event", event)
      return
    }
    
    // Find component metadata by traversing up the DOM tree
    const componentData = this.findComponentData()
    
    if (!componentData.component_id || !componentData.component_class) {
      console.error("Could not find component metadata", componentData)
      return
    }
    
    // Prepare the action data
    const actionData = {
      action_id: actionId,
      component_id: componentData.component_id,
      component_class: componentData.component_class,
      event_type: event.type,
      target_value: this.getTargetValue(event),
      target_checked: event.target.checked,
      target_dataset: event.target.dataset,
      // Add storybook context if available
      story_session_id: window.storybookSessionId,
      story_name: window.currentStoryName,
      story_variant: window.currentStoryVariant
    }
    
    // Send action to server
    this.sendAction(actionData)
  }
  
  findComponentData() {
    console.log("Finding component data for element:", this.element)
    
    // First try to get from this element's Stimulus values
    if (this.componentIdValue && this.componentClassValue) {
      console.log("Found on element:", this.componentIdValue, this.componentClassValue)
      return {
        component_id: this.componentIdValue,
        component_class: this.componentClassValue
      }
    }
    
    // Otherwise, traverse up the DOM to find the component wrapper
    let element = this.element
    while (element && element !== document.body) {
      console.log("Checking element:", element.tagName, element.id, element.dataset)
      
      // Check if this element has the component metadata
      if (element.dataset.componentId && element.dataset.componentClass) {
        console.log("Found component data on element:", element.dataset.componentId, element.dataset.componentClass)
        return {
          component_id: element.dataset.componentId,
          component_class: element.dataset.componentClass
        }
      }
      
      // Also check for Stimulus values on parent controllers
      const controller = this.application.getControllerForElementAndIdentifier(element, 'swift-ui-component')
      if (controller && controller !== this && controller.componentIdValue && controller.componentClassValue) {
        console.log("Found on parent controller:", controller.componentIdValue, controller.componentClassValue)
        return {
          component_id: controller.componentIdValue,
          component_class: controller.componentClassValue
        }
      }
      
      element = element.parentElement
    }
    
    console.warn("No component data found, using fallback")
    // Fallback to element ID if nothing found
    return {
      component_id: this.element.id || '',
      component_class: ''
    }
  }
  
  findActionId(element) {
    // Look for data-swift-ui-component-action-* attributes
    const attributes = element.attributes
    for (let i = 0; i < attributes.length; i++) {
      const attr = attributes[i]
      if (attr.name.startsWith('data-swift-ui-component-action-')) {
        return attr.value
      }
    }
    return null
  }
  
  getTargetValue(event) {
    const target = event.target
    
    // Handle different input types
    if (target.tagName === 'SELECT') {
      return target.value
    } else if (target.type === 'checkbox' || target.type === 'radio') {
      return target.checked
    } else if (target.value !== undefined) {
      return target.value
    } else {
      return target.textContent
    }
  }
  
  async sendAction(actionData) {
    const url = this.updateUrlValue || '/swift_ui/actions'
    
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html, application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify(actionData)
      })
      
      if (response.ok) {
        const contentType = response.headers.get('content-type')
        
        if (contentType.includes('turbo-stream')) {
          // Let Turbo handle the stream
          const text = await response.text()
          Turbo.renderStreamMessage(text)
        } else if (contentType.includes('json')) {
          // Handle JSON response
          const data = await response.json()
          if (data.redirect_to) {
            Turbo.visit(data.redirect_to)
          } else if (data.update_component) {
            // Trigger component update
            this.dispatch('update', { detail: data })
          }
        }
      } else {
        console.error('Action failed:', response.statusText)
      }
    } catch (error) {
      console.error('Error sending action:', error)
    }
  }
  
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
  
  // Allow programmatic triggering of actions
  triggerAction(actionId, data = {}) {
    const actionData = {
      action_id: actionId,
      component_id: this.componentIdValue || this.element.id,
      component_class: this.componentClassValue,
      ...data
    }
    
    this.sendAction(actionData)
  }
}