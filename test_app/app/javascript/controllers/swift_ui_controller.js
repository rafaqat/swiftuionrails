import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    state: Object, 
    componentId: String
  }
  
  connect() {
    try {
      this.initializeState()
    } catch (error) {
      console.error('Error initializing SwiftUI controller:', error)
    }
  }
  
  initializeState() {
    try {
      // Set up reactive state
      this.state = new Proxy(this.stateValue || {}, {
        set: (target, property, value) => {
          const oldValue = target[property]
          target[property] = value
          this.onStateChange(property, oldValue, value)
          return true
        }
      })
    } catch (error) {
      console.error('Error setting up reactive state:', error)
    }
  }
  
  onStateChange(property, oldValue, newValue) {
    try {
      // Dispatch custom event for state changes
      this.dispatch("stateChange", { 
        detail: { property, oldValue, newValue } 
      })
    } catch (error) {
      console.error('Error dispatching state change:', error)
    }
  }
  
  updateState(event) {
    try {
      const { property, value } = event.detail
      this.state[property] = value
    } catch (error) {
      console.error('Error updating state:', error)
    }
  }
}