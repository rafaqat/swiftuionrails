import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { submitMethod: String }

  submit(event) {
    event.preventDefault()
    
    if (!this.submitMethodValue) {
      console.warn("ReactiveForm: onSubmit method not specified.")
      return
    }
    
    // Aggregate all input values within the form
    const formData = new FormData(this.element)
    const formValues = {}
    for (let [key, value] of formData.entries()) {
      formValues[key] = value
    }

    // Find the parent component ID
    const componentElement = this.element.closest("[data-swift-ui-component-component-id-value]")
    if (!componentElement) {
      console.error("ReactiveForm: Could not find parent component")
      return
    }
    
    const componentId = componentElement.dataset.swiftUiComponentComponentIdValue
    const componentClass = componentElement.dataset.swiftUiComponentComponentClassValue
    const componentState = JSON.parse(componentElement.dataset.swiftUiComponentStateValue || "{}")

    // Send the aggregated form values as an argument to the submit method
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
        method_name: this.submitMethodValue,
        args: [formValues], // Send the whole form data as one argument
        state: componentState
      })
    })
    .then(response => response.text())
    .then(html => {
      if (window.Turbo) {
        window.Turbo.renderStreamMessage(html)
      }
    })
    .catch(error => {
      console.error("ReactiveForm: Submission error", error)
    })
  }
}
