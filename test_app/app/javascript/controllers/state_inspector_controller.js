import { Controller } from "@hotwired/stimulus"

// State inspector controller that updates only when state changes
export default class extends Controller {
  static targets = ["display"]
  static values = { 
    story: String,
    variant: String,
    sessionId: String,
    state: Object
  }

  connect() {
    console.log("🔍 State inspector connected")
    
    // Listen for state change events from the parent controller
    this.boundStateChangeHandler = this.handleStateChange.bind(this)
    this.element.closest('[data-controller*="live-story"]')?.addEventListener('state:changed', this.boundStateChangeHandler)
    
    // Listen for Turbo Stream updates
    this.boundStreamHandler = this.handleStreamRender.bind(this)
    document.addEventListener('turbo:before-stream-render', this.boundStreamHandler)
    
    // Display initial state if provided
    if (this.hasStateValue && Object.keys(this.stateValue).length > 0) {
      this.updateDisplay(this.stateValue)
    }
  }

  disconnect() {
    // Clean up event listeners
    this.element.closest('[data-controller*="live-story"]')?.removeEventListener('state:changed', this.boundStateChangeHandler)
    document.removeEventListener('turbo:before-stream-render', this.boundStreamHandler)
  }

  handleStateChange(event) {
    // Update display when state changes
    if (event.detail && event.detail.state) {
      this.updateDisplay(event.detail.state)
    }
  }

  handleStreamRender(event) {
    // Wait for the stream to be rendered, then look for state data
    setTimeout(() => {
      const stateScript = document.getElementById('component-state-data')
      if (stateScript) {
        try {
          const state = JSON.parse(stateScript.textContent)
          this.updateDisplay(state)
        } catch (e) {
          console.error("Failed to parse state from script:", e)
        }
      }
    }, 50)
  }

  updateDisplay(stateData) {
    if (!this.hasDisplayTarget || !stateData) return

    const html = `
      <div class="space-y-2">
        ${Object.entries(stateData).map(([key, value]) => `
          <div class="flex justify-between items-center">
            <span class="text-sm text-gray-600">${key}:</span>
            <span class="font-mono text-sm">${JSON.stringify(value)}</span>
          </div>
        `).join('')}
      </div>
      ${this.sessionIdValue ? `
        <div class="text-xs text-gray-500 mt-3 pt-3 border-t">
          Session: ${this.sessionIdValue.substring(0, 8)}...
        </div>
      ` : ''}
    `
    
    // Add subtle animation
    this.displayTarget.style.opacity = '0.7'
    this.displayTarget.innerHTML = html
    
    requestAnimationFrame(() => {
      this.displayTarget.style.transition = 'opacity 0.2s ease-out'
      this.displayTarget.style.opacity = '1'
    })
  }

  // Manual refresh if needed
  refresh() {
    if (!this.storyValue || !this.variantValue || !this.sessionIdValue) return

    fetch(`/storybook/state_inspector?story=${this.storyValue}&story_variant=${this.variantValue}&session_id=${this.sessionIdValue}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.getCSRFToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      this.updateDisplay(data)
    })
    .catch(error => {
      console.error('State refresh failed:', error)
    })
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
}