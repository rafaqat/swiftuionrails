# SwiftUI Rails Playground V2 - Technical Specification

## Executive Summary

We're rebuilding the SwiftUI Rails Playground using our own DSL to replace the current ERB-based implementation. This serves as the ultimate dogfooding exercise - proving our DSL can handle complex, real-world applications.

**Key Goal**: Replace V1 entirely with a DSL-powered version that demonstrates the framework's maturity and capabilities.

## Current State (V1)

The existing playground is built with:
- View: ERB template (app/views/playground/index.html.erb) - 600+ lines
- Controller: PlaygroundController handling preview/completions
- JavaScript: Stimulus controller + Monaco Editor integration
- Route: /playground

## Proposed Architecture (V2)

### 1. Route Structure

```ruby
# config/routes.rb (REPLACE existing playground routes)
get "playground", to: "playground_v2#index"
post "playground/preview", to: "playground_v2#preview"

namespace :playground do
  resources :completions, only: [:create]
end
get "playground/signatures", to: "playground_v2#signatures"
```

### 2. New Controller

```ruby
# app/controllers/playground_v2_controller.rb (NEW FILE)
class PlaygroundV2Controller < ApplicationController
  def index
    @playground = PlaygroundV2Component.new(
      default_code: default_playground_code,
      components: available_components,
      examples: code_examples
    )
  end

  def preview
    # Reuse existing preview logic from V1
    code = params[:code]
    # ... (same as PlaygroundController#preview)
  end

  def signatures
    # Reuse from V1
  end

  private

  # Copy these methods from PlaygroundController
  def default_playground_code
    # ...
  end

  def available_components
    # ...
  end

  def code_examples
    # ...
  end
end
```

### 3. Component Structure

```ruby
# app/components/playground_v2_component.rb (NEW FILE)
class PlaygroundV2Component < ApplicationComponent
  include SwiftUIRails::DSL

  prop :default_code, type: String, required: true
  prop :components, type: Array, default: []
  prop :examples, type: Array, default: []

  swift_ui do
    div(data: { controller: "playground-v2" }) do
      # Header bar
      header_component

      # Main content area
      hstack(spacing: 0) do
        # Sidebar
        sidebar_component

        # Editor + Preview
        main_content_area
      end.h("[calc(100vh-64px)]")
    end
    .min_h("screen")
    .bg("gray-50")
  end

  private

  def header_component
    header do
      div.px(4).py(3) do
        hstack(justify: :between) do
          # Logo and title
          hstack(spacing: 4) do
            text("SwiftUI Rails Playground")
              .font_size("2xl")
              .font_weight("bold")
              .text_color("gray-900")

            badge("DSL Powered")
              .bg("green-100")
              .text_color("green-800")
          end

          # Action buttons
          hstack(spacing: 4) do
            run_button
            share_button
            # V2-only feature: Export button
            export_button
          end
        end
      end
    end
    .bg("white")
    .shadow("sm")
    .border_b
  end

  def sidebar_component
    aside do
      div.p(3) do
        # V2-only feature: Search box
        search_box
        
        # Components section
        text("Components").font_weight("semibold").mb(3)

        components.group_by { |c| c[:category] }.each do |category, items|
          component_category(category, items)
        end

        # Examples section
        divider.my(4)

        text("Examples").font_weight("semibold").mb(3)
        examples.each do |example|
          example_button(example)
        end

        # V2-only feature: Favorites
        if has_favorites?
          divider.my(4)
          favorites_section
        end
      end
    end
    .w(48)
    .bg("white")
    .border_r
    .overflow_y("auto")
  end

  def main_content_area
    hstack(spacing: 0).flex_1 do
      # Code editor section
      editor_section

      # Preview section
      preview_section
    end
  end

  def editor_section
    div.w("70%").relative do
      # Editor header
      div.px(4).py(2).bg("gray-100").border_b do
        hstack(justify: :between) do
          text("Ruby DSL Code").text_sm.text_color("gray-700")

          hstack(spacing: 2) do
            # V2-only feature: Theme switcher
            theme_switcher
            
            button("Format")
              .text_sm
              .text_color("gray-600")
              .hover_text_color("gray-900")
              .data(action: "click->playground-v2#formatCode")

            button("Clear")
              .text_sm
              .text_color("gray-600")
              .hover_text_color("gray-900")
              .data(action: "click->playground-v2#clearCode")
          end
        end
      end

      # Monaco container
      div(
        id: "monaco-editor-v2",
        data: {
          playground_v2_target: "monacoContainer",
          initial_code: default_code
        }
      ).h("full")

      # Hidden form for preview submission
      hidden_preview_form
    end
    .bg("gray-50")
  end

  def preview_section
    div.w("30%").bg("white") do
      # Preview header with V2 features
      div.px(4).py(2).bg("gray-50").border_b do
        hstack(justify: :between) do
          text("Preview").font_weight("medium").text_color("gray-700")
          
          # V2-only: Device preview switcher
          device_switcher
        end
      end

      # Preview container with device frame
      div(
        id: "preview-container-v2",
        data: { playground_v2_target: "preview" }
      ).p(6)
    end
  end

  # V2-only features
  def search_box
    textfield(
      placeholder: "Search components...",
      data: {
        action: "input->playground-v2#filterComponents",
        playground_v2_target: "searchInput"
      }
    ).mb(4)
  end

  def export_button
    button("Export")
      .px(4).py(2)
      .bg("purple-600")
      .text_color("white")
      .rounded("lg")
      .hover_bg("purple-700")
      .transition
      .data(action: "click->playground-v2#exportCode")
  end

  def theme_switcher
    select(
      data: {
        action: "change->playground-v2#changeTheme",
        playground_v2_target: "themeSelect"
      }
    ) do
      option("Light", value: "vs-light")
      option("Dark", value: "vs-dark")
      option("Solarized", value: "solarized-light")
    end.text_sm
  end

  def device_switcher
    hstack(spacing: 1) do
      ["desktop", "tablet", "mobile"].each do |device|
        button
          .p(1)
          .rounded
          .data(
            action: "click->playground-v2#switchDevice",
            device: device
          )
          .tap do |btn|
            btn.bg("gray-200") if device == "desktop"
            btn.hover_bg("gray-100")
          end do
          device_icon(device)
        end
      end
    end
  end

  def favorites_section
    vstack(spacing: 2) do
      text("Favorites").font_weight("semibold")
      # Render favorite snippets
    end
  end

  # Helper methods
  def component_category(category, items)
    div.mb(4) do
      text(category)
        .text_xs
        .font_weight("medium")
        .text_color("gray-500")
        .uppercase
        .tracking("wider")
        .mb(1)

      vstack(spacing: 0.5) do
        items.each do |component|
          button(component[:name])
            .w("full")
            .text_align("left")
            .px(2).py(1.5)
            .text_sm
            .rounded
            .hover_bg("gray-100")
            .transition
            .data(
              action: "click->playground-v2#insertComponent",
              playground_v2_code_param: component[:code]
            )
        end
      end
    end
  end

  def example_button(example)
    button(example[:name])
      .w("full")
      .text_align("left")
      .px(2).py(1.5)
      .text_sm
      .rounded
      .hover_bg("gray-100")
      .transition
      .data(
        action: "click->playground-v2#loadExample",
        playground_v2_code_param: example[:code]
      )
  end

  def run_button
    button do
      hstack(spacing: 2) do
        icon("play").w(5).h(5)
        text("Run")
      end
    end
    .px(4).py(2)
    .bg("green-600")
    .text_color("white")
    .rounded("lg")
    .hover_bg("green-700")
    .transition
    .data(action: "click->playground-v2#runCode")
  end

  def share_button
    button("Share")
      .px(4).py(2)
      .bg("blue-600")
      .text_color("white")
      .rounded("lg")
      .hover_bg("blue-700")
      .transition
      .data(action: "click->playground-v2#shareCode")
  end

  def hidden_preview_form
    # This demonstrates form_with usage in DSL
    form_with(
      url: preview_playground_path,
      method: :post,
      data: { playground_v2_target: "form" }
    ) do |f|
      f.hidden_field :code, data: { playground_v2_target: "codeInput" }
    end
  end

  def divider
    div.h("px").bg("gray-200").w("full")
  end

  def badge(text_content)
    span(text_content)
      .text_xs
      .font_medium
      .px(2).py(1)
      .rounded("full")
  end

  def icon(name)
    # Icon implementation
    case name
    when "play"
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor") do
        path(
          d: "M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z",
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2"
        )
      end
    end
  end

  def device_icon(type)
    # Device icons for preview switcher
    case type
    when "desktop"
      svg(class: "w-5 h-5", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor") do
        path(d: "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z")
      end
    when "tablet"
      svg(class: "w-5 h-5", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor") do
        path(d: "M12 18h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z")
      end
    when "mobile"
      svg(class: "w-5 h-5", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor") do
        path(d: "M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z")
      end
    end
  end

  def has_favorites?
    # Check localStorage via Stimulus
    false # Placeholder
  end
end
```

### 4. View File (Minimal)

```erb
<!-- app/views/playground_v2/index.html.erb (NEW FILE) -->
<%= @playground %>

<!-- Monaco Editor -->
<script src="/monaco-editor/min/vs/loader.js"></script>
<script>
  require.config({ 
    paths: { 
      'vs': '/monaco-editor/min/vs' 
    }
  });
</script>
```

### 5. JavaScript Controller

```javascript
// app/javascript/controllers/playground_v2_controller.js (NEW FILE)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monacoContainer", "preview", "form", "codeInput", "searchInput", "themeSelect"]

  connect() {
    console.log("Playground V2 controller connected")
    this.initializeMonaco()
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
        automaticLayout: true
      })

      // Set up auto-preview
      this.editor.onDidChangeModelContent(() => {
        this.debouncedPreview()
      })

      // Hook up existing completion/signature providers
      this.setupLanguageFeatures()
    })
  }

  setupLanguageFeatures() {
    // Reuse the completion and signature providers from V1
    // This code would be copied from the existing playground
  }

  // V2-specific features
  filterComponents(event) {
    const query = event.target.value.toLowerCase()
    // Filter sidebar components based on search
  }

  changeTheme(event) {
    const theme = event.target.value
    monaco.editor.setTheme(theme)
  }

  switchDevice(event) {
    const device = event.params.device
    const preview = this.previewTarget
    
    // Apply device-specific classes
    preview.classList.remove('device-desktop', 'device-tablet', 'device-mobile')
    preview.classList.add(`device-${device}`)
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
```

## V2-Only Features

1. **Component Search**: Filter components in real-time
2. **Theme Switcher**: Switch between editor themes
3. **Device Preview**: See how components look on different devices
4. **Export Functionality**: Download code as Ruby file
5. **Favorites System**: Save and reuse code snippets
6. **Enhanced UI**: Badges, better organization, cleaner design

## Migration Plan

### Phase 1: Build V2 Alongside V1
1. Create new controller and component
2. Set up routes at `/playground-v2` temporarily
3. Implement core functionality
4. Add V2-only features

### Phase 2: Testing & Refinement
1. Ensure feature parity with V1
2. Test all interactive features
3. Optimize performance
4. Gather feedback

### Phase 3: Replace V1
1. Move V2 to main `/playground` route
2. Archive V1 code
3. Update all references
4. Deploy

## Key Technical Challenges & Solutions

1. **Monaco Editor Integration**
   - Challenge: Monaco needs direct DOM access
   - Solution: Create a div with ID, initialize via Stimulus controller

2. **Form Integration**
   - Challenge: Need Rails form helpers within DSL
   - Solution: Use form_with helper that's already included in DSL

3. **Dynamic Content**
   - Challenge: Looping through components/examples
   - Solution: Use Ruby's each within DSL blocks

4. **Event Handling**
   - Challenge: Complex interactions
   - Solution: Stimulus controllers with data-action attributes

## Benefits of This Approach

1. **Proves DSL Maturity**: Shows we can build complex apps
2. **Discovers Limitations**: We'll find what's missing in the DSL
3. **Creates Patterns**: Establishes best practices for others
4. **Real Dogfooding**: We use what we build
5. **Better Features**: V2 includes enhancements not in V1

## Files to Create/Modify

**New Files:**
- app/controllers/playground_v2_controller.rb
- app/components/playground_v2_component.rb
- app/views/playground_v2/index.html.erb
- app/javascript/controllers/playground_v2_controller.js

**Modified Files:**
- config/routes.rb (replace playground routes)
- app/javascript/controllers/index.js (register new controller)

**To Be Archived:**
- app/controllers/playground_controller.rb
- app/views/playground/index.html.erb
- app/javascript/controllers/playground_controller.js

## Success Criteria

1. ✅ Complete feature parity with V1
2. ✅ Clean, maintainable DSL code
3. ✅ All V2-only features working
4. ✅ No ERB in the main component (only the minimal view)
5. ✅ Successfully replaces V1

## Timeline Estimate

- Phase 1 (Build): 6 hours
- Phase 2 (Test & Refine): 2 hours
- Phase 3 (Replace V1): 2 hours
- Total: ~10 hours

## Next Steps

1. Create the new controller and component files
2. Set up temporary route for development
3. Build core functionality
4. Add V2-only features
5. Test thoroughly
6. Replace V1