import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Connects to the SwiftUI Rails live reload channel
export default class extends Controller {
  static values = { 
    enabled: { type: Boolean, default: true },
    delay: { type: Number, default: 100 }
  }
  
  connect() {
    if (!this.enabledValue || !this.isDevelopment()) return
    
    this.setupChannel()
    this.showIndicator()
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    this.hideIndicator()
  }
  
  setupChannel() {
    const consumer = createConsumer()
    
    this.subscription = consumer.subscriptions.create("SwiftUiLiveReloadChannel", {
      connected: () => {
        console.log("SwiftUI Rails LiveReload connected")
        this.updateIndicator("connected")
      },
      
      disconnected: () => {
        console.log("SwiftUI Rails LiveReload disconnected")
        this.updateIndicator("disconnected")
      },
      
      received: (data) => {
        this.handleReload(data)
      }
    })
  }
  
  handleReload(data) {
    if (data.type === "reload") {
      // SECURITY: Now receiving component names instead of file paths
      console.log("SwiftUI Rails: Reloading due to changes in components:", data.components)
      
      // Show reload indicator
      this.updateIndicator("reloading")
      
      // Delay reload slightly to allow server to process changes
      setTimeout(() => {
        if (this.shouldUseHotReload(data.components)) {
          this.hotReload(data.components)
        } else {
          this.fullReload()
        }
      }, this.delayValue)
    }
  }
  
  shouldUseHotReload(components) {
    // Use hot reload for component changes
    // If we only have component names (not "view_file"), we can hot reload
    return components.every(component => 
      component !== "view_file"
    )
  }
  
  hotReload(components) {
    // For Turbo-enabled apps, use Turbo to reload just the changed parts
    if (window.Turbo) {
      // Reload the current page with Turbo
      Turbo.visit(window.location.href, { action: "replace" })
      
      // Clear Turbo cache for changed components
      if (window.Turbo.cache) {
        window.Turbo.cache.clear()
      }
    } else {
      // Fallback to full reload
      this.fullReload()
    }
  }
  
  fullReload() {
    window.location.reload()
  }
  
  isDevelopment() {
    // Check if we're in development mode
    return document.querySelector('meta[name="rails-env"]')?.content === "development"
  }
  
  // Visual indicator methods
  showIndicator() {
    if (this.indicator) return
    
    this.indicator = document.createElement("div")
    this.indicator.className = "swift-ui-live-reload-indicator"
    this.indicator.innerHTML = `
      <div class="indicator-dot"></div>
      <div class="indicator-text">Live</div>
    `
    
    // Add styles
    const style = document.createElement("style")
    style.textContent = `
      .swift-ui-live-reload-indicator {
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: rgba(0, 0, 0, 0.8);
        color: white;
        padding: 8px 12px;
        border-radius: 20px;
        font-size: 12px;
        font-family: system-ui, -apple-system, sans-serif;
        display: flex;
        align-items: center;
        gap: 6px;
        z-index: 9999;
        transition: all 0.3s ease;
      }
      
      .indicator-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #10b981;
        transition: background 0.3s ease;
      }
      
      .indicator-dot.disconnected {
        background: #ef4444;
      }
      
      .indicator-dot.reloading {
        background: #f59e0b;
        animation: pulse 1s ease-in-out infinite;
      }
      
      @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.5; }
      }
      
      .swift-ui-live-reload-indicator:hover {
        background: rgba(0, 0, 0, 0.9);
        cursor: pointer;
      }
    `
    document.head.appendChild(style)
    
    // Add click to toggle
    this.indicator.addEventListener("click", () => {
      this.enabledValue = !this.enabledValue
      this.updateIndicator(this.enabledValue ? "connected" : "disconnected")
      if (!this.enabledValue && this.subscription) {
        this.subscription.unsubscribe()
      } else if (this.enabledValue && !this.subscription) {
        this.setupChannel()
      }
    })
    
    document.body.appendChild(this.indicator)
  }
  
  hideIndicator() {
    this.indicator?.remove()
    this.indicator = null
  }
  
  updateIndicator(status) {
    if (!this.indicator) return
    
    const dot = this.indicator.querySelector(".indicator-dot")
    const text = this.indicator.querySelector(".indicator-text")
    
    dot.className = `indicator-dot ${status}`
    
    switch(status) {
      case "connected":
        text.textContent = "Live"
        break
      case "disconnected":
        text.textContent = "Off"
        break
      case "reloading":
        text.textContent = "Reloading..."
        break
    }
  }
}