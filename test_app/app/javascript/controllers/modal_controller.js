import { Controller } from "@hotwired/stimulus"

// Progressive enhancement for modal functionality
export default class extends Controller {
  static targets = ["backdrop"]
  
  connect() {
    // Focus trap
    this.element.focus()
    
    // Prevent body scroll when modal is open
    document.body.style.overflow = 'hidden'
  }
  
  disconnect() {
    // Restore body scroll
    document.body.style.overflow = ''
  }
  
  close(event) {
    // If there's a close link, click it
    const closeLink = this.element.querySelector('a[aria-label="Close modal"]')
    if (closeLink) {
      closeLink.click()
    }
  }
  
  closeOnBackdrop(event) {
    // Only close if clicking the backdrop itself
    if (event.target === this.backdropTarget) {
      event.preventDefault()
      this.close(event)
    }
  }
}