// Login Dialog Stimulus Controller
// Provides complete interactive behavior for the LoginDialogComponent
//
// Features:
// - Form validation and submission
// - Social login integration
// - Modal management (open/close)
// - Loading states
// - Error handling
// - Progressive enhancement

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", 
    "emailInput", 
    "passwordInput", 
    "rememberInput", 
    "submitButton"
  ]
  
  static values = {
    closeUrl: String,
    loginUrl: String
  }
  
  static classes = [
    "loading",
    "error",
    "success"
  ]
  
  connect() {
    this.isLoading = false
    this.formData = {
      email: '',
      password: '',
      remember_me: false
    }
    
    // Bind keyboard events
    document.addEventListener('keydown', this.handleKeydown.bind(this))
    
    // Prevent body scroll when modal is open
    document.body.style.overflow = 'hidden'
    
    // Focus management
    this.focusFirstInput()
  }
  
  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
    document.body.style.overflow = ''
  }
  
  // Form data management
  updateFormData(event) {
    const input = event.target
    const field = this.getFieldName(input)
    
    if (input.type === 'checkbox') {
      this.formData[field] = input.checked
    } else {
      this.formData[field] = input.value
    }
    
    this.validateForm()
    this.updateSubmitButton()
  }
  
  // Form validation
  validateForm() {
    const errors = {}
    
    // Email validation
    if (!this.formData.email) {
      errors.email = ['Email is required']
    } else if (!this.isValidEmail(this.formData.email)) {
      errors.email = ['Please enter a valid email address']
    }
    
    // Password validation
    if (!this.formData.password) {
      errors.password = ['Password is required']
    } else if (this.formData.password.length < 6) {
      errors.password = ['Password must be at least 6 characters']
    }
    
    this.errors = errors
    this.displayErrors(errors)
    
    return Object.keys(errors).length === 0
  }
  
  // Form submission
  async submitForm(event) {
    event.preventDefault()
    
    if (this.isLoading) return
    
    // Validate form
    if (!this.validateForm()) {
      this.focusFirstError()
      return
    }
    
    this.setLoading(true)
    
    try {
      const response = await this.performLogin()
      
      if (response.ok) {
        this.handleLoginSuccess(response)
      } else {
        const errorData = await response.json()
        this.handleLoginError(errorData)
      }
    } catch (error) {
      this.handleNetworkError(error)
    } finally {
      this.setLoading(false)
    }
  }
  
  // Social login
  async socialLogin(event) {
    const provider = event.params.provider
    
    if (this.isLoading) return
    
    this.setLoading(true)
    
    try {
      // Redirect to social login URL
      window.location.href = `/auth/${provider}`
    } catch (error) {
      console.error('Social login error:', error)
      this.setLoading(false)
    }
  }
  
  // Modal management
  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    // Animate close
    this.modalTarget.classList.add('animate-fade-out')
    
    setTimeout(() => {
      if (this.closeUrlValue) {
        window.location.href = this.closeUrlValue
      } else {
        this.element.remove()
      }
    }, 200)
  }
  
  closeOnBackdrop(event) {
    // Only close if clicking on the backdrop, not the modal content
    if (event.target === this.element) {
      this.close()
    }
  }
  
  // Loading state management
  setLoading(loading) {
    this.isLoading = loading
    
    if (loading) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = 'Signing in...'
      this.submitButtonTarget.classList.add('opacity-75')
      
      // Add loading spinner
      this.addLoadingSpinner()
    } else {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = 'Sign In'
      this.submitButtonTarget.classList.remove('opacity-75')
      
      // Remove loading spinner
      this.removeLoadingSpinner()
    }
    
    // Update form inputs
    this.targets.find('emailInput', 'passwordInput').forEach(input => {
      input.disabled = loading
    })
  }
  
  // Error handling
  displayErrors(errors) {
    // Clear existing errors
    this.clearErrors()
    
    Object.entries(errors).forEach(([field, messages]) => {
      const input = this.getInputForField(field)
      if (input) {
        // Add error styling
        input.classList.add('border-red-500', 'focus:ring-red-500')
        input.classList.remove('border-gray-300', 'focus:ring-blue-500')
        
        // Add error message
        this.addErrorMessage(input, messages[0])
      }
    })
  }
  
  clearErrors() {
    // Remove error styling from all inputs
    [this.emailInputTarget, this.passwordInputTarget].forEach(input => {
      input.classList.remove('border-red-500', 'focus:ring-red-500')
      input.classList.add('border-gray-300', 'focus:ring-blue-500')
    })
    
    // Remove error messages
    this.element.querySelectorAll('.field-error').forEach(error => {
      error.remove()
    })
  }
  
  // API interaction
  async performLogin() {
    const formData = new FormData()
    formData.append('login[email]', this.formData.email)
    formData.append('login[password]', this.formData.password)
    formData.append('login[remember_me]', this.formData.remember_me)
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      formData.append('authenticity_token', csrfToken)
    }
    
    return fetch(this.loginUrlValue, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
  }
  
  // Success/Error handlers
  handleLoginSuccess(response) {
    // Show success state
    this.submitButtonTarget.textContent = 'Success!'
    this.submitButtonTarget.classList.add('bg-green-600')
    
    setTimeout(() => {
      // Redirect or trigger success action
      if (response.headers.get('Location')) {
        window.location.href = response.headers.get('Location')
      } else {
        // Trigger custom event for parent components
        this.dispatch('loginSuccess', { detail: { response } })
        this.close()
      }
    }, 1000)
  }
  
  handleLoginError(errorData) {
    if (errorData.errors) {
      this.displayErrors(errorData.errors)
      this.focusFirstError()
    } else {
      this.showGeneralError(errorData.message || 'Login failed. Please try again.')
    }
  }
  
  handleNetworkError(error) {
    console.error('Network error:', error)
    this.showGeneralError('Connection error. Please check your internet connection and try again.')
  }
  
  // Helper methods
  getFieldName(input) {
    const name = input.name
    const match = name.match(/login\[(.+)\]/)
    return match ? match[1] : name
  }
  
  getInputForField(field) {
    return this[`${field}InputTarget`]
  }
  
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }
  
  focusFirstInput() {
    if (this.hasEmailInputTarget) {
      this.emailInputTarget.focus()
    }
  }
  
  focusFirstError() {
    const firstErrorInput = this.element.querySelector('input.border-red-500')
    if (firstErrorInput) {
      firstErrorInput.focus()
    }
  }
  
  updateSubmitButton() {
    const isValid = this.formData.email && this.formData.password
    this.submitButtonTarget.disabled = !isValid || this.isLoading
  }
  
  addErrorMessage(input, message) {
    const errorElement = document.createElement('div')
    errorElement.className = 'field-error text-sm text-red-600 mt-1'
    errorElement.textContent = message
    input.parentNode.appendChild(errorElement)
  }
  
  addLoadingSpinner() {
    const spinner = document.createElement('div')
    spinner.className = 'login-spinner inline-block animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2'
    this.submitButtonTarget.prepend(spinner)
  }
  
  removeLoadingSpinner() {
    const spinner = this.submitButtonTarget.querySelector('.login-spinner')
    if (spinner) {
      spinner.remove()
    }
  }
  
  showGeneralError(message) {
    // Create or update general error display
    let errorBanner = this.element.querySelector('.general-error')
    
    if (!errorBanner) {
      errorBanner = document.createElement('div')
      errorBanner.className = 'general-error mb-4 p-4 bg-red-50 border border-red-200 rounded-md'
      
      const modalBody = this.element.querySelector('[data-modal-section="body"]')
      modalBody.prepend(errorBanner)
    }
    
    errorBanner.innerHTML = `
      <div class="flex">
        <div class="text-red-400 mr-2">⚠️</div>
        <div class="text-red-800 text-sm">${message}</div>
      </div>
    `
  }
  
  handleKeydown(event) {
    // Close on Escape key
    if (event.key === 'Escape') {
      this.close()
    }
    
    // Submit on Enter key (if form is valid)
    if (event.key === 'Enter' && !event.shiftKey) {
      const activeElement = document.activeElement
      if (activeElement && (activeElement === this.emailInputTarget || activeElement === this.passwordInputTarget)) {
        event.preventDefault()
        this.submitForm(event)
      }
    }
  }
}