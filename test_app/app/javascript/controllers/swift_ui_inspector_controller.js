import { Controller } from "@hotwired/stimulus"

// Development mode component inspector
export default class extends Controller {
  static targets = ["panel", "content", "toggle"]
  static values = { 
    open: { type: Boolean, default: false },
    enabled: { type: Boolean, default: true }
  }
  
  connect() {
    if (!this.isDevelopment() || !this.enabledValue) return
    
    this.setupInspector()
    this.attachComponentListeners()
    this.addKeyboardShortcuts()
  }
  
  setupInspector() {
    // Create inspector panel if it doesn't exist
    if (!document.getElementById("swift-ui-inspector")) {
      this.createInspectorPanel()
    }
  }
  
  createInspectorPanel() {
    const panel = document.createElement("div")
    panel.id = "swift-ui-inspector"
    panel.innerHTML = `
      <div class="inspector-header">
        <h3>SwiftUI Component Inspector</h3>
        <button class="inspector-close" data-action="click->swift-ui-inspector#toggle">×</button>
      </div>
      <div class="inspector-content" data-swift-ui-inspector-target="content">
        <p class="inspector-hint">Click on any component to inspect it</p>
      </div>
    `
    
    // Add styles
    const style = document.createElement("style")
    style.textContent = `
      #swift-ui-inspector {
        position: fixed;
        right: -400px;
        top: 0;
        width: 400px;
        height: 100vh;
        background: white;
        box-shadow: -2px 0 10px rgba(0, 0, 0, 0.1);
        z-index: 9998;
        transition: right 0.3s ease;
        font-family: system-ui, -apple-system, sans-serif;
        overflow-y: auto;
      }
      
      #swift-ui-inspector.open {
        right: 0;
      }
      
      .inspector-header {
        position: sticky;
        top: 0;
        background: #1f2937;
        color: white;
        padding: 16px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        z-index: 1;
      }
      
      .inspector-header h3 {
        margin: 0;
        font-size: 16px;
        font-weight: 600;
      }
      
      .inspector-close {
        background: none;
        border: none;
        color: white;
        font-size: 24px;
        cursor: pointer;
        padding: 0;
        width: 32px;
        height: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 4px;
        transition: background 0.2s;
      }
      
      .inspector-close:hover {
        background: rgba(255, 255, 255, 0.1);
      }
      
      .inspector-content {
        padding: 16px;
      }
      
      .inspector-hint {
        color: #6b7280;
        text-align: center;
        padding: 32px 16px;
        margin: 0;
      }
      
      .inspector-section {
        margin-bottom: 24px;
      }
      
      .inspector-section h4 {
        font-size: 14px;
        font-weight: 600;
        margin: 0 0 8px 0;
        color: #374151;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }
      
      .inspector-props {
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        border-radius: 6px;
        padding: 12px;
      }
      
      .inspector-prop {
        display: flex;
        align-items: start;
        margin-bottom: 8px;
        font-size: 13px;
      }
      
      .inspector-prop:last-child {
        margin-bottom: 0;
      }
      
      .inspector-prop-name {
        font-weight: 600;
        color: #6b7280;
        min-width: 100px;
        margin-right: 8px;
      }
      
      .inspector-prop-value {
        color: #111827;
        word-break: break-word;
        flex: 1;
      }
      
      .inspector-prop-value.string {
        color: #059669;
      }
      
      .inspector-prop-value.number {
        color: #3b82f6;
      }
      
      .inspector-prop-value.boolean {
        color: #8b5cf6;
      }
      
      .inspector-code {
        background: #1f2937;
        color: #d1d5db;
        padding: 12px;
        border-radius: 6px;
        font-family: 'SF Mono', Monaco, monospace;
        font-size: 12px;
        overflow-x: auto;
        white-space: pre;
      }
      
      .component-highlight {
        outline: 2px solid #3b82f6 !important;
        outline-offset: 2px !important;
        position: relative !important;
      }
      
      .component-highlight::after {
        content: attr(data-component-name);
        position: absolute;
        top: -24px;
        left: 0;
        background: #3b82f6;
        color: white;
        padding: 2px 8px;
        font-size: 11px;
        border-radius: 4px;
        font-family: system-ui, -apple-system, sans-serif;
        z-index: 9999;
        pointer-events: none;
      }
    `
    document.head.appendChild(style)
    document.body.appendChild(panel)
    
    this.panel = panel
    this.contentTarget = panel.querySelector('[data-swift-ui-inspector-target="content"]')
  }
  
  attachComponentListeners() {
    document.addEventListener("click", this.handleComponentClick.bind(this), true)
    document.addEventListener("mouseover", this.handleComponentHover.bind(this), true)
    document.addEventListener("mouseout", this.handleComponentOut.bind(this), true)
  }
  
  handleComponentClick(event) {
    if (!this.enabledValue) return
    
    // Don't inspect the inspector itself
    if (event.target.closest("#swift-ui-inspector")) return
    
    // Find the nearest component
    const component = this.findNearestComponent(event.target)
    if (component) {
      event.preventDefault()
      event.stopPropagation()
      this.inspectComponent(component)
    }
  }
  
  handleComponentHover(event) {
    if (!this.enabledValue || !event.metaKey) return // Only on Cmd/Ctrl hover
    
    const component = this.findNearestComponent(event.target)
    if (component && !component.classList.contains("component-highlight")) {
      component.classList.add("component-highlight")
    }
  }
  
  handleComponentOut(event) {
    const component = this.findNearestComponent(event.target)
    if (component) {
      component.classList.remove("component-highlight")
    }
  }
  
  findNearestComponent(element) {
    // Look for ViewComponent rendered elements
    return element.closest('[data-swift-component]') || 
           element.closest('[data-component]') ||
           element.closest('[class*="component"]')
  }
  
  inspectComponent(component) {
    this.openValue = true
    this.updatePanel()
    
    const componentData = this.extractComponentData(component)
    this.renderInspectorContent(componentData)
  }
  
  extractComponentData(component) {
    const data = {
      name: component.dataset.swiftComponent || 
            component.dataset.component || 
            component.className.match(/(\w+)component/i)?.[1] || 
            "Unknown Component",
      element: component,
      props: {},
      state: {},
      dsl: "",
      html: component.outerHTML
    }
    
    // Extract props from data attributes
    Object.keys(component.dataset).forEach(key => {
      if (key.startsWith("prop")) {
        const propName = key.replace("prop", "").toLowerCase()
        data.props[propName] = component.dataset[key]
      }
    })
    
    // Extract state if available
    const controller = this.getStimulusController(component)
    if (controller) {
      data.state = controller.state || {}
    }
    
    // Try to extract DSL from comments or data
    const dslComment = Array.from(component.childNodes)
      .find(node => node.nodeType === 8 && node.textContent.includes("DSL:"))
    
    if (dslComment) {
      data.dsl = dslComment.textContent.replace("DSL:", "").trim()
    }
    
    return data
  }
  
  getStimulusController(element) {
    if (!window.Stimulus) return null
    
    const application = window.Stimulus
    const controllerAttribute = element.getAttribute("data-controller")
    if (!controllerAttribute) return null
    
    const controllerName = controllerAttribute.split(" ")[0]
    return application.getControllerForElementAndIdentifier(element, controllerName)
  }
  
  renderInspectorContent(data) {
    this.contentTarget.innerHTML = `
      <div class="inspector-section">
        <h4>Component</h4>
        <div class="inspector-props">
          <div class="inspector-prop">
            <span class="inspector-prop-name">Name:</span>
            <span class="inspector-prop-value">${data.name}</span>
          </div>
        </div>
      </div>
      
      ${Object.keys(data.props).length > 0 ? `
        <div class="inspector-section">
          <h4>Props</h4>
          <div class="inspector-props">
            ${Object.entries(data.props).map(([key, value]) => `
              <div class="inspector-prop">
                <span class="inspector-prop-name">${key}:</span>
                <span class="inspector-prop-value ${typeof value}">${value}</span>
              </div>
            `).join("")}
          </div>
        </div>
      ` : ""}
      
      ${Object.keys(data.state).length > 0 ? `
        <div class="inspector-section">
          <h4>State</h4>
          <div class="inspector-props">
            ${Object.entries(data.state).map(([key, value]) => `
              <div class="inspector-prop">
                <span class="inspector-prop-name">${key}:</span>
                <span class="inspector-prop-value ${typeof value}">${JSON.stringify(value)}</span>
              </div>
            `).join("")}
          </div>
        </div>
      ` : ""}
      
      ${data.dsl ? `
        <div class="inspector-section">
          <h4>DSL</h4>
          <div class="inspector-code">${data.dsl}</div>
        </div>
      ` : ""}
      
      <div class="inspector-section">
        <h4>HTML</h4>
        <div class="inspector-code">${this.formatHtml(data.html)}</div>
      </div>
    `
  }
  
  formatHtml(html) {
    // Basic HTML formatting for readability
    return html
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/(&lt;\/?\w+)/g, '<span style="color: #60a5fa;">$1</span>')
      .replace(/(\s\w+)=/g, '<span style="color: #fbbf24;">$1</span>=')
      .replace(/="([^"]*)"/g, '="<span style="color: #34d399;">$1</span>"')
  }
  
  addKeyboardShortcuts() {
    document.addEventListener("keydown", (event) => {
      // Cmd/Ctrl + Shift + I to toggle inspector
      if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === "I") {
        event.preventDefault()
        this.toggle()
      }
      
      // Escape to close
      if (event.key === "Escape" && this.openValue) {
        this.openValue = false
        this.updatePanel()
      }
    })
  }
  
  toggle() {
    this.openValue = !this.openValue
    this.updatePanel()
  }
  
  updatePanel() {
    if (this.panel) {
      this.panel.classList.toggle("open", this.openValue)
    }
  }
  
  isDevelopment() {
    return document.querySelector('meta[name="rails-env"]')?.content === "development"
  }
}