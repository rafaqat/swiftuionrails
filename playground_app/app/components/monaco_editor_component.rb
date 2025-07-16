# frozen_string_literal: true

# MonacoEditorComponent - Full DSL composition for Monaco Editor
class MonacoEditorComponent < ApplicationComponent
  prop :initial_code, type: String, default: ""
  prop :language, type: String, default: "ruby"
  prop :theme, type: String, default: "solarized-light"
  prop :height, type: String, default: "100%"
  prop :font_size, type: Integer, default: 14
  
  swift_ui do
    div(class: "relative w-full h-full") do
      # Loading indicator
      loading_indicator
      
      # Monaco container (hidden initially)
      monaco_container
      
      # Fallback textarea (hidden initially)
      fallback_textarea
      
      # Monaco initialization script
      monaco_script
    end
  end
  
  private
  
  def loading_indicator
    div(id: "editor-loading-#{editor_id}", class: "absolute inset-0 flex items-center justify-center bg-solarized-base3") do
      text("Loading editor...").text_color("solarized-base00")
    end
  end
  
  def monaco_container
    div(
      id: "monaco-editor-#{editor_id}",
      data: {
        monaco_target: "container",
        monaco_language: language,
        monaco_theme: theme,
        monaco_font_size: font_size
      },
      class: "absolute inset-0",
      style: "display: none;"
    )
  end
  
  def fallback_textarea
    create_element(:textarea,
      initial_code,
      id: "fallback-editor-#{editor_id}",
      data: { monaco_target: "fallback" },
      class: "absolute inset-0 w-full h-full p-4 bg-solarized-base3 text-solarized-base01 font-mono text-sm resize-none focus:outline-none",
      style: "display: none;",
      spellcheck: false
    )
  end
  
  def monaco_script
    # Script tag to initialize Monaco for this specific editor
    create_element(:script, nil, type: "text/javascript") do
      <<~JS.html_safe
        (function() {
          const editorId = '#{editor_id}';
          const container = document.getElementById('monaco-editor-' + editorId);
          const fallback = document.getElementById('fallback-editor-' + editorId);
          const loading = document.getElementById('editor-loading-' + editorId);
          
          function initializeMonaco() {
            if (typeof monaco === 'undefined') {
              // Monaco not loaded, use fallback
              loading.style.display = 'none';
              fallback.style.display = 'block';
              return;
            }
            
            try {
              // Create editor instance
              const editor = monaco.editor.create(container, {
                value: #{initial_code.to_json},
                language: '#{language}',
                theme: '#{theme}',
                fontSize: #{font_size},
                fontFamily: 'Menlo, Monaco, "Courier New", monospace',
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
                }
              });
              
              // Store editor instance
              window['monacoEditor_' + editorId] = editor;
              
              // Hide loading, show editor
              loading.style.display = 'none';
              container.style.display = 'block';
              
              // Dispatch ready event
              window.dispatchEvent(new CustomEvent('monaco-editor-ready', {
                detail: { editorId: editorId, editor: editor }
              }));
              
              // Sync to hidden input/textarea if exists
              const hiddenInput = document.querySelector('[data-monaco-sync="' + editorId + '"]');
              if (hiddenInput) {
                editor.onDidChangeModelContent(() => {
                  hiddenInput.value = editor.getValue();
                });
              }
            } catch (error) {
              console.error('Failed to initialize Monaco:', error);
              loading.style.display = 'none';
              fallback.style.display = 'block';
            }
          }
          
          // Wait for Monaco to be loaded
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeMonaco);
          } else {
            initializeMonaco();
          }
        })();
      JS
    end
  end
  
  def editor_id
    @editor_id ||= "editor_#{SecureRandom.hex(8)}"
  end
end