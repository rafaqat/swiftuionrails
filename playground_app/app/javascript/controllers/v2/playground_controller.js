import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monacoContainer", "preview", "form", "codeInput", "searchInput", "themeSelect", "categoryItem", "componentItem"]

  connect() {
    console.log("Playground V2 controller connected")
    this.debouncedPreview = this.debounce(this.updatePreview.bind(this), 500)
    
    // Check if require is loaded (Monaco loader)
    if (window.require) {
      this.initializeMonaco()
    } else {
      // Wait for loader
      const checkRequire = setInterval(() => {
        if (window.require) {
          clearInterval(checkRequire)
          this.initializeMonaco()
        }
      }, 100)
    }
    
    this.loadFavorites()
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
        fontFamily: 'Menlo, Monaco, "Courier New", monospace',
        scrollBeyondLastLine: false,
        renderWhitespace: 'selection',
        tabSize: 2,
        insertSpaces: true,
        padding: { top: 16, bottom: 16 },
        suggestOnTriggerCharacters: true
      })

      // Set up auto-preview
      this.editor.onDidChangeModelContent(() => {
        this.debouncedPreview()
      })

      // Hook up existing completion/signature providers
      this.setupLanguageFeatures()
      
      // Initial preview
      this.updatePreview()
    })
  }

  setupLanguageFeatures() {
    // Register completion provider for SwiftUI DSL
    if (!this.completionProviderRegistered) {
      this.completionProviderRegistered = true
      
      monaco.languages.registerCompletionItemProvider('ruby', {
        provideCompletionItems: (model, position) => {
          return new Promise((resolve) => {
            const word = model.getWordUntilPosition(position);
            const range = {
              startLineNumber: position.lineNumber,
              endLineNumber: position.lineNumber,
              startColumn: word.startColumn,
              endColumn: word.endColumn
            };
            
            // Get text around cursor for context
            const textBeforeCursor = model.getValueInRange({
              startLineNumber: position.lineNumber,
              startColumn: 1,
              endLineNumber: position.lineNumber,
              endColumn: position.column
            });
            
            // Fetch completions from Rails backend
            fetch('/v2/playground/completions', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({
                prefix: word.word,
                context: textBeforeCursor,
                line: position.lineNumber,
                column: position.column
              })
            })
            .then(response => response.json())
            .then(data => {
              const suggestions = data.completions.map(completion => ({
                label: completion.label,
                kind: this.getCompletionKind(completion.kind),
                insertText: completion.insertText,
                insertTextRules: completion.snippet ? 
                  monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet : 
                  monaco.languages.CompletionItemInsertTextRule.None,
                documentation: completion.documentation,
                detail: completion.detail,
                range: range,
                sortText: completion.sortText || completion.label
              }));
              
              resolve({
                suggestions: suggestions
              });
            })
            .catch(error => {
              console.error('Error fetching completions:', error);
              resolve({ suggestions: [] });
            });
          });
        },
        
        triggerCharacters: ['.', '(', ' ', '\t']
      });

      // Register signature help provider
      monaco.languages.registerSignatureHelpProvider('ruby', {
        signatureHelpTriggerCharacters: ['(', ','],
        provideSignatureHelp: (model, position) => {
          return new Promise((resolve) => {
            const textBeforeCursor = model.getValueInRange({
              startLineNumber: position.lineNumber,
              startColumn: 1,
              endLineNumber: position.lineNumber,
              endColumn: position.column
            });
            
            fetch('/v2/playground/signatures', {
              method: 'GET',
              headers: {
                'Content-Type': 'application/json'
              }
            })
            .then(response => response.json())
            .then(data => {
              // Find method signature based on cursor position
              const methodMatch = textBeforeCursor.match(/(\w+)\s*\(([^)]*)$/);
              if (methodMatch) {
                const methodName = methodMatch[1];
                const signature = data.signatures.find(sig => sig.label.startsWith(methodName));
                
                if (signature) {
                  resolve({
                    value: {
                      signatures: [{
                        label: signature.label,
                        documentation: signature.documentation,
                        parameters: signature.parameters || []
                      }],
                      activeSignature: 0,
                      activeParameter: 0
                    }
                  });
                  return;
                }
              }
              
              resolve({ value: { signatures: [], activeSignature: 0, activeParameter: 0 } });
            })
            .catch(error => {
              console.error('Error fetching signatures:', error);
              resolve({ value: { signatures: [], activeSignature: 0, activeParameter: 0 } });
            });
          });
        }
      });
    }
  }

  getCompletionKind(kind) {
    const kindMap = {
      'dsl_element': monaco.languages.CompletionItemKind.Class,
      'modifier': monaco.languages.CompletionItemKind.Method,
      'parameter': monaco.languages.CompletionItemKind.Property,
      'value': monaco.languages.CompletionItemKind.Value,
      'color': monaco.languages.CompletionItemKind.Color,
      'keyword': monaco.languages.CompletionItemKind.Keyword
    };
    return kindMap[kind] || monaco.languages.CompletionItemKind.Text;
  }

  // V2-specific features
  filterComponents(event) {
    const query = event.target.value.toLowerCase()
    
    // Filter sidebar components based on search
    this.categoryItemTargets.forEach(category => {
      let hasVisibleItems = false
      
      const items = category.querySelectorAll('[data-playground-v2-target="componentItem"]')
      items.forEach(item => {
        const name = item.dataset.name
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
    monaco.editor.setTheme(theme)
  }

  switchDevice(event) {
    const device = event.params.device
    const preview = this.previewTarget
    
    // Remove existing device classes
    preview.classList.remove('max-w-sm', 'mx-auto', 'max-w-3xl')
    
    // Apply device-specific classes
    if (device === 'mobile') {
      preview.classList.add('max-w-sm', 'mx-auto')
    } else if (device === 'tablet') {
      preview.classList.add('max-w-3xl', 'mx-auto')
    }
    // Desktop is default (full width)
  }

  exportCode() {
    const code = this.editor.getValue()
    const blob = new Blob([code], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    
    const a = document.createElement('a')
    a.href = url
    a.download = 'playground-export.rb'
    a.click()
  }

  saveFavorite() {
    const code = this.editor.getValue()
    const favorites = JSON.parse(localStorage.getItem('playground-favorites') || '[]')
    favorites.push({
      code: code,
      name: prompt('Name this snippet:'),
      timestamp: Date.now()
    })
    localStorage.setItem('playground-favorites', JSON.stringify(favorites))
  }

  loadFavorites() {
    // Load and display favorites from localStorage
    // This would need a UI element to display them
  }

  // Existing methods from V1
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
    const code = event.params.code
    
    // Check if we're inside a swift_ui block
    const currentCode = this.editor.getValue().trim()
    const hasSwiftUIWrapper = currentCode.startsWith('swift_ui do')
    
    if (hasSwiftUIWrapper) {
       // Just append at the end of the block (simple implementation)
       const lines = currentCode.split('\n')
       let lastEndLineIndex = -1
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
         this.editor.setValue(currentCode + '\n' + code)
       }
    } else {
       // Insert at cursor
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
    }
    
    this.editor.focus()
  }

  loadExample(event) {
    const code = event.params.code
    this.editor.setValue(code)
  }

  formatCode() {
    this.editor.getAction('editor.action.formatDocument').run()
  }

  clearCode() {
    this.editor.setValue('')
  }

  shareCode() {
    const code = this.editor.getValue()
    const encoded = btoa(code)
    const url = `${window.location.origin}/playground?code=${encoded}`

    navigator.clipboard.writeText(url).then(() => {
      alert('Playground link copied!')
    })
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
}
