import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    state: Object, 
    componentId: String
  }
  
  connect() {
    this.initializeState()
  }
  
  initializeState() {
    // Set up reactive state
    this.state = new Proxy(this.stateValue || {}, {
      set: (target, property, value) => {
        const oldValue = target[property]
        target[property] = value
        this.onStateChange(property, oldValue, value)
        return true
      }
    })
  }
  
  onStateChange(property, oldValue, newValue) {
    // Dispatch custom event for state changes
    this.dispatch("stateChange", { 
      detail: { property, oldValue, newValue } 
    })
  }
  
  updateState(event) {
    if (!event?.detail || typeof event.detail !== 'object') {
      console.warn('Invalid event detail in updateState:', event)
      return
    }
    const { property, value } = event.detail
    if (property === undefined) {
      console.warn('Missing property in updateState event detail')
      return
    }
    this.state[property] = value
    
    // Dispatch state change event for other components to listen
    this.dispatch("stateChanged", { 
      detail: { property, value, state: this.state },
      bubbles: true 
    })
  }
}