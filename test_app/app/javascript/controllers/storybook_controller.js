import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Connects to data-controller="storybook"
export default class extends Controller {
  static targets = ["form", "preview", "controls"]
  static values = { 
    updateUrl: String,
    story: String,
    variant: String
  }

  connect() {
    console.log("Storybook controller connected")
    this.setupAutoUpdate()
  }

  setupAutoUpdate() {
    // Find all form inputs and add event listeners
    const inputs = this.formTarget.querySelectorAll('input[type="text"], select, input[type="checkbox"]')
    
    inputs.forEach(input => {
      if (input.type === 'checkbox') {
        input.addEventListener('change', () => this.updatePreview())
      } else {
        // Debounce text inputs
        let timeout
        input.addEventListener('input', () => {
          clearTimeout(timeout)
          timeout = setTimeout(() => this.updatePreview(), 300)
        })
        // Immediate update for selects
        if (input.tagName === 'SELECT') {
          input.addEventListener('change', () => this.updatePreview())
        }
      }
    })
  }

  updatePreview() {
    // Add loading state
    const previewContainer = document.getElementById('component-preview')
    if (previewContainer) {
      previewContainer.classList.add('opacity-50', 'scale-95')
    }
    
    const formData = new FormData(this.formTarget)
    const params = new URLSearchParams(formData)
    
    // Add story and variant to params
    params.set('story', this.storyValue)
    params.set('story_variant', this.variantValue)
    
    const url = `${this.updateUrlValue}?${params.toString()}`
    
    // Use Turbo to fetch and update only the preview area
    fetch(url, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html, text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // If it's a turbo stream response, let Turbo handle it
      if (html.includes('turbo-stream')) {
        Turbo.renderStreamMessage(html)
      } else {
        // Otherwise, update the preview area manually
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const newPreview = doc.querySelector('[data-storybook-target="preview"]')
        if (newPreview && this.previewTarget) {
          // Use Turbo's morphing for smooth updates
          Turbo.morph(this.previewTarget, newPreview.innerHTML)
        }
      }
      
      // Remove loading state with a slight delay for smooth transition
      setTimeout(() => {
        if (previewContainer) {
          previewContainer.classList.remove('opacity-50', 'scale-95')
        }
        
        // Show update indicator
        const indicator = document.getElementById('update-indicator')
        if (indicator) {
          indicator.classList.remove('opacity-0')
          indicator.classList.add('opacity-100')
          setTimeout(() => {
            indicator.classList.remove('opacity-100')
            indicator.classList.add('opacity-0')
          }, 1000)
        }
      }, 100)
    })
    .catch(error => {
      console.error('Error updating preview:', error)
      // Remove loading state on error too
      if (previewContainer) {
        previewContainer.classList.remove('opacity-50', 'scale-95')
      }
    })
  }

  // Handle variant link clicks
  changeVariant(event) {
    event.preventDefault()
    const variant = event.currentTarget.dataset.variant
    this.variantValue = variant
    
    // Update active state on variant links
    this.element.querySelectorAll('[data-variant]').forEach(link => {
      if (link.dataset.variant === variant) {
        link.classList.add('bg-blue-100', 'text-blue-700', 'font-medium')
        link.classList.remove('text-gray-700', 'hover:bg-gray-100')
      } else {
        link.classList.remove('bg-blue-100', 'text-blue-700', 'font-medium')
        link.classList.add('text-gray-700', 'hover:bg-gray-100')
      }
    })
    
    this.updatePreview()
  }
}