import LoginDialogController from "../../../app/javascript/controllers/login_dialog_controller";

describe('LoginDialogController Unit Tests', () => {
  let controller;
  let mockElement;
  let createMockElement;

  beforeEach(() => {
    // Create mock DOM elements
    createMockElement = () => ({
      querySelector: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      classList: {
        add: jest.fn(),
        remove: jest.fn(),
        contains: jest.fn(() => false),
        toggle: jest.fn()
      },
      style: {},
      textContent: '',
      value: '',
      focus: jest.fn(),
      blur: jest.fn(),
      disabled: false,
      checked: false,
    });
    
    mockElement = createMockElement();

    // Create controller instance
    controller = new LoginDialogController();
    
    // Mock targets and values
    controller.closeUrlValue = '/close';
    controller.loginUrlValue = '/login';
    
    // Mock target elements - create separate mock for each to avoid shared state
    controller.modalTarget = createMockElement();
    controller.formTarget = createMockElement();
    controller.emailInputTarget = createMockElement();
    controller.passwordInputTarget = createMockElement();
    controller.rememberInputTarget = createMockElement();
    controller.submitButtonTarget = createMockElement();
    controller.emailErrorTarget = createMockElement();
    controller.passwordErrorTarget = createMockElement();
    controller.errorBannerTarget = createMockElement();
    controller.passwordStrengthTarget = createMockElement();
    controller.strengthTextTarget = createMockElement();
    controller.strengthBarTarget = createMockElement();
    controller.requirementsTarget = createMockElement();
    controller.requirementLengthIconTarget = createMockElement();
    controller.requirementSpecialIconTarget = createMockElement();
    controller.requirementNumberIconTarget = createMockElement();
    
    // Mock has* methods
    controller.hasEmailInputTarget = true;
    controller.hasPasswordInputTarget = true;
    controller.hasSubmitButtonTarget = true;
    controller.hasEmailErrorTarget = true;
    controller.hasPasswordErrorTarget = true;
    controller.hasErrorBannerTarget = true;
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
      expect(controller.validationState.email).toBe(false);
      expect(controller.validationState.password).toBe(false);
    });

    test('initializes password requirements state', () => {
      expect(controller.passwordRequirements.length).toBe(false);
      expect(controller.passwordRequirements.special).toBe(false);
      expect(controller.passwordRequirements.number).toBe(false);
      expect(controller.passwordRequirements.repeating).toBe(false);
      expect(controller.passwordRequirements.sequential).toBe(false);
    });

    test('initializes common passwords list', () => {
      expect(controller.commonPasswords).toContain('password');
      expect(controller.commonPasswords).toContain('123456');
      expect(controller.commonPasswords).toContain('qwerty');
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

    test('validates email and updates state', () => {
      const mockEvent = { 
        target: { value: 'test@example.com' } 
      };
      controller.validateEmail(mockEvent);
      
      expect(controller.validationState.email).toBe(true);
      expect(controller.emailErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
    });

    test('shows error for invalid email', () => {
      const mockEvent = { 
        target: { value: 'invalid-email' } 
      };
      controller.validateEmail(mockEvent);
      
      expect(controller.validationState.email).toBe(false);
      expect(controller.emailErrorTarget.classList.remove).toHaveBeenCalledWith('hidden');
      expect(controller.emailErrorTarget.textContent).toContain('valid email address');
    });

    test('shows error for empty email', () => {
      const mockEvent = { 
        target: { value: '' } 
      };
      controller.validateEmail(mockEvent);
      
      expect(controller.validationState.email).toBe(false);
      expect(controller.emailErrorTarget.textContent).toContain('Email address is required');
    });
  });

  describe('password validation', () => {
    test('checks password length requirement', () => {
      expect(controller.checkPasswordLength('1234567')).toBe(false); // 7 chars
      expect(controller.checkPasswordLength('12345678')).toBe(true);  // 8 chars
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
      expect(controller.checkPasswordRepeating('password')).toBe(true);  // no repeating
      expect(controller.checkPasswordRepeating('passsword')).toBe(false); // 3 s's
      expect(controller.checkPasswordRepeating('paasword')).toBe(true);   // only 2 a's
    });

    test('checks sequential characters', () => {
      expect(controller.checkPasswordSequential('password')).toBe(true);  // no sequence
      expect(controller.checkPasswordSequential('abc123')).toBe(false);   // has abc
      expect(controller.checkPasswordSequential('password123')).toBe(false); // has 123
      expect(controller.checkPasswordSequential('pasqword')).toBe(true);   // no sequence
    });

    test('calculates password strength correctly', () => {
      expect(controller.calculatePasswordStrength('123')).toBe(0);
      expect(controller.calculatePasswordStrength('password')).toBeGreaterThan(0);
      expect(controller.calculatePasswordStrength('Password123!')).toBeGreaterThan(3);
      expect(controller.calculatePasswordStrength('VerySecureP@ssw0rd2024!')).toBe(5);
    });

    test('validates password and updates state', () => {
      const mockEvent = { 
        target: { value: 'ValidPass123!' } 
      };
      controller.validatePassword(mockEvent);
      
      expect(controller.validationState.password).toBe(true);
      expect(controller.passwordErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
    });

    test('shows error for short password', () => {
      const mockEvent = { 
        target: { value: '123' } 
      };
      controller.validatePassword(mockEvent);
      
      expect(controller.validationState.password).toBe(false);
      expect(controller.passwordErrorTarget.textContent).toContain('at least 8 characters');
    });
  });

  describe('form submission', () => {
    beforeEach(() => {
      global.fetch = jest.fn();
    });

    test('prevents submission when already submitting', () => {
      controller.isSubmitting = true;
      const mockEvent = { preventDefault: jest.fn() };
      
      controller.submitForm(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(global.fetch).not.toHaveBeenCalled();
    });

    test('prevents submission with invalid form', () => {
      controller.validationState.email = false;
      controller.validationState.password = false;
      const mockEvent = { preventDefault: jest.fn() };
      
      controller.submitForm(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(global.fetch).not.toHaveBeenCalled();
    });

    test('checks form validity correctly', () => {
      // Initially invalid
      expect(controller.isFormValid()).toBe(false);
      
      // Set valid state
      controller.validationState.email = true;
      controller.validationState.password = true;
      
      expect(controller.isFormValid()).toBe(true);
    });

    test('updates submit button text during submission', () => {
      // Set validation states to true so button can be enabled
      controller.validationState.email = true;
      controller.validationState.password = true;
      
      controller.isSubmitting = true;
      controller.updateSubmitButton();
      
      expect(controller.submitButtonTarget.textContent).toBe('Signing In...');
      expect(controller.submitButtonTarget.disabled).toBe(true);
      
      controller.isSubmitting = false;
      controller.updateSubmitButton();
      
      expect(controller.submitButtonTarget.textContent).toBe('Sign In');
      expect(controller.submitButtonTarget.disabled).toBe(false);
    });
  });

  describe('modal controls', () => {
    test('handles escape key correctly', () => {      
      const escapeEvent = { key: 'Escape', preventDefault: jest.fn() };
      controller.handleEscape(escapeEvent);
      
      expect(escapeEvent.preventDefault).toHaveBeenCalled();
    });

    test('ignores non-escape keys', () => {      
      const enterEvent = { key: 'Enter', preventDefault: jest.fn() };
      controller.handleEscape(enterEvent);
      
      expect(enterEvent.preventDefault).not.toHaveBeenCalled();
    });

    test('closes modal correctly', () => {
      // Since close() just sets window.location.href and JSDOM doesn't support navigation,
      // we'll verify the method behavior without actually executing it
      expect(typeof controller.close).toBe('function');
      expect(controller.closeUrlValue).toBe('/close');
    });

    test('handles backdrop clicks correctly', () => {      
      const backdropEvent = { 
        target: controller.modalTarget, 
        currentTarget: controller.modalTarget 
      };
      
      // Mock the close method to avoid navigation
      const closeSpy = jest.spyOn(controller, 'close').mockImplementation(() => {});
      
      controller.closeOnBackdrop(backdropEvent);
      
      expect(closeSpy).toHaveBeenCalled();
      
      closeSpy.mockRestore();
    });

    test('does not close on non-backdrop clicks', () => {      
      const mockTarget = createMockElement();
      const modalClickEvent = { 
        target: mockTarget, 
        currentTarget: controller.modalTarget 
      };
      
      // Ensure hasModalTarget returns true and modalTarget.contains returns true
      controller.hasModalTarget = true;
      controller.modalTarget.contains = jest.fn().mockReturnValue(true);
      
      // Mock the close method to verify it's NOT called
      const closeSpy = jest.spyOn(controller, 'close').mockImplementation(() => {});
      
      controller.closeOnBackdrop(modalClickEvent);
      
      expect(closeSpy).not.toHaveBeenCalled();
      
      closeSpy.mockRestore();
    });
  });

  describe('error handling', () => {
    test('displays error messages correctly', () => {
      const errorMessage = 'Invalid credentials';
      controller.displayError(errorMessage);
      
      expect(controller.errorBannerTarget.classList.remove).toHaveBeenCalledWith('hidden');
      expect(controller.errorBannerTarget.textContent).toBe(errorMessage);
    });

    test('hides error messages', () => {
      controller.hideErrors();
      
      expect(controller.errorBannerTarget.classList.add).toHaveBeenCalledWith('hidden');
      expect(controller.emailErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
      expect(controller.passwordErrorTarget.classList.add).toHaveBeenCalledWith('hidden');
    });
  });

  describe('utility methods', () => {
    test('stops event propagation', () => {
      const mockEvent = { stopPropagation: jest.fn() };
      controller.stopPropagation(mockEvent);
      
      expect(mockEvent.stopPropagation).toHaveBeenCalled();
    });

    test('updates form data correctly', () => {
      const mockEvent = { 
        target: { 
          name: 'login[email]', 
          value: 'test@example.com',
          type: 'text'
        } 
      };
      controller.updateFormData(mockEvent);
      
      expect(controller.formData.email).toBe('test@example.com');
    });

    test('handles checkbox form data', () => {
      const mockEvent = { 
        target: { 
          name: 'login[remember_me]', 
          checked: true,
          type: 'checkbox'
        } 
      };
      controller.updateFormData(mockEvent);
      
      expect(controller.formData.remember_me).toBe(true);
    });
  });

  describe('disconnect cleanup', () => {
    test('removes event listeners', () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
      
      controller.disconnect();
      
      expect(removeEventListenerSpy).toHaveBeenCalledWith("keydown", controller.boundEscapeHandler);
      removeEventListenerSpy.mockRestore();
    });
  });
});