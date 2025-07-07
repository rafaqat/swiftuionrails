import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    // Close dropdown when clicking outside
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
  }
  
  toggle() {
    if (this.hasMenuTarget) {
      const isHidden = this.menuTarget.classList.contains('hidden')
      
      if (isHidden) {
        this.open()
      } else {
        this.close()
      }
    }
  }
  
  open() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove('hidden')
      // Add event listener for clicking outside
      setTimeout(() => {
        document.addEventListener('click', this.closeOnClickOutside)
      }, 0)
    }
  }
  
  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
      // Remove event listener
      document.removeEventListener('click', this.closeOnClickOutside)
    }
  }
  
  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
  
  disconnect() {
    document.removeEventListener('click', this.closeOnClickOutside)
  }
}