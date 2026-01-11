import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String }

  trigger(event) {
    event.preventDefault()
    
    // Find the parent component ID
    const componentElement = this.element.closest("[data-swift-ui-component-component-id-value]")
    if (!componentElement) {
      console.error("ServerAction: Could not find parent component")
      return
    }
    
    const componentId = componentElement.dataset.swiftUiComponentComponentIdValue
    const componentClass = componentElement.dataset.swiftUiComponentComponentClassValue
    const componentState = JSON.parse(componentElement.dataset.swiftUiComponentStateValue || "{}")
    
    // Determine arguments based on element type
    let args = []
    
    // Check for fixed params (e.g. the binding key)
    if (this.element.dataset.serverActionParamsValue) {
      try {
        const fixedArgs = JSON.parse(this.element.dataset.serverActionParamsValue)
        if (Array.isArray(fixedArgs)) {
          args.push(...fixedArgs)
        } else {
          args.push(fixedArgs)
        }
      } catch (e) {
        console.error("Invalid server-action-params-value", e)
      }
    }

    if (this.element.tagName === "INPUT") {
      if (this.element.type === "checkbox") {
        args.push(this.element.checked)
      } else if (this.element.type === "radio") {
        if (this.element.checked) args.push(this.element.value)
      } else {
        args.push(this.element.value)
      }
    }
    
    // Perform the request
    fetch("/swift_ui/action", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        component_class: componentClass,
        component_id: componentId,
        method_name: this.nameValue,
        args: args,
        state: componentState
      })
    })
    .then(response => response.text())
    .then(html => {
      // Turbo will handle the stream automatically if we used Turbo.visit or form submission.
      // For fetch, we need to process it manually or use Turbo.renderStreamMessage
      if (window.Turbo) {
        window.Turbo.renderStreamMessage(html)
      }
    })
  }
}
