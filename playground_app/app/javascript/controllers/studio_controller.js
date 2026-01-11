import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["emptyState", "controls", "componentName", "propsContainer", "previewSection", "previewContainer"]

  connect() {
    console.log("Studio controller connected")

    // Store bound reference for cleanup
    this.boundDebouncedSync = this.debouncedSync.bind(this)

    // Listen for Monaco editor changes (Code -> UI)
    window.addEventListener("monaco:change", this.boundDebouncedSync)

    this.isUpdatingFromStudio = false
  }

  disconnect() {
    // Clean up event listeners to prevent memory leaks
    if (this.boundDebouncedSync) {
      window.removeEventListener("monaco:change", this.boundDebouncedSync)
    }
  }

  async loadComponent(componentName) {
    this.componentName = componentName // Store for sync
    this.emptyStateTarget.classList.add("hidden")
    this.controlsTarget.classList.remove("hidden")
    this.componentNameTarget.textContent = componentName
    this.propsContainerTarget.innerHTML = '<div class="animate-pulse flex space-x-4"><div class="flex-1 space-y-4 py-1"><div class="h-4 bg-gray-200 rounded w-3/4"></div><div class="space-y-2"><div class="h-4 bg-gray-200 rounded"></div><div class="h-4 bg-gray-200 rounded w-5/6"></div></div></div></div>'
    this.previewSectionTarget.classList.add("hidden")

    try {
      const response = await fetch(`/playground/component_schema?component=${encodeURIComponent(componentName)}`)
      if (!response.ok) throw new Error("Failed to load schema")

      const schema = await response.json()
      this.renderControls(schema)

      // Render Preview if available - sanitize HTML to prevent XSS
      if (schema.preview_html && schema.preview_html !== "No preview defined") {
        this.previewSectionTarget.classList.remove("hidden")
        // Use textContent for plain text or sanitize HTML
        // Since preview_html comes from trusted server-side rendering, we trust it
        // but add a basic sanitization layer
        this.previewContainerTarget.innerHTML = this.sanitizeHtml(schema.preview_html)
      }

    } catch (error) {
      console.error(error)
      this.propsContainerTarget.innerHTML = `<div class="text-red-500 text-sm">Error loading component schema</div>`
    }
  }

  // Basic HTML sanitizer - removes script tags and event handlers
  sanitizeHtml(html) {
    const template = document.createElement('template')
    template.innerHTML = html
    const content = template.content

    // Remove script tags
    content.querySelectorAll('script').forEach(el => el.remove())

    // Remove event handlers from all elements
    content.querySelectorAll('*').forEach(el => {
      Array.from(el.attributes).forEach(attr => {
        if (attr.name.startsWith('on')) {
          el.removeAttribute(attr.name)
        }
      })
    })

    return template.innerHTML
  }

  renderControls(schema) {
    this.propsContainerTarget.innerHTML = ""
    this.currentSchema = schema

    schema.props.forEach(prop => {
      const control = this.createControl(prop)
      this.propsContainerTarget.appendChild(control)
    })
  }

  createControl(prop) {
    const wrapper = document.createElement("div")
    wrapper.className = "flex flex-col gap-1"

    const label = document.createElement("label")
    label.className = "text-sm font-medium text-gray-700"
    label.textContent = prop.name
    if (prop.required) {
      // Use DOM manipulation instead of innerHTML to prevent XSS
      const asterisk = document.createElement("span")
      asterisk.className = "text-red-500"
      asterisk.textContent = " *"
      label.appendChild(asterisk)
    }

    let input
    
    // Determine input type based on prop type
    if (prop.type === "Boolean" || prop.type === "TrueClass" || prop.type === "FalseClass") {
      input = document.createElement("input")
      input.type = "checkbox"
      input.className = "h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
      input.checked = prop.default === true
    } else if (prop.type === "Integer" || prop.type === "Float") {
      input = document.createElement("input")
      input.type = "number"
      input.className = "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
      input.value = prop.default || ""
    } else if (prop.type === "Symbol") {
      // For symbols, we ideally want a select if we knew the options, but text input for now
      input = document.createElement("input")
      input.type = "text"
      input.className = "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm font-mono text-xs"
      input.placeholder = ":symbol"
      input.value = prop.default ? prop.default.replace(/^:/, '') : ""
    } else {
      // Default to text
      input = document.createElement("input")
      input.type = "text"
      input.className = "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
      input.value = prop.default || ""
    }

    // Add event listener to update code
    input.dataset.propName = prop.name
    input.dataset.propType = prop.type
    input.addEventListener("input", () => this.updateCode())
    input.addEventListener("change", () => this.updateCode())

    wrapper.appendChild(label)
    wrapper.appendChild(input)
    return wrapper
  }

  // Code -> UI Sync
  async syncFromEditor(event) {
    if (this.isUpdatingFromStudio) {
      this.isUpdatingFromStudio = false
      return
    }

    if (!this.componentName || this.controlsTarget.classList.contains("hidden")) return

    const code = event.detail.code
    
    try {
      const response = await fetch("/playground/parse_component", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          code: code,
          component_name: this.componentName
        })
      })
      
      if (!response.ok) return
      
      const data = await response.json()
      this.updateControls(data.props)
    } catch (error) {
      console.error("Sync error:", error)
    }
  }

  updateControls(props) {
    const inputs = this.propsContainerTarget.querySelectorAll("input, select, textarea")
    
    inputs.forEach(input => {
      const name = input.dataset.propName
      const value = props[name]
      
      if (value === undefined) return
      
      if (input.type === "checkbox") {
        input.checked = value === true
      } else {
        input.value = value
      }
    })
  }

  debouncedSync = this.debounce((e) => this.syncFromEditor(e), 1000)

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  updateCode() {
    this.isUpdatingFromStudio = true
    
    // Generate the Ruby code for the component
    const inputs = this.propsContainerTarget.querySelectorAll("input, select, textarea")
    const props = []

    inputs.forEach(input => {
      const name = input.dataset.propName
      const type = input.dataset.propType
      let value = input.type === "checkbox" ? input.checked : input.value

      // Skip empty optional values
      if (value === "" && !input.required) return

      // Format value based on type
      let formattedValue
      if (type === "String") {
        formattedValue = `"${value}"`
      } else if (type === "Symbol") {
        formattedValue = `:${value.replace(/^:/, '')}`
      } else if (type === "Boolean" || type === "TrueClass" || type === "FalseClass") {
        formattedValue = value ? "true" : "false"
      } else {
        formattedValue = value
      }

      props.push(`${name}: ${formattedValue}`)
    })

    const componentName = this.componentNameTarget.textContent
    const propsString = props.length > 0 ? `(
  ${props.join(",\n  ")}
)` : ""
    
    const code = `swift_ui do\n  render ${componentName}.new${propsString}\nend`

    // Emit event to main controller to update editor
    const event = new CustomEvent("studio:code-update", { detail: { code } })
    window.dispatchEvent(event)
  }
}