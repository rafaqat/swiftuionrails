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
    const { property, value } = event.detail
    this.state[property] = value
  }
}