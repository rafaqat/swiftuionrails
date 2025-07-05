import { Controller } from "@hotwired/stimulus"

// Progressive enhancement for search functionality
export default class extends Controller {
  static values = { 
    delay: { type: Number, default: 300 }
  }
  
  connect() {
    this.timeout = null
  }
  
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
  
  debouncedSubmit(event) {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Don't submit on enter key (let form handle that naturally)
    if (event.type === "keydown" && event.key === "Enter") {
      return
    }
    
    // Set new timeout for auto-submit
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.delayValue)
  }
  
  submitForm() {
    // Find the form (could be the element itself or a parent)
    const form = this.element.closest('form') || this.element
    
    if (form && form.requestSubmit) {
      form.requestSubmit()
    } else if (form) {
      // Fallback for older browsers
      form.submit()
    }
  }
}