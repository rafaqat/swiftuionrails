import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="login-dialog"
export default class extends Controller {
  static targets = [
    "modal", "form", "emailInput", "passwordInput", "rememberInput", "submitButton",
    "emailError", "passwordError", "emailIcon", "emailSuccessIcon", "errorBanner",
    "passwordStrength", "strengthText", "strengthBar", "strengthIndicator", "requirements",
    "requirementLengthIcon", "requirementSpecialIcon", "requirementNumberIcon",
    "requirementRepeatingIcon", "requirementSequentialIcon"
  ]
  
  static values = {
    closeUrl: String,
    loginUrl: String
  }
  
  connect() {
    this.isSubmitting = false
    this.validationState = {
      email: false,
      password: false
    }
    
    // Form data storage
    this.formData = {
      email: '',
      password: '',
      remember_me: false
    }
    
    // Password requirements state
    this.passwordRequirements = {
      length: false,
      special: false,
      number: false,
      repeating: false,
      sequential: false
    }
    
    // Common passwords list (simplified)
    this.commonPasswords = [
      'password', '123456', '123456789', 'password123', 'admin',
      'qwerty', 'letmein', 'welcome', 'monkey', '1234567890'
    ]
    
    // Set up escape key listener
    this.boundEscapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
    
    // Focus email input and trigger initial validation
    if (this.hasEmailInputTarget) {
      setTimeout(() => {
        this.emailInputTarget.focus()
        // If there's a pre-filled value, trigger validation
        if (this.emailInputTarget.value) {
          this.validateEmail()
        }
      }, 100)
    }
    
    // If password has pre-filled value, trigger validation
    if (this.hasPasswordInputTarget && this.passwordInputTarget.value) {
      setTimeout(() => {
        this.validatePassword()
      }, 100)
    }
    
    // Show password requirements on password focus
    if (this.hasPasswordInputTarget && this.hasRequirementsTarget) {
      this.passwordInputTarget.addEventListener('focus', () => {
        this.requirementsTarget.style.display = 'block'
      })
    }
    
    // Prevent body scroll - use multiple methods for cross-browser compatibility
    document.body.style.overflow = 'hidden'
    document.body.classList.add('overflow-hidden')
    document.documentElement.style.overflow = 'hidden'
    document.documentElement.classList.add('overflow-hidden')
  }
  
  disconnect() {
    document.removeEventListener("keydown", this.boundEscapeHandler)
    // Restore body scroll - use multiple methods for cross-browser compatibility
    document.body.style.overflow = ''
    document.body.classList.remove('overflow-hidden')
    document.documentElement.style.overflow = ''
    document.documentElement.classList.remove('overflow-hidden')
  }
  
  // Modal control methods
  close() {
    // Restore body scroll before navigation - use multiple methods for cross-browser compatibility
    document.body.style.overflow = ''
    document.body.classList.remove('overflow-hidden')
    document.documentElement.style.overflow = ''
    document.documentElement.classList.remove('overflow-hidden')
    
    // Always navigate to the close URL if provided, or clean up current URL
    if (this.closeUrlValue) {
      // Use timeout for mobile devices to ensure scroll restoration completes
      setTimeout(() => {
        window.location.href = this.closeUrlValue
      }, 10)
    } else {
      // Fallback: navigate to current path without query params to ensure clean URL
      const currentPath = window.location.pathname
      // Use history.pushState for immediate URL update, then navigate
      history.pushState({}, '', currentPath)
      setTimeout(() => {
        window.location.href = currentPath
      }, 10)
    }
  }
  
  closeOnBackdrop(event) {
    // Close if clicking on the backdrop or outside the modal content
    if (event.target === event.currentTarget || 
        !this.hasModalTarget || 
        !this.modalTarget.contains(event.target)) {
      if (typeof event.preventDefault === 'function') {
        event.preventDefault()
      }
      this.close()
    }
  }
  
  stopPropagation(event) {
    event.stopPropagation()
  }
  
  handleEscape(event) {
    if (event.key === 'Escape') {
      event.preventDefault()
      this.close()
    }
  }
  
  // Form validation
  isValidEmail(email) {
    return email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  }

  validateEmail(event) {
    const email = event ? event.target.value.trim() : this.emailInputTarget.value.trim()
    const isValid = email.length > 0 && this.isValidEmail(email)
    
    this.validationState.email = isValid
    
    // Show/hide email error
    if (this.hasEmailErrorTarget) {
      if (!isValid) {
        this.emailErrorTarget.classList.remove('hidden')
        if (email.length === 0) {
          this.emailErrorTarget.textContent = 'Email address is required'
        } else {
          this.emailErrorTarget.textContent = 'Please enter a valid email address'
        }
      } else {
        this.emailErrorTarget.classList.add('hidden')
      }
    }
    
    this.updateSubmitButton()
    return isValid
  }
  
  checkPasswordLength(password) {
    return password.length >= 8
  }

  checkPasswordSpecialChar(password) {
    return /[!@#$%^&*(),.?":{}|<>]/.test(password)
  }

  checkPasswordNumber(password) {
    return /\d/.test(password)
  }

  checkPasswordRepeating(password) {
    return !this.hasRepeatingCharacters(password)
  }

  checkPasswordSequential(password) {
    return !this.hasSequentialCharacters(password)
  }

  validatePassword(event) {
    const password = event ? event.target.value : this.passwordInputTarget.value
    
    // Check individual requirements
    this.passwordRequirements.length = this.checkPasswordLength(password)
    this.passwordRequirements.special = this.checkPasswordSpecialChar(password)
    this.passwordRequirements.number = this.checkPasswordNumber(password)
    this.passwordRequirements.repeating = this.checkPasswordRepeating(password)
    this.passwordRequirements.sequential = this.checkPasswordSequential(password)
    
    // Check for common passwords
    const isCommonPassword = this.commonPasswords.includes(password.toLowerCase())
    
    // Update requirement icons
    this.updateRequirementIcon('requirementLengthIcon', this.passwordRequirements.length)
    this.updateRequirementIcon('requirementSpecialIcon', this.passwordRequirements.special)
    this.updateRequirementIcon('requirementNumberIcon', this.passwordRequirements.number)
    this.updateRequirementIcon('requirementRepeatingIcon', this.passwordRequirements.repeating)
    this.updateRequirementIcon('requirementSequentialIcon', this.passwordRequirements.sequential)
    
    // Calculate password strength
    const strength = this.calculatePasswordStrength(password)
    this.updatePasswordStrength(strength)
    
    // For basic validation, only require core requirements (length, special, number)
    // Allow some repeating/sequential for user convenience, but still show warnings
    const coreRequirements = [
      this.passwordRequirements.length,
      this.passwordRequirements.special, 
      this.passwordRequirements.number
    ]
    const isValid = password.length > 0 && coreRequirements.every(req => req)
    this.validationState.password = isValid
    
    // Show/hide password error
    if (this.hasPasswordErrorTarget) {
      if (!isValid) {
        let errorMsg = ''
        if (password.length === 0) {
          errorMsg = 'Password required'
        } else if (!this.passwordRequirements.length) {
          errorMsg = 'Password must be at least 8 characters long'
        } else if (!this.passwordRequirements.special) {
          errorMsg = 'Password must contain at least one special character'
        } else if (!this.passwordRequirements.number) {
          errorMsg = 'Password must contain at least one number'
        }
        this.passwordErrorTarget.classList.remove('hidden')
        this.passwordErrorTarget.textContent = errorMsg
      } else {
        this.passwordErrorTarget.classList.add('hidden')
      }
    }
    
    this.updateSubmitButton()
    return isValid
  }
  
  updateFormData(event) {
    if (!event || !event.target) return
    
    const { name, value, type, checked } = event.target
    
    // Extract field name from login[field_name] format
    const fieldMatch = name.match(/login\[([^\]]+)\]/)
    if (fieldMatch) {
      const fieldName = fieldMatch[1]
      if (!this.formData) this.formData = {}
      
      if (type === 'checkbox') {
        this.formData[fieldName] = checked
      } else {
        this.formData[fieldName] = value
      }
    }
    
    // Trigger validation for the field that was updated
    if (name === 'login[email]') {
      this.validateEmail(event)
    } else if (name === 'login[password]') {
      this.validatePassword(event)
    }
  }

  isFormValid() {
    return this.validationState.email && this.validationState.password
  }

  displayError(message) {
    if (this.hasErrorBannerTarget) {
      this.errorBannerTarget.classList.remove('hidden')
      this.errorBannerTarget.textContent = message
    }
  }

  hideErrors() {
    if (this.hasErrorBannerTarget) {
      this.errorBannerTarget.classList.add('hidden')
    }
    if (this.hasEmailErrorTarget) {
      this.emailErrorTarget.classList.add('hidden')
    }
    if (this.hasPasswordErrorTarget) {
      this.passwordErrorTarget.classList.add('hidden')
    }
  }
  
  updateSubmitButton() {
    const allValid = this.validationState.email && this.validationState.password
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !allValid || this.isSubmitting
      this.submitButtonTarget.classList.toggle('opacity-50', !allValid || this.isSubmitting)
      this.submitButtonTarget.classList.toggle('cursor-not-allowed', !allValid || this.isSubmitting)
      
      // Ensure button can receive focus when enabled
      if (this.hasSubmitButtonTarget && typeof this.submitButtonTarget.setAttribute === 'function') {
        if (allValid && !this.isSubmitting) {
          this.submitButtonTarget.removeAttribute('tabindex')
          this.submitButtonTarget.style.pointerEvents = 'auto'
        } else {
          this.submitButtonTarget.setAttribute('tabindex', '-1')
          this.submitButtonTarget.style.pointerEvents = 'none'
        }
      }
      
      if (this.isSubmitting) {
        this.submitButtonTarget.textContent = 'Signing In...'
      } else {
        this.submitButtonTarget.textContent = 'Sign In'
      }
    }
  }
  
  // Password validation helpers
  hasRepeatingCharacters(password) {
    for (let i = 0; i < password.length - 2; i++) {
      if (password[i] === password[i + 1] && password[i] === password[i + 2]) {
        return true
      }
    }
    return false
  }
  
  hasSequentialCharacters(password) {
    const lower = password.toLowerCase()
    
    // Check for 3+ character sequences
    for (let i = 0; i < lower.length - 2; i++) {
      const char1 = lower.charCodeAt(i)
      const char2 = lower.charCodeAt(i + 1) 
      const char3 = lower.charCodeAt(i + 2)
      // Check for ascending or descending sequences
      if ((char2 === char1 + 1 && char3 === char2 + 1) || 
          (char2 === char1 - 1 && char3 === char2 - 1)) {
        return true
      }
    }
    return false
  }
  
  calculatePasswordStrength(password) {
    let score = 0
    
    // Must meet minimum length first
    if (password.length < 3) return 0
    
    // Length bonus
    if (password.length >= 8) score += 1
    if (password.length >= 12) score += 1
    
    // Character variety
    if (/[a-z]/.test(password)) score += 1
    if (/[A-Z]/.test(password)) score += 1
    if (/\d/.test(password)) score += 1
    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) score += 1
    
    // Penalties - but allow common passwords to still have some score
    if (this.hasRepeatingCharacters(password)) score -= 1
    if (this.hasSequentialCharacters(password)) score -= 1
    if (this.commonPasswords.includes(password.toLowerCase())) score -= 1 // Changed from -2 to -1
    
    return Math.max(0, Math.min(5, score))
  }
  
  updatePasswordStrength(strength) {
    if (!this.hasPasswordStrengthTarget) return
    
    const strengthText = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong', 'Very Strong'][strength]
    const strengthColors = ['#dc2626', '#ea580c', '#ca8a04', '#65a30d', '#16a34a', '#059669']
    const strengthWidths = ['10%', '20%', '40%', '60%', '80%', '100%']
    
    if (this.hasStrengthTextTarget) {
      this.strengthTextTarget.textContent = strengthText
      this.strengthTextTarget.style.color = strengthColors[strength]
    }
    
    if (this.hasStrengthBarTarget) {
      this.strengthBarTarget.style.width = strengthWidths[strength]
      this.strengthBarTarget.style.background = strengthColors[strength]
    }
  }
  
  updateRequirementIcon(targetName, isValid) {
    const target = this[targetName + 'Target']
    if (!target) return
    
    if (isValid) {
      target.style.background = '#16a34a' // green
      target.classList.remove('bg-gray-300')
      target.classList.add('bg-green-500')
    } else {
      target.style.background = '#d1d5db' // gray
      target.classList.remove('bg-green-500')
      target.classList.add('bg-gray-300')
    }
  }
  
  // Social login
  socialLogin(event) {
    const provider = event.target.dataset.loginDialogProviderParam
    console.log('Social login with:', provider)
    // Implement social login logic here
  }
  
  // Form submission
  async submitForm(event) {
    event.preventDefault()
    
    if (this.isSubmitting) {
      return
    }
    
    // Validate all fields
    const emailValid = this.validateEmail()
    const passwordValid = this.validatePassword()
    
    if (!this.isFormValid()) {
      this.shake()
      return
    }
    
    this.setLoading(true)
    
    try {
      const formData = new FormData()
      formData.append("login[email]", this.emailInputTarget.value)
      formData.append("login[password]", this.passwordInputTarget.value)
      
      if (this.hasRememberInputTarget) {
        formData.append("login[remember_me]", this.rememberInputTarget.checked)
      }
      
      // Add CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]')
      if (csrfToken) {
        formData.append("authenticity_token", csrfToken.content)
      }
      
      const response = await fetch(this.loginUrlValue, {
        method: "POST",
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "Accept": "application/json"
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.handleSuccess(data)
      } else {
        const errorData = await response.json()
        this.handleError(errorData)
      }
    } catch (error) {
      console.error("Login error:", error)
      this.handleError({ 
        errors: { 
          base: ["Network error. Please check your connection and try again."] 
        } 
      })
    } finally {
      this.setLoading(false)
    }
  }
  
  setLoading(loading) {
    this.isSubmitting = loading
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = loading
      this.submitButtonTarget.textContent = loading ? 'Signing In...' : 'Sign In'
      this.submitButtonTarget.classList.toggle('opacity-50', loading)
      this.submitButtonTarget.classList.toggle('cursor-not-allowed', loading)
    }
  }
  
  shake() {
    if (this.hasModalTarget) {
      this.modalTarget.style.animation = 'shake 0.5s ease-in-out'
      setTimeout(() => {
        this.modalTarget.style.animation = ''
      }, 500)
    }
  }
  
  handleSuccess(data) {
    console.log('Login successful:', data)
    setTimeout(() => {
      window.location.href = data.redirect_url || this.closeUrlValue
    }, 1000)
  }
  
  handleError(data) {
    console.error('Login error:', data)
    
    // Show error banner if available
    if (this.hasErrorBannerTarget) {
      this.errorBannerTarget.style.display = 'block'
      
      // Display specific error messages
      if (data.errors) {
        let errorMessage = ''
        if (data.errors.base) {
          errorMessage = data.errors.base.join(', ')
        } else if (data.errors.email) {
          errorMessage = 'Email: ' + data.errors.email.join(', ')
        } else if (data.errors.password) {
          errorMessage = 'Password: ' + data.errors.password.join(', ')
        } else {
          errorMessage = 'Login failed. Please check your credentials.'
        }
        this.errorBannerTarget.textContent = errorMessage
      } else {
        this.errorBannerTarget.textContent = data.message || 'Login failed. Please try again.'
      }
    }
    
    // Clear any field-specific errors and show new ones
    if (data.errors) {
      if (data.errors.email && this.hasEmailErrorTarget) {
        this.emailErrorTarget.style.display = 'block'
        this.emailErrorTarget.textContent = data.errors.email.join(', ')
      }
      
      if (data.errors.password && this.hasPasswordErrorTarget) {
        this.passwordErrorTarget.style.display = 'block'
        this.passwordErrorTarget.textContent = data.errors.password.join(', ')
      }
    }
    
    this.shake()
  }
}