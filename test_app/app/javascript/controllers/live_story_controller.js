import { Controller } from "@hotwired/stimulus"

// Enhanced interactive storybook controller for real-time prop updates
export default class extends Controller {
  static targets = [
    "form", 
    "preview", 
    "control", 
    "variantLink",
    "modeToggle",
    "stateInspector",
    "usageCode"
  ]
  
  static values = { 
    story: String, 
    variant: String,
    sessionId: String,
    mode: { type: String, default: "interactive" },
    updateUrl: String
  }

  connect() {
    console.log(`🎭 LiveStory controller connected for ${this.storyValue}/${this.variantValue}`)
    
    // Auto-generate session ID if not provided
    if (!this.sessionIdValue) {
      this.sessionIdValue = this.generateSessionId()
    }
    
    // Setup form change listeners for real-time updates
    this.setupFormListeners()
    
    // Setup variant switching
    this.setupVariantSwitching()
    
    // Initialize mode toggle if present
    this.initializeModeToggle()
    
    // Setup state inspector updates
    this.initializeStateInspector()
    
    // Initialize usage code display
    setTimeout(() => this.updateUsageCode(), 100)
  }

  disconnect() {
    console.log(`🎭 LiveStory controller disconnected`)
    
    // Clean up any debounce timers
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
    
    // Remove event listeners
    document.removeEventListener('turbo:before-stream-render', this.turboStreamHandler)
  }

  // Real-time control updates with enhanced feedback
  controlChanged(event) {
    if (this.modeValue === "interactive") {
      const fieldName = event.target.name
      const newValue = event.target.type === 'checkbox' ? event.target.checked : event.target.value
      
      console.log(`🔄 Control changed: ${fieldName} = ${newValue}`)
      
      // Add visual feedback to the control
      this.addControlFeedback(event.target)
      
      // Update preview with debouncing
      this.debounce(() => this.updatePreview(), 200)
      
      // Update current value display
      this.updateValueDisplay(fieldName, newValue)
    }
  }

  // Handle option selection from visual buttons
  selectOption(event) {
    event.preventDefault()
    const field = event.currentTarget.dataset.field
    const value = event.currentTarget.dataset.value
    
    // Find and update the corresponding select element
    const selectElement = this.element.querySelector(`select[name="${field}"]`)
    if (selectElement) {
      selectElement.value = value
      
      // Trigger change event
      selectElement.dispatchEvent(new Event('change', { bubbles: true }))
      
      // Update visual buttons
      this.updateOptionButtons(field, value)
    }
  }

  // Variant switching with Turbo
  switchVariant(event) {
    event.preventDefault()
    const variantName = event.currentTarget.dataset.variant
    
    console.log(`🔀 Switching to variant: ${variantName}`)
    
    // Update active variant link styling
    this.updateActiveVariant(variantName)
    
    // Update the preview with new variant
    this.variantValue = variantName
    this.updatePreview()
  }

  // Mode switching between static and interactive
  toggleMode(event) {
    const newMode = event.currentTarget.checked ? "interactive" : "static"
    console.log(`🎛️ Switching to ${newMode} mode`)
    
    this.modeValue = newMode
    this.toggleModeUI(newMode)
    
    if (newMode === "interactive") {
      this.enableInteractiveMode()
    } else {
      this.disableInteractiveMode()
    }
  }

  // Component action handlers (for button clicks, etc.)
  handleComponentAction(event) {
    event.preventDefault()
    const action = event.currentTarget.dataset.action
    const componentId = event.currentTarget.dataset.componentId
    
    console.log(`🎯 Component action: ${action} on ${componentId}`)
    
    if (this.modeValue === "interactive") {
      this.executeComponentAction(action, componentId)
    }
  }


  // Private methods
  
  setupFormListeners() {
    if (this.hasFormTarget) {
      // Listen to all form controls
      this.controlTargets.forEach(control => {
        control.addEventListener('input', this.controlChanged.bind(this))
        control.addEventListener('change', this.controlChanged.bind(this))
      })
    }
  }

  setupVariantSwitching() {
    this.variantLinkTargets.forEach(link => {
      link.addEventListener('click', this.switchVariant.bind(this))
    })
  }

  initializeModeToggle() {
    if (this.hasModeToggleTarget) {
      this.modeToggleTarget.addEventListener('change', this.toggleMode.bind(this))
      
      // Set initial state
      this.modeToggleTarget.checked = this.modeValue === "interactive"
      this.toggleModeUI(this.modeValue)
    }
  }

  initializeStateInspector() {
    if (this.hasStateInspectorTarget) {
      // Initial state load
      this.updateStateInspector()
      
      // Setup event-driven updates instead of polling
      this.setupStateChangeListeners()
    }
  }
  
  setupStateChangeListeners() {
    // Listen for state changes via custom events
    this.element.addEventListener('state:changed', (event) => {
      if (this.modeValue === "interactive") {
        this.handleStateChange(event.detail)
      }
    })
    
    // Create bound handler for proper cleanup
    this.turboStreamHandler = (event) => {
      // Update state inspector after stream renders
      setTimeout(() => {
        if (this.modeValue === "interactive" && this.hasStateInspectorTarget) {
          this.updateStateInspector()
        }
      }, 50)
    }
    
    // Listen for Turbo Stream updates that might affect state
    document.addEventListener('turbo:before-stream-render', this.turboStreamHandler)
  }
  
  handleStateChange(detail) {
    // Update state inspector with new state data
    if (detail && detail.state) {
      this.renderStateInspector(detail.state)
    } else {
      // Fallback to fetching current state
      this.updateStateInspector()
    }
  }

  updatePreview() {
    if (!this.hasPreviewTarget) return

    const formData = new FormData(this.formTarget)
    formData.append('story', this.storyValue)
    formData.append('story_variant', this.variantValue)  // Keep current story variant (like "default")
    formData.append('session_id', this.sessionIdValue)
    formData.append('mode', this.modeValue)
    
    // Form data already includes all component props from the form controls

    console.log(`📡 Updating preview for ${this.storyValue}/${this.variantValue}`)

    fetch(this.updateUrlValue || '/storybook/update_preview', {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.getCSRFToken()
      }
    })
    .then(response => response.text())
    .then(html => {
      // Handle Turbo Stream response with smooth morphing
      if (html.includes('<turbo-stream')) {
        console.log('🔀 Applying smooth morphing transition')
        this.applySmoothMorphing(html)
      } else {
        // Fallback for non-stream responses
        this.previewTarget.innerHTML = html
      }
      
      // Emit state change event and update usage code
      setTimeout(() => {
        this.element.dispatchEvent(new CustomEvent('state:changed'))
        this.updateUsageCode()
      }, 100)
    })
    .catch(error => {
      console.error('Preview update failed:', error)
      this.showErrorMessage('Failed to update preview')
    })
  }

  executeComponentAction(action, componentId) {
    const formData = new FormData()
    formData.append('story', this.storyValue)
    formData.append('story_variant', this.variantValue)  // Use story_variant to avoid conflict
    formData.append('session_id', this.sessionIdValue)
    formData.append('action', action)
    formData.append('component_id', componentId)

    fetch('/storybook/component_action', {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.getCSRFToken()
      }
    })
    .then(response => response.text())
    .then(html => {
      if (html.includes('<turbo-stream')) {
        Turbo.renderStreamMessage(html)
      }
      
      // Emit state change event
      setTimeout(() => {
        this.element.dispatchEvent(new CustomEvent('state:changed'))
      }, 100)
    })
    .catch(error => {
      console.error('Component action failed:', error)
      this.showErrorMessage('Action failed')
    })
  }

  updateStateInspector() {
    // Only fetch initial state if needed
    if (!this.hasStateInspectorTarget) return
    
    // Trigger state refresh on the state inspector controller
    const stateInspectorController = this.application.getControllerForElementAndIdentifier(
      this.stateInspectorTarget,
      'state-inspector'
    )
    
    if (stateInspectorController) {
      stateInspectorController.refresh()
    }
  }

  updateActiveVariant(variantName) {
    this.variantLinkTargets.forEach(link => {
      if (link.dataset.variant === variantName) {
        link.classList.add('bg-blue-100', 'text-blue-800')
        link.classList.remove('text-gray-600', 'hover:text-gray-900')
      } else {
        link.classList.remove('bg-blue-100', 'text-blue-800')
        link.classList.add('text-gray-600', 'hover:text-gray-900')
      }
    })
  }

  toggleModeUI(mode) {
    const isInteractive = mode === "interactive"
    
    // Update form controls
    if (this.hasFormTarget) {
      this.formTarget.classList.toggle('border-green-300', isInteractive)
      this.formTarget.classList.toggle('bg-green-50', isInteractive)
    }
    
    // Show/hide state inspector
    if (this.hasStateInspectorTarget) {
      this.stateInspectorTarget.style.display = isInteractive ? 'block' : 'none'
    }
    
    // Update preview container
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.toggle('border-green-300', isInteractive)
      this.previewTarget.classList.toggle('shadow-green-100', isInteractive)
    }
  }

  enableInteractiveMode() {
    console.log('🟢 Interactive mode enabled')
    this.showSuccessMessage('Interactive mode enabled - controls now update in real-time!')
    
    // Setup real-time listeners
    this.setupFormListeners()
  }

  disableInteractiveMode() {
    console.log('⚪ Interactive mode disabled')
    this.showInfoMessage('Static mode enabled - use "Update Preview" button to see changes')
  }

  generateSessionId() {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }

  updateUsageCode() {
    if (!this.hasUsageCodeTarget) return

    // Get current form data to generate component code
    const formData = new FormData(this.formTarget)
    const props = {}
    
    // Extract all form values
    for (let [key, value] of formData.entries()) {
      if (key !== 'story' && key !== 'story_variant' && key !== 'session_id' && key !== 'mode') {
        props[key] = value
      }
    }
    
    // Get story name to determine which component we're showing
    const storyName = formData.get('story') || ''
    
    // Generate appropriate code based on component type
    const componentCode = this.generateComponentCode(storyName, props)
    
    // Update the code display
    const codeElement = this.usageCodeTarget.querySelector('#chainable-code')
    if (codeElement) {
      codeElement.textContent = componentCode
      
      // Add visual feedback with smooth animation
      this.usageCodeTarget.classList.add('ring-2', 'ring-green-300', 'transition-all', 'duration-300')
      codeElement.classList.add('animate-pulse')
      
      setTimeout(() => {
        this.usageCodeTarget.classList.remove('ring-2', 'ring-green-300')
        codeElement.classList.remove('animate-pulse')
      }, 800)
    }
  }

  generateComponentCode(storyName, props) {
    // Always generate SwiftUI DSL code with full examples
    return this.generateSwiftUIDSLCode(storyName, props)
  }

  generateProductListCode(props) {
    // Generate proper ProductListComponent creation code
    const title = props.title || 'Products'
    const columns = props.columns || 'auto'
    const sortable = props.sortable === 'true' || props.sortable === true
    const filterable = props.filterable === 'true' || props.filterable === true
    const enableAnimations = props.enable_animations === 'true' || props.enable_animations === true
    const showQuickActions = props.show_quick_actions === 'true' || props.show_quick_actions === true
    const currencySymbol = props.currency_symbol || '$'
    
    return `render ProductListComponent.new(
  products: @products,
  title: "${title}",
  columns: :${columns},
  gap: "${props.gap || '6'}",
  background_color: "${props.background_color || 'white'}",
  container_padding: "${props.container_padding || '16'}",
  max_width: "${props.max_width || '7xl'}",
  image_aspect: "${props.image_aspect || 'square'}",
  show_colors: ${props.show_colors !== 'false'},
  currency_symbol: "${currencySymbol}"
)`
  }

  generateSimpleButtonCode(props) {
    // Generate proper SimpleButtonComponent creation code
    const title = props.title || 'Click Me'
    const variant = props.variant || 'primary'
    const size = props.size || 'md'
    const disabled = props.disabled === 'true'
    
    let propsArray = [
      `title: "${title}"`,
      `variant: :${variant}`,
      `size: :${size}`,
      `disabled: ${disabled}`
    ]
    
    // Add optional props only if they have values
    if (props.background_color && props.background_color.trim() !== '') {
      propsArray.push(`background_color: "${props.background_color}"`)
    }
    if (props.text_color && props.text_color.trim() !== '') {
      propsArray.push(`text_color: "${props.text_color}"`)
    }
    if (props.corner_radius && props.corner_radius !== 'md') {
      propsArray.push(`corner_radius: "${props.corner_radius}"`)
    }
    if (props.padding_x && props.padding_x.trim() !== '') {
      propsArray.push(`padding_x: "${props.padding_x}"`)
    }
    if (props.padding_y && props.padding_y.trim() !== '') {
      propsArray.push(`padding_y: "${props.padding_y}"`)
    }
    if (props.font_weight && props.font_weight !== 'medium') {
      propsArray.push(`font_weight: "${props.font_weight}"`)
    }
    if (props.font_size && props.font_size.trim() !== '') {
      propsArray.push(`font_size: "${props.font_size}"`)
    }
    
    return `render SimpleButtonComponent.new(
  ${propsArray.join(',\n  ')}
)`
  }

  generateSwiftUIDSLCode(storyName, props) {
    // Generate complete SwiftUI-style DSL code with slots and data
    if (storyName.includes('product_list')) {
      return this.generateFullProductListDSL(props)
    } else if (storyName.includes('simple_button')) {
      return this.generateFullButtonDSL(props)
    } else if (storyName.includes('product_layout_simple')) {
      return this.generateProductLayoutSimpleDSL(props)
    } else {
      // Default chainable code
      const chainableCode = this.generateChainableCode(props)
      return `<%= swift_ui do
  vstack(spacing: 16) do
    ${chainableCode}
  end
end %>`
    }
  }

  generateFullProductListDSL(props) {
    const title = props.title || 'Products'
    const columns = props.columns || 'auto'
    const sortable = props.sortable === 'true' || props.sortable === true
    const filterable = props.filterable === 'true' || props.filterable === true
    const enableAnimations = props.enable_animations === 'true' || props.enable_animations === true
    const currencySymbol = props.currency_symbol || '$'
    
    return `# In your Rails controller:
# @products = [
#   { id: 1, name: "Basic Tee", image_url: "...", color: "Black", price: 35 },
#   { id: 2, name: "Premium Hoodie", image_url: "...", color: "Navy", price: 89 }
# ]

<%= swift_ui do
  enhanced_product_list(products: @products, title: "${title}")
    .grid_columns(:${columns})
    .sortable(${sortable})
    .filterable(${filterable})
    .animated(${enableAnimations})
    .currency("${currencySymbol}")
    .hover_scale("${props.hover_scale || '105'}")
    .quick_actions(${props.show_quick_actions !== 'false'})
end %>

# With slots for complete customization:
<%= swift_ui do
  enhanced_product_list(products: @products) do |component|
    
    # Custom header slot
    component.with_header do
      vstack(spacing: 8) do
        text("${title}")
          .font_size("3xl")
          .font_weight("bold")
          .text_color("gray-900")
        
        text("Discover our handpicked selection")
          .font_size("lg")
          .text_color("gray-600")
      end
    end
    
    # Custom product card slot
    component.with_product_card do |product:, index:|
      card(elevation: 2) do
        vstack(spacing: 12) do
          # Product image
          image(product[:image_url])
            .corner_radius("lg")
            .aspect_ratio("square")
          
          # Product details
          vstack(spacing: 4) do
            text(product[:name])
              .font_weight("semibold")
              .text_color("gray-900")
            
            text(product[:color])
              .font_size("sm")
              .text_color("gray-500")
            
            text("${currencySymbol}#{product[:price]}")
              .font_weight("bold")
              .text_color("blue-600")
          end
          
          # Action buttons
          hstack(spacing: 8) do
            button("Quick View")
              .button_style(:secondary)
              .button_size(:sm)
              .on_tap { |product_id| quick_view(product_id) }
            
            button("Add to Cart")
              .button_style(:primary)
              .button_size(:sm)
              .on_tap { |product_id| add_to_cart(product_id) }
          end
        end
      end
      .padding(16)
      .background("white")
      .hover_scale("105")
      .animation
    end
    
    # Custom filters slot
    component.with_filters do
      hstack(spacing: 16) do
        # Sort controls
        vstack(alignment: :start, spacing: 4) do
          label("Sort by:")
            .font_size("sm")
            .font_weight("medium")
          
          # Custom sort dropdown would go here
        end
        
        # Filter controls  
        vstack(alignment: :start, spacing: 4) do
          label("Filter by color:")
            .font_size("sm")
            .font_weight("medium")
          
          hstack(spacing: 8) do
            button("All").filter_button
            button("Black").filter_button
            button("Navy").filter_button
            button("Indigo").filter_button
          end
        end
      end
      .padding(16)
      .background("gray-50")
      .corner_radius("lg")
    end
    
    # Custom empty state slot
    component.with_empty_state do
      vstack(spacing: 16) do
        text("🛍️")
          .font_size("6xl")
        
        text("No products found")
          .font_size("xl")
          .font_weight("semibold")
          .text_color("gray-900")
        
        text("Try adjusting your filters")
          .text_color("gray-500")
        
        button("Browse All Products")
          .button_style(:primary)
          .on_tap { navigate_to(products_path) }
      end
      .padding_vertical(64)
      .text_align("center")
    end
    
  end
end %>`
  }

  generateProductLayoutSimpleDSL(props) {
    // Since product_layout_simple doesn't have interactive controls,
    // we'll show the full DSL pattern with the dsl_product_card method
    return `# Product Layout using pure SwiftUI Rails DSL
    
# Sample products data:
@products = [
  { name: "Basic Tee", variant: "Black", price: 35, 
    image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/product-page-01-related-product-04.jpg" },
  { name: "Nomad Tumbler", variant: "White", price: 35,
    image: "https://tailwindcss.com/plus-assets/img/ecommerce-images/category-page-04-image-card-02.jpg" }
]

<%= swift_ui do
  section.bg("gray-50").min_h("screen") do
    div.max_w("7xl").mx("auto").px(4).py(8) do
      # Header section
      hstack(alignment: :center).mb(8) do
        vstack(alignment: :start, spacing: 2) do
          text("Product Catalog")
            .text_size("3xl")
            .font_weight("bold")
            .text_color("gray-900")
          
          text("#{@products.count} items")
            .text_size("base")
            .text_color("gray-600")
        end
        spacer
      end
      
      # Product grid with DSL cards
      grid(columns: 3, spacing: 6) do
        @products.each do |product|
          # Using the reusable dsl_product_card method
          dsl_product_card(
            name: product[:name],
            price: product[:price],
            image_url: product[:image],
            variant: product[:variant],
            currency: "$",
            show_cta: true,
            cta_text: "Add to Cart",
            cta_style: "primary"
          )
        end
      end
    end
  end
end %>

# Alternative: Create product cards manually with full DSL control
<%= swift_ui do
  grid(columns: 2, spacing: 4) do
    @products.each do |product|
      card do
        # Product image
        div.aspect("square").overflow("hidden").rounded("md").bg("gray-200") do
          image(src: product[:image], alt: product[:name])
            .w("full").h("full").object_fit("cover")
            .hover_scale(105).transition.duration(300)
        end
        
        # Product details
        vstack(spacing: 2, alignment: :start) do
          text(product[:name])
            .font_weight("semibold")
            .text_color("gray-900")
            .text_size("lg")
            .line_clamp(1)
          
          text(product[:variant])
            .text_color("gray-600")
            .text_size("sm")
          
          text("$#{product[:price]}")
            .font_weight("bold")
            .text_color("gray-900")
            .text_size("xl")
            .mt(2)
        end.mt(4)
        
        # CTA Button
        button("Add to Cart")
          .w("full").mt(4).px(4).py(2)
          .bg("black").text_color("white")
          .rounded("md").font_weight("medium")
          .hover("bg-gray-800").transition
      end
      .p(6).bg("white").rounded("lg")
      .shadow("md").overflow("hidden")
    end
  end
end %>`
  }

  generateFullButtonDSL(props) {
    const title = props.title || 'Click Me'
    const variant = props.variant || 'primary'
    const size = props.size || 'md'
    
    return `<%= swift_ui do
  vstack(spacing: 16) do
    
    # Basic button
    button("${title}")
      .button_style(:${variant})
      .button_size(:${size})
      ${props.background_color && props.background_color.trim() !== '' ? `.background("${props.background_color}")` : ''}
      ${props.text_color && props.text_color.trim() !== '' ? `.foreground_color("${props.text_color}")` : ''}
      ${props.corner_radius && props.corner_radius !== 'md' ? `.corner_radius("${props.corner_radius}")` : ''}
      ${props.padding_x && props.padding_x.trim() !== '' ? `.padding_horizontal(${props.padding_x})` : ''}
      ${props.padding_y && props.padding_y.trim() !== '' ? `.padding_vertical(${props.padding_y})` : ''}
      ${props.font_weight && props.font_weight !== 'medium' ? `.font_weight("${props.font_weight}")` : ''}
      ${props.font_size && props.font_size.trim() !== '' ? `.font_size("${props.font_size}")` : ''}
      .animation
      .focus_ring
      .on_tap { handle_button_click }
    
    # Advanced button with state management
    button("Interactive Button") do |btn|
      btn.title = @button_text || "${title}"
      btn.disabled = @loading
      btn.style = @button_style || :${variant}
    end
      .button_style(:${variant})
      .loading_state(@loading)
      .success_feedback
      .on_tap do |event|
        @loading = true
        # Perform action
        handle_async_action.then do |result|
          @loading = false
          @button_text = "Success!"
          show_success_message(result)
        end
      end
    
    # Button with icon and complex layout
    button do
      hstack(spacing: 8) do
        if @loading
          spinner(size: :sm)
        else
          icon("plus", size: 16)
        end
        
        text(@loading ? "Processing..." : "${title}")
          .font_weight("medium")
      end
    end
      .button_style(:${variant})
      .disabled(@loading)
      .animation
      
  end
end %>

# Button state management in Rails controller:
# @loading = false
# @button_text = "${title}"
# @button_style = :${variant}

# Button action handler:
def handle_button_click
  # Your button logic here
  redirect_to success_path, notice: "Action completed!"
end`
  }

  generateChainableCode(props) {
    // Determine component type and generate appropriate DSL
    const storyName = this.storyValue || ''
    
    if (storyName.includes('card')) {
      return this.generateCardDSLCode(props)
    } else {
      // Default to button for other components
      const title = props.title || 'Click Me'
      let code = `simple_button("${title}")`
      return this.generateButtonChainableCode(code, props)
    }
  }

  generateCardDSLCode(props) {
    const title = props.title || 'Card Title'
    const content = props.content || 'This is a sample card content. Cards are great for organizing related information and creating visual hierarchy.'
    const elevation = props.elevation || 1
    
    // Generate slot-based composition example
    return `# Define reusable DSL component objects
header_content = proc {
  text("${title}")
    .font_size("lg")
    .font_weight("semibold")
    .text_color("gray-900")
}

main_content = proc {
  text("${content}")
    .text_color("gray-600")
    .line_clamp(3)
}

card_actions = [
  proc { 
    button("Primary Action")
      .button_style(:primary)
      .button_size(:sm)
  },
  proc {
    button("Secondary")
      .button_style(:secondary) 
      .button_size(:sm)
  }
]

# Use slot-based composition
card(
  header: header_content,
  content: main_content, 
  actions: card_actions,
  elevation: ${elevation}
)${this.generateCardModifiers(props)}`
  }

  generateCardModifiers(props) {
    const modifiers = []
    
    if (props.background_color && props.background_color !== 'white') {
      modifiers.push(`.background("${props.background_color}")`)
    }
    
    if (props.corner_radius && props.corner_radius !== 'lg') {
      modifiers.push(`.corner_radius("${props.corner_radius}")`)
    }
    
    if (props.padding && props.padding !== '16') {
      modifiers.push(`.padding(${props.padding})`)
    }
    
    if (props.border === 'true' || props.border === true) {
      modifiers.push('.border')
    }
    
    if (props.hover_effect === 'true' || props.hover_effect === true) {
      modifiers.push('.hover_scale("105")')
    }
    
    return modifiers.length > 0 ? '\n' + modifiers.join('\n') : ''
  }

  generateButtonChainableCode(code, props) {
    const modifiers = []
    
    // Handle variant with button_style
    if (props.variant && props.variant !== 'primary') {
      modifiers.push(`.button_style(:${props.variant})`)
    }
    
    // Handle size with button_size  
    if (props.size && props.size !== 'md') {
      modifiers.push(`.button_size(:${props.size})`)
    }
    
    // Handle custom background color
    if (props.background_color && props.background_color.trim() !== '') {
      modifiers.push(`.background("${props.background_color}")`)
    }
    
    // Handle custom text color
    if (props.text_color && props.text_color.trim() !== '') {
      modifiers.push(`.foreground_color("${props.text_color}")`)
    }
    
    // Handle corner radius
    if (props.corner_radius && props.corner_radius !== 'md') {
      modifiers.push(`.corner_radius("${props.corner_radius}")`)
    }
    
    // Handle custom padding
    if (props.padding_x && props.padding_x.trim() !== '') {
      modifiers.push(`.padding_horizontal(${props.padding_x})`)
    }
    if (props.padding_y && props.padding_y.trim() !== '') {
      modifiers.push(`.padding_vertical(${props.padding_y})`)
    }
    
    // Handle font weight
    if (props.font_weight && props.font_weight !== 'medium') {
      switch (props.font_weight) {
        case 'bold':
          modifiers.push('.font_bold')
          break
        case 'semibold':
          modifiers.push('.font_semibold')
          break
        case 'light':
          modifiers.push('.font_light')
          break
        default:
          modifiers.push(`.font_weight("${props.font_weight}")`)
      }
    }
    
    // Handle font size
    if (props.font_size && props.font_size.trim() !== '') {
      modifiers.push(`.font_size("${props.font_size}")`)
    }
    
    // Handle disabled state
    if (props.disabled === 'true' || props.disabled === true) {
      modifiers.push('.disabled')
    }
    
    // Add default modifiers for better styling
    if (modifiers.length === 0 || !modifiers.some(m => m.includes('animation'))) {
      modifiers.push('.animation')
      modifiers.push('.focus_ring')
    }
    
    // Join everything together with proper formatting
    if (modifiers.length > 0) {
      return code + '\n      ' + modifiers.join('\n      ')
    } else {
      return code + '\n      .animation\n      .focus_ring'
    }
  }

  debounce(func, wait) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(func, wait)
  }

  showSuccessMessage(message) {
    this.showNotification(message, 'bg-green-100 text-green-800 border-green-300')
  }

  showErrorMessage(message) {
    this.showNotification(message, 'bg-red-100 text-red-800 border-red-300')
  }

  showInfoMessage(message) {
    this.showNotification(message, 'bg-blue-100 text-blue-800 border-blue-300')
  }

  showNotification(message, classes) {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-3 rounded border z-50 ${classes}`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  // Enhanced helper methods for interactive UI
  
  addControlFeedback(element) {
    // Add pulse animation to show the control was changed
    element.classList.add('ring-2', 'ring-blue-400', 'ring-opacity-50')
    
    setTimeout(() => {
      element.classList.remove('ring-2', 'ring-blue-400', 'ring-opacity-50')
    }, 500)
  }

  updateValueDisplay(fieldName, newValue) {
    // Find the current value display for this field
    const valueDisplay = this.element.querySelector(`[data-field="${fieldName}"] .font-mono`)
    if (valueDisplay) {
      valueDisplay.textContent = `Current: ${JSON.stringify(newValue)}`
      
      // Add highlight animation
      valueDisplay.classList.add('bg-green-200')
      setTimeout(() => {
        valueDisplay.classList.remove('bg-green-200')
        valueDisplay.classList.add('bg-gray-100')
      }, 300)
    }
  }

  updateOptionButtons(field, selectedValue) {
    // Update visual option buttons
    const buttons = this.element.querySelectorAll(`[data-field="${field}"]`)
    buttons.forEach(button => {
      if (button.dataset.value === selectedValue) {
        button.classList.remove('bg-gray-100', 'text-gray-600')
        button.classList.add('bg-blue-100', 'text-blue-800')
      } else {
        button.classList.remove('bg-blue-100', 'text-blue-800')
        button.classList.add('bg-gray-100', 'text-gray-600')
      }
    })
  }



  applySmoothMorphing(streamHTML) {
    // Extract the target element and new content from the Turbo stream
    const tempContainer = document.createElement('div')
    tempContainer.innerHTML = streamHTML
    
    const turboStream = tempContainer.querySelector('turbo-stream')
    if (!turboStream || turboStream.getAttribute('target') !== 'component-preview') {
      // Not our target, use standard Turbo processing
      Turbo.renderStreamMessage(streamHTML)
      return
    }

    const template = turboStream.querySelector('template')
    if (!template) {
      // No template content, use standard processing
      Turbo.renderStreamMessage(streamHTML)
      return
    }

    // Get the target element
    const targetElement = document.getElementById('component-preview')
    if (!targetElement) {
      // Target not found, use standard processing
      Turbo.renderStreamMessage(streamHTML)
      return
    }

    // Apply smooth morphing transition
    this.performSmoothTransition(targetElement, template.innerHTML)
  }

  performSmoothTransition(targetElement, newContent) {
    // Enhanced anti-flash morphing specifically for product cards
    const originalTransition = targetElement.style.transition
    const originalOpacity = targetElement.style.opacity
    
    // Find all product cards in the current content
    const currentProductCards = targetElement.querySelectorAll('[data-enhanced-product-list-target="productCard"]')
    const cardPositions = new Map()
    
    // Store current card positions and content to prevent layout shift
    currentProductCards.forEach((card, index) => {
      const rect = card.getBoundingClientRect()
      const productId = card.dataset.productId
      cardPositions.set(productId, {
        element: card,
        rect: rect,
        index: index,
        content: card.innerHTML
      })
    })
    
    // Apply ultra-smooth transition with minimal visual disturbance
    targetElement.style.transition = 'opacity 0.15s cubic-bezier(0.4, 0, 0.2, 1)'
    targetElement.style.opacity = '0.95'
    
    // Very short transition time to minimize flash
    setTimeout(() => {
      // Store scroll position
      const scrollTop = targetElement.scrollTop
      const scrollLeft = targetElement.scrollLeft
      
      // Temporarily disable all transitions in the container
      targetElement.style.transition = 'none'
      const allElements = targetElement.querySelectorAll('*')
      allElements.forEach(el => {
        el.style.transition = 'none'
      })
      
      // Update content instantly
      targetElement.innerHTML = newContent
      
      // Restore scroll position immediately
      targetElement.scrollTop = scrollTop
      targetElement.scrollLeft = scrollLeft
      
      // Force immediate reflow
      targetElement.offsetHeight
      
      // Re-enable transitions with optimized timing
      requestAnimationFrame(() => {
        // Restore transitions on container
        targetElement.style.transition = 'opacity 0.15s cubic-bezier(0.4, 0, 0.2, 1)'
        targetElement.style.opacity = '1'
        
        // Re-enable transitions on product cards with staggered timing
        const newProductCards = targetElement.querySelectorAll('[data-enhanced-product-list-target="productCard"]')
        newProductCards.forEach((card, index) => {
          // Restore optimized transitions for each card
          setTimeout(() => {
            card.style.transition = 'transform 0.3s ease-out'
            // Re-enable child element transitions
            const cardElements = card.querySelectorAll('*')
            cardElements.forEach(el => {
              el.style.transition = ''
            })
          }, index * 10) // Minimal stagger to prevent flash
        })
        
        // Clean up after animation with faster timing
        setTimeout(() => {
          targetElement.style.transition = originalTransition
          targetElement.style.opacity = originalOpacity
          
          // Ensure all child elements have proper transitions restored
          const allElements = targetElement.querySelectorAll('*')
          allElements.forEach(el => {
            el.style.transition = ''
          })
          
          console.log('✅ Enhanced flash-free transition completed')
        }, 150)
      })
    }, 150) // Reduced from 200ms to 150ms for faster updates
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
}