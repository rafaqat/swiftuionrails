import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monacoContainer", "preview", "form", "codeInput", "searchInput", "themeSelect", "favoritesList", "studioSidebar"]

  connect() {
    console.log("Playground controller connected")
    this.initializeMonaco()
    this.loadFavorites()

    // Store bound reference for cleanup
    this.boundStudioCodeUpdate = (e) => {
      if (this.editor) {
        this.editor.setValue(e.detail.code)
      }
    }

    // Listen for Studio code updates
    window.addEventListener("studio:code-update", this.boundStudioCodeUpdate)

    // Inject X-Ray styles
    this.injectXRayStyles()
  }

  disconnect() {
    // Clean up event listeners to prevent memory leaks
    if (this.boundStudioCodeUpdate) {
      window.removeEventListener("studio:code-update", this.boundStudioCodeUpdate)
    }

    // Dispose Monaco editor if it exists
    if (this.editor) {
      this.editor.dispose()
      this.editor = null
    }
  }
  
  injectXRayStyles() {
    if (document.getElementById("xray-styles")) return
    
    const style = document.createElement("style")
    style.id = "xray-styles"
    style.textContent = `
      .xray-active [data-dsl-node] {
        outline: 1px dashed rgba(59, 130, 246, 0.5) !important;
        position: relative !important;
      }
      .xray-active [data-dsl-node]:hover {
        outline: 2px solid #2563eb !important;
        background-color: rgba(59, 130, 246, 0.05) !important;
      }
      .xray-active [data-dsl-node]:hover::after {
        content: attr(data-dsl-node);
        position: absolute;
        top: 0;
        left: 0;
        background: #2563eb;
        color: white;
        font-size: 10px;
        padding: 2px 4px;
        z-index: 9999;
        pointer-events: none;
        border-radius: 0 0 4px 0;
        font-family: monospace;
      }
    `
    document.head.appendChild(style)
  }

  toggleXRay() {
    this.previewTarget.classList.toggle("xray-active")
  }

  toggleStudio() {
    this.studioSidebarTarget.classList.toggle("hidden")
    // Resize editor if needed
    if (this.editor) {
      setTimeout(() => this.editor.layout(), 300)
    }
  }

  initializeMonaco() {
    const container = this.monacoContainerTarget
    const initialCode = container.dataset.initialCode

    require(['vs/editor/editor.main'], () => {
      this.editor = monaco.editor.create(container, {
        value: initialCode,
        language: 'ruby',
        theme: 'vs-light',
        minimap: { enabled: false },
        fontSize: 14,
        automaticLayout: true,
        scrollBeyondLastLine: false,
        padding: { top: 16, bottom: 16 }
      })

      // Set up auto-preview
      this.editor.onDidChangeModelContent(() => {
        this.debouncedPreview()
        
        // Emit event for Studio sync
        const event = new CustomEvent("monaco:change", { 
          detail: { code: this.editor.getValue() } 
        })
        window.dispatchEvent(event)
      })

      // Initial preview
      this.updatePreview()

      // Setup completion provider
      this.setupCompletionProvider()
    })
  }

  setupCompletionProvider() {
    monaco.languages.registerCompletionItemProvider('ruby', {
      provideCompletionItems: async (model, position) => {
        try {
          const textUntilPosition = model.getValueInRange({
            startLineNumber: 1,
            startColumn: 1,
            endLineNumber: position.lineNumber,
            endColumn: position.column
          });

          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
          if (!csrfToken) {
            console.warn('CSRF token not found, completions disabled')
            return { suggestions: [] }
          }

          const response = await fetch('/playground/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({
              context: textUntilPosition,
              line: position.lineNumber,
              column: position.column
            })
          });

          if (!response.ok) {
            console.warn('Completion request failed:', response.status)
            return { suggestions: [] }
          }

          const data = await response.json();
          return { suggestions: data.completions || [] };
        } catch (error) {
          console.error('Completion error:', error)
          return { suggestions: [] }
        }
      }
    });
  }

  // V2-specific features
  filterComponents(event) {
    const query = event.target.value.toLowerCase() // Fixed typo
    const categories = document.querySelectorAll('[data-category-name]')
    
    categories.forEach(category => {
      let hasVisibleItems = false
      const items = category.querySelectorAll('[data-component-name]')
      
      items.forEach(item => {
        const name = item.dataset.componentName
        if (name.includes(query)) {
          item.style.display = 'block'
          hasVisibleItems = true
        } else {
          item.style.display = 'none'
        }
      })
      
      category.style.display = hasVisibleItems ? 'block' : 'none'
    })
  }

  changeTheme(event) {
    const theme = event.target.value
    if (this.editor) {
      monaco.editor.setTheme(theme)
    }
  }

  switchDevice(event) {
    const device = event.params.device
    const preview = this.previewTarget
    
    // Reset classes
    preview.style.maxWidth = '100%'
    preview.style.border = 'none'
    preview.style.borderRadius = '0'
    
    if (device === 'mobile') {
      preview.style.maxWidth = '375px'
      preview.style.border = '1px solid #e5e7eb'
      preview.style.borderRadius = '2rem'
    } else if (device === 'tablet') {
      preview.style.maxWidth = '768px'
      preview.style.border = '1px solid #e5e7eb'
      preview.style.borderRadius = '1rem'
    }
    
    // Animate change
    preview.animate([
      { opacity: 0.5 },
      { opacity: 1 }
    ], {
      duration: 300,
      easing: 'ease-out'
    })
  }

  exportCode() {
    if (!this.editor) return
    
    const code = this.editor.getValue()
    const blob = new Blob([code], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    
    const a = document.createElement('a')
    a.href = url
    a.download = 'playground_export.rb'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  saveFavorite() {
    if (!this.editor) return

    const code = this.editor.getValue()
    const name = prompt('Name this snippet:')
    
    if (name) {
      const favorites = JSON.parse(localStorage.getItem('playground-favorites') || '[]')
      favorites.push({
        id: Date.now(),
        code: code,
        name: name,
        timestamp: Date.now()
      })
      localStorage.setItem('playground-favorites', JSON.stringify(favorites))
      this.loadFavorites()
    }
  }

  loadFavorites() {
    if (!this.hasFavoritesListTarget) return

    let favorites = []
    try {
      favorites = JSON.parse(localStorage.getItem('playground-favorites') || '[]')
      if (!Array.isArray(favorites)) favorites = []
    } catch (e) {
      console.warn('Failed to parse favorites:', e)
      favorites = []
    }

    const container = this.favoritesListTarget
    container.innerHTML = ''

    if (favorites.length === 0) {
      const emptyDiv = document.createElement('div')
      emptyDiv.className = 'text-xs text-gray-500 italic'
      emptyDiv.textContent = 'No favorites yet'
      container.appendChild(emptyDiv)
      return
    }

    favorites.forEach(fav => {
      // Validate fav object has required properties
      if (!fav || typeof fav.name !== 'string' || typeof fav.code !== 'string') return

      const div = document.createElement('div')
      div.className = 'flex justify-between items-center group py-1'

      // Create load button using DOM instead of innerHTML
      const loadBtn = document.createElement('button')
      loadBtn.className = 'text-sm text-gray-700 hover:text-blue-600 text-left truncate flex-1'
      loadBtn.textContent = fav.name
      loadBtn.dataset.action = 'click->playground#loadExample'
      loadBtn.dataset.playgroundCodeParam = fav.code

      // Create delete button using DOM instead of innerHTML with onclick
      const deleteBtn = document.createElement('button')
      deleteBtn.className = 'text-xs text-red-500 opacity-0 group-hover:opacity-100 px-2'
      deleteBtn.textContent = '×'
      deleteBtn.dataset.favId = fav.id
      deleteBtn.addEventListener('click', () => {
        div.remove()
        try {
          const storedFavs = JSON.parse(localStorage.getItem('playground-favorites') || '[]')
          const newFavs = storedFavs.filter(f => f.id !== fav.id)
          localStorage.setItem('playground-favorites', JSON.stringify(newFavs))
        } catch (e) {
          console.warn('Failed to update favorites:', e)
        }
      })

      div.appendChild(loadBtn)
      div.appendChild(deleteBtn)
      container.appendChild(div)
    })
  }

  // Standard Actions
  updatePreview() {
    if (!this.editor) return
    
    const code = this.editor.getValue()
    this.codeInputTarget.value = code
    this.formTarget.requestSubmit()
  }

  runCode() {
    this.updatePreview()
  }

  insertComponent(event) {
    if (!this.editor) return
    
    const code = event.params.code
    const position = this.editor.getPosition()

    this.editor.executeEdits('insert', [{
      range: {
        startLineNumber: position.lineNumber,
        startColumn: position.column,
        endLineNumber: position.lineNumber,
        endColumn: position.column
      },
      text: code
    }])
    
    this.editor.focus()
  }

  loadExample(event) {
    if (!this.editor) return
    
    const code = event.params.code
    this.editor.setValue(code)
  }

  formatCode() {
    if (this.editor) {
      this.editor.getAction('editor.action.formatDocument').run()
    }
  }

  clearCode() {
    if (this.editor) {
      this.editor.setValue('')
    }
  }

  shareCode() {
    if (!this.editor) return

    const code = this.editor.getValue()
    // Use encodeURIComponent for Unicode-safe base64 encoding
    const encoded = btoa(unescape(encodeURIComponent(code)))
    const url = `${window.location.origin}/playground?code=${encoded}`

    navigator.clipboard.writeText(url).then(() => {
      alert('Playground link copied to clipboard!')
    })
  }

  // Utilities
  debouncedPreview = this.debounce(() => {
    this.updatePreview()
  }, 1000) // 1 second delay

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
  
  escapeHtml(unsafe) {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
}