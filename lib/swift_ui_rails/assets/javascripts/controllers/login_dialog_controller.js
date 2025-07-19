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
    
    // Focus email input
    if (this.hasEmailInputTarget) {
      setTimeout(() => this.emailInputTarget.focus(), 100)
    }
    
    // Show password requirements on password focus
    if (this.hasPasswordInputTarget && this.hasRequirementsTarget) {
      this.passwordInputTarget.addEventListener('focus', () => {
        this.requirementsTarget.style.display = 'block'
      })
    }
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
  }
  
  disconnect() {
    document.removeEventListener("keydown", this.boundEscapeHandler)
    document.body.style.overflow = ''
  }
  
  // Modal control methods
  close() {
    window.location.href = this.closeUrlValue
  }
  
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
  
  stopPropagation(event) {
    event.stopPropagation()
  }
  
  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
  
  // Form validation
  validateEmail() {
    const email = this.emailInputTarget.value.trim()
    const isValid = email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    
    this.validationState.email = isValid
    
    // Show/hide email error
    if (this.hasEmailErrorTarget) {
      if (!isValid && email.length > 0) {
        this.emailErrorTarget.style.display = 'block'
        this.emailErrorTarget.textContent = 'Please enter a valid email address'
      } else {
        this.emailErrorTarget.style.display = 'none'
      }
    }
    
    this.updateSubmitButton()
    return isValid
  }
  
  validatePassword() {
    const password = this.passwordInputTarget.value
    
    // Check individual requirements
    this.passwordRequirements.length = password.length >= 8
    this.passwordRequirements.special = /[!@#$%^&*(),.?":{}|<>]/.test(password)
    this.passwordRequirements.number = /\d/.test(password)
    this.passwordRequirements.repeating = !this.hasRepeatingCharacters(password)
    this.passwordRequirements.sequential = !this.hasSequentialCharacters(password)
    
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
    
    // Overall password validity
    const isValid = Object.values(this.passwordRequirements).every(req => req) && !isCommonPassword
    this.validationState.password = isValid
    
    // Show/hide password error
    if (this.hasPasswordErrorTarget) {
      if (!isValid && password.length > 0) {
        let errorMsg = ''
        if (isCommonPassword) {
          errorMsg = 'This password is too common. Please choose a more secure password.'
        } else if (!this.passwordRequirements.length) {
          errorMsg = 'Password must be at least 8 characters long'
        } else if (!this.passwordRequirements.special) {
          errorMsg = 'Password must contain at least one special character'
        } else if (!this.passwordRequirements.number) {
          errorMsg = 'Password must contain at least one number'
        } else if (!this.passwordRequirements.repeating) {
          errorMsg = 'Password cannot contain repeating characters'
        } else if (!this.passwordRequirements.sequential) {
          errorMsg = 'Password cannot contain sequential characters'
        }
        this.passwordErrorTarget.style.display = 'block'
        this.passwordErrorTarget.textContent = errorMsg
      } else {
        this.passwordErrorTarget.style.display = 'none'
      }
    }
    
    this.updateSubmitButton()
    return isValid
  }
  
  updateFormData() {
    // Update form validation
    this.validateEmail()
    this.validatePassword()
  }
  
  updateSubmitButton() {
    const allValid = this.validationState.email && this.validationState.password
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !allValid || this.isSubmitting
      this.submitButtonTarget.classList.toggle('opacity-50', !allValid)
      this.submitButtonTarget.classList.toggle('cursor-not-allowed', !allValid)
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
    const sequences = ['123', '234', '345', '456', '567', '678', '789', '890', 
                     'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi', 'hij', 
                     'ijk', 'jkl', 'klm', 'lmn', 'mno', 'nop', 'opq', 'pqr', 
                     'qrs', 'rst', 'stu', 'tuv', 'uvw', 'vwx', 'wxy', 'xyz']
    const lower = password.toLowerCase()
    return sequences.some(seq => lower.includes(seq) || lower.includes(seq.split('').reverse().join('')))
  }
  
  calculatePasswordStrength(password) {
    let score = 0
    
    // Length bonus
    if (password.length >= 8) score += 1
    if (password.length >= 12) score += 1
    
    // Character variety
    if (/[a-z]/.test(password)) score += 1
    if (/[A-Z]/.test(password)) score += 1
    if (/\d/.test(password)) score += 1
    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) score += 1
    
    // Penalties
    if (this.hasRepeatingCharacters(password)) score -= 1
    if (this.hasSequentialCharacters(password)) score -= 1
    if (this.commonPasswords.includes(password.toLowerCase())) score -= 2
    
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
    
    if (this.isSubmitting) return
    
    // Validate all fields
    const emailValid = this.validateEmail()
    const passwordValid = this.validatePassword()
    
    if (!emailValid || !passwordValid) {
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
    this.shake()
  }
}