import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // onAppear
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.element.dispatchEvent(new CustomEvent("appear"))
          this.observer.disconnect() // Only trigger once
        }
      })
    })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer.disconnect()
  }
}
