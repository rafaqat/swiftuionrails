// test/javascript/playground_controller_test.js
import { Application } from "@hotwired/stimulus"
import PlaygroundController from "../../app/javascript/controllers/playground_controller"

describe("PlaygroundController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="playground"
           data-playground-execute-url-value="/playground/execute">
        <textarea data-playground-target="codeInput">initial code</textarea>
        <div id="playground-preview"></div>
        <div id="playground-errors" class="hidden"></div>
        <div data-playground-target="inspector"></div>
      </div>
    `
    
    application = Application.start()
    application.register("playground", PlaygroundController)
    element = document.querySelector('[data-controller="playground"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#connect", () => {
    it("generates a session ID if not provided", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      
      expect(controller.sessionIdValue).toBeTruthy()
      expect(controller.sessionIdValue).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    })
    
    it("sets up playground alert function", async () => {
      await nextFrame()
      expect(window.playgroundAlert).toBeDefined()
      expect(typeof window.playgroundAlert).toBe("function")
    })
  })
  
  describe("#disconnect", () => {
    it("cleans up playground alert function", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      
      controller.disconnect()
      expect(window.playgroundAlert).toBeUndefined()
    })
  })
  
  describe("#getCode", () => {
    it("returns code from textarea", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const textarea = element.querySelector('[data-playground-target="codeInput"]')
      
      textarea.value = "test code"
      expect(controller.getCode()).toBe("test code")
    })
    
    it("returns code from Monaco editor if available", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      
      window.monacoEditor = {
        getValue: () => "monaco code"
      }
      
      expect(controller.getCode()).toBe("monaco code")
      
      delete window.monacoEditor
    })
  })
  
  describe("#loadSnippet", () => {
    it("loads snippet code into textarea", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const textarea = element.querySelector('[data-playground-target="codeInput"]')
      
      const button = document.createElement("button")
      button.dataset.playgroundSnippetCode = "swift_ui { text('Snippet') }"
      
      const event = new Event("click")
      event.currentTarget = button
      
      controller.loadSnippet(event)
      
      expect(textarea.value).toBe("swift_ui { text('Snippet') }")
    })
    
    it("unescapes newlines in snippet code", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const textarea = element.querySelector('[data-playground-target="codeInput"]')
      
      const button = document.createElement("button")
      button.dataset.playgroundSnippetCode = "line1\\nline2\\nline3"
      
      const event = new Event("click")
      event.currentTarget = button
      
      controller.loadSnippet(event)
      
      expect(textarea.value).toBe("line1\nline2\nline3")
    })
  })
  
  describe("#clearErrors", () => {
    it("hides and clears error container", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const errors = document.getElementById("playground-errors")
      
      errors.classList.remove("hidden")
      errors.innerHTML = "Some error"
      
      controller.clearErrors()
      
      expect(errors.classList.contains("hidden")).toBe(true)
      expect(errors.innerHTML).toBe("")
    })
  })
  
  describe("#showError", () => {
    it("displays error message", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const errors = document.getElementById("playground-errors")
      
      controller.showError(new Error("Test error message"))
      
      expect(errors.classList.contains("hidden")).toBe(false)
      expect(errors.innerHTML).toContain("Test error message")
      expect(errors.innerHTML).toContain("Error")
    })
  })
  
  describe("#setPreviewDevice", () => {
    it("updates preview classes for mobile", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const preview = document.getElementById("playground-preview")
      
      const button = document.createElement("button")
      const event = new Event("click")
      event.currentTarget = button
      event.params = { device: "mobile" }
      
      controller.setPreviewDevice(event)
      
      expect(preview.classList.contains("max-w-sm")).toBe(true)
      expect(preview.classList.contains("mx-auto")).toBe(true)
    })
    
    it("updates preview classes for tablet", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      const preview = document.getElementById("playground-preview")
      
      const button = document.createElement("button")
      const event = new Event("click")
      event.currentTarget = button
      event.params = { device: "tablet" }
      
      controller.setPreviewDevice(event)
      
      expect(preview.classList.contains("max-w-md")).toBe(true)
      expect(preview.classList.contains("mx-auto")).toBe(true)
    })
  })
  
  describe("#handleKeydown", () => {
    it("executes on Cmd+Enter", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      
      // Mock execute method
      controller.execute = jest.fn()
      
      const event = new KeyboardEvent("keydown", {
        key: "Enter",
        metaKey: true
      })
      
      controller.handleKeydown(event)
      
      expect(controller.execute).toHaveBeenCalled()
    })
    
    it("executes on Ctrl+Enter", async () => {
      await nextFrame()
      const controller = application.getControllerForElementAndIdentifier(element, "playground")
      
      // Mock execute method
      controller.execute = jest.fn()
      
      const event = new KeyboardEvent("keydown", {
        key: "Enter",
        ctrlKey: true
      })
      
      controller.handleKeydown(event)
      
      expect(controller.execute).toHaveBeenCalled()
    })
  })
})

// Helper function to wait for next frame
function nextFrame() {
  return new Promise(resolve => requestAnimationFrame(resolve))
}