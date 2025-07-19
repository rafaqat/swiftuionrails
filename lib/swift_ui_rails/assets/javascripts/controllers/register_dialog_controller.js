import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="register-dialog"
export default class extends Controller {
  static targets = ["modal"]
  
  static values = {
    closeUrl: String
  }
  
  connect() {
    // Set up escape key listener
    this.boundEscapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
  }
  
  disconnect() {
    document.removeEventListener("keydown", this.boundEscapeHandler)
    document.body.style.overflow = ''
  }
  
  // Modal control methods
  close() {
    window.location.href = this.closeUrlValue
  }
  
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
  
  stopPropagation(event) {
    event.stopPropagation()
  }
  
  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}