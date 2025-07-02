import { Controller } from "@hotwired/stimulus"

// State debugging panel controller
export default class extends Controller {
  static values = {
    state: Object,
    open: { type: Boolean, default: false }
  }
  
  connect() {
    this.setupKeyboardShortcuts()
    this.updateVisibility()
  }
  
  show() {
    this.openValue = true
  }
  
  hide() {
    this.openValue = false
  }
  
  toggle() {
    this.openValue = !this.openValue
  }
  
  openValueChanged() {
    this.updateVisibility()
  }
  
  updateVisibility() {
    if (this.openValue) {
      this.element.style.display = 'flex'
      this.refreshState()
    } else {
      this.element.style.display = 'none'
    }
  }
  
  refreshState() {
    // Get latest state from component
    const component = this.findParentComponent()
    if (component && component._swiftUIReactiveController) {
      const controller = component._swiftUIReactiveController
      
      // Update state display
      this.updateStateDisplay({
        props: controller.propsValue,
        bindings: controller.collectBindings(),
        fingerprint: controller.stateFingerprintValue
      })
    }
  }
  
  updateStateDisplay(additionalState) {
    const content = this.element.querySelector('.debug-content')
    if (!content) return
    
    // Merge with existing state
    const fullState = {
      ...this.stateValue,
      ...additionalState,
      lastUpdate: new Date().toISOString()
    }
    
    // Find tables to update
    const tables = content.querySelectorAll('.debug-table')
    tables.forEach(table => {
      const section = table.closest('.debug-section')
      const title = section.querySelector('h5')?.textContent
      
      if (title === 'Component' && fullState.lastUpdate) {
        // Add last update time
        const existingRow = table.querySelector('tr:last-child')
        if (!existingRow?.querySelector('.debug-key')?.textContent.includes('last_update')) {
          const row = document.createElement('tr')
          row.innerHTML = `
            <td class="debug-key">last_update</td>
            <td class="debug-value">${this.formatTime(fullState.lastUpdate)}</td>
          `
          table.appendChild(row)
        } else {
          existingRow.querySelector('.debug-value').textContent = this.formatTime(fullState.lastUpdate)
        }
      }
    })
    
    // Highlight recent changes
    this.highlightRecentChanges()
  }
  
  highlightRecentChanges() {
    const changes = this.element.querySelectorAll('.debug-change')
    changes.forEach(change => {
      const timeText = change.querySelector('.change-time')?.textContent
      if (timeText && timeText.includes('0s ago')) {
        change.style.backgroundColor = '#fef3c7'
        setTimeout(() => {
          change.style.transition = 'background-color 1s'
          change.style.backgroundColor = '#f9fafb'
        }, 100)
      }
    })
  }
  
  findParentComponent() {
    let parent = this.element.parentElement
    while (parent) {
      if (parent.dataset.swiftUiReactive === 'true') {
        return parent
      }
      parent = parent.parentElement
    }
    return null
  }
  
  setupKeyboardShortcuts() {
    this.keydownHandler = (event) => {
      // Cmd/Ctrl + Shift + D to toggle debug panel
      if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === 'D') {
        event.preventDefault()
        this.toggle()
      }
      
      // R to refresh when open
      if (this.openValue && event.key === 'r' && !event.metaKey && !event.ctrlKey) {
        event.preventDefault()
        this.refreshState()
      }
    }
    
    document.addEventListener('keydown', this.keydownHandler)
  }
  
  disconnect() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
  }
  
  formatTime(isoString) {
    const date = new Date(isoString)
    const now = new Date()
    const diff = now - date
    
    if (diff < 1000) return 'just now'
    if (diff < 60000) return `${Math.floor(diff / 1000)}s ago`
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
    
    return date.toLocaleTimeString()
  }
  
  // Export state to console
  exportState() {
    const state = {
      ...this.stateValue,
      exported_at: new Date().toISOString()
    }
    
    console.group(`%c${state.component.class} State Export`, 'color: #3b82f6; font-weight: bold;')
    console.log('Component:', state.component)
    console.log('Props:', state.props)
    console.log('State:', state.state)
    console.log('Bindings:', state.bindings)
    console.log('Observed:', state.observed)
    console.log('Recent Changes:', state.changes)
    console.groupEnd()
    
    // Copy to clipboard
    navigator.clipboard.writeText(JSON.stringify(state, null, 2))
    this.showNotification('State exported to console and copied to clipboard')
  }
  
  showNotification(message) {
    const notification = document.createElement('div')
    notification.textContent = message
    notification.style.cssText = `
      position: fixed;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: #10b981;
      color: white;
      padding: 12px 24px;
      border-radius: 6px;
      font-size: 14px;
      z-index: 9999;
      animation: slideUp 0.3s ease;
    `
    
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.style.animation = 'slideDown 0.3s ease'
      setTimeout(() => notification.remove(), 300)
    }, 2000)
  }
}