import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: Number }

  connect() {
    this.durationValue = this.durationValue || 500 // Default 500ms
  }

  startLongPress(event) {
    this.longPressTimer = setTimeout(() => {
      // Dispatch custom event that our component can listen to
      const longPressEvent = new CustomEvent("longpress", { bubbles: true })
      this.element.dispatchEvent(longPressEvent)
      
      // Visual feedback
      this.element.classList.add("scale-95", "opacity-80")
      setTimeout(() => this.element.classList.remove("scale-95", "opacity-80"), 200)
      
      // If we had a server action, we'd trigger it here
      console.log("Long Press Triggered!")
    }, this.durationValue)
  }

  cancelLongPress(event) {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
  }
}
