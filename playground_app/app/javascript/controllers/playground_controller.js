import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "form", "codeInput", "monacoContainer"]
  
  connect() {
    console.log("Playground controller connected")
    
    // Set up debounced update
    this.debouncedUpdate = this.debounce(this.updatePreview.bind(this), 500)
    
    // Wait for Monaco Editor to be ready
    if (window.monacoEditorInstance) {
      console.log("Monaco already initialized")
      this.initializeEditor()
    } else {
      console.log("Waiting for Monaco to initialize")
      window.addEventListener('monaco-editor-ready', (event) => {
        console.log("Monaco editor ready event received")
        this.initializeEditor()
      })
    }
  }
  
  initializeEditor() {
    this.editor = window.monacoEditorInstance
    console.log("Editor initialized:", this.editor)
    
    if (this.editor) {
      // Monaco editor initialized successfully
      // Set up change listener
      this.editor.onDidChangeModelContent(() => {
        // Update hidden form input
        if (this.hasCodeInputTarget) {
          this.codeInputTarget.value = this.editor.getValue()
        }
        // Trigger preview update
        this.debouncedUpdate()
      })
    } else {
      console.error("Monaco editor not available")
      return
    }
    
    // Initial preview
    this.updatePreview()
  }
  
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
  
  runCode(event) {
    event.preventDefault()
    this.updatePreview()
  }
  
  updatePreview() {
    if (!this.editor) {
      console.error("Monaco editor not available")
      return
    }
    
    const code = this.editor.getValue()
    if (this.hasCodeInputTarget) {
      this.codeInputTarget.value = code
    }
    
    // Submit the form via Turbo
    this.formTarget.requestSubmit()
  }
  
  insertComponent(event) {
    console.log("Insert component clicked", event.params.code)
    
    if (!this.editor) {
      console.error("Monaco editor not available")
      return
    }
    
    const code = event.params.code
    const currentCode = this.editor.getValue().trim()
    
    // Check if we're inside a swift_ui block
    const hasSwiftUIWrapper = currentCode.startsWith('swift_ui do')
    
    if (hasSwiftUIWrapper) {
      // Find a good place to insert (before the last 'end')
      const lines = currentCode.split('\n')
      let lastEndLineIndex = -1
      
      // Find last 'end' line (findLastIndex might not be supported in all browsers)
      for (let i = lines.length - 1; i >= 0; i--) {
        if (lines[i].trim() === 'end') {
          lastEndLineIndex = i
          break
        }
      }
      
      if (lastEndLineIndex > 0) {
        lines.splice(lastEndLineIndex, 0, '  ' + code)
        const newCode = lines.join('\n')
        this.editor.setValue(newCode)
      } else {
        // Just append
        const newCode = currentCode + '\n' + code
        this.editor.setValue(newCode)
      }
    } else {
      // Insert at cursor position
      const position = this.editor.getPosition()
      const selection = {
        startLineNumber: position.lineNumber,
        startColumn: position.column,
        endLineNumber: position.lineNumber,
        endColumn: position.column
      }
      
      this.editor.executeEdits('insert', [{
        range: selection,
        text: code,
        forceMoveMarkers: true
      }])
    }
    
    this.editor.focus()
  }
  
  loadExample(event) {
    if (!this.editor) return
    
    const code = event.params.code
    this.editor.setValue(code)
    this.editor.focus()
  }
  
  clearCode() {
    if (!this.editor) return
    
    this.editor.setValue('')
    this.editor.focus()
  }
  
  formatCode() {
    if (!this.editor) return
    
    // Use Monaco's built-in formatting
    this.editor.getAction('editor.action.formatDocument').run()
  }
  
  shareCode() {
    if (!this.editor) return
    
    const code = this.editor.getValue()
    const encoded = btoa(code)
    const url = `${window.location.origin}${window.location.pathname}?code=${encoded}`
    
    navigator.clipboard.writeText(url).then(() => {
      alert('Shareable link copied to clipboard!')
    })
  }
  
  toggleDevice() {
    // Toggle between desktop and mobile view
    this.previewTarget.classList.toggle('max-w-sm')
    this.previewTarget.classList.toggle('mx-auto')
  }
  
  refreshPreview() {
    this.updatePreview()
  }
  
  handleClick(event) {
    console.log('Button clicked in preview!', event)
    alert('Button clicked! This is handled by Stimulus.')
  }
}