import { Application } from "@hotwired/stimulus"
import SwiftUIController from "../../app/javascript/controllers/swift_ui_controller"

describe("SwiftUIController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="swift-ui" 
           data-swift-ui-state-value='{"count": 0, "visible": true}'
           data-swift-ui-component-id-value="test-component">
        <button data-action="click->swift-ui#updateState">Update</button>
      </div>
    `
    
    element = document.querySelector('[data-controller="swift-ui"]')
    
    // Set up Stimulus
    application = Application.start()
    application.register("swift-ui", SwiftUIController)
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("initialization", () => {
    it("initializes with state values", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "swift-ui")
      
      expect(controller.stateValue).toEqual({ count: 0, visible: true })
      expect(controller.componentIdValue).toBe("test-component")
    })
    
    it("creates reactive state proxy", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "swift-ui")
      
      expect(controller.state).toBeDefined()
      expect(controller.state.count).toBe(0)
      expect(controller.state.visible).toBe(true)
    })
  })
  
  describe("state management", () => {
    it("updates state and dispatches event", (done) => {
      const controller = application.getControllerForElementAndIdentifier(element, "swift-ui")
      
      element.addEventListener("swift-ui:stateChange", (event) => {
        expect(event.detail.property).toBe("count")
        expect(event.detail.oldValue).toBe(0)
        expect(event.detail.newValue).toBe(5)
        done()
      })
      
      controller.state.count = 5
    })
    
    it("handles updateState action", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "swift-ui")
      
      const event = new CustomEvent("test", {
        detail: { property: "visible", value: false }
      })
      
      controller.updateState(event)
      
      expect(controller.state.visible).toBe(false)
    })
  })
  
  describe("event handling", () => {
    it("dispatches custom events with correct detail", (done) => {
      const controller = application.getControllerForElementAndIdentifier(element, "swift-ui")
      
      let eventCount = 0
      element.addEventListener("swift-ui:stateChange", (event) => {
        eventCount++
        
        if (eventCount === 1) {
          expect(event.detail.property).toBe("count")
          expect(event.detail.newValue).toBe(10)
        } else if (eventCount === 2) {
          expect(event.detail.property).toBe("visible")
          expect(event.detail.newValue).toBe(false)
          done()
        }
      })
      
      controller.state.count = 10
      controller.state.visible = false
    })
  })
  
  describe("edge cases", () => {
    it("handles missing state value", () => {
      document.body.innerHTML = `
        <div data-controller="swift-ui" 
             data-swift-ui-component-id-value="no-state">
        </div>
      `
      
      const noStateElement = document.querySelector('[data-controller="swift-ui"]')
      const controller = application.getControllerForElementAndIdentifier(noStateElement, "swift-ui")
      
      expect(controller.stateValue).toBeUndefined()
      expect(controller.state).toBeDefined()
    })
    
    it("handles complex state objects", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "swift-ui")
      
      controller.state.nested = { deep: { value: "test" } }
      
      expect(controller.state.nested.deep.value).toBe("test")
    })
  })
})