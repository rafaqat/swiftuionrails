import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor", "codeInput", "previewContainer", "inspector"]
  static values = { 
    executeUrl: String,
    sessionId: String
  }
  
  connect() {
    console.log("🎮 Playground controller connected")
    
    // Generate session ID if not provided
    if (!this.hasSessionIdValue) {
      this.sessionIdValue = crypto.randomUUID()
    }
    
    this.setupEventListeners()
    
    // Initialize with a demo alert function for the playground
    window.playgroundAlert = (message) => {
      alert(message || "Hello from SwiftUI Rails Playground!")
    }
  }
  
  disconnect() {
    // Clean up
    delete window.playgroundAlert
  }
  
  setupEventListeners() {
    // Handle Cmd+Enter for execution
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }
  
  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      event.preventDefault()
      this.execute()
    }
  }
  
  async execute() {
    console.log("🚀 Executing playground code")
    
    const code = this.getCode()
    if (!code) {
      console.warn("No code to execute")
      return
    }
    
    // Clear previous errors
    this.clearErrors()
    
    // Show loading state
    this.showLoading()
    
    try {
      const response = await fetch(this.executeUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: JSON.stringify({
          code: code,
          session_id: this.sessionIdValue
        })
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      // Turbo will handle the stream response automatically
      const turboStream = await response.text()
      Turbo.renderStreamMessage(turboStream)
      
    } catch (error) {
      console.error("Playground execution error:", error)
      this.showError(error)
    } finally {
      this.hideLoading()
    }
  }
  
  getCode() {
    // Try to get code from Monaco editor first
    if (window.monacoEditor && window.monacoEditor.getValue) {
      return window.monacoEditor.getValue()
    }
    
    // Fallback to textarea
    if (this.hasCodeInputTarget) {
      return this.codeInputTarget.value
    }
    
    return null
  }
  
  loadSnippet(event) {
    // Try multiple ways to get the code
    let code = event.params?.code || 
               event.currentTarget.dataset.playgroundSnippetCode ||
               event.target.closest('button')?.dataset.playgroundSnippetCode
    
    if (code) {
      // Decode HTML entities
      const textarea = document.createElement('textarea')
      textarea.innerHTML = code
      code = textarea.value
      
      // Unescape newlines
      code = code.replace(/\\n/g, '\n')
      
      console.log("Loading snippet with code:", code)
      
      // Update Monaco editor
      if (window.monacoEditor && window.monacoEditor.setValue) {
        window.monacoEditor.setValue(code)
      }
      
      // Update textarea fallback
      if (this.hasCodeInputTarget) {
        this.codeInputTarget.value = code
      }
      
      // Auto-execute after loading snippet
      setTimeout(() => this.execute(), 100)
    }
  }
  
  setPreviewDevice(event) {
    const device = event.params.device
    const preview = document.getElementById('playground-preview')
    
    if (!preview) return
    
    // Remove existing device classes
    preview.classList.remove('max-w-sm', 'max-w-md', 'max-w-4xl', 'mx-auto')
    
    // Apply new device class
    switch (device) {
      case 'mobile':
        preview.classList.add('max-w-sm', 'mx-auto')
        break
      case 'tablet':
        preview.classList.add('max-w-md', 'mx-auto')
        break
      case 'desktop':
        preview.classList.add('max-w-4xl')
        break
    }
    
    // Update button states
    event.target.parentElement.querySelectorAll('button').forEach(btn => {
      btn.classList.remove('bg-white', 'shadow-sm')
      btn.classList.add('hover:bg-gray-100')
    })
    event.target.classList.remove('hover:bg-gray-100')
    event.target.classList.add('bg-white', 'shadow-sm')
  }
  
  share() {
    // TODO: Implement sharing functionality
    alert("Sharing functionality coming soon!")
  }
  
  export() {
    // TODO: Implement export functionality
    alert("Export functionality coming soon!")
  }
  
  clearErrors() {
    const errorsContainer = document.getElementById('playground-errors')
    if (errorsContainer) {
      errorsContainer.classList.add('hidden')
      errorsContainer.innerHTML = ''
    }
  }
  
  showError(error) {
    const errorsContainer = document.getElementById('playground-errors')
    if (errorsContainer) {
      errorsContainer.classList.remove('hidden')
      errorsContainer.innerHTML = `
        <div class="flex items-start gap-3">
          <svg class="w-5 h-5 text-red-600 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <div class="flex-1">
            <h3 class="text-sm font-medium text-red-800">Error</h3>
            <p class="mt-1 text-sm text-red-700">${error.message}</p>
          </div>
        </div>
      `
    }
  }
  
  showLoading() {
    const preview = document.getElementById('playground-preview')
    if (preview) {
      preview.style.opacity = '0.5'
      preview.style.transition = 'opacity 0.2s'
    }
  }
  
  hideLoading() {
    const preview = document.getElementById('playground-preview')
    if (preview) {
      preview.style.opacity = '1'
    }
  }
  
  // Handler for demo button clicks
  showAlert(message) {
    alert(message || "Hello from SwiftUI Rails!")
  }
}