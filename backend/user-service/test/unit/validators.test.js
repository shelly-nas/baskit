const {
  isValidEmail,
  isValidPassword,
  isValidDisplayName,
  getValidationErrors,
  registrationSchema,
  emailSchema,
  passwordSchema,
  displayNameSchema,
} = require('../../src/utils/validators');

describe('Validators - Email Validation', () => {
  describe('FR-001.1.2: Email format validation according to RFC 5322 standards', () => {
    test('should accept valid email addresses', () => {
      const validEmails = [
        'user@example.com',
        'john.doe@company.co.uk',
        'test+tag@domain.com',
        'user123@test-domain.com',
        'a@b.co',
      ];

      validEmails.forEach(email => {
        expect(isValidEmail(email)).toBe(true);
      });
    });

    test('should reject invalid email addresses', () => {
      const invalidEmails = [
        'notanemail',
        '@example.com',
        'user@',
        'user @example.com',
        'user@.com',
        'user@domain',
        '',
        null,
        undefined,
      ];

      invalidEmails.forEach(email => {
        expect(isValidEmail(email)).toBe(false);
      });
    });

    test('should provide clear error message for invalid email', () => {
      const { error } = emailSchema.validate('invalid-email');
      expect(error).toBeDefined();
      expect(error.message).toBe('Please enter a valid email address');
    });

    test('should handle email length limits (max 255 characters)', () => {
      const longEmail = 'a'.repeat(250) + '@example.com';
      expect(isValidEmail(longEmail)).toBe(false);
    });
  });
});

describe('Validators - Password Validation', () => {
  describe('FR-001.1.3: Password complexity requirements', () => {
    test('should accept passwords meeting all complexity requirements', () => {
      const validPasswords = [
        'SecurePass123!',
        'MyP@ssw0rd',
        'Complex1ty!',
        'Str0ng&P@ss',
        'Test1234!@#$',
      ];

      validPasswords.forEach(password => {
        expect(isValidPassword(password)).toBe(true);
      });
    });

    test('FR-001.1.3: Minimum 8 characters', () => {
      const shortPasswords = [
        'Short1!',
        'Ab1!',
        'Test1@',
      ];

      shortPasswords.forEach(password => {
        expect(isValidPassword(password)).toBe(false);
      });
    });

    test('FR-001.1.3: At least one uppercase letter', () => {
      const noUppercase = [
        'lowercase123!',
        'nouppercas3!',
        'test1234!@',
      ];

      noUppercase.forEach(password => {
        expect(isValidPassword(password)).toBe(false);
      });
    });

    test('FR-001.1.3: At least one lowercase letter', () => {
      const noLowercase = [
        'UPPERCASE123!',
        'ALLCAPS1234!',
        'TESTING123@',
      ];

      noLowercase.forEach(password => {
        expect(isValidPassword(password)).toBe(false);
      });
    });

    test('FR-001.1.3: At least one number', () => {
      const noNumber = [
        'NoNumbers!@#',
        'Password!Test',
        'SecurePass!',
      ];

      noNumber.forEach(password => {
        expect(isValidPassword(password)).toBe(false);
      });
    });

    test('FR-001.1.3: At least one special character', () => {
      const noSpecial = [
        'NoSpecial123',
        'Password1234',
        'TestCase123',
      ];

      noSpecial.forEach(password => {
        expect(isValidPassword(password)).toBe(false);
      });
    });

    test('should provide clear error message for weak password', () => {
      const { error } = passwordSchema.validate('weak');
      expect(error).toBeDefined();
      expect(error.message).toContain('Password must');
    });

    test('should reject empty password', () => {
      const { error } = passwordSchema.validate('');
      expect(error).toBeDefined();
      expect(error.message).toBe('Password is required');
    });
  });
});

describe('Validators - Display Name Validation', () => {
  describe('FR-001.1.4: Display name between 2 and 50 characters', () => {
    test('should accept valid display names', () => {
      const validNames = [
        'Jo',
        'John Doe',
        'Mary Jane Watson',
        'A'.repeat(50),
        'User123',
      ];

      validNames.forEach(name => {
        expect(isValidDisplayName(name)).toBe(true);
      });
    });

    test('should reject display names shorter than 2 characters', () => {
      const shortNames = ['A', '', 'J'];

      shortNames.forEach(name => {
        expect(isValidDisplayName(name)).toBe(false);
      });
    });

    test('should reject display names longer than 50 characters', () => {
      const longNames = [
        'A'.repeat(51),
        'A'.repeat(100),
        'This is a very long name that exceeds the fifty character limit',
      ];

      longNames.forEach(name => {
        expect(isValidDisplayName(name)).toBe(false);
      });
    });

    test('should provide clear error message for invalid display name', () => {
      const { error: shortError } = displayNameSchema.validate('A');
      expect(shortError).toBeDefined();
      expect(shortError.message).toBe('Name must be between 2 and 50 characters');

      const { error: longError } = displayNameSchema.validate('A'.repeat(51));
      expect(longError).toBeDefined();
      expect(longError.message).toBe('Name must be between 2 and 50 characters');
    });

    test('should trim whitespace from display name', () => {
      const { error, value } = displayNameSchema.validate('  John Doe  ');
      expect(error).toBeUndefined();
      expect(value).toBe('John Doe');
    });

    test('should reject empty display name', () => {
      const { error } = displayNameSchema.validate('');
      expect(error).toBeDefined();
      expect(error.message).toBe('Display name is required');
    });
  });
});

describe('Validators - Registration Schema', () => {
  describe('FR-001.1.1: Registration with email, password, and display name', () => {
    test('should accept valid registration data', () => {
      const validData = {
        email: 'user@example.com',
        password: 'SecurePass123!',
        displayName: 'John Doe',
      };

      const { error } = registrationSchema.validate(validData);
      expect(error).toBeUndefined();
    });

    test('should reject registration with missing fields', () => {
      const missingEmail = {
        password: 'SecurePass123!',
        displayName: 'John Doe',
      };

      const missingPassword = {
        email: 'user@example.com',
        displayName: 'John Doe',
      };

      const missingDisplayName = {
        email: 'user@example.com',
        password: 'SecurePass123!',
      };

      expect(registrationSchema.validate(missingEmail).error).toBeDefined();
      expect(registrationSchema.validate(missingPassword).error).toBeDefined();
      expect(registrationSchema.validate(missingDisplayName).error).toBeDefined();
    });

    test('should return detailed validation errors for multiple fields', () => {
      const invalidData = {
        email: 'invalid-email',
        password: 'weak',
        displayName: 'A',
      };

      const errors = getValidationErrors(registrationSchema, invalidData);
      expect(errors).toBeDefined();
      expect(errors.email).toBeDefined();
      expect(errors.password).toBeDefined();
      expect(errors.displayName).toBeDefined();
    });

    test('should validate all fields independently', () => {
      const testCases = [
        {
          data: { email: 'invalid', password: 'SecurePass123!', displayName: 'John Doe' },
          expectedError: 'email',
        },
        {
          data: { email: 'user@example.com', password: 'weak', displayName: 'John Doe' },
          expectedError: 'password',
        },
        {
          data: { email: 'user@example.com', password: 'SecurePass123!', displayName: 'A' },
          expectedError: 'displayName',
        },
      ];

      testCases.forEach(({ data, expectedError }) => {
        const errors = getValidationErrors(registrationSchema, data);
        expect(errors).toBeDefined();
        expect(errors[expectedError]).toBeDefined();
      });
    });
  });
});

describe('Validators - Edge Cases', () => {
  test('should handle null values', () => {
    expect(isValidEmail(null)).toBe(false);
    expect(isValidPassword(null)).toBe(false);
    expect(isValidDisplayName(null)).toBe(false);
  });

  test('should handle undefined values', () => {
    expect(isValidEmail(undefined)).toBe(false);
    expect(isValidPassword(undefined)).toBe(false);
    expect(isValidDisplayName(undefined)).toBe(false);
  });

  test('should handle special characters in email', () => {
    expect(isValidEmail('user+tag@example.com')).toBe(true);
    expect(isValidEmail('user.name@example.com')).toBe(true);
    expect(isValidEmail('user_name@example.com')).toBe(true);
  });

  test('should handle unicode characters in display name', () => {
    expect(isValidDisplayName('José García')).toBe(true);
    expect(isValidDisplayName('李明')).toBe(true);
    expect(isValidDisplayName('Müller')).toBe(true);
  });

  test('should handle special characters in password', () => {
    const specialCharPasswords = [
      'Test123!@#$%',
      'Pass&word1',
      'Secure*Pass9',
      'My$ecure1',
    ];

    specialCharPasswords.forEach(password => {
      expect(isValidPassword(password)).toBe(true);
    });
  });
});
