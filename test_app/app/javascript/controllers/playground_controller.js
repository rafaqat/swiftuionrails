import { Controller } from "@hotwired/stimulus"
import playgroundDataManager from 'playground_data_manager'

export default class extends Controller {
  static targets = [
    "monacoContainer", "preview", "form", "codeInput", "codeEditor",
    "searchInput", "themeSelect", "componentsContainer", "examplesContainer",
    "favoritesContainer", "favoritesList"
  ]

  connect() {
    console.log("Playground controller connected - DSL Powered! 🚀")
    // Initialize the global playground data manager
    window.playgroundDataManager = playgroundDataManager
    // Preload completion data
    playgroundDataManager.preloadAll()
    
    this.initializeMonaco()
    this.loadFavorites()
  }

  initializeMonaco() {
    const container = this.monacoContainerTarget
    const initialCode = container.dataset.initialCode || ""
    const loadingIndicator = document.getElementById('editor-loading')

    require(['vs/editor/editor.main'], () => {
      console.log("Monaco loaded")
      
      // Define Solarized Light theme
      monaco.editor.defineTheme('solarized-light', {
        base: 'vs',
        inherit: true,
        rules: [
          { token: 'comment', foreground: '93a1a1', fontStyle: 'italic' },
          { token: 'keyword', foreground: '859900' },
          { token: 'string', foreground: '2aa198' },
          { token: 'number', foreground: '2aa198' },
          { token: 'regexp', foreground: 'dc322f' },
          { token: 'type', foreground: 'b58900' },
          { token: 'class', foreground: 'b58900' },
          { token: 'function', foreground: '268bd2' },
          { token: 'variable', foreground: '268bd2' },
          { token: 'constant', foreground: 'cb4b16' },
          { token: 'symbol', foreground: '6c71c4' },
          { token: 'operator', foreground: '859900' }
        ],
        colors: {
          'editor.background': '#fdf6e3',
          'editor.foreground': '#586e75',
          'editor.lineHighlightBackground': '#eee8d5',
          'editorLineNumber.foreground': '#93a1a1',
          'editorCursor.foreground': '#586e75',
          'editor.selectionBackground': '#eee8d5',
          'editor.inactiveSelectionBackground': '#eee8d5'
        }
      })

      this.editor = monaco.editor.create(container, {
        value: initialCode,
        language: 'ruby',
        theme: 'solarized-light',
        fontSize: 14,
        fontFamily: 'Menlo, Monaco, "Courier New", monospace',
        lineNumbers: 'on',  // Explicitly enable line numbers
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        renderWhitespace: 'selection',
        tabSize: 2,
        insertSpaces: true,
        automaticLayout: true,
        padding: { top: 16, bottom: 16 },
        suggestOnTriggerCharacters: true,
        quickSuggestions: {
          other: true,
          comments: false,
          strings: false
        },
        quickSuggestionsDelay: 200
      })

      // Create smooth transition when Monaco loads
      setTimeout(() => {
        // Add fade-out animation to loading indicator
        loadingIndicator.style.opacity = '0'
        loadingIndicator.style.transform = 'scale(0.9)'
        
        // Show editor with fade-in animation
        container.style.display = 'block'
        container.style.opacity = '0'
        container.style.transform = 'scale(1.05)'
        
        // Animate editor in
        setTimeout(() => {
          container.style.opacity = '1'
          container.style.transform = 'scale(1)'
        }, 100)
        
        // Remove loading indicator after transition
        setTimeout(() => {
          loadingIndicator.style.display = 'none'
        }, 300)
      }, 800) // Small delay to show the loading animation

      // Set up auto-preview
      this.editor.onDidChangeModelContent(() => {
        this.debouncedPreview()
      })

      // Hook up existing completion/signature providers from V1
      this.setupLanguageFeatures()

      // Sync to hidden textarea
      this.editor.onDidChangeModelContent(() => {
        if (this.hasCodeEditorTarget) {
          this.codeEditorTarget.value = this.editor.getValue()
        }
      })

      // Dispatch ready event
      window.dispatchEvent(new CustomEvent('monaco-editor-ready', { 
        detail: { editor: this.editor } 
      }))
    })
  }

  setupLanguageFeatures() {
    // Copy the completion and signature provider setup from V1
    // This reuses all the existing infrastructure
    
    // Completion provider
    let completionAbortController = null
    let completionCache = new Map()
    let lastCompletionRequest = 0
    
    monaco.languages.registerCompletionItemProvider('ruby', {
      triggerCharacters: ['.', '('],
      provideCompletionItems: async function(model, position, context, token) {
        console.log("Completion triggered", { position, context })
        
        // Abort any in-flight request
        if (completionAbortController) {
          completionAbortController.abort()
        }
        
        // Rate limiting
        const now = Date.now()
        if (now - lastCompletionRequest < 50) {
          return { suggestions: [] }
        }
        lastCompletionRequest = now
        
        // Get context
        const lineNumber = position.lineNumber
        const column = position.column
        const textUntilPosition = model.getValueInRange({
          startLineNumber: 1,
          startColumn: 1,
          endLineNumber: lineNumber,
          endColumn: column
        })
        
        // Simple caching based on context
        const cacheKey = `${textUntilPosition}:${lineNumber}:${column}`
        if (completionCache.has(cacheKey)) {
          console.log("Returning cached completions")
          return completionCache.get(cacheKey)
        }
        
        // Extract the relevant context (last few lines)
        const lines = textUntilPosition.split('\n')
        const contextLines = lines.slice(Math.max(0, lines.length - 5))
        const textContent = contextLines.join('\n')
        
        // Get word at position for proper range calculation
        const wordInfo = model.getWordUntilPosition(position)
        const range = {
          startLineNumber: position.lineNumber,
          startColumn: wordInfo.startColumn,
          endLineNumber: position.lineNumber,
          endColumn: wordInfo.endColumn
        }
        
        const positionData = {
          lineNumber: position.lineNumber,
          column: position.column
        }
        
        // Create new abort controller
        completionAbortController = new AbortController()
        
        try {
          // Prepare cached data to send based on context
          const cachedData = {}
          
          // Only send specific data that might be needed for the current completion
          const dataManager = window.playgroundDataManager
          if (dataManager) {
            // Determine what data might be needed based on context
            const needsColors = context.triggerCharacter === '(' || 
                              textContent.match(/\.(bg|text_color|border_color|hover_bg|hover_text_color)\s*\(?$/)
            const needsSpacing = textContent.match(/\.(p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|spacing|gap)\s*\(?$/)
            const needsFontSize = textContent.match(/\.font_size\s*\(?$/)
            
            if (needsColors) {
              cachedData.tailwind_colors = dataManager.getCachedData('tailwind_colors')
            }
            if (needsSpacing) {
              cachedData.spacing_values = dataManager.getCachedData('spacing_values')
            }
            if (needsFontSize) {
              cachedData.font_sizes = dataManager.getCachedData('font_sizes')
            }
          }
          
          // Get CSRF token from meta tag
          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
          
          // Fetch completions from Rails backend
          const response = await fetch('/playground/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({
              context: textContent,
              position: positionData,
              cached_data: cachedData
            }),
            signal: completionAbortController.signal
          })
          
          if (!response.ok) {
            console.error('Failed to fetch completions:', response.status)
            return { suggestions: [] }
          }
          
          const data = await response.json()
          console.log("Received completions:", data.suggestions.length, "items")
          
          // Transform Rails completions to Monaco format
          const suggestions = data.suggestions.map(item => {
            try {
              return {
                label: item.label,
                kind: this.getCompletionItemKind(item.kind),
                detail: item.detail,
                documentation: item.documentation,
                insertText: item.insertText,
                insertTextRules: item.insertTextFormat === 2 ? monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet : undefined,
                range: range
              }
            } catch (e) {
              console.error('Error mapping completion item:', e, item)
              return {
                label: item.label,
                kind: monaco.languages.CompletionItemKind.Property,
                insertText: item.label
              }
            }
          })
          
          const result = { suggestions }
          
          // Cache the result
          completionCache.set(cacheKey, result)
          
          // Clear cache after 5 seconds
          setTimeout(() => {
            completionCache.delete(cacheKey)
          }, 5000)
          
          return result
        } catch (error) {
          if (error.name === 'AbortError') {
            console.log('Completion request aborted')
          } else {
            console.error('Error fetching completions:', error)
          }
          return { suggestions: [] }
        } finally {
          completionAbortController = null
        }
      }.bind(this)
    })

    // Signature help provider
    monaco.languages.registerSignatureHelpProvider('ruby', {
      signatureHelpTriggerCharacters: ['(', ','],
      signatureHelpRetriggerCharacters: [','],
      provideSignatureHelp: async function(model, position, token, context) {
        console.log("Signature help triggered at position:", position)
        
        // Get the current line and find the method name
        const line = model.getLineContent(position.lineNumber)
        const beforeCursor = line.substring(0, position.column - 1)
        
        // Find the method name by looking backwards from the cursor
        const methodMatch = beforeCursor.match(/(\w+)\s*\(/)
        if (!methodMatch) {
          return null
        }
        
        const methodName = methodMatch[1]
        console.log("Getting signature help for method:", methodName)
        
        // Calculate active parameter based on comma count
        const afterMethod = beforeCursor.substring(beforeCursor.lastIndexOf('(') + 1)
        const commaCount = (afterMethod.match(/,/g) || []).length
        const activeParameter = commaCount
        
        try {
          // Get CSRF token from meta tag
          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
          
          const response = await fetch('/playground/signatures?' + new URLSearchParams({
            method: methodName,
            active_parameter: activeParameter
          }), {
            method: 'GET',
            headers: {
              'Accept': 'application/json',
              'X-CSRF-Token': csrfToken
            }
          })
          
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`)
          }
          
          const data = await response.json()
          
          if (!data.signatures || data.signatures.length === 0) {
            return null
          }
          
          // Convert to Monaco signature help format
          const signatures = data.signatures.map(sig => ({
            label: sig.label,
            documentation: sig.documentation,
            parameters: sig.parameters.map(param => ({
              label: param.label,
              documentation: param.documentation
            }))
          }))
          
          return {
            signatures: signatures,
            activeSignature: 0,
            activeParameter: data.signatures[0].activeParameter
          }
        } catch (error) {
          console.error('Error fetching signature help:', error)
          return null
        }
      }
    })
  }

  // Helper to map completion kinds
  getCompletionItemKind(kind) {
    const kindMap = {
      'Function': monaco.languages.CompletionItemKind.Function,
      'Method': monaco.languages.CompletionItemKind.Method,
      'Value': monaco.languages.CompletionItemKind.Value,
      'Color': monaco.languages.CompletionItemKind.Color,
      'Variable': monaco.languages.CompletionItemKind.Variable,
      'Property': monaco.languages.CompletionItemKind.Property
    }
    return kindMap[kind] || monaco.languages.CompletionItemKind.Property
  }

  // Playground-specific features
  filterComponents(event) {
    const query = event.target.value.toLowerCase()
    
    // Filter components
    const componentButtons = this.componentsContainerTarget.querySelectorAll('button')
    componentButtons.forEach(button => {
      const text = button.textContent.toLowerCase()
      const parent = button.closest('[data-category]') || button.parentElement
      if (text.includes(query)) {
        parent.style.display = ''
      } else {
        parent.style.display = 'none'
      }
    })

    // Filter examples
    const exampleButtons = this.examplesContainerTarget.querySelectorAll('button')
    exampleButtons.forEach(button => {
      const text = button.textContent.toLowerCase()
      button.style.display = text.includes(query) ? '' : 'none'
    })
  }

  changeTheme(event) {
    const theme = event.target.value
    monaco.editor.setTheme(theme)
  }

  switchDevice(event) {
    const device = event.params.device
    const preview = this.previewTarget.parentElement
    
    // Remove all device classes
    preview.classList.remove('device-desktop', 'device-tablet', 'device-mobile')
    
    // Add new device class
    if (device !== 'desktop') {
      preview.classList.add(`device-${device}`)
    }

    // Update button states
    event.currentTarget.parentElement.querySelectorAll('button').forEach(btn => {
      btn.classList.remove('bg-gray-200')
    })
    event.currentTarget.classList.add('bg-gray-200')
  }

  exportCode() {
    const code = this.editor.getValue()
    const blob = new Blob([code], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    
    const a = document.createElement('a')
    a.href = url
    a.download = 'swiftui-rails-playground.rb'
    a.click()
    
    URL.revokeObjectURL(url)
  }

  saveFavorite() {
    const code = this.editor.getValue()
    const name = prompt('Name this snippet:')
    
    if (!name) return
    
    const favorites = this.getFavorites()
    favorites.push({
      id: Date.now(),
      name: name,
      code: code,
      timestamp: new Date().toISOString()
    })
    
    localStorage.setItem('playground-favorites', JSON.stringify(favorites))
    this.loadFavorites()
  }

  loadFavorites() {
    const favorites = this.getFavorites()
    
    if (favorites.length === 0) {
      this.favoritesListTarget.innerHTML = '<span class="text-sm text-gray-500">No favorites yet</span>'
      return
    }

    this.favoritesListTarget.innerHTML = favorites.map(fav => `
      <div class="flex items-center justify-between py-1 group">
        <button 
          class="text-sm text-left flex-1 hover:text-blue-600"
          data-action="click->playground#loadFavorite"
          data-playground-favorite-id-param="${fav.id}"
        >
          ${this.escapeHtml(fav.name)}
        </button>
        <button 
          class="text-xs text-red-500 opacity-0 group-hover:opacity-100 transition"
          data-action="click->playground#deleteFavorite"
          data-playground-favorite-id-param="${fav.id}"
        >
          ✕
        </button>
      </div>
    `).join('')
  }

  loadFavorite(event) {
    const id = parseInt(event.params.favoriteId)
    const favorites = this.getFavorites()
    const favorite = favorites.find(f => f.id === id)
    
    if (favorite) {
      this.editor.setValue(favorite.code)
    }
  }

  deleteFavorite(event) {
    const id = parseInt(event.params.favoriteId)
    const favorites = this.getFavorites()
    const filtered = favorites.filter(f => f.id !== id)
    
    localStorage.setItem('playground-favorites', JSON.stringify(filtered))
    this.loadFavorites()
  }

  getFavorites() {
    return JSON.parse(localStorage.getItem('playground-favorites') || '[]')
  }

  // Existing methods from V1
  updatePreview() {
    const code = this.editor.getValue()
    this.codeInputTarget.value = code
    this.formTarget.requestSubmit()
  }

  runCode() {
    this.updatePreview()
  }

  insertComponent(event) {
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
    const code = event.params.code
    this.editor.setValue(code)
    this.updatePreview()
  }

  formatCode() {
    this.editor.getAction('editor.action.formatDocument').run()
  }

  clearCode() {
    if (confirm('Clear all code?')) {
      this.editor.setValue('')
    }
  }

  shareCode() {
    const code = this.editor.getValue()
    const encoded = btoa(code)
    const url = `${window.location.origin}/playground?code=${encoded}`

    navigator.clipboard.writeText(url).then(() => {
      // Show success message
      const button = this.element.querySelector('[data-action*="shareCode"]')
      const originalText = button.textContent
      button.textContent = 'Copied!'
      button.classList.add('bg-green-600')
      
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove('bg-green-600')
      }, 2000)
    })
  }

  handleClick() {
    alert('Hello from Playground! 🎉')
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  debouncedPreview = this.debounce(() => {
    this.updatePreview()
  }, 500)

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
}