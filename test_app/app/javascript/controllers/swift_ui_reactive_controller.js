import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// SwiftUI Rails reactive state management
export default class extends Controller {
  static values = {
    componentId: String,
    componentClass: String,
    updateUrl: String,
    props: Object,
    stateFingerprint: String,
    debounce: { type: Number, default: 100 }
  }
  
  static targets = ["content"]
  
  connect() {
    this.setupStateTracking()
    this.setupBindings()
    this.setupObservers()
    this.subscribeToUpdates()
    
    // Register globally for coordination
    this.registerComponent()
  }
  
  disconnect() {
    // Clean up observers
    if (this.stateObserver) {
      this.stateObserver.disconnect()
    }
    
    // Clean up event listeners
    this.cleanupBindings()
    
    this.unsubscribeFromUpdates()
    this.unregisterComponent()
  }
  
  setupStateTracking() {
    // Track state changes via MutationObserver
    this.stateObserver = new MutationObserver((mutations) => {
      this.handleStateMutations(mutations)
    })
    
    this.stateObserver.observe(this.element, {
      attributes: true,
      attributeFilter: ['data-state-changes', 'data-binding-changes', 'data-observed-changes'],
      subtree: true
    })
  }
  
  setupBindings() {
    // Store event listeners for cleanup
    this.bindingListeners = new Map()
    
    // Two-way binding for form elements
    this.element.querySelectorAll('[data-binding]').forEach(element => {
      const bindingName = element.dataset.binding
      
      // Create and store listener
      const listener = (event) => {
        this.updateBinding(bindingName, event.target.value)
      }
      
      element.addEventListener('input', listener)
      this.bindingListeners.set(element, { event: 'input', listener })
      
      // Handle different input types
      if (element.type === 'checkbox') {
        const checkboxListener = (event) => {
          this.updateBinding(bindingName, event.target.checked)
        }
        element.addEventListener('change', checkboxListener)
        this.bindingListeners.set(element, { event: 'change', listener: checkboxListener })
      } else if (element.tagName === 'SELECT') {
        const selectListener = (event) => {
          this.updateBinding(bindingName, event.target.value)
        }
        element.addEventListener('change', selectListener)
        this.bindingListeners.set(element, { event: 'change', listener: selectListener })
      }
    })
  }
  
  setupObservers() {
    // Setup observers for @ObservedObject stores
    const observedStores = this.element.dataset.observedStores
    if (observedStores) {
      JSON.parse(observedStores).forEach(storeName => {
        this.observeStore(storeName)
      })
    }
  }
  
  handleStateMutations(mutations) {
    const changes = {}
    
    mutations.forEach(mutation => {
      const target = mutation.target
      
      // Parse state changes
      if (mutation.attributeName === 'data-state-changes') {
        const stateChanges = JSON.parse(target.dataset.stateChanges || '[]')
        stateChanges.forEach(change => {
          changes[`state.${change.name}`] = change
        })
      }
      
      // Parse binding changes
      if (mutation.attributeName === 'data-binding-changes') {
        const bindingChanges = JSON.parse(target.dataset.bindingChanges || '[]')
        bindingChanges.forEach(change => {
          changes[`binding.${change.name}`] = change
        })
      }
      
      // Parse observed object changes
      if (mutation.attributeName === 'data-observed-changes') {
        const observedChanges = JSON.parse(target.dataset.observedChanges || '{}')
        Object.entries(observedChanges).forEach(([store, storeChanges]) => {
          Object.entries(storeChanges).forEach(([key, change]) => {
            changes[`observed.${store}.${key}`] = change
          })
        })
      }
    })
    
    if (Object.keys(changes).length > 0) {
      this.scheduleUpdate(changes)
    }
  }
  
  updateBinding(name, value) {
    // Update binding value
    const bindingData = {
      name: name,
      value: value,
      timestamp: Date.now()
    }
    
    // Dispatch custom event for other components
    this.dispatch('binding-change', {
      detail: bindingData,
      bubbles: true
    })
    
    // Schedule component update
    this.scheduleUpdate({ [`binding.${name}`]: { new: value } })
  }
  
  observeStore(storeName) {
    // Subscribe to store changes via ActionCable
    if (!this.storeSubscriptions) {
      this.storeSubscriptions = {}
    }
    
    this.storeSubscriptions[storeName] = true
  }
  
  scheduleUpdate(changes) {
    // Debounce updates
    clearTimeout(this.updateTimer)
    
    this.pendingChanges = {
      ...this.pendingChanges,
      ...changes
    }
    
    this.updateTimer = setTimeout(() => {
      this.performUpdate()
    }, this.debounceValue)
  }
  
  async performUpdate() {
    const changes = this.pendingChanges
    this.pendingChanges = {}
    
    try {
      // Check if we need to update
      const newFingerprint = await this.calculateFingerprint()
      if (newFingerprint === this.stateFingerprintValue) {
        return // No changes needed
      }
      
      // Prepare update data
      const updateData = {
        component_id: this.componentIdValue,
        component_class: this.componentClassValue,
        props: this.propsValue,
        changes: changes,
        fingerprint: this.stateFingerprintValue
      }
      
      // Perform update via fetch or Turbo
      const response = await fetch(this.updateUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html, application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify(updateData)
      })
      
      if (response.ok) {
        const contentType = response.headers.get('content-type')
        
        if (contentType.includes('turbo-stream')) {
          // Let Turbo handle the stream
          const text = await response.text()
          Turbo.renderStreamMessage(text)
        } else {
          // Handle JSON response
          const data = await response.json()
          this.updateComponent(data.html)
          this.stateFingerprintValue = data.state_fingerprint
        }
      }
    } catch (error) {
      console.error('Failed to update component:', error)
      this.handleUpdateError(error)
    }
  }
  
  updateComponent(html) {
    // Use morphdom or similar for smooth updates
    if (window.morphdom) {
      morphdom(this.element, html, {
        childrenOnly: true,
        onBeforeElUpdated: (fromEl, toEl) => {
          // Preserve focus
          if (fromEl === document.activeElement) {
            return false
          }
          return true
        }
      })
    } else {
      // Fallback to innerHTML
      this.element.innerHTML = html
    }
    
    // Re-setup after update
    this.setupBindings()
    this.setupObservers()
  }
  
  subscribeToUpdates() {
    // Subscribe to ActionCable for real-time updates
    if (!this.consumer) {
      this.consumer = createConsumer()
    }
    
    this.channel = this.consumer.subscriptions.create(
      {
        channel: "SwiftUIRails::Reactive::ReactiveChannel",
        component_id: this.componentIdValue
      },
      {
        received: (data) => {
          this.handleChannelUpdate(data)
        }
      }
    )
  }
  
  unsubscribeFromUpdates() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }
  
  handleChannelUpdate(data) {
    if (data.action === 'update') {
      // External update received
      this.performUpdate()
    }
  }
  
  handleUpdateError(error) {
    // Show error in development
    if (this.isDevelopment()) {
      console.error('SwiftUI Reactive Update Error:', error)
      
      // Dispatch error event
      this.dispatch('update-error', {
        detail: { error, componentId: this.componentIdValue }
      })
    }
  }
  
  async calculateFingerprint() {
    // Calculate current state fingerprint
    const state = {
      props: this.propsValue,
      bindings: this.collectBindings(),
      observed: this.collectObservedData()
    }
    
    const text = JSON.stringify(state)
    const encoder = new TextEncoder()
    const data = encoder.encode(text)
    const hashBuffer = await crypto.subtle.digest('SHA-256', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  }
  
  collectBindings() {
    const bindings = {}
    
    this.element.querySelectorAll('[data-binding]').forEach(element => {
      const name = element.dataset.binding
      bindings[name] = element.value || element.checked
    })
    
    return bindings
  }
  
  collectObservedData() {
    // This would collect data from observed stores
    return {}
  }
  
  registerComponent() {
    // Register with global tracker
    if (!window.SwiftUIReactive) {
      window.SwiftUIReactive = {
        components: new Map(),
        register(element, config) {
          this.components.set(config.component_id, { element, config })
        },
        unregister(componentId) {
          this.components.delete(componentId)
        },
        updateStore(storeName, changes) {
          // Notify all components observing this store
          this.components.forEach(({ element, config }) => {
            const controller = element._swiftUIReactiveController
            if (controller && controller.storeSubscriptions?.[storeName]) {
              controller.handleStoreUpdate(storeName, changes)
            }
          })
        }
      }
    }
    
    window.SwiftUIReactive.register(this.element, {
      component_id: this.componentIdValue,
      component_class: this.componentClassValue
    })
    
    // Store reference on element
    this.element._swiftUIReactiveController = this
  }
  
  unregisterComponent() {
    if (window.SwiftUIReactive) {
      window.SwiftUIReactive.unregister(this.componentIdValue)
    }
    delete this.element._swiftUIReactiveController
  }
  
  handleStoreUpdate(storeName, changes) {
    // Handle updates from observed stores
    const storeChanges = {}
    Object.entries(changes).forEach(([key, change]) => {
      storeChanges[`observed.${storeName}.${key}`] = change
    })
    
    this.scheduleUpdate(storeChanges)
  }
  
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
  
  cleanupBindings() {
    // Remove all stored event listeners
    if (this.bindingListeners) {
      this.bindingListeners.forEach((info, element) => {
        element.removeEventListener(info.event, info.listener)
      })
      this.bindingListeners.clear()
    }
  }
  
  isDevelopment() {
    return document.querySelector('meta[name="rails-env"]')?.content === 'development'
  }
}