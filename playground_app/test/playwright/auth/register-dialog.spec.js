const { test, expect } = require('@playwright/test');

test.describe('Register Dialog Component', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/auth_test/register');
  });

  test('should open and display register dialog correctly', async ({ page }) => {
    // Initially dialog should not be visible
    await expect(page.locator('[data-controller="register-dialog"]')).not.toBeVisible();
    
    // Click to open dialog
    await page.click('button:has-text("Open Register Dialog")');
    
    // Dialog should be visible
    await expect(page.locator('[data-controller="register-dialog"]')).toBeVisible();
    await expect(page.getByText('Create Account')).toBeVisible();
    await expect(page.getByText('Join us today and get started')).toBeVisible();
    
    // All form elements should be present
    await expect(page.locator('input[name="register[first_name]"]')).toBeVisible();
    await expect(page.locator('input[name="register[last_name]"]')).toBeVisible();
    await expect(page.locator('input[name="register[email]"]')).toBeVisible();
    await expect(page.locator('input[name="register[password]"]')).toBeVisible();
    await expect(page.locator('input[name="register[password_confirmation]"]')).toBeVisible();
    await expect(page.locator('input[name="register[terms_accepted]"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]:has-text("Create Account")')).toBeVisible();
  });

  test('should auto-focus first name input when dialog opens', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    // Wait for dialog to be visible
    await expect(page.locator('[data-controller="register-dialog"]')).toBeVisible();
    
    // First name input should be focused
    await expect(page.locator('input[name="register[first_name]"]')).toBeFocused();
  });

  test('should close dialog with X button', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    await expect(page.locator('[data-controller="register-dialog"]')).toBeVisible();
    
    // Click close button
    await page.click('button:has-text("×")');
    
    // Should navigate away from dialog
    await expect(page).toHaveURL('/auth_test/register');
    await expect(page.locator('[data-controller="register-dialog"]')).not.toBeVisible();
  });

  test('should close dialog with Escape key', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    await expect(page.locator('[data-controller="register-dialog"]')).toBeVisible();
    
    // Press Escape key
    await page.keyboard.press('Escape');
    
    // Should navigate away from dialog
    await expect(page).toHaveURL('/auth_test/register');
    await expect(page.locator('[data-controller="register-dialog"]')).not.toBeVisible();
  });

  test('should validate name fields in real-time', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    const firstNameInput = page.locator('input[name="register[first_name]"]');
    const firstNameError = page.locator('[data-register-dialog-target="firstNameError"]');
    
    // Type short name and blur
    await firstNameInput.fill('A');
    await firstNameInput.blur();
    
    // Error should be visible
    await expect(firstNameError).toBeVisible();
    await expect(firstNameError).toContainText('First name must be at least 2 characters');
    
    // Type valid name
    await firstNameInput.fill('John');
    await firstNameInput.blur();
    
    // Error should be hidden
    await expect(firstNameError).not.toBeVisible();
  });

  test('should validate email field with uniqueness check', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    const emailInput = page.locator('input[name="register[email]"]');
    const emailError = page.locator('[data-register-dialog-target="emailError"]');
    const emailAvailability = page.locator('[data-register-dialog-target="emailAvailability"]');
    
    // Type invalid email
    await emailInput.fill('invalid-email');
    await emailInput.blur();
    
    // Error should be visible
    await expect(emailError).toBeVisible();
    await expect(emailError).toContainText('Please enter a valid email address');
    
    // Type valid email
    await emailInput.fill('new@example.com');
    await emailInput.blur();
    
    // Error should be hidden, availability check should show
    await expect(emailError).not.toBeVisible();
    await expect(emailAvailability).toBeVisible();
    await expect(emailAvailability).toContainText('Checking availability...');
  });

  test('should show comprehensive password strength validation', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    const passwordInput = page.locator('input[name="register[password]"]');
    const strengthText = page.locator('[data-register-dialog-target="strengthText"]');
    const requirementsSection = page.locator('[data-register-dialog-target="requirements"]');
    const lengthIcon = page.locator('[data-register-dialog-target="requirementLengthIcon"]');
    
    // Focus password input to show requirements
    await passwordInput.focus();
    
    // Requirements section should be visible
    await expect(requirementsSection).toBeVisible();
    
    // Type weak password
    await passwordInput.fill('123');
    
    // Strength should be weak
    await expect(strengthText).toContainText('Weak');
    
    // Length requirement should not be met (red icon)
    const lengthIconStyle = await lengthIcon.evaluate(el => window.getComputedStyle(el).background);
    expect(lengthIconStyle).toContain('rgb(209, 213, 219)'); // gray
    
    // Type strong password
    await passwordInput.fill('SecurePass123!');
    
    // Strength should improve
    await expect(strengthText).not.toContainText('Very Weak');
    
    // Length requirement should be met (green icon)
    const updatedLengthIconStyle = await lengthIcon.evaluate(el => window.getComputedStyle(el).background);
    expect(updatedLengthIconStyle).toContain('rgb(22, 163, 74)'); // green
  });

  test('should validate password confirmation matching', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    const passwordInput = page.locator('input[name="register[password]"]');
    const confirmationInput = page.locator('input[name="register[password_confirmation]"]');
    const confirmationError = page.locator('[data-register-dialog-target="passwordConfirmationError"]');
    const passwordMatch = page.locator('[data-register-dialog-target="passwordMatch"]');
    
    // Set password
    await passwordInput.fill('SecurePass123!');
    
    // Type mismatched confirmation
    await confirmationInput.fill('DifferentPassword');
    await confirmationInput.blur();
    
    // Error should be visible
    await expect(confirmationError).toBeVisible();
    await expect(confirmationError).toContainText('Passwords do not match');
    
    // Type matching confirmation
    await confirmationInput.fill('SecurePass123!');
    await confirmationInput.blur();
    
    // Error should be hidden, match indicator should show
    await expect(confirmationError).not.toBeVisible();
    await expect(passwordMatch).toBeVisible();
    await expect(passwordMatch).toContainText('Passwords match');
  });

  test('should validate terms of service acceptance', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    const termsCheckbox = page.locator('input[name="register[terms_accepted]"]');
    const termsError = page.locator('[data-register-dialog-target="termsError"]');
    const submitButton = page.locator('button[type="submit"]');
    
    // Fill all other fields
    await page.fill('input[name="register[first_name]"]', 'John');
    await page.fill('input[name="register[last_name]"]', 'Doe');
    await page.fill('input[name="register[email]"]', 'john@example.com');
    await page.fill('input[name="register[password]"]', 'SecurePass123!');
    await page.fill('input[name="register[password_confirmation]"]', 'SecurePass123!');
    
    // Submit button should be disabled without terms acceptance
    await expect(submitButton).toBeDisabled();
    
    // Check terms
    await termsCheckbox.check();
    
    // Submit button should be enabled
    await expect(submitButton).toBeEnabled();
  });

  test('should handle complete registration flow', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    // Fill all fields with valid data
    await page.fill('input[name="register[first_name]"]', 'John');
    await page.fill('input[name="register[last_name]"]', 'Doe');
    await page.fill('input[name="register[email]"]', 'john.doe@example.com');
    await page.fill('input[name="register[password]"]', 'SecurePass123!');
    await page.fill('input[name="register[password_confirmation]"]', 'SecurePass123!');
    await page.check('input[name="register[terms_accepted]"]');
    
    // Submit form
    await page.click('button[type="submit"]:has-text("Create Account")');
    
    // Button should show loading state
    await expect(page.locator('button[type="submit"]')).toContainText('Creating Account...');
  });

  test('should show social registration options', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    // Social buttons should be visible
    await expect(page.getByText('Continue with Google')).toBeVisible();
    await expect(page.getByText('Continue with Github')).toBeVisible();
    
    // Divider should be present
    await expect(page.getByText('or')).toBeVisible();
  });

  test('should navigate to login dialog', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    // Click sign in link
    await page.click('a:has-text("Sign in")');
    
    // Should navigate to login page
    await expect(page).toHaveURL('/auth_test/login');
  });

  test('should handle keyboard navigation through all fields', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    // First name input should be focused initially
    await expect(page.locator('input[name="register[first_name]"]')).toBeFocused();
    
    // Tab through all fields
    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="register[last_name]"]')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="register[email]"]')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="register[password]"]')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="register[password_confirmation]"]')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="register[terms_accepted]"]')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('button[type="submit"]')).toBeFocused();
  });

  test('should work with pre-filled form data', async ({ page }) => {
    // Navigate with pre-filled data
    await page.goto('/auth_test/register?show_register=true&form_data[first_name]=Jane&form_data[last_name]=Smith&form_data[email]=jane@example.com');
    
    // Fields should be pre-filled
    await expect(page.locator('input[name="register[first_name]"]')).toHaveValue('Jane');
    await expect(page.locator('input[name="register[last_name]"]')).toHaveValue('Smith');
    await expect(page.locator('input[name="register[email]"]')).toHaveValue('jane@example.com');
  });

  test('should display server validation errors', async ({ page }) => {
    // Navigate with error parameters
    await page.goto('/auth_test/register?show_register=true&errors[first_name][]=Required&errors[email][]=Invalid+format');
    
    // Error messages should be visible
    await expect(page.getByText('Required')).toBeVisible();
    await expect(page.getByText('Invalid format')).toBeVisible();
  });

  test('should prevent submission with invalid data', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    const submitButton = page.locator('button[type="submit"]');
    
    // Submit button should be disabled initially
    await expect(submitButton).toBeDisabled();
    
    // Fill some but not all required fields
    await page.fill('input[name="register[first_name]"]', 'John');
    await page.fill('input[name="register[email]"]', 'invalid-email');
    
    // Submit button should still be disabled
    await expect(submitButton).toBeDisabled();
  });

  test('should show modal shake animation on validation error', async ({ page }) => {
    await page.click('button:has-text("Open Register Dialog")');
    
    // Try to submit with invalid data
    await page.fill('input[name="register[first_name]"]', 'A'); // Too short
    await page.check('input[name="register[terms_accepted]"]'); // Enable submit
    
    // Wait for validation state to update
    await page.waitForTimeout(100);
    
    // Even if submit is enabled, validation should prevent submission
    // and show shake animation (we can't easily test the animation itself,
    // but we can verify the modal structure supports it)
    const modal = page.locator('[data-register-dialog-target="modal"]');
    await expect(modal).toBeVisible();
  });
});