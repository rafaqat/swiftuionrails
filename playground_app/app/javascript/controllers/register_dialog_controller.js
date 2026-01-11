import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="register-dialog"
export default class extends Controller {
  static targets = [
    "modal", "form", "firstNameInput", "lastNameInput", "emailInput", 
    "passwordInput", "passwordConfirmationInput", "termsInput", "submitButton",
    "firstNameError", "lastNameError", "emailError", "passwordError", 
    "passwordConfirmationError", "termsError", "errorBanner",
    "emailAvailability", "passwordMatch", "strengthText", "strengthBar", 
    "requirements", "requirementLengthIcon", "requirementSpecialIcon", 
    "requirementNumberIcon", "requirementRepeatingIcon", "requirementSequentialIcon"
  ]
  
  static values = {
    closeUrl: String,
    registerUrl: String
  }
  
  connect() {
    this.isSubmitting = false
    this.validationState = {
      firstName: false,
      lastName: false,
      email: false,
      password: false,
      passwordConfirmation: false,
      terms: false
    }
    
    // Password requirements state
    this.passwordRequirements = {
      length: false,
      special: false,
      number: false,
      repeating: false,
      sequential: false
    }
    
    // Form data storage
    this.formData = {}
    
    // Set up escape key listener
    this.boundEscapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
    
    // Focus first name input
    if (this.hasFirstNameInputTarget) {
      setTimeout(() => this.firstNameInputTarget.focus(), 100)
    }
    
    // Show password requirements on password focus
    if (this.hasPasswordInputTarget && this.hasRequirementsTarget) {
      this.passwordInputTarget.addEventListener('focus', () => {
        this.requirementsTarget.classList.remove('hidden')
      })
    }
    
    this.updateSubmitButtonState()
  }
  
  disconnect() {
    document.removeEventListener("keydown", this.boundEscapeHandler)
    document.body.style.overflow = ''
  }
  
  // Form data management
  updateFormData(event) {
    const field = event.target.name.replace('register[', '').replace(']', '')
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value
    this.formData[field] = value
    this.updateSubmitButtonState()
  }
  
  // Name validation
  validateFirstName(event) {
    const value = event.target.value.trim()
    const isValid = value.length >= 2
    
    this.validationState.firstName = isValid
    
    if (this.hasFirstNameErrorTarget) {
      if (!isValid && value.length > 0) {
        this.firstNameErrorTarget.textContent = 'First name must be at least 2 characters'
        this.firstNameErrorTarget.classList.remove('hidden')
      } else if (value.length === 0) {
        this.firstNameErrorTarget.textContent = 'First name is required'
        this.firstNameErrorTarget.classList.remove('hidden')
      } else {
        this.firstNameErrorTarget.classList.add('hidden')
      }
    }
    
    this.updateSubmitButtonState()
  }
  
  validateLastName(event) {
    const value = event.target.value.trim()
    const isValid = value.length >= 2
    
    this.validationState.lastName = isValid
    
    if (this.hasLastNameErrorTarget) {
      if (!isValid && value.length > 0) {
        this.lastNameErrorTarget.textContent = 'Last name must be at least 2 characters'
        this.lastNameErrorTarget.classList.remove('hidden')
      } else if (value.length === 0) {
        this.lastNameErrorTarget.textContent = 'Last name is required'
        this.lastNameErrorTarget.classList.remove('hidden')
      } else {
        this.lastNameErrorTarget.classList.add('hidden')
      }
    }
    
    this.updateSubmitButtonState()
  }
  
  // Email validation
  validateEmail(event) {
    const value = event.target.value.trim()
    const isValid = this.isValidEmail(value)
    
    this.validationState.email = isValid
    
    if (this.hasEmailErrorTarget) {
      if (!isValid && value.length > 0) {
        this.emailErrorTarget.textContent = 'Please enter a valid email address'
        this.emailErrorTarget.classList.remove('hidden')
      } else if (value.length === 0) {
        this.emailErrorTarget.textContent = 'Email address is required'
        this.emailErrorTarget.classList.remove('hidden')
      } else {
        this.emailErrorTarget.classList.add('hidden')
        this.checkEmailAvailability(value)
      }
    }
    
    this.updateSubmitButtonState()
  }
  
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }
  
  checkEmailAvailability(email) {
    if (this.hasEmailAvailabilityTarget) {
      this.emailAvailabilityTarget.classList.remove('hidden')
      this.emailAvailabilityTarget.textContent = 'Checking availability...'
      
      // Simulate availability check
      setTimeout(() => {
        if (email.includes('taken')) {
          this.emailAvailabilityTarget.textContent = 'Email already in use'
          this.emailAvailabilityTarget.className = 'text-red-600 text-sm'
          this.validationState.email = false
        } else {
          this.emailAvailabilityTarget.textContent = 'Email available'
          this.emailAvailabilityTarget.className = 'text-green-600 text-sm'
        }
        this.updateSubmitButtonState()
      }, 1000)
    }
  }
  
  // Password validation
  validatePassword(event) {
    const value = event.target.value
    const isValid = value.length >= 8
    
    this.validationState.password = isValid
    this.updatePasswordRequirements()
    
    if (this.hasPasswordErrorTarget) {
      if (!isValid && value.length > 0) {
        this.passwordErrorTarget.textContent = 'Password must be at least 8 characters'
        this.passwordErrorTarget.classList.remove('hidden')
      } else if (value.length === 0) {
        this.passwordErrorTarget.textContent = 'Password is required'
        this.passwordErrorTarget.classList.remove('hidden')
      } else {
        this.passwordErrorTarget.classList.add('hidden')
      }
    }
    
    this.updateSubmitButtonState()
    
    // Also validate password confirmation if it has a value
    if (this.hasPasswordConfirmationInputTarget && this.passwordConfirmationInputTarget.value) {
      this.validatePasswordConfirmation({ target: this.passwordConfirmationInputTarget })
    }
  }
  
  validatePasswordConfirmation(event) {
    const confirmationValue = event.target.value
    const passwordValue = this.hasPasswordInputTarget ? this.passwordInputTarget.value : ''
    const isValid = confirmationValue === passwordValue && passwordValue.length > 0
    
    this.validationState.passwordConfirmation = isValid
    
    if (this.hasPasswordConfirmationErrorTarget) {
      if (!isValid && confirmationValue.length > 0) {
        this.passwordConfirmationErrorTarget.textContent = 'Passwords do not match'
        this.passwordConfirmationErrorTarget.classList.remove('hidden')
        
        if (this.hasPasswordMatchTarget) {
          this.passwordMatchTarget.classList.add('hidden')
        }
      } else if (confirmationValue.length === 0) {
        this.passwordConfirmationErrorTarget.textContent = 'Password confirmation is required'
        this.passwordConfirmationErrorTarget.classList.remove('hidden')
      } else {
        this.passwordConfirmationErrorTarget.classList.add('hidden')
        
        if (this.hasPasswordMatchTarget) {
          this.passwordMatchTarget.textContent = 'Passwords match'
          this.passwordMatchTarget.className = 'text-green-600 text-sm'
          this.passwordMatchTarget.classList.remove('hidden')
        }
      }
    }
    
    this.updateSubmitButtonState()
  }
  
  // Terms validation
  validateTerms(event) {
    const isChecked = event.target.checked
    this.validationState.terms = isChecked
    
    if (this.hasTermsErrorTarget) {
      if (!isChecked) {
        this.termsErrorTarget.textContent = 'You must accept the terms of service'
        this.termsErrorTarget.classList.remove('hidden')
      } else {
        this.termsErrorTarget.classList.add('hidden')
      }
    }
    
    this.updateSubmitButtonState()
  }
  
  // Password requirements checking
  updatePasswordRequirements() {
    if (!this.hasPasswordInputTarget) return
    
    const password = this.passwordInputTarget.value
    
    this.passwordRequirements.length = this.checkPasswordLength(password)
    this.passwordRequirements.special = this.checkPasswordSpecialChar(password)
    this.passwordRequirements.number = this.checkPasswordNumber(password)
    this.passwordRequirements.repeating = this.checkPasswordRepeating(password)
    this.passwordRequirements.sequential = this.checkPasswordSequential(password)
    
    this.updatePasswordRequirementIcons()
    this.updatePasswordStrength(password)
  }
  
  checkPasswordLength(password) {
    return password.length >= 8
  }
  
  checkPasswordSpecialChar(password) {
    return /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)
  }
  
  checkPasswordNumber(password) {
    return /\d/.test(password)
  }
  
  checkPasswordRepeating(password) {
    return !/(.)\1{2,}/.test(password) // No character repeated 3+ times
  }
  
  checkPasswordSequential(password) {
    const sequences = ['abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi', 'hij', 'ijk', 'jkl', 'klm', 'lmn', 'mno', 'nop', 'opq', 'pqr', 'qrs', 'rst', 'stu', 'tuv', 'uvw', 'vwx', 'wxy', 'xyz', '123', '234', '345', '456', '567', '678', '789']
    return !sequences.some(seq => password.toLowerCase().includes(seq))
  }
  
  updatePasswordRequirementIcons() {
    const requirements = [
      { key: 'length', target: 'requirementLengthIcon' },
      { key: 'special', target: 'requirementSpecialIcon' },
      { key: 'number', target: 'requirementNumberIcon' },
      { key: 'repeating', target: 'requirementRepeatingIcon' },
      { key: 'sequential', target: 'requirementSequentialIcon' }
    ]
    
    requirements.forEach(req => {
      const targetName = req.target + 'Target'
      if (this['has' + req.target.charAt(0).toUpperCase() + req.target.slice(1) + 'Target']) {
        const element = this[targetName]
        if (this.passwordRequirements[req.key]) {
          element.style.background = 'rgb(22, 163, 74)' // green
        } else {
          element.style.background = 'rgb(209, 213, 219)' // gray
        }
      }
    })
  }
  
  updatePasswordStrength(password) {
    const strength = this.calculatePasswordStrength(password)
    const strengthLevels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong', 'Very Strong']
    
    if (this.hasStrengthTextTarget) {
      this.strengthTextTarget.textContent = strengthLevels[strength] || 'Very Weak'
    }
    
    if (this.hasStrengthBarTarget) {
      const percentage = (strength / 5) * 100
      this.strengthBarTarget.style.width = `${percentage}%`
      
      const colors = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#16a34a', '#15803d']
      this.strengthBarTarget.style.backgroundColor = colors[strength] || colors[0]
    }
  }
  
  calculatePasswordStrength(password) {
    // Must meet minimum length first
    if (password.length < 8) return 0
    
    let score = 0
    
    if (password.length >= 8) score++
    if (password.length >= 12) score++
    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score++
    if (/\d/.test(password)) score++
    if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) score++
    
    return Math.min(score, 5)
  }
  
  // Submit button state management
  updateSubmitButtonState() {
    if (this.hasSubmitButtonTarget) {
      const isValid = this.isFormValid()
      this.submitButtonTarget.disabled = !isValid || this.isSubmitting
    }
  }
  
  isFormValid() {
    return Object.values(this.validationState).every(state => state === true)
  }
  
  // Form submission
  async submitForm(event) {
    event.preventDefault()
    
    if (this.isSubmitting || !this.isFormValid()) {
      return
    }
    
    this.isSubmitting = true
    this.updateSubmitButton()
    this.hideErrors()
    
    try {
      const formData = new FormData(this.formTarget)
      const jsonData = {}
      
      for (let [key, value] of formData.entries()) {
        jsonData[key] = value
      }
      
      const response = await fetch(this.registerUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify(jsonData)
      })
      
      const data = await response.json()
      
      if (response.ok && data.success) {
        if (data.redirect) {
          window.location.href = data.redirect
        } else {
          this.close()
        }
      } else {
        this.displayError(data.error || 'Registration failed. Please try again.')
      }
    } catch (error) {
      this.displayError('Network error. Please check your connection and try again.')
    } finally {
      this.isSubmitting = false
      this.updateSubmitButton()
    }
  }
  
  updateSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      if (this.isSubmitting) {
        this.submitButtonTarget.textContent = 'Creating Account...'
        this.submitButtonTarget.disabled = true
        this.submitButtonTarget.classList.add('opacity-50')
      } else {
        this.submitButtonTarget.textContent = 'Create Account'
        this.submitButtonTarget.disabled = !this.isFormValid()
        this.submitButtonTarget.classList.remove('opacity-50')
      }
    }
  }
  
  // Error handling
  displayError(message) {
    if (this.hasErrorBannerTarget) {
      this.errorBannerTarget.textContent = message
      this.errorBannerTarget.classList.remove('hidden')
    }
  }
  
  hideErrors() {
    const errorTargets = [
      'errorBanner', 'firstNameError', 'lastNameError', 'emailError',
      'passwordError', 'passwordConfirmationError', 'termsError'
    ]
    
    errorTargets.forEach(target => {
      const targetName = target + 'Target'
      if (this['has' + target.charAt(0).toUpperCase() + target.slice(1) + 'Target']) {
        this[targetName].classList.add('hidden')
      }
    })
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
      event.preventDefault()
      this.close()
    }
  }
}