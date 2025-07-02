import { Controller } from "@hotwired/stimulus"

// Rails-first counter controller - manages state on the client side
export default class extends Controller {
  static values = { 
    count: { type: Number, default: 0 },
    step: { type: Number, default: 1 },
    label: { type: String, default: "Counter" }
  }
  
  static targets = ["count", "label", "decrementBtn", "incrementBtn", "history"]
  
  connect() {
    console.log("Counter controller connected", {
      count: this.countValue,
      step: this.stepValue,
      label: this.labelValue
    })
    
    // Initialize history
    this.history = []
    
    // Initial render
    this.render()
  }
  
  // Actions
  increment() {
    const oldValue = this.countValue
    this.countValue += this.stepValue
    this.addToHistory(oldValue, this.countValue)
    this.render()
  }
  
  decrement() {
    const oldValue = this.countValue
    this.countValue -= this.stepValue
    this.addToHistory(oldValue, this.countValue)
    this.render()
  }
  
  reset() {
    const oldValue = this.countValue
    this.countValue = 0
    this.addToHistory(oldValue, 0)
    this.render()
  }
  
  // Update display when values change
  countValueChanged() {
    this.render()
  }
  
  labelValueChanged() {
    this.render()
  }
  
  stepValueChanged() {
    this.render()
  }
  
  // Private methods
  render() {
    // Update count display
    if (this.hasCountTarget) {
      this.countTarget.textContent = this.countValue.toString()
      
      // Apply scale animation
      if (this.countValue === 0) {
        this.countTarget.classList.remove("scale-110")
        this.countTarget.classList.add("scale-100")
      } else {
        this.countTarget.classList.remove("scale-100")
        this.countTarget.classList.add("scale-110")
      }
    }
    
    // Update label with color
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = `${this.labelValue}: ${this.countValue}`
      
      // Apply color based on positive/negative
      if (this.countValue > 0) {
        this.labelTarget.classList.remove("text-red-600")
        this.labelTarget.classList.add("text-green-600")
      } else if (this.countValue < 0) {
        this.labelTarget.classList.remove("text-green-600")
        this.labelTarget.classList.add("text-red-600")
      } else {
        this.labelTarget.classList.remove("text-green-600", "text-red-600")
        this.labelTarget.classList.add("text-gray-600")
      }
    }
    
    // Update button states
    if (this.hasDecrementBtnTarget) {
      if (this.countValue <= 0) {
        this.decrementBtnTarget.classList.add("opacity-50", "cursor-not-allowed")
        this.decrementBtnTarget.disabled = true
      } else {
        this.decrementBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
        this.decrementBtnTarget.disabled = false
      }
    }
    
    // Render history
    this.renderHistory()
  }
  
  addToHistory(from, to) {
    this.history.push({
      from: from,
      to: to,
      at: new Date().toLocaleTimeString()
    })
    
    // Keep only last 5 entries
    if (this.history.length > 5) {
      this.history = this.history.slice(-5)
    }
  }
  
  renderHistory() {
    if (!this.hasHistoryTarget || !this.history || this.history.length === 0) return
    
    // Build history HTML
    let historyHTML = `
      <div class="my-4 border-t border-gray-200"></div>
      <h3 class="text-sm font-semibold text-gray-700 mb-2">History</h3>
      <div class="space-y-1">
    `
    
    // Show latest first
    this.history.slice().reverse().forEach(entry => {
      historyHTML += `
        <div class="text-xs text-gray-500">
          ${entry.from} → ${entry.to} <span class="text-gray-400">(${entry.at})</span>
        </div>
      `
    })
    
    historyHTML += '</div>'
    
    this.historyTarget.innerHTML = historyHTML
  }
  
  // Public API for external updates (e.g., from storybook controls)
  updateFromProps(props) {
    if (props.initial_count !== undefined) {
      this.countValue = props.initial_count
    }
    if (props.step !== undefined) {
      this.stepValue = props.step
    }
    if (props.label !== undefined) {
      this.labelValue = props.label
    }
    this.render()
  }
}