import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "submitButton", "errorMessage"]
  static values = { url: String }
  
  connect() {
    this.validationTimeout = null
    // Safe search pattern - matches the Ruby pattern
    this.safePattern = /^[a-zA-Z0-9\s\-_.,!?'"()]*$/
    this.minLength = 2
    this.maxLength = 255
  }
  
  disconnect() {
    if (this.validationTimeout) {
      clearTimeout(this.validationTimeout)
    }
  }
  
  handleInput() {
    // Clear previous validation timeout
    if (this.validationTimeout) {
      clearTimeout(this.validationTimeout)
    }
    
    // Debounce validation
    this.validationTimeout = setTimeout(() => {
      this.validateInput()
    }, 300)
  }
  
  validateInput() {
    const value = this.inputTarget.value.trim()
    const isValid = this.isValidSearchTerm(value)
    
    // Show/hide error message
    if (this.hasErrorMessageTarget) {
      if (!isValid && value.length > 0) {
        this.errorMessageTarget.classList.remove('hidden')
      } else {
        this.errorMessageTarget.classList.add('hidden')
      }
    }
    
    // Enable/disable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !isValid || value.length < this.minLength
      this.submitButtonTarget.classList.toggle('opacity-50', !isValid)
    }
    
    // Add visual feedback to input
    this.inputTarget.classList.toggle('border-red-500', !isValid && value.length > 0)
    this.inputTarget.classList.toggle('border-green-500', isValid && value.length >= this.minLength)
    
    return isValid
  }
  
  isValidSearchTerm(value) {
    // Check length constraints
    if (value.length > this.maxLength) {
      return false
    }
    
    // Check pattern - only allow safe characters
    if (!this.safePattern.test(value)) {
      return false
    }
    
    // Check for common injection patterns
    if (this.containsSuspiciousPatterns(value)) {
      return false
    }
    
    return true
  }
  
  containsSuspiciousPatterns(value) {
    const suspiciousPatterns = [
      /<script/i,
      /javascript:/i,
      /on\w+\s*=/i,  // Event handlers like onclick=
      /\bselect\b.*\bfrom\b/i,  // SQL SELECT
      /\bunion\b.*\bselect\b/i,  // SQL UNION
      /\binsert\b.*\binto\b/i,  // SQL INSERT
      /\bdelete\b.*\bfrom\b/i,  // SQL DELETE
      /\bdrop\b.*\btable\b/i,  // SQL DROP
      /\bexec\b/i,  // SQL EXEC
      /\{.*\}/,  // Template injection patterns
      /\$\{.*\}/,  // Template literal injection
      /%[0-9a-f]{2}/i,  // URL encoding (potential bypass attempt)
    ]
    
    return suspiciousPatterns.some(pattern => pattern.test(value))
  }
  
  submit(event) {
    event.preventDefault()
    
    const value = this.inputTarget.value.trim()
    
    // Final validation before submission
    if (!this.isValidSearchTerm(value)) {
      console.warn('Search submission blocked: invalid search term')
      this.shake()
      return
    }
    
    if (value.length < this.minLength) {
      console.warn('Search submission blocked: term too short')
      this.shake()
      return
    }
    
    // Sanitize the value before submission
    const sanitizedValue = this.sanitizeSearchTerm(value)
    this.inputTarget.value = sanitizedValue
    
    // Submit the form
    const form = this.element
    const formData = new FormData(form)
    
    // Log for security monitoring
    console.log('Search submitted:', { 
      original: value, 
      sanitized: sanitizedValue,
      length: sanitizedValue.length 
    })
    
    // Redirect to search URL with sanitized query
    const searchUrl = new URL(this.urlValue, window.location.origin)
    searchUrl.searchParams.set('q', sanitizedValue)
    window.location.href = searchUrl.toString()
  }
  
  sanitizeSearchTerm(value) {
    return value
      // Remove any HTML tags
      .replace(/<[^>]*>/g, '')
      // Remove any script content
      .replace(/javascript:/gi, '')
      // Remove event handlers
      .replace(/on\w+\s*=/gi, '')
      // Normalize whitespace
      .replace(/\s+/g, ' ')
      // Trim
      .trim()
      // Limit length as final safeguard
      .substring(0, this.maxLength)
  }
  
  shake() {
    this.inputTarget.style.animation = 'shake 0.5s ease-in-out'
    setTimeout(() => {
      this.inputTarget.style.animation = ''
    }, 500)
  }
}