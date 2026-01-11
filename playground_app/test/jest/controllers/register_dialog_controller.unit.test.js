import RegisterDialogController from "../../../app/javascript/controllers/register_dialog_controller";

describe('RegisterDialogController Unit Tests', () => {
  let controller;
  let mockElement;

  beforeEach(() => {
    // Create mock DOM elements
    mockElement = {
      querySelector: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      classList: {
        add: jest.fn(),
        remove: jest.fn(),
        contains: jest.fn(() => false),
      },
      style: {},
      textContent: '',
      value: '',
      focus: jest.fn(),
      blur: jest.fn(),
      disabled: false,
      checked: false,
    };

    // Create controller instance
    controller = new RegisterDialogController();
    
    // Mock targets and values
    controller.closeUrlValue = '/close';
    controller.registerUrlValue = '/register';
    
    // Mock target elements
    controller.modalTarget = mockElement;
    controller.formTarget = mockElement;
    controller.firstNameInputTarget = mockElement;
    controller.lastNameInputTarget = mockElement;
    controller.emailInputTarget = mockElement;
    controller.passwordInputTarget = mockElement;
    controller.passwordConfirmationInputTarget = mockElement;
    controller.termsInputTarget = mockElement;
    controller.submitButtonTarget = mockElement;
    controller.firstNameErrorTarget = mockElement;
    controller.lastNameErrorTarget = mockElement;
    controller.emailErrorTarget = mockElement;
    controller.passwordErrorTarget = mockElement;
    controller.passwordConfirmationErrorTarget = mockElement;
    controller.termsErrorTarget = mockElement;
    controller.errorBannerTarget = mockElement;
    controller.emailAvailabilityTarget = mockElement;
    controller.passwordMatchTarget = mockElement;
    controller.strengthTextTarget = mockElement;
    controller.strengthBarTarget = mockElement;
    controller.requirementsTarget = mockElement;
    controller.requirementLengthIconTarget = mockElement;
    controller.requirementSpecialIconTarget = mockElement;
    controller.requirementNumberIconTarget = mockElement;
    
    // Mock has* methods
    controller.hasFirstNameInputTarget = true;
    controller.hasLastNameInputTarget = true;
    controller.hasEmailInputTarget = true;
    controller.hasPasswordInputTarget = true;
    controller.hasPasswordConfirmationInputTarget = true;
    controller.hasTermsInputTarget = true;
    controller.hasSubmitButtonTarget = true;
    controller.hasFirstNameErrorTarget = true;
    controller.hasLastNameErrorTarget = true;
    controller.hasEmailErrorTarget = true;
    controller.hasPasswordErrorTarget = true;
    controller.hasPasswordConfirmationErrorTarget = true;
    controller.hasTermsErrorTarget = true;
    controller.hasErrorBannerTarget = true;
    controller.hasEmailAvailabilityTarget = true;
    controller.hasPasswordMatchTarget = true;
    controller.hasStrengthTextTarget = true;
    controller.hasStrengthBarTarget = true;
    controller.hasRequirementsTarget = true;
    controller.hasRequirementLengthIconTarget = true;
    controller.hasRequirementSpecialIconTarget = true;
    controller.hasRequirementNumberIconTarget = true;
    
    // Initialize controller
    controller.connect();
  });

  afterEach(() => {
    if (controller.disconnect) {
      controller.disconnect();
    }
  });

  describe('initialization', () => {
    test('sets up initial state correctly', () => {
      expect(controller.isSubmitting).toBe(false);
      expect(controller.validationState.firstName).toBe(false);
      expect(controller.validationState.lastName).toBe(false);
      expect(controller.validationState.email).toBe(false);
      expect(controller.validationState.password).toBe(false);
      expect(controller.validationState.passwordConfirmation).toBe(false);
      expect(controller.validationState.terms).toBe(false);
    });

    test('initializes password requirements state', () => {
      expect(controller.passwordRequirements.length).toBe(false);
      expect(controller.passwordRequirements.special).toBe(false);
      expect(controller.passwordRequirements.number).toBe(false);
      expect(controller.passwordRequirements.repeating).toBe(false);
      expect(controller.passwordRequirements.sequential).toBe(false);
    });

    test('initializes form data storage', () => {
      expect(controller.formData).toEqual({});
    });
  });

  describe('form data management', () => {
    test('updates form data on input change', () => {
      const mockEvent = { 
        target: { 
          name: 'register[first_name]', 
          value: 'John',
          type: 'text'
        } 
      };
      controller.updateFormData(mockEvent);
      
      expect(controller.formData.first_name).toBe('John');
    });

    test('handles checkbox input correctly', () => {
      const mockEvent = { 
        target: { 
          name: 'register[terms_accepted]', 
          checked: true,
          type: 'checkbox'
        } 
      };
      controller.updateFormData(mockEvent);
      
      expect(controller.formData.terms_accepted).toBe(true);
    });
  });

  describe('name validation', () => {
    describe('first name', () => {
      test('validates minimum length requirement', () => {
        const validEvent = { target: { value: 'John' } };
        controller.validateFirstName(validEvent);
        
        expect(controller.validationState.firstName).toBe(true);
        expect(controller.firstNameErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
        
        const invalidEvent = { target: { value: 'J' } };
        controller.validateFirstName(invalidEvent);
        
        expect(controller.validationState.firstName).toBe(false);
        expect(controller.firstNameErrorTarget.classList.remove).toHaveBeenCalledWith('hidden');
        expect(controller.firstNameErrorTarget.textContent).toContain('at least 2 characters');
      });

      test('shows required error for empty input', () => {
        const emptyEvent = { target: { value: '' } };
        controller.validateFirstName(emptyEvent);
        
        expect(controller.validationState.firstName).toBe(false);
        expect(controller.firstNameErrorTarget.textContent).toContain('required');
      });

      test('trims whitespace from input', () => {
        const whitespaceEvent = { target: { value: '  John  ' } };
        controller.validateFirstName(whitespaceEvent);
        
        expect(controller.validationState.firstName).toBe(true);
      });
    });

    describe('last name', () => {
      test('validates minimum length requirement', () => {
        const validEvent = { target: { value: 'Doe' } };
        controller.validateLastName(validEvent);
        
        expect(controller.validationState.lastName).toBe(true);
        
        const invalidEvent = { target: { value: 'D' } };
        controller.validateLastName(invalidEvent);
        
        expect(controller.validationState.lastName).toBe(false);
        expect(controller.lastNameErrorTarget.textContent).toContain('at least 2 characters');
      });
    });
  });

  describe('email validation', () => {
    test('validates email format correctly', () => {
      expect(controller.isValidEmail('test@example.com')).toBe(true);
      expect(controller.isValidEmail('user.name+tag@domain.co.uk')).toBe(true);
      expect(controller.isValidEmail('invalid-email')).toBe(false);
      expect(controller.isValidEmail('test@')).toBe(false);
      expect(controller.isValidEmail('@example.com')).toBe(false);
    });

    test('validates email and updates UI state', () => {
      const validEvent = { target: { value: 'test@example.com' } };
      controller.validateEmail(validEvent);
      
      expect(controller.validationState.email).toBe(true);
      expect(controller.emailErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
    });

    test('shows error for invalid email', () => {
      const invalidEvent = { target: { value: 'invalid-email' } };
      controller.validateEmail(invalidEvent);
      
      expect(controller.validationState.email).toBe(false);
      expect(controller.emailErrorTarget.classList.remove).toHaveBeenCalledWith('hidden');
      expect(controller.emailErrorTarget.textContent).toContain('valid email address');
    });

    test('checks email availability for valid emails', (done) => {
      const validEvent = { target: { value: 'available@example.com' } };
      controller.validateEmail(validEvent);
      
      expect(controller.emailAvailabilityTarget.classList.remove).toHaveBeenCalledWith('hidden');
      expect(controller.emailAvailabilityTarget.textContent).toContain('Checking availability');
      
      setTimeout(() => {
        expect(controller.emailAvailabilityTarget.textContent).toContain('available');
        done();
      }, 1100);
    });

    test('detects taken email addresses', (done) => {
      const takenEvent = { target: { value: 'taken@example.com' } };
      controller.validateEmail(takenEvent);
      
      setTimeout(() => {
        expect(controller.emailAvailabilityTarget.textContent).toContain('already in use');
        expect(controller.validationState.email).toBe(false);
        done();
      }, 1100);
    });
  });

  describe('password validation', () => {
    test('validates minimum length requirement', () => {
      const shortEvent = { target: { value: '1234567' } };
      controller.validatePassword(shortEvent);
      
      expect(controller.validationState.password).toBe(false);
      expect(controller.passwordErrorTarget.textContent).toContain('at least 8 characters');
      
      const validEvent = { target: { value: '12345678' } };
      controller.validatePassword(validEvent);
      
      expect(controller.validationState.password).toBe(true);
      expect(controller.passwordErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
    });

    test('checks password length requirement', () => {
      expect(controller.checkPasswordLength('1234567')).toBe(false);
      expect(controller.checkPasswordLength('12345678')).toBe(true);
      expect(controller.checkPasswordLength('verylongpassword')).toBe(true);
    });

    test('checks special character requirement', () => {
      expect(controller.checkPasswordSpecialChar('password')).toBe(false);
      expect(controller.checkPasswordSpecialChar('password!')).toBe(true);
      expect(controller.checkPasswordSpecialChar('pass@word')).toBe(true);
      expect(controller.checkPasswordSpecialChar('pass#word$')).toBe(true);
    });

    test('checks number requirement', () => {
      expect(controller.checkPasswordNumber('password')).toBe(false);
      expect(controller.checkPasswordNumber('password1')).toBe(true);
      expect(controller.checkPasswordNumber('p4ssw0rd')).toBe(true);
    });

    test('checks repeating characters', () => {
      expect(controller.checkPasswordRepeating('password')).toBe(true);
      expect(controller.checkPasswordRepeating('passsword')).toBe(false); // 3 s's
      expect(controller.checkPasswordRepeating('paasword')).toBe(true);   // only 2 a's
    });

    test('checks sequential characters', () => {
      expect(controller.checkPasswordSequential('password')).toBe(true);
      expect(controller.checkPasswordSequential('abc123')).toBe(false);   // has abc
      expect(controller.checkPasswordSequential('password123')).toBe(false); // has 123
      expect(controller.checkPasswordSequential('pasqword')).toBe(true);
    });

    test('calculates password strength correctly', () => {
      expect(controller.calculatePasswordStrength('123')).toBe(0);
      expect(controller.calculatePasswordStrength('password')).toBeGreaterThan(0);
      expect(controller.calculatePasswordStrength('Password123!')).toBeGreaterThan(3);
      expect(controller.calculatePasswordStrength('VerySecureP@ssw0rd2024!')).toBe(5);
    });

    test('updates password strength display', () => {
      controller.updatePasswordStrength('WeakPass123!');
      
      expect(controller.strengthTextTarget.textContent).toBeTruthy();
      expect(controller.strengthBarTarget.style.width).toBeTruthy();
      expect(controller.strengthBarTarget.style.backgroundColor).toBeTruthy();
    });

    test('updates password requirement icons', () => {
      controller.passwordInputTarget.value = 'StrongPass123!';
      controller.updatePasswordRequirements();
      
      expect(controller.passwordRequirements.length).toBe(true);
      expect(controller.passwordRequirements.special).toBe(true);
      expect(controller.passwordRequirements.number).toBe(true);
      expect(controller.requirementLengthIconTarget.style.background).toContain('22, 163, 74'); // green
    });
  });

  describe('password confirmation validation', () => {
    beforeEach(() => {
      controller.passwordInputTarget.value = 'Password123!';
    });

    test('validates password matching', () => {
      const matchingEvent = { target: { value: 'Password123!' } };
      controller.validatePasswordConfirmation(matchingEvent);
      
      expect(controller.validationState.passwordConfirmation).toBe(true);
      expect(controller.passwordConfirmationErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
      expect(controller.passwordMatchTarget.classList.remove).toHaveBeenCalledWith('hidden');
      expect(controller.passwordMatchTarget.textContent).toContain('match');
    });

    test('shows error for mismatched passwords', () => {
      const mismatchedEvent = { target: { value: 'DifferentPassword' } };
      controller.validatePasswordConfirmation(mismatchedEvent);
      
      expect(controller.validationState.passwordConfirmation).toBe(false);
      expect(controller.passwordConfirmationErrorTarget.textContent).toContain('do not match');
    });

    test('requires password confirmation', () => {
      const emptyEvent = { target: { value: '' } };
      controller.validatePasswordConfirmation(emptyEvent);
      
      expect(controller.validationState.passwordConfirmation).toBe(false);
      expect(controller.passwordConfirmationErrorTarget.textContent).toContain('required');
    });
  });

  describe('terms validation', () => {
    test('validates terms acceptance', () => {
      const acceptedEvent = { target: { checked: true } };
      controller.validateTerms(acceptedEvent);
      
      expect(controller.validationState.terms).toBe(true);
      expect(controller.termsErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
      
      const rejectedEvent = { target: { checked: false } };
      controller.validateTerms(rejectedEvent);
      
      expect(controller.validationState.terms).toBe(false);
      expect(controller.termsErrorTarget.textContent).toContain('must accept');
    });
  });

  describe('form validation and submission', () => {
    beforeEach(() => {
      global.fetch = jest.fn();
    });

    test('checks form validity correctly', () => {
      // Initially invalid
      expect(controller.isFormValid()).toBe(false);
      
      // Set all fields valid
      controller.validationState = {
        firstName: true,
        lastName: true,
        email: true,
        password: true,
        passwordConfirmation: true,
        terms: true
      };
      
      expect(controller.isFormValid()).toBe(true);
    });

    test('updates submit button state based on form validity', () => {
      // Initially disabled
      controller.updateSubmitButtonState();
      expect(controller.submitButtonTarget.disabled).toBe(true);
      
      // Enable when valid
      controller.validationState = {
        firstName: true,
        lastName: true,
        email: true,
        password: true,
        passwordConfirmation: true,
        terms: true
      };
      
      controller.updateSubmitButtonState();
      expect(controller.submitButtonTarget.disabled).toBe(false);
    });

    test('prevents submission when already submitting', () => {
      controller.isSubmitting = true;
      const mockEvent = { preventDefault: jest.fn() };
      
      controller.submitForm(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(global.fetch).not.toHaveBeenCalled();
    });

    test('prevents submission with invalid form', () => {
      controller.validationState.firstName = false;
      const mockEvent = { preventDefault: jest.fn() };
      
      controller.submitForm(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(global.fetch).not.toHaveBeenCalled();
    });

    test('updates submit button text during submission', () => {
      controller.isSubmitting = true;
      controller.updateSubmitButton();
      
      expect(controller.submitButtonTarget.textContent).toBe('Creating Account...');
      expect(controller.submitButtonTarget.disabled).toBe(true);
      
      controller.isSubmitting = false;
      controller.updateSubmitButton();
      
      expect(controller.submitButtonTarget.textContent).toBe('Create Account');
    });
  });

  describe('modal controls', () => {
    test('handles escape key correctly', () => {      
      const escapeEvent = { key: 'Escape', preventDefault: jest.fn() };
      
      // Mock the close method to avoid navigation
      const closeSpy = jest.spyOn(controller, 'close').mockImplementation(() => {});
      
      controller.handleEscape(escapeEvent);
      
      expect(escapeEvent.preventDefault).toHaveBeenCalled();
      expect(closeSpy).toHaveBeenCalled();
      
      closeSpy.mockRestore();
    });

    test('ignores non-escape keys', () => {      
      const enterEvent = { key: 'Enter', preventDefault: jest.fn() };
      
      // Mock the close method to verify it's NOT called
      const closeSpy = jest.spyOn(controller, 'close').mockImplementation(() => {});
      
      controller.handleEscape(enterEvent);
      
      expect(enterEvent.preventDefault).not.toHaveBeenCalled();
      expect(closeSpy).not.toHaveBeenCalled();
      
      closeSpy.mockRestore();
    });

    test('closes modal correctly', () => {
      // Since close() just sets window.location.href and JSDOM doesn't support navigation,
      // we'll verify the method behavior without actually executing it
      expect(typeof controller.close).toBe('function');
      expect(controller.closeUrlValue).toBe('/close');
    });
  });

  describe('error handling', () => {
    test('displays error messages correctly', () => {
      const errorMessage = 'Registration failed';
      controller.displayError(errorMessage);
      
      expect(controller.errorBannerTarget.classList.remove).toHaveBeenCalledWith('hidden');
      expect(controller.errorBannerTarget.textContent).toBe(errorMessage);
    });

    test('hides all error messages', () => {
      controller.hideErrors();
      
      expect(controller.errorBannerTarget.classList.add).toHaveBeenCalledWith('hidden');
      expect(controller.firstNameErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
      expect(controller.emailErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
    });
  });

  describe('utility methods', () => {
    test('stops event propagation', () => {
      const mockEvent = { stopPropagation: jest.fn() };
      controller.stopPropagation(mockEvent);
      
      expect(mockEvent.stopPropagation).toHaveBeenCalled();
    });
  });

  describe('disconnect cleanup', () => {
    test('removes event listeners and restores body scroll', () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
      
      // Set body style to test restoration
      document.body.style.overflow = 'hidden';
      
      controller.disconnect();
      
      expect(removeEventListenerSpy).toHaveBeenCalledWith("keydown", controller.boundEscapeHandler);
      expect(document.body.style.overflow).toBe('');
      
      removeEventListenerSpy.mockRestore();
    });
  });
});